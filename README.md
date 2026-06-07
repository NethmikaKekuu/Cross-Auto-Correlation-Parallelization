# SE3082 Parallel Computing – Assignment 03
## Cross-Correlation and Autocorrelation of Large Signal Arrays
Kekulanthale K. M. N. Y |IT23657496

---

## Folder Structure

```
project-root/
├── AutoCorrelation/
│   ├── serial_autocorr.c
│   ├── omp_autocorr.c
│   ├── mpi_autocorr.c
│   
├── CrossCorrelation/
│   ├── serial_crosscorr.c
│   ├── omp_crosscorr.c
│   ├── mpi_crosscorr.c
│   
├── CrossCorr.ipynb              ← (colab notebook for both cuda implementations)
├── run_all                ← master script to compile + run everything
└── README.md
```

---

## Prerequisites

Make sure the following are installed before compiling:

| Tool | Version | Check Command |
|------|---------|---------------|
| GCC | 11.4+ | `gcc --version` |
| OpenMP | 4.5 (via GCC) | `gcc -fopenmp --version` |
| Open MPI | 4.1+ | `mpirun --version` |
| CUDA Toolkit | 12.x | `nvcc --version` |
| Python 3 | 3.10+ | `python3 --version` |
| NumPy / Matplotlib | 1.24 / 3.7 | `pip3 list` |

Install MPI if missing:
```bash
sudo apt update && sudo apt install -y libopenmpi-dev openmpi-bin
```

Install Python dependencies if missing:
```bash
pip3 install numpy scipy matplotlib
```

---

## Quick Start — Run Everything at Once

From the project root directory:

```bash
chmod +x run_all
./run_all
```

This script will automatically compile all implementations and run all benchmarks for both cross-correlation and autocorrelation.

---

## Manual Compilation & Execution

### Cross-Correlation

Navigate into the CrossCorrelation folder first:
```bash
cd CrossCorrelation
```

#### Serial (Baseline)
```bash
gcc -O0 -o serial_crosscorr serial_crosscorr.c -lm
./serial_crosscorr
```

#### OpenMP
```bash
gcc -fopenmp -O3 -march=native -o omp_crosscorr omp_crosscorr.c -lm

# Run with different thread counts
OMP_NUM_THREADS=1  ./omp_crosscorr 1
OMP_NUM_THREADS=2  ./omp_crosscorr 2
OMP_NUM_THREADS=4  ./omp_crosscorr 4
OMP_NUM_THREADS=8  ./omp_crosscorr 8
OMP_NUM_THREADS=12 ./omp_crosscorr 12
OMP_NUM_THREADS=16 ./omp_crosscorr 16
```

#### MPI
```bash
mpicc -O3 -march=native -o mpi_crosscorr mpi_crosscorr.c -lm

# Run with different process counts
mpirun -np 1  ./mpi_crosscorr
mpirun -np 2  ./mpi_crosscorr
mpirun -np 4  ./mpi_crosscorr
mpirun --oversubscribe -np 8  ./mpi_crosscorr
mpirun --oversubscribe -np 12 ./mpi_crosscorr
mpirun --oversubscribe -np 16 ./mpi_crosscorr
```
> **Note:** `--oversubscribe` is required when running more processes than physical CPU cores.

#### CUDA (Google Colab)
```bash
# Compile
nvcc -O3 -arch=sm_75 -o cuda_crosscorr cuda_crosscorr.cu

# Run with different block sizes
./cuda_crosscorr 32
./cuda_crosscorr 64
./cuda_crosscorr 128
./cuda_crosscorr 256
./cuda_crosscorr 512
./cuda_crosscorr 1024
```
> **Note:** `-arch=sm_75` targets the Tesla T4 GPU (Compute Capability 7.5). Change to `sm_86` for RTX 30-series locally.

---

### Autocorrelation

Navigate into the AutoCorrelation folder first:
```bash
cd AutoCorrelation
```

#### Serial (Baseline)
```bash
gcc -O0 -o serial_autocorr serial_autocorr.c -lm
./serial_autocorr
```

#### OpenMP
```bash
gcc -fopenmp -O3 -march=native -o omp_autocorr omp_autocorr.c -lm

OMP_NUM_THREADS=1  ./omp_autocorr 1
OMP_NUM_THREADS=2  ./omp_autocorr 2
OMP_NUM_THREADS=4  ./omp_autocorr 4
OMP_NUM_THREADS=8  ./omp_autocorr 8
OMP_NUM_THREADS=12 ./omp_autocorr 12
OMP_NUM_THREADS=16 ./omp_autocorr 16
```

#### MPI
```bash
mpicc -O3 -march=native -o mpi_autocorr mpi_autocorr.c -lm

mpirun -np 1  ./mpi_autocorr
mpirun -np 2  ./mpi_autocorr
mpirun -np 4  ./mpi_autocorr
mpirun --oversubscribe -np 8  ./mpi_autocorr
mpirun --oversubscribe -np 12 ./mpi_autocorr
mpirun --oversubscribe -np 16 ./mpi_autocorr
```

#### CUDA (Google Colab)
```bash
nvcc -O3 -arch=sm_75 -o cuda_autocorr cuda_autocorr.cu

./cuda_autocorr 32
./cuda_autocorr 64
./cuda_autocorr 128
./cuda_autocorr 256
./cuda_autocorr 512
./cuda_autocorr 1024
```

---

## Generating Performance Graphs

After all runs are complete, timing results are saved as CSV files. Generate all plots with:

```bash
python3 generate_graphs.py
```

### Output Graph Files

| File | Description |
|------|-------------|
| `omp_time.png` | OpenMP execution time vs thread count |
| `omp_speedup.png` | OpenMP speedup vs thread count |
| `mpi_time.png` | MPI execution time vs process count |
| `mpi_speedup.png` | MPI speedup vs process count |
| `cuda_time.png` | CUDA execution time vs block size |
| `cuda_speedup.png` | CUDA speedup vs block size |
| `comparative_time.png` | Best execution time across all implementations |
| `comparative_speedup.png` | Best speedup across all implementations |

---

## Configuration Parameters

| Parameter | Value |
|-----------|-------|
| Signal length (N) | 65,536 samples |
| Cross-correlation signals | Sinusoids at 1/64 Hz and 1/32 Hz |
| Autocorrelation signal | Single sinusoid at 1/64 Hz |
| Thread/process counts tested | 1, 2, 4, 8, 12, 16 |
| CUDA block sizes tested | 32, 64, 128, 256, 512, 1024 |
| Serial baseline flag | `-O0` (no optimisation) |
| Parallel build flag | `-O3 -march=native` |

---

## Expected Best Results

| Algorithm | Implementation | Best Config | Time | Speedup |
|-----------|---------------|-------------|------|---------|
| Cross-Correlation | Serial | — | 7.487 s | 1.00x |
| Cross-Correlation | OpenMP | 16 threads | 0.331 s | 22.62x |
| Cross-Correlation | MPI | 8 processes | 0.638 s | 11.72x |
| Cross-Correlation | CUDA | Block 1024 | 7.03 ms | 1066x |
| Autocorrelation | Serial | — | 7.343 s | 1.00x |
| Autocorrelation | OpenMP | 16 threads | 0.324 s | 22.66x |
| Autocorrelation | MPI | 8 processes | 0.591 s | 12.42x |
| Autocorrelation | CUDA | Block 1024 | 6.03 ms | 1217x |

---

## Troubleshooting

**`mpirun` not found:**
```bash
sudo apt install -y openmpi-bin libopenmpi-dev
```

**`nvcc` not found (local machine):**
```bash
# Install CUDA Toolkit from https://developer.nvidia.com/cuda-downloads
# Or run CUDA steps on Google Colab
```

**Permission denied on `run_all`:**
```bash
chmod +x run_all
./run_all
```

**MPI crashes without `--oversubscribe`:**  
Add the flag when running more processes than your CPU core count:
```bash
mpirun --oversubscribe -np 16 ./mpi_crosscorr
```"# Cross-Auto-Correlation-Parallelization" 
