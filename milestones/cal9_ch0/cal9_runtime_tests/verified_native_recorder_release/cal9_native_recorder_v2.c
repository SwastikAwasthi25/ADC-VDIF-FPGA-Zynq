#define main original_first_frames_main
#include "cal9_first_frames_v1.c"
#undef main

#include <stdlib.h>
#include <signal.h>
#include <sys/stat.h>

#define CAPACITY 12000U
#define PERIOD 125000U
#define BASE_COMPLETED 3515U
#define BASE_SKIPPED 8498U

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

static int save_output(
    const uint32_t *data,
    const struct metadata *meta,
    unsigned buffered)
{
    FILE *f = fopen("native_ch0.vdif", "wbx");

    if (!f)
        return -1;

    size_t bytes =
        (size_t)buffered * FRAME_WORDS * sizeof(uint32_t);

    int ok = fwrite(data, 1, bytes, f) == bytes;

    if (fflush(f) != 0)
        ok = 0;

    if (fsync(fileno(f)) != 0)
        ok = 0;

    if (fclose(f) != 0)
        ok = 0;

    if (!ok)
        return -1;

    f = fopen("native_ch0.vdif", "rb");

    if (!f)
        return -1;

    uint32_t check[FRAME_WORDS];

    for (unsigned i = 0; i < buffered; i++) {

        if (fread(check, 1, sizeof(check), f)
                != sizeof(check) ||
            memcmp(check,
                   data + i * FRAME_WORDS,
                   sizeof(check))) {

            fclose(f);
            return -1;
        }
    }

    if (fgetc(f) != EOF || ferror(f)) {
        fclose(f);
        return -1;
    }

    if (fclose(f) != 0)
        return -1;

    FILE *j = fopen("native_ch0.csv", "wx");

    if (!j)
        return -1;

    ok = fprintf(j,
        "sequence,bank,acknowledged,"
        "host_elapsed_seconds,service_us\n") >= 0;

    for (unsigned i = 0; i < buffered; i++) {

        if (fprintf(j, "%u,%u,%u,%.9f,%.3f\n",
            meta[i].seq,
            meta[i].bank,
            meta[i].acknowledged,
            meta[i].host_time,
            meta[i].service_us) < 0)
            ok = 0;
    }

    if (fflush(j) != 0)
        ok = 0;

    if (fsync(fileno(j)) != 0)
        ok = 0;

    if (fclose(j) != 0)
        ok = 0;

    if (!ok)
        return -1;

    int dirfd = open(".", O_RDONLY | O_DIRECTORY);

    if (dirfd < 0)
        return -1;

    int synced = fsync(dirfd);

    close(dirfd);

    return synced == 0 ? 0 : -1;
}

int main(int argc, char **argv)
{
    setvbuf(stdout, NULL, _IONBF, 0);

    if (argc != 2 || chdir(argv[1]) != 0)
        return 1;

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
        errors != 1 ||
        fresh_status() != 0 ||
        !is_drained() ||
        RD(0x024) != BASE_COMPLETED ||
        RD(0x064) != BASE_SKIPPED) {

        puts("STOP_NATIVE_RECORDER_PREFLIGHT_FAILED");
        goto done;
    }

    puts("NATIVE_RECORDER_PREFLIGHT: PASS");

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

        if (fresh_status() != 0) {

            puts("STOP_STATUS_FAILED");
            goto done;
        }

        if (!stopped &&
            (interrupted || now() - start >= 10.0)) {

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
            BASE_COMPLETED + acknowledged;

        unsigned bank;

        if (owns_bank(0, expected))
            bank = 0;

        else if (owns_bank(1, expected))
            bank = 1;

        else {

            puts("STOP_SEQUENCE_DISCONTINUITY");
            goto done;
        }

        if (buffered >= CAPACITY) {

            puts("STOP_RAM_BUFFER_FULL");
            goto done;
        }

        double service_start = now();

        uint32_t *dest =
            data + buffered * FRAME_WORDS;

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

        if (!valid_frame(dest)) {

            puts("STOP_HEADER_VALIDATION_FAILED");
            goto done;
        }

        if (fresh_status() != 0 ||
            !owns_bank(bank, expected)) {

            puts("STOP_BANK_OWNERSHIP_CHANGED");
            goto done;
        }

        unsigned idx = buffered++;

        meta[idx].seq = expected;
        meta[idx].bank = bank;
        meta[idx].host_time = now() - start;
        meta[idx].acknowledged = 0;

        if (fast_ack(bank, expected) != 0) {

            puts("STOP_ACK_FAILED_OR_UNCERTAIN");
            goto done;
        }

        meta[idx].acknowledged = 1;

        acknowledged++;

        double service_us =
            (now() - service_start) * 1000000.0;

        meta[idx].service_us = service_us;

        service_sum += service_us;

        if (service_us > service_max)
            service_max = service_us;

        last_progress = now();
    }

    if (fresh_status() != 0 ||
        !is_drained() ||
        RD(0x024) != BASE_COMPLETED + acknowledged ||
        buffered != acknowledged ||
        RD(0x064) < BASE_SKIPPED ||
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
          acknowledged > 0 &&
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

    if (buffered > 0) {

        printf("SAVING_RAM_FRAMES: %u\n", buffered);

        if (save_output(data, meta, buffered) != 0) {

            puts("STOP_OUTPUT_SAVE_FAILED");
            rc = 5;
        } else {

            puts("FILE_WRITE_READBACK: PASS");
            puts("DIRECTORY_SYNC: PASS");
        }
    }

    free(data);
    free(meta);

    puts("RAM_BEFORE_ACK: YES");
    puts("POWER_LOSS_DURABILITY_BEFORE_ACK: NO");
    puts("DMA_STATUS: HOLD");
    puts("SCIENTIFIC_RECORDING_GO: NO");

    if (rc == 0)
        puts("CAL9_NATIVE_1000HZ_ZERO_SKIP: PASS");
    else
        puts("CAL9_NATIVE_1000HZ_QUALIFICATION: NOT_PASS");

    return rc;
}
