#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <mpi.h>

#define N 65536

void init_signal(float *x, int n) {
    for (int i = 0; i < n; i++) {
        x[i] = (float)sin(2.0 * M_PI * (double)i / 64.0);
    }
}

int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int chunk     = N / size;
    int lag_start = rank * chunk;
    int lag_end   = (rank == size - 1) ? N : lag_start + chunk;
    int local_n   = lag_end - lag_start;

    float *x       = (float *)malloc(N * sizeof(float));
    float *r_local = (float *)malloc(local_n * sizeof(float));

    init_signal(x, N);

    MPI_Barrier(MPI_COMM_WORLD);
    double t_start = MPI_Wtime();

    for (int lag = lag_start; lag < lag_end; lag++) {
        float sum = 0.0f;
        for (int i = 0; i < N - lag; i++) {
            sum += x[i] * x[i + lag];
        }
        r_local[lag - lag_start] = sum;
    }

    MPI_Barrier(MPI_COMM_WORLD);
    double elapsed = MPI_Wtime() - t_start;

    float *r_global   = NULL;
    int   *recvcounts = NULL;
    int   *displs     = NULL;

    if (rank == 0) {
        r_global   = (float *)malloc(N * sizeof(float));
        recvcounts = (int *)malloc(size * sizeof(int));
        displs     = (int *)malloc(size * sizeof(int));
        for (int p = 0; p < size; p++) {
            int s = p * chunk;
            int e = (p == size - 1) ? N : s + chunk;
            recvcounts[p] = e - s;
            displs[p]     = s;
        }
    }

    MPI_Gatherv(r_local, local_n, MPI_FLOAT,
                r_global, recvcounts, displs, MPI_FLOAT,
                0, MPI_COMM_WORLD);

    double max_elapsed;
    MPI_Reduce(&elapsed, &max_elapsed, 1, MPI_DOUBLE,
               MPI_MAX, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("=================================================\n");
        printf("  Autocorrelation -- MPI Parallel\n");
        printf("  Signal length N = %d\n", N);
        printf("  Processes       = %d\n", size);
        printf("=================================================\n\n");
        printf("  Execution time  : %.6f seconds\n", max_elapsed);
        printf("\n--- First 8 values (must match serial) ---\n");
        for (int k = 0; k < 8; k++)
            printf("  r[%5d] = %12.4f\n", k, r_global[k]);

        FILE *fp = fopen("mpi_autocorr_timing.csv", "a");
        if (fp) { fprintf(fp, "%d,%.6f\n", size, max_elapsed); fclose(fp); }
        printf("\nResult saved -> mpi_autocorr_timing.csv\n");

        free(r_global); free(recvcounts); free(displs);
    }

    free(x); free(r_local);
    MPI_Finalize();
    return 0;
}
