#define main original_first_frames_main
#include "cal9_first_frames_v1.c"
#undef main

int main(void)
{
    setvbuf(stdout, NULL, _IONBF, 0);

    int fd = open("/dev/mem", O_RDWR | O_SYNC);

    if (fd < 0) {
        perror("open");
        return 1;
    }

    void *ctrl = mmap(
        NULL, CTRL_SIZE,
        PROT_READ | PROT_WRITE,
        MAP_SHARED, fd, CTRL_BASE
    );

    if (ctrl == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 2;
    }

    r = ctrl;

    int rc = 3;

    if (RD(0x000) != 0x56344332 ||
        RD(0x004) != 0x00010003 ||
        RD(0x008) != 0 ||
        RD(0x018) != 0 ||
        RD(0x024) != 0 ||
        RD(0x02C) != 0 ||
        RD(0x030) != 0 ||
        RD(0x034) != 0 ||
        RD(0x038) != 0 ||
        RD(0x048) != 3 ||
        RD(0x04C) != 125000000 ||
        RD(0x054) != 0 ||
        RD(0x05C) != 0 ||
        RD(0x060) != 0 ||
        RD(0x064) != 0) {

        puts("STOP_RECOVERY_PREFLIGHT_FAILED");
        goto done;
    }

    puts("RECOVERY_EXIT_PREFLIGHT: PASS");

    puts("ISSUING_NATIVE_CALIBRATION_EXIT");

    WR(0x044, 0x43414C45);

    double deadline = now() + 3.0;

    while (now() < deadline) {

        if (RD(0x02C) != 0 ||
            RD(0x038) != 0 ||
            (RD(0x008) & 0x20)) {

            puts("STOP_NEW_HARDWARE_ERROR");
            goto done;
        }

        if (RD(0x048) == 0x1D &&
            RD(0x034) == 1)
            break;

        usleep(1000);
    }

    epoch = 0;
    errors = 0;

    if (!live()) {

        puts("STOP_NORMAL_MODE_NOT_READY");
        goto done;
    }

    if (snapshot() != 0 ||
        (RD(0x054) & 0x39) != 0x30 ||
        RD(0x018) != 0 ||
        RD(0x024) != 0 ||
        RD(0x05C) != 0 ||
        RD(0x060) != 0 ||
        RD(0x064) != 0 ||
        RD(0x058) != 125000000 ||
        !live()) {

        puts("STOP_POST_EXIT_VERIFICATION_FAILED");
        goto done;
    }

    printf("CAL_STATUS: 0x%08X\n", RD(0x048));
    printf("FRONTEND_AVAIL: %u\n", RD(0x034));
    printf("EPOCH: %u\n", RD(0x038));

    show_status();

    puts("CAL9_RECOVERY_NORMAL_MODE: PASS");
    puts("ADDITIONAL_ERRORS: ZERO");
    puts("FRESH_STATUS_TRANSACTION: PASS");
    puts("RECORDING_STARTED: NO");
    puts("ACK_ISSUED: NO");
    puts("DMA_STATUS: HOLD");

    rc = 0;

done:

    if (rc != 0)
        puts("STOP_DO_NOT_REPEAT_WITHOUT_DIAGNOSIS");

    munmap(ctrl, CTRL_SIZE);
    close(fd);

    return rc;
}
