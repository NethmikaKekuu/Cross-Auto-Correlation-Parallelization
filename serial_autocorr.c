#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define N 65536

static double now_sec(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + (double)t.tv_nsec * 1e-9;
}

void autocorrelation(const float *x, float *r, int n) {
    for (int lag = 0; lag < n; lag++) {
        float sum = 0.0f;
        for (int i = 0; i < n - lag; i++) {
            sum += x[i] * x[i + lag];  /* same signal, no y[] */
        }
        r[lag] = sum;
    }
}

void init_signal(float *x, int n) {
    for (int i = 0; i < n; i++) {
        x[i] = (float)sin(2.0 * M_PI * (double)i / 64.0);
    }
}

int main(void) {
    printf("\n");
    printf(" --Autocorrelation--Serial--\n");
    printf(" --Signal length N = %d--\n", N);
    printf("\n");

    float *x = (float *)malloc(N * sizeof(float));
    float *r = (float *)malloc(N * sizeof(float));

    init_signal(x, N);

    double t_start = now_sec();
    autocorrelation(x, r, N);
    double elapsed = now_sec() - t_start;

    printf("Execution time : %.6f seconds\n", elapsed);
    printf("Threads        : 1 (serial baseline)\n\n");

    printf("--First 8 values (note for correctness check)--\n");
    for (int k = 0; k < 8; k++)
        printf("  r[%5d] = %12.4f\n", k, r[k]);

    FILE *fp = fopen("serial_autocorr_timing.txt", "w");
    fprintf(fp, "threads,time_sec\n1,%.6f\n", elapsed);
    fclose(fp);
    printf("\nTiming saved -> serial_autocorr_timing.txt\n");

    free(x); free(r);
    return 0;
}
