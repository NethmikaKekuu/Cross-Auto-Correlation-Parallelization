#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <omp.h>

#define N 65536

static double now_sec(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + (double)t.tv_nsec * 1e-9;
}

void autocorrelation_omp(const float *x, float *r, int n, int num_threads) {
    omp_set_num_threads(num_threads);
    #pragma omp parallel for schedule(static) shared(x, r, n)
    for (int lag = 0; lag < n; lag++) {
        float sum = 0.0f;
        for (int i = 0; i < n - lag; i++) {
            sum += x[i] * x[i + lag];
        }
        r[lag] = sum;
    }
}

void init_signal(float *x, int n) {
    for (int i = 0; i < n; i++) {
        x[i] = (float)sin(2.0 * M_PI * (double)i / 64.0);
    }
}

int main(int argc, char *argv[]) {
    int num_threads = 4;
    if (argc >= 2) num_threads = atoi(argv[1]);

    printf("=================================================\n");
    printf("  Autocorrelation -- OpenMP Parallel\n");
    printf("  Signal length N = %d\n", N);
    printf("  Threads         = %d\n", num_threads);
    printf("=================================================\n\n");

    float *x = (float *)malloc(N * sizeof(float));
    float *r = (float *)malloc(N * sizeof(float));

    init_signal(x, N);

    double t_start = now_sec();
    autocorrelation_omp(x, r, N, num_threads);
    double elapsed = now_sec() - t_start;

    printf("Execution time  : %.6f seconds\n", elapsed);
    printf("Threads         : %d\n\n", num_threads);

    printf("--- First 8 values (must match serial) ---\n");
    for (int k = 0; k < 8; k++)
        printf("  r[%5d] = %12.4f\n", k, r[k]);

    FILE *fp = fopen("omp_autocorr_timing.csv", "a");
    if (fp) { fprintf(fp, "%d,%.6f\n", num_threads, elapsed); fclose(fp); }
    printf("\nResult saved -> omp_autocorr_timing.csv\n");

    free(x); free(r);
    return 0;
}
