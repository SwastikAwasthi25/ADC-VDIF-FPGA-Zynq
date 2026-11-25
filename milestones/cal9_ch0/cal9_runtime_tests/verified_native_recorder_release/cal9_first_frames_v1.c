#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <string.h>
#include <time.h>

#define CTRL_BASE 0x40010000UL
#define BRAM_BASE 0x40000000UL
#define CTRL_SIZE 4096
#define BRAM_SIZE 8192
#define FRAME_WORDS 264
#define BANK_STRIDE 0x800

static volatile uint32_t *r;
static uint32_t epoch;
static uint32_t errors;

__attribute__((noinline))
uint32_t rd32(volatile uint32_t *p)
{
    uint32_t v = *p;
    __asm__ volatile("dmb sy" ::: "memory");
    return v;
}

__attribute__((noinline))
void wr32(volatile uint32_t *p, uint32_t v)
{
    __asm__ volatile("dmb sy" ::: "memory");
    *p = v;
    __asm__ volatile("dsb sy" ::: "memory");
}

#define RD(o) rd32(&r[(o)/4])
#define WR(o,v) wr32(&r[(o)/4],v)

static double now(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}

static int live(void)
{
    return RD(0x034) == 1 &&
           RD(0x038) == epoch &&
           RD(0x048) == 0x1D &&
           RD(0x02C) == errors &&
           !(RD(0x008) & 0x20);
}

static int snapshot(void)
{
    if (!live() || (RD(0x008) & 3))
        return -1;

    WR(0x030, 1);

    if (RD(0x008) & 4)
        return -1;

    WR(0x00C, 1);

    double deadline = now() + 2.0;

    while (now() < deadline) {

        if (!live())
            return -1;

        uint32_t state = RD(0x008);

        if ((state & 5) == 4)
            return 0;

        usleep(200);
    }

    return -1;
}

static int capture_command(uint32_t cmd)
{
    if (!live() || (RD(0x054) & 1))
        return -1;

    WR(0x050, cmd);

    double deadline = now() + 2.0;

    while (now() < deadline) {

        if (!live())
            return -1;

        uint32_t s = RD(0x054);

        if (!(s & 1) && (s & 2))
            return (s & 4) ? 0 : -1;

        usleep(200);
    }

    return -1;
}

static void show_status(void)
{
    printf("CAPTURE_STATUS: 0x%08X\n", RD(0x054));
    printf("READY_MASK:     %u\n", RD(0x018));
    printf("BANK0_SEQ:      %u\n", RD(0x01C));
    printf("BANK1_SEQ:      %u\n", RD(0x020));
    printf("COMPLETED:      %u\n", RD(0x024));
    printf("STARTED:        %u\n", RD(0x05C));
    printf("REPLAYED:       %u\n", RD(0x060));
    printf("SKIPPED:        %u\n", RD(0x064));
    printf("ERROR_COUNT:    %u\n", RD(0x02C));
}

int main(void)
{
    setvbuf(stdout, NULL, _IONBF, 0);

    int fd = open("/dev/mem", O_RDWR | O_SYNC);

    if (fd < 0) {
        perror("open");
        return 1;
    }

    void *ctrl = mmap(NULL, CTRL_SIZE,
        PROT_READ | PROT_WRITE,
        MAP_SHARED, fd, CTRL_BASE);

    void *bram = mmap(NULL, BRAM_SIZE,
        PROT_READ, MAP_SHARED, fd, BRAM_BASE);

    if (ctrl == MAP_FAILED || bram == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 2;
    }

    r = ctrl;

    int rc = 3;
    int start_attempted = 0;

    epoch = RD(0x038);
    errors = RD(0x02C);

    if (RD(0x000) != 0x56344332 ||
        RD(0x004) != 0x00010003 ||
        epoch != 0 ||
        errors != 1 ||
        !live() ||
        snapshot() != 0 ||
        (RD(0x054) & 0x39) != 0x30 ||
        RD(0x018) ||
        RD(0x024) ||
        RD(0x05C) ||
        RD(0x060) ||
        RD(0x064)) {

        puts("STOP_PREFLIGHT_FAILED");
        goto done;
    }

    puts("FIRST_FRAME_PREFLIGHT: PASS");

    WR(0x04C, 125000000);

    if (RD(0x04C) != 125000000 ||
        !live()) {

        puts("STOP_PERIOD_CONFIG_FAILED");
        goto done;
    }

    puts("PERIOD_CONFIG: 1 FRAME/SECOND");

    puts("ISSUING_CAPTURE_START");

    start_attempted = 1;

    if (capture_command(1) != 0) {
        puts("STOP_START_COMMAND_FAILED");
        goto done;
    }

    if (snapshot() != 0 ||
        !(RD(0x054) & 8) ||
        RD(0x058) != 125000000) {

        puts("STOP_START_READBACK_FAILED");
        goto done;
    }

    puts("CAPTURE_START: PASS");

    double deadline = now() + 5.0;

    int both_ready = 0;

    while (now() < deadline) {

        if (snapshot() != 0) {
            puts("STOP_STATUS_FAILED");
            goto done;
        }

        if (RD(0x018) == 3 &&
            RD(0x024) == 2) {

            both_ready = 1;
            break;
        }

        usleep(20000);
    }

    if (!both_ready) {
        puts("STOP_TWO_BANK_TIMEOUT");
        show_status();
        goto done;
    }

    puts("BOTH_BANKS_READY: YES");

    show_status();

    puts("ISSUING_CAPTURE_STOP");

    if (capture_command(2) != 0) {
        puts("STOP_COMMAND_FAILED");
        goto done;
    }

    puts("CAPTURE_STOP_ACCEPTED");

    deadline = now() + 3.0;

    int drained = 0;

    while (now() < deadline) {

        if (snapshot() != 0)
            goto done;

        if ((RD(0x054) & 0x39) == 0x30 &&
            RD(0x05C) == RD(0x060) &&
            RD(0x060) == RD(0x024)) {

            drained = 1;
            break;
        }

        usleep(1000);
    }

    if (!drained) {
        puts("STOP_PIPELINE_DRAIN_TIMEOUT");
        goto done;
    }

    start_attempted = 0;

    puts("PIPELINE_DRAINED: YES");

    show_status();

    if (RD(0x018) != 3 ||
        RD(0x024) != 2 ||
        RD(0x01C) == RD(0x020)) {

        puts("STOP_UNEXPECTED_BANK_STATE");
        goto done;
    }

    uint32_t seq[2] = {
        RD(0x01C), RD(0x020)
    };

    for (unsigned bank = 0; bank < 2; bank++) {

        uint32_t first[FRAME_WORDS];
        uint32_t second[FRAME_WORDS];

        volatile uint32_t *p =
            (volatile uint32_t *)
            ((char *)bram + bank * BANK_STRIDE);

        if (!live())
            goto done;

        for (unsigned i = 0; i < FRAME_WORDS; i++)
            first[i] = rd32(&p[i]);

        for (unsigned i = 0; i < FRAME_WORDS; i++)
            second[i] = rd32(&p[i]);

        if (memcmp(first, second, sizeof(first))) {
            printf("STOP_BANK_%u_READ_MISMATCH\n", bank);
            goto done;
        }

        if (snapshot() != 0 ||
            RD(0x018) != 3 ||
            RD(0x01C) != seq[0] ||
            RD(0x020) != seq[1]) {

            puts("STOP_BANK_OWNERSHIP_CHANGED");
            goto done;
        }

        printf("\n===== BANK %u =====\n", bank);
        printf("SEQUENCE: %u\n", seq[bank]);
        printf("DOUBLE_READ_MATCH: YES\n");

        for (unsigned i = 0; i < 8; i++)
            printf("HEADER[%u]: 0x%08X\n", i, first[i]);

        unsigned length =
            (first[2] & 0x00FFFFFFU) * 8U;

        printf("DECLARED_FRAME_BYTES: %u\n", length);

        char name[128];

        snprintf(name, sizeof(name),
            "cal9_bank%u_seq%u.vdif",
            bank, seq[bank]);

        FILE *f = fopen(name, "wbx");

        if (!f) {
            perror("frame output");
            goto done;
        }

        size_t written =
            fwrite(first, 1, sizeof(first), f);

        int saved = written == sizeof(first);

        if (fflush(f) != 0)
            saved = 0;

        if (fsync(fileno(f)) != 0)
            saved = 0;

        if (fclose(f) != 0)
            saved = 0;

        if (!saved) {
            puts("STOP_FRAME_SAVE_FAILED");
            goto done;
        }

        printf("FRAME_SAVED: %s\n", name);
        printf("FRAME_BYTES: %zu\n", written);

        if (length != sizeof(first)) {
            puts("STOP_VDIF_HEADER_LENGTH_MISMATCH");
            goto done;
        }
    }

    puts("\nCAL9_FIRST_TWO_PHYSICAL_FRAMES: PASS");
    puts("BRAM_DOUBLE_READ: PASS");
    puts("CAPTURE_STOPPED: YES");
    puts("PENDING_BANKS_PRESERVED: YES");
    puts("ACK_ISSUED: NO");
    puts("ADDITIONAL_ERRORS: ZERO");
    puts("DMA_STATUS: HOLD");
    puts("SCIENTIFIC_RECORDING_GO: NO");

    rc = 0;

done:

    if (start_attempted) {

        puts("ATTEMPTING_GUARDED_EMERGENCY_STOP");

        if (live() && !(RD(0x054) & 1) &&
            capture_command(2) == 0 &&
            snapshot() == 0 &&
            !(RD(0x054) & 8)) {

            puts("EMERGENCY_STOP_READBACK: PASS");

        } else {

            puts("STOP_UNCONFIRMED: MANUAL_DIAGNOSIS_REQUIRED");
        }
    }

    munmap(bram, BRAM_SIZE);
    munmap(ctrl, CTRL_SIZE);
    close(fd);

    return rc;
}
