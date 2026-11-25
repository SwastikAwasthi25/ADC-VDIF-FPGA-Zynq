#define main original_first_frames_main
#include "cal9_first_frames_v1.c"
#undef main

#include <stdlib.h>
#include <signal.h>
#include <sys/stat.h>

#define CAPACITY 32768U
#define PERIOD 125000U
/* baseline supplied explicitly on command line */
#define BASE_SKIPPED 0U

struct metadata {
    uint32_t seq;
    uint32_t bank;
    uint32_t acknowledged;
    double host_time;
    double service_us;
};

static volatile sig_atomic_t interrupted;

static void on_signal(int sig)
{
    (void)sig;
    interrupted = 1;
}

static int fresh_status(void)
{
    if (!live() || (RD(0x008) & 0x23))
        return -1;

    WR(0x030, 1);

    if (!live() || (RD(0x008) & 4))
        return -1;

    WR(0x00C, 1);

    double deadline = now() + 0.1;

    while (now() < deadline) {

        if (!live())
            return -1;

        uint32_t state = RD(0x008);

        if ((state & 5) == 4)
            return live() ? 0 : -1;
    }

    return -1;
}

static int owns_bank(unsigned bank, uint32_t seq)
{
    return (RD(0x018) & (1U << bank)) &&
           RD(bank ? 0x020 : 0x01C) == seq;
}

static int fast_ack(unsigned bank, uint32_t seq)
{
    if (fresh_status() != 0 ||
        !owns_bank(bank, seq) ||
        !live() ||
        (RD(0x008) & 0x23))
        return -1;

    WR(0x030, 2);

    if (RD(0x008) & 8)
        return -1;

    WR(0x010, seq);
    WR(0x014, bank);
    WR(0x040, epoch);

    if (RD(0x010) != seq ||
        RD(0x014) != bank ||
        RD(0x040) != epoch ||
        !live())
        return -1;

    WR(0x00C, 2);

    double deadline = now() + 0.1;

    while (now() < deadline) {

        if (!live())
            return -1;

        uint32_t state = RD(0x008);

        if ((state & 0x0A) == 8) {

            if (!(state & 0x10) ||
                RD(0x028) != 1)
                return -1;

            return live() ? 0 : -1;
        }
    }

    return -1;
}

static int is_drained(void)
{
    return (RD(0x054) & 0x39) == 0x30 &&
           RD(0x018) == 0 &&
           RD(0x05C) == RD(0x060) &&
           RD(0x060) == RD(0x024);
}

static int valid_frame(const uint32_t *w)
{
    if ((w[2] & 0x00FFFFFFU) != 132U)
        return 0;

    /* Non-legacy, non-invalid VDIF frame. */

    if (w[0] & 0xC0000000U)
        return 0;

    /* One channel, real, 8-bit, thread zero. */

    if ((w[2] >> 29) != 1U || (w[3] & 0xFFFFU) != 0x5342U)
        return 0;

    if (((w[2] >> 24) & 31U) != 0)
        return 0;

    if (w[3] & 0x80000000U)
        return 0;

    if (((w[3] >> 26) & 31U) != 7U)
        return 0;

    if (((w[3] >> 16) & 1023U) != 0)
        return 0;

    return 1;
}


/* SPSC: producer owns head, writer owns tail; release/acquire publishes
 * complete slots. Tail advances only after batch sync and VDIF readback. */
#include <pthread.h>
#include <stdatomic.h>
#include <errno.h>
#include <limits.h>
#define BATCH 256U
struct queue {
    uint32_t *data;
    struct metadata *meta;
    atomic_uint head, tail, written, failed, done;
    unsigned high;
    int fd, journal;
    pthread_t thread;
    int started;
    unsigned inject_fail_at; /* selftest only; zero in acquisition */
};

static int write_all(int fd, const void *buf, size_t len)
{
    const unsigned char *p = buf;
    while (len) {
        ssize_t n = write(fd, p, len);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) return -1;
        p += n; len -= (size_t)n;
    }
    return 0;
}
static int read_at(int fd, void *buf, size_t len, off_t off)
{
    unsigned char *p = buf;
    while (len) {
        ssize_t n = pread(fd, p, len, off);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) return -1;
        p += n; len -= (size_t)n; off += n;
    }
    return 0;
}
static int sync_dir(void)
{
    int fd = open(".", O_RDONLY | O_DIRECTORY);
    if (fd < 0) return -1;
    int rc = fsync(fd);
    if (close(fd) != 0) rc = -1;
    return rc;
}
static int journal_row(int fd, const struct metadata *m)
{
    char row[160];
    int n = snprintf(row, sizeof(row), "%u,%u,%u,%.9f,%.3f\n",
                     m->seq,m->bank,m->acknowledged,
                     m->host_time,m->service_us);
    return n > 0 && (size_t)n < sizeof(row) ?
           write_all(fd,row,(size_t)n) : -1;
}
static const char csv_header[] =
    "sequence,bank,acknowledged,host_elapsed_seconds,service_us\n";

static void *storage_worker(void *arg)
{
    struct queue *q = arg;
    unsigned tail = 0;
    uint32_t check[FRAME_WORDS];
    for (;;) {
        unsigned head = atomic_load_explicit(&q->head,memory_order_acquire);
        unsigned n = head - tail;
        int done = atomic_load_explicit(&q->done,memory_order_acquire);
        /* Re-read head after observing done to see the final publication. */
        if (done) {
            head = atomic_load_explicit(&q->head,memory_order_acquire);
            n = head - tail;
        }
        if (n == 0 && done) break;
        if (n < BATCH && !done) { usleep(1000); continue; }
        if (n > CAPACITY) goto fail;
        if (n > BATCH) n = BATCH;
        if (q->inject_fail_at && tail >= q->inject_fail_at) {
            errno = EIO; goto fail;
        }
        unsigned slot = tail % CAPACITY;
        unsigned first = CAPACITY - slot;
        if (first > n) first = n;
        if (write_all(q->fd, q->data + (size_t)slot*FRAME_WORDS,
                      (size_t)first*FRAME_WORDS*4) != 0) goto fail;
        if (n > first &&
            write_all(q->fd,q->data,(size_t)(n-first)*FRAME_WORDS*4) != 0)
            goto fail;
        for (unsigned i=0;i<n;i++)
            if (journal_row(q->journal,&q->meta[(tail+i)%CAPACITY]) != 0)
                goto fail;
        atomic_store_explicit(&q->written,tail+n,memory_order_release);
        if (fsync(q->fd) != 0 || fsync(q->journal) != 0) goto fail;
        for (unsigned i=0;i<n;i++) {
            if (read_at(q->fd,check,sizeof(check),
                        (off_t)(tail+i)*sizeof(check)) != 0 ||
                memcmp(check,q->data+(size_t)((tail+i)%CAPACITY)*FRAME_WORDS,
                       sizeof(check))) goto fail;
        }
        tail += n;
        atomic_store_explicit(&q->tail,tail,memory_order_release);
    }
    return NULL;
fail:
    atomic_store_explicit(&q->failed,1,memory_order_release);
    fprintf(stderr,"STORAGE_WORKER_FAILURE: tail=%u errno=%d\n",tail,errno);
    return NULL;
}
static void queue_init(struct queue *q, uint32_t *data, struct metadata *meta)
{
    memset(q,0,sizeof(*q));
    q->data=data; q->meta=meta; q->fd=-1; q->journal=-1;
    atomic_init(&q->head,0); atomic_init(&q->tail,0);
    atomic_init(&q->written,0); atomic_init(&q->failed,0);
    atomic_init(&q->done,0);
}
static int queue_start(struct queue *q)
{
    if (!atomic_is_lock_free(&q->head) || !atomic_is_lock_free(&q->tail) ||
        !atomic_is_lock_free(&q->failed) || !atomic_is_lock_free(&q->done) ||
        !atomic_is_lock_free(&q->written)) return -1;
    q->fd=open("native_ch0.vdif",O_CREAT|O_EXCL|O_RDWR,0600);
    if (q->fd < 0) return -1;
    q->journal=open("native_ch0.csv",O_CREAT|O_EXCL|O_WRONLY,0600);
    if (q->journal < 0) return -1;
    if (write_all(q->journal,csv_header,sizeof(csv_header)-1) != 0 ||
        fsync(q->fd) != 0 || fsync(q->journal) != 0 ||
        sync_dir() != 0) return -1;
    int e=pthread_create(&q->thread,NULL,storage_worker,q);
    if (e) { errno=e; return -1; }
    q->started=1;
    return 0;
}
static int queue_full(struct queue *q,unsigned head)
{
    return head-atomic_load_explicit(&q->tail,memory_order_acquire)>=CAPACITY;
}
static void queue_publish(struct queue *q,unsigned head)
{
    unsigned depth=head-atomic_load_explicit(&q->tail,memory_order_acquire);
    if (depth>q->high) q->high=depth;
    atomic_store_explicit(&q->head,head,memory_order_release);
}
/* Preserve unsynchronized suffix separately, never alter partial main files.
 * The suffix may overlap main files if a batch failed after a partial write. */
static int salvage(struct queue *q,unsigned first,unsigned end)
{
    int fd=open("unsynced_suffix.vdif",O_CREAT|O_EXCL|O_WRONLY,0600);
    if (fd<0) return -1;
    int j=open("unsynced_suffix.csv",O_CREAT|O_EXCL|O_WRONLY,0600);
    if (j<0) { close(fd); return -1; }
    int ok=write_all(j,csv_header,sizeof(csv_header)-1)==0;
    for (unsigned i=first;i<end && ok;i++) {
        unsigned slot=i%CAPACITY;
        if (write_all(fd,q->data+(size_t)slot*FRAME_WORDS,FRAME_WORDS*4) ||
            journal_row(j,&q->meta[slot])) ok=0;
    }
    if (fsync(fd)!=0) ok=0;
    if (fsync(j)!=0) ok=0;
    if (close(fd)!=0) ok=0;
    if (close(j)!=0) ok=0;
    if (sync_dir()!=0) ok=0;
    return ok?0:-1;
}
static int queue_finish(struct queue *q,unsigned buffered)
{
    int ok=1;
    if (q->started) {
        atomic_store_explicit(&q->done,1,memory_order_release);
        if (pthread_join(q->thread,NULL)!=0) {
            /* Do not free memory while a potentially live thread owns it. */
            fprintf(stderr,"STOP_WRITER_JOIN_FAILED\n");
            _Exit(7);
        }
    }
    unsigned tail=atomic_load(&q->tail);
    unsigned written=atomic_load(&q->written);
    printf("WRITER_WRITTEN_FRAMES: %u\n",written);
    printf("WRITER_SYNCED_READBACK_FRAMES: %u\n",tail);
    printf("QUEUE_HIGH_WATER_ESTIMATE: %u\n",q->high);
    printf("QUEUE_FINAL_PENDING: %u\n",buffered-tail);
    if (atomic_load(&q->failed) || tail!=buffered ||
        written!=buffered) ok=0;
    if (q->fd>=0) {
        struct stat st;
        if (fstat(q->fd,&st)!=0 ||
            st.st_size!=(off_t)buffered*FRAME_WORDS*4) ok=0;
        if (close(q->fd)!=0) ok=0;
    }
    if (q->journal>=0 && close(q->journal)!=0) ok=0;
    if (!ok && buffered>tail) {
        printf("UNSYNCED_SUFFIX_START_INDEX: %u\n",tail);
        puts(salvage(q,tail,buffered)==0 ?
             "UNSYNCED_SUFFIX_SAVED: YES" :
             "UNSYNCED_SUFFIX_SAVE_FAILED_DATA_AT_RISK");
    }
    if (sync_dir()!=0) ok=0;
    return ok?0:-1;
}
/* Offline test: same queue and writer, no /dev/mem access. */
static int queue_selftest(int fault)
{
    uint32_t *data=malloc((size_t)CAPACITY*FRAME_WORDS*4);
    struct metadata *meta=calloc(CAPACITY,sizeof(*meta));
    if (!data || !meta) { free(data); free(meta); return 2; }
    struct queue q;
    queue_init(&q,data,meta);
    if (fault) q.inject_fail_at=BATCH;
    if (!queue_full(&q,CAPACITY) || queue_full(&q,CAPACITY-1)) {
        free(data);free(meta);return 2;
    }
    unsigned n=0, target=fault?2*BATCH+1:CAPACITY+1024;
    int ok=queue_start(&q)==0;
    double deadline=now()+120;
    while (ok && n<target) {
        if (atomic_load(&q.failed)) break;
        if (now()>deadline) {ok=0;break;}
        if (queue_full(&q,n)) {usleep(1000);continue;}
        unsigned slot=n%CAPACITY;
        for (unsigned j=0;j<FRAME_WORDS;j++)
            data[(size_t)slot*FRAME_WORDS+j]=n^j;
        meta[slot]=(struct metadata){.seq=n,.bank=n%2,.acknowledged=1};
        queue_publish(&q,++n);
    }
    int finished=queue_finish(&q,n);
    if (fault) {
        ok=ok && finished!=0 && atomic_load(&q.failed) &&
           atomic_load(&q.tail)==BATCH && n>BATCH;
        FILE *f=fopen("unsynced_suffix.vdif","rb");
        uint32_t words[FRAME_WORDS];
        if (!f) ok=0;
        if (f) {
            for (unsigned i=BATCH;i<n && ok;i++) {
                if (fread(words,4,FRAME_WORDS,f)!=FRAME_WORDS) {ok=0;break;}
                for(unsigned j=0;j<FRAME_WORDS;j++)
                    if(words[j]!=(i^j)) {ok=0;break;}
            }
            if(fgetc(f)!=EOF || ferror(f))ok=0;
            fclose(f);
        }
    } else {
        ok=ok && finished==0 && n==target;
        FILE *f=fopen("native_ch0.vdif","rb");
        uint32_t words[FRAME_WORDS];
        if (!f) ok=0;
        if (f) {
            for (unsigned i=0;i<n && ok;i++) {
                if (fread(words,4,FRAME_WORDS,f)!=FRAME_WORDS) {ok=0;break;}
                for(unsigned j=0;j<FRAME_WORDS;j++)
                    if(words[j]!=(i^j)) {ok=0;break;}
            }
            if(fgetc(f)!=EOF || ferror(f))ok=0;
            fclose(f);
        }
    }
    free(data); free(meta);
    puts(ok ? (fault?"OFFLINE_WRITER_FAILURE_TEST: PASS":
                      "OFFLINE_RING_WRAP_TEST: PASS") :
              "OFFLINE_QUEUE_TEST: FAIL");
    puts("FPGA_ACCESSED: NO");
    return ok?0:6;
}

int main(int argc, char **argv)
{
    setvbuf(stdout, NULL, _IONBF, 0);

    if (argc == 3 && (!strcmp(argv[2],"--selftest") ||
                      !strcmp(argv[2],"--selftest-fault"))) {
        if (chdir(argv[1]) != 0) return 1;
        return queue_selftest(!strcmp(argv[2],"--selftest-fault"));
    }
    if (argc != 4 || chdir(argv[1]) != 0) return 1;
    char *end;
    errno=0;
    unsigned long duration=strtoul(argv[2],&end,10);
    if (errno || *end || (duration!=10 && duration!=60 && duration!=300))
        return 1;
    errno=0;
    unsigned long base=strtoul(argv[3],&end,10);
    if (errno || *end || base>UINT32_MAX-400000U) return 1;
    uint32_t base_completed=(uint32_t)base;

    if (access("native_ch0.vdif", F_OK) == 0 ||
        access("native_ch0.csv", F_OK) == 0) {

        puts("STOP_OUTPUT_ALREADY_EXISTS");
        return 1;
    }

    signal(SIGINT, on_signal);
    signal(SIGTERM, on_signal);

    size_t capacity_bytes =
        (size_t)CAPACITY * FRAME_WORDS * sizeof(uint32_t);

    uint32_t *data = malloc(capacity_bytes);

    struct metadata *meta =
        calloc(CAPACITY, sizeof(*meta));

    if (!data || !meta) {

        puts("STOP_RAM_ALLOCATION_FAILED");
        free(data);
        free(meta);
        return 2;
    }

    /* Prefault the recording buffer before START. */

    volatile unsigned char *pages =
        (volatile unsigned char *)data;

    for (size_t i = 0; i < capacity_bytes; i += 4096)
        pages[i] = 0;

    volatile unsigned char *mp =
        (volatile unsigned char *)meta;

    for (size_t i = 0;
         i < CAPACITY * sizeof(*meta);
         i += 4096)
        mp[i] = 0;

    int fd = open("/dev/mem", O_RDWR | O_SYNC);

    if (fd < 0) {
        free(data);
        free(meta);
        return 2;
    }

    void *ctrl = mmap(NULL, CTRL_SIZE,
        PROT_READ | PROT_WRITE,
        MAP_SHARED, fd, CTRL_BASE);

    void *bram = mmap(NULL, BRAM_SIZE,
        PROT_READ, MAP_SHARED, fd, BRAM_BASE);

    if (ctrl == MAP_FAILED || bram == MAP_FAILED) {

        puts("STOP_MMAP_FAILED");

        if (ctrl != MAP_FAILED)
            munmap(ctrl, CTRL_SIZE);

        if (bram != MAP_FAILED)
            munmap(bram, BRAM_SIZE);

        close(fd);
        free(data);
        free(meta);
        return 2;
    }

    r = ctrl;

    struct queue q;
    queue_init(&q,data,meta);
    unsigned buffered = 0;
    unsigned acknowledged = 0;

    int armed = 0;
    int stopped = 0;
    int rc = 3;

    double start = 0;
    double stop_requested = 0;
    double stop_ack = 0;
    double drain_deadline = 0;

    double service_sum = 0;
    double service_max = 0;

    epoch = RD(0x038);
    errors = RD(0x02C);

    if (RD(0x000) != 0x56344332 ||
        RD(0x004) != 0x00010003 ||
        epoch != 0 ||
        errors != 0 ||
        fresh_status() != 0 ||
        !is_drained() ||
        RD(0x024) != base_completed ||
        RD(0x064) != BASE_SKIPPED) {

        puts("STOP_NATIVE_RECORDER_PREFLIGHT_FAILED");
        goto done;
    }

    puts("NATIVE_RECORDER_PREFLIGHT: PASS");
    if (queue_start(&q)!=0) {
        puts("STOP_STORAGE_WRITER_START_FAILED");
        goto done;
    }
    puts("STORAGE_WRITER_READY: YES");
    if (interrupted || atomic_load(&q.failed)) goto done;

    WR(0x04C, PERIOD);

    if (RD(0x04C) != PERIOD || !live()) {

        puts("STOP_PERIOD_CONFIG_FAILED");
        goto done;
    }

    armed = 1;

    if (capture_command(1) != 0) {

        puts("STOP_START_FAILED");
        goto done;
    }

    start = now();

    if (fresh_status() != 0 ||
        !(RD(0x054) & 8) ||
        RD(0x058) != PERIOD) {

        puts("STOP_START_READBACK_FAILED");
        goto done;
    }

    puts("NATIVE_CAPTURE_START: PASS");

    double last_progress = start;

    while (1) {

        if (atomic_load_explicit(&q.failed,memory_order_acquire)) {
            puts("STOP_STORAGE_WORKER_FAILED");
            goto done;
        }
        if (fresh_status() != 0) {

            puts("STOP_STATUS_FAILED");
            goto done;
        }

        if (!stopped &&
            (interrupted || now() - start >= (double)duration)) {

            stop_requested = now();

            if (capture_command(2) != 0) {

                puts("STOP_COMMAND_FAILED");
                goto done;
            }

            stop_ack = now();
            stopped = 1;
            drain_deadline = stop_ack + 3.0;

            puts("NATIVE_CAPTURE_STOP_ACCEPTED");

            continue;
        }

        if (stopped && now() >= drain_deadline) {

            puts("STOP_DRAIN_TIMEOUT");
            goto done;
        }

        uint32_t mask = RD(0x018);

        if (mask & ~3U) {

            puts("STOP_INVALID_READY_MASK");
            goto done;
        }

        if (mask == 0) {

            if (stopped && is_drained())
                break;

            if (!stopped && !(RD(0x054) & 8)) {

                puts("STOP_UNEXPECTED_RUN_LOSS");
                goto done;
            }

            if (!stopped &&
                now() - last_progress > 2.0) {

                puts("STOP_NO_FRAME_PROGRESS");
                goto done;
            }

            continue;
        }

        uint32_t expected =
            base_completed + acknowledged;

        unsigned bank;

        if (owns_bank(0, expected))
            bank = 0;

        else if (owns_bank(1, expected))
            bank = 1;

        else {

            puts("STOP_SEQUENCE_DISCONTINUITY");
            goto done;
        }

        if (queue_full(&q,buffered)) {

            puts("STOP_RAM_BUFFER_FULL");
            goto done;
        }

        double service_start = now();

        uint32_t *dest =
            data + (size_t)(buffered % CAPACITY) * FRAME_WORDS;

        uint32_t second[FRAME_WORDS];

        volatile uint32_t *src =
            (volatile uint32_t *)
            ((char *)bram + bank * BANK_STRIDE);

        for (unsigned i = 0; i < FRAME_WORDS; i++)
            dest[i] = rd32(&src[i]);

        for (unsigned i = 0; i < FRAME_WORDS; i++)
            second[i] = rd32(&src[i]);

        if (memcmp(dest, second, sizeof(second))) {

            puts("STOP_DOUBLE_READ_MISMATCH");
            goto done;
        }

        if (!valid_frame(dest) ||
            (dest[1] & 0x00FFFFFFU) != (expected & 0x00FFFFFFU)) {

            puts("STOP_HEADER_VALIDATION_FAILED");
            goto done;
        }

        if (fresh_status() != 0 ||
            !owns_bank(bank, expected)) {

            puts("STOP_BANK_OWNERSHIP_CHANGED");
            goto done;
        }

        unsigned idx = buffered % CAPACITY;
        buffered++;

        meta[idx].seq = expected;
        meta[idx].bank = bank;
        meta[idx].host_time = now() - start;
        meta[idx].acknowledged = 0;

        if (atomic_load_explicit(&q.failed,memory_order_acquire)) {
            queue_publish(&q,buffered);
            puts("STOP_STORAGE_WORKER_FAILED_BEFORE_ACK");
            goto done;
        }
        if (fast_ack(bank, expected) != 0) {
            queue_publish(&q,buffered);
            puts("STOP_ACK_FAILED_OR_UNCERTAIN");
            goto done;
        }

        meta[idx].acknowledged = 1;

        acknowledged++;

        double service_us =
            (now() - service_start) * 1000000.0;

        meta[idx].service_us = service_us;
        queue_publish(&q,buffered);

        service_sum += service_us;

        if (service_us > service_max)
            service_max = service_us;

        last_progress = now();
    }

    if (fresh_status() != 0 ||
        !is_drained() ||
        RD(0x024) != base_completed + acknowledged ||
        buffered != acknowledged ||
        !live()) {

        puts("STOP_FINAL_COUNTER_MISMATCH");
        goto done;
    }

    armed = 0;

    uint32_t skipped =
        RD(0x064) - BASE_SKIPPED;

    show_status();

    printf("BUFFERED_FRAMES: %u\n", buffered);
    printf("ACKNOWLEDGED_FRAMES: %u\n", acknowledged);
    printf("NEW_SKIPPED_WINDOWS: %u\n", skipped);

    printf("HOST_CAPTURE_SECONDS: %.9f\n",
           stop_requested - start);

    printf("STOP_TO_DRAIN_SECONDS: %.9f\n",
           now() - stop_ack);

    printf("MEAN_FRAME_SERVICE_US: %.3f\n",
           acknowledged ?
           service_sum / acknowledged : 0);

    printf("MAX_FRAME_SERVICE_US: %.3f\n",
           service_max);

    puts("HARDWARE_RECONCILIATION: PASS");

    rc = (!interrupted &&
          acknowledged >= duration*1000UL-5 &&
          acknowledged <= duration*1000UL+5 &&
          skipped == 0) ? 0 : 4;

done:

    if (armed) {

        puts("ATTEMPTING_GUARDED_STOP");

        if (live() &&
            !(RD(0x054) & 1) &&
            capture_command(2) == 0 &&
            fresh_status() == 0 &&
            !(RD(0x054) & 8)) {

            puts("EMERGENCY_STOP_ACCEPTED");
            puts("PENDING_BANKS_MAY_REMAIN");
        } else {

            puts("STOP_UNCONFIRMED_MANUAL_DIAGNOSIS_REQUIRED");
        }
    }

    munmap(bram, BRAM_SIZE);
    munmap(ctrl, CTRL_SIZE);
    close(fd);

    if (q.started || q.fd>=0 || q.journal>=0) {
        if (queue_finish(&q,buffered)!=0) {
            puts("STOP_STORAGE_RECONCILIATION_FAILED");
            rc=5;
        } else {
            puts("FILE_WRITE_READBACK: PASS");
            puts("DIRECTORY_SYNC: PASS");
            puts("STORAGE_RECONCILIATION: PASS");
        }
    }

    free(data);
    free(meta);

    puts("RAM_BEFORE_ACK: YES");
    puts("POWER_LOSS_DURABILITY_BEFORE_ACK: NO");
    puts("DMA_STATUS: HOLD");
    puts("SCIENTIFIC_RECORDING_GO: NO");

    if (rc == 0)
        puts("CAL9_NATIVE_V3_ZERO_SKIP: PASS");
    else
        puts("CAL9_NATIVE_V3_QUALIFICATION: NOT_PASS");

    return rc;
}
