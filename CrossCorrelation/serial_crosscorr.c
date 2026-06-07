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

void cross_correlation(const float *x, const float *y, float *r, int n) {
    for (int lag = 0; lag < n; lag++) {
        float sum = 0.0f;
        for (int i = 0; i < n - lag; i++) {
            sum += x[i] * y[i + lag];
        }
        r[lag] = sum;
    }
}

void init_signals(float *x, float *y, int n) {
    FILE *fx = fopen("signal_x.csv", "r");
    FILE *fy = fopen("signal_y.csv", "r");
    if (!fx || !fy) {
        fprintf(stderr, "ERROR: Cannot open signal_x.csv or signal_y.csv\n");
        exit(1);
    }
    for (int i = 0; i < n; i++) {
        (void)fscanf(fx, "%f", &x[i]);
        (void)fscanf(fy, "%f", &y[i]);
    }
    fclose(fx);
    fclose(fy);
}

int main(void) {

    float *x = (float *)malloc(N * sizeof(float));
    float *y = (float *)malloc(N * sizeof(float));
    float *r = (float *)malloc(N * sizeof(float));

    init_signals(x, y, N);

    double t_start = now_sec();
    cross_correlation(x, y, r, N);
    double elapsed = now_sec() - t_start;

    printf("Execution time : %.6f seconds\n", elapsed);
    printf("Threads        : 1 (serial baseline)\n\n");

    printf("--- First 8 values (note these for correctness check) ---\n");
    for (int k = 0; k < 8; k++)
        printf("  r[%5d] = %12.4f\n", k, r[k]);

    // Save timing for graph script
    FILE *fp = fopen("serial_timing.txt", "w");
    fprintf(fp, "threads,time_sec\n1,%.6f\n", elapsed);
    fclose(fp);
    printf("\nTiming saved -> serial_timing.txt\n");

    free(x); free(y); free(r);
    return 0;
}
