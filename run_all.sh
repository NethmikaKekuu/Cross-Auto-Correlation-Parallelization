#!/bin/bash
# ============================================================
# run_all.sh
# SE3082 Parallel Computing - Assignment 03
# Student: Kekulanthale K. M. N. Y | IT23657496
#
# This script compiles and runs all implementations and
# generates all performance graphs automatically.
#
# Usage: bash run_all.sh
# ============================================================

echo "================================================="
echo " SE3082 Assignment 03 - Full Execution Script"
echo " Cross-Correlation and Autocorrelation"
echo "================================================="

# ── Step 1: Generate signal CSV files ────────────────
echo ""
echo "[1/6] Generating signal CSV files..."
python3 -c "
import math
N = 65536
with open('signal_x.csv', 'w') as fx, open('signal_y.csv', 'w') as fy:
    for i in range(N):
        fx.write(f'{math.sin(2*math.pi*i/64.0)}\n')
        fy.write(f'{math.sin(2*math.pi*i/32.0)}\n')
print('signal_x.csv and signal_y.csv created.')
"

# ── Step 2: Serial ────────────────────────────────────
echo ""
echo "[2/6] Compiling and running Serial..."
gcc -O0 -o serial_crosscorr serial_crosscorr.c -lm
gcc -O0 -o serial_autocorr serial_autocorr.c -lm

echo "--- Serial Cross-Correlation ---"
./serial_crosscorr

echo "--- Serial Autocorrelation ---"
./serial_autocorr

# ── Step 3: OpenMP ────────────────────────────────────
echo ""
echo "[3/6] Compiling and running OpenMP..."
gcc -fopenmp -O3 -march=native -o omp_crosscorr omp_crosscorr.c -lm
gcc -fopenmp -O3 -march=native -o omp_autocorr omp_autocorr.c -lm

echo "threads,time_sec" > omp_timing.csv
echo "threads,time_sec" > omp_autocorr_timing.csv

for t in 1 2 4 8 12 16; do
    echo "--- Cross-Correlation: $t threads ---"
    OMP_NUM_THREADS=$t ./omp_crosscorr $t
    echo "--- Autocorrelation: $t threads ---"
    OMP_NUM_THREADS=$t ./omp_autocorr $t
done

# ── Step 4: MPI ───────────────────────────────────────
echo ""
echo "[4/6] Compiling and running MPI..."
mpicc -O3 -march=native -o mpi_crosscorr mpi_crosscorr.c -lm
mpicc -O3 -march=native -o mpi_autocorr mpi_autocorr.c -lm

echo "procs,time_sec" > mpi_timing.csv
echo "procs,time_sec" > mpi_autocorr_timing.csv

for p in 1 2 4; do
    echo "--- Cross-Correlation: $p processes ---"
    mpirun -np $p ./mpi_crosscorr
    echo "--- Autocorrelation: $p processes ---"
    mpirun -np $p ./mpi_autocorr
done

for p in 8 12 16; do
    echo "--- Cross-Correlation: $p processes ---"
    mpirun --oversubscribe -np $p ./mpi_crosscorr
    echo "--- Autocorrelation: $p processes ---"
    mpirun --oversubscribe -np $p ./mpi_autocorr
done

# ── Step 5: Graphs ────────────────────────────────────
echo ""
echo "[5/6] Generating all performance graphs..."
python3 -c "
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

serial = 7.487288

# OpenMP Cross-Correlation
omp_x = [1,2,4,8,12,16]
omp_t = [1.869643,1.403286,0.781857,0.542130,0.392286,0.331637]
omp_s = [serial/t for t in omp_t]

plt.figure(figsize=(7,4))
plt.plot(omp_x, omp_t, 'o-', color='#2196F3', linewidth=2)
plt.xlabel('Threads'); plt.ylabel('Time (s)')
plt.title('OpenMP Cross-Correlation: Threads vs Time')
plt.xticks(omp_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('omp_time.png', dpi=150); plt.close()

plt.figure(figsize=(7,4))
plt.plot(omp_x, omp_s, 'o-', color='#2196F3', linewidth=2, label='Actual')
plt.plot(omp_x, omp_x, '--', color='gray', label='Ideal')
plt.xlabel('Threads'); plt.ylabel('Speedup')
plt.title('OpenMP Cross-Correlation: Threads vs Speedup')
plt.legend(); plt.xticks(omp_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('omp_speedup.png', dpi=150); plt.close()

# MPI Cross-Correlation
mpi_x = [1,2,4,8,12,16]
mpi_t = [1.893086,1.330194,0.855515,0.638060,0.700653,0.745995]
mpi_s = [serial/t for t in mpi_t]

plt.figure(figsize=(7,4))
plt.plot(mpi_x, mpi_t, 'o-', color='#4CAF50', linewidth=2)
plt.xlabel('Processes'); plt.ylabel('Time (s)')
plt.title('MPI Cross-Correlation: Processes vs Time')
plt.xticks(mpi_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('mpi_time.png', dpi=150); plt.close()

plt.figure(figsize=(7,4))
plt.plot(mpi_x, mpi_s, 'o-', color='#4CAF50', linewidth=2, label='Actual')
plt.plot(mpi_x, mpi_x, '--', color='gray', label='Ideal')
plt.xlabel('Processes'); plt.ylabel('Speedup')
plt.title('MPI Cross-Correlation: Processes vs Speedup')
plt.legend(); plt.xticks(mpi_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('mpi_speedup.png', dpi=150); plt.close()

# CUDA Cross-Correlation
cuda_x  = [32,64,128,256,512,1024]
cuda_ms = [10.5358,9.8366,8.1506,7.1066,7.5162,7.0267]
cuda_t  = [t/1000 for t in cuda_ms]
cuda_s  = [serial/t for t in cuda_t]

plt.figure(figsize=(7,4))
plt.plot(cuda_x, cuda_ms, 'o-', color='#FF5722', linewidth=2)
plt.xlabel('Block Size'); plt.ylabel('Time (ms)')
plt.title('CUDA Cross-Correlation: Block Size vs Time')
plt.xticks(cuda_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('cuda_time.png', dpi=150); plt.close()

plt.figure(figsize=(7,4))
plt.plot(cuda_x, cuda_s, 'o-', color='#FF5722', linewidth=2)
plt.xlabel('Block Size'); plt.ylabel('Speedup')
plt.title('CUDA Cross-Correlation: Block Size vs Speedup')
plt.xticks(cuda_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('cuda_speedup.png', dpi=150); plt.close()

# Autocorrelation graphs
auto_serial = 7.3435
auto_omp_t = [1.877,1.326,0.822,0.506,0.393,0.324]
auto_omp_s = [auto_serial/t for t in auto_omp_t]
auto_mpi_t = [1.737,1.288,0.891,0.591,0.783,0.815]
auto_mpi_s = [auto_serial/t for t in auto_mpi_t]
auto_cuda_ms = [10.4147,8.5484,8.3890,7.5351,7.5235,6.0293]
auto_cuda_t = [t/1000 for t in auto_cuda_ms]
auto_cuda_s = [auto_serial/t for t in auto_cuda_t]

plt.figure(figsize=(7,4))
plt.plot(omp_x, auto_omp_t, 'o-', color='#2196F3', linewidth=2)
plt.xlabel('Threads'); plt.ylabel('Time (s)')
plt.title('OpenMP Autocorrelation: Threads vs Time')
plt.xticks(omp_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('auto_omp_time.png', dpi=150); plt.close()

plt.figure(figsize=(7,4))
plt.plot(omp_x, auto_omp_s, 'o-', color='#2196F3', linewidth=2, label='Actual')
plt.plot(omp_x, omp_x, '--', color='gray', label='Ideal')
plt.xlabel('Threads'); plt.ylabel('Speedup')
plt.title('OpenMP Autocorrelation: Threads vs Speedup')
plt.legend(); plt.xticks(omp_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('auto_omp_speedup.png', dpi=150); plt.close()

plt.figure(figsize=(7,4))
plt.plot(mpi_x, auto_mpi_t, 'o-', color='#4CAF50', linewidth=2)
plt.xlabel('Processes'); plt.ylabel('Time (s)')
plt.title('MPI Autocorrelation: Processes vs Time')
plt.xticks(mpi_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('auto_mpi_time.png', dpi=150); plt.close()

plt.figure(figsize=(7,4))
plt.plot(mpi_x, auto_mpi_s, 'o-', color='#4CAF50', linewidth=2, label='Actual')
plt.plot(mpi_x, mpi_x, '--', color='gray', label='Ideal')
plt.xlabel('Processes'); plt.ylabel('Speedup')
plt.title('MPI Autocorrelation: Processes vs Speedup')
plt.legend(); plt.xticks(mpi_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('auto_mpi_speedup.png', dpi=150); plt.close()

plt.figure(figsize=(7,4))
plt.plot(cuda_x, auto_cuda_ms, 'o-', color='#FF5722', linewidth=2)
plt.xlabel('Block Size'); plt.ylabel('Time (ms)')
plt.title('CUDA Autocorrelation: Block Size vs Time')
plt.xticks(cuda_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('auto_cuda_time.png', dpi=150); plt.close()

plt.figure(figsize=(7,4))
plt.plot(cuda_x, auto_cuda_s, 'o-', color='#FF5722', linewidth=2)
plt.xlabel('Block Size'); plt.ylabel('Speedup')
plt.title('CUDA Autocorrelation: Block Size vs Speedup')
plt.xticks(cuda_x); plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('auto_cuda_speedup.png', dpi=150); plt.close()

# Comparative
labels  = ['Serial','OpenMP\n(16t)','MPI\n(8p)','CUDA\n(1024)']
c_times = [serial, 0.331637, 0.638060, 7.0267/1000]
c_spd   = [serial/t for t in c_times]
colors  = ['#9E9E9E','#2196F3','#4CAF50','#FF5722']

plt.figure(figsize=(9,5))
bars = plt.bar(labels, c_times, color=colors, edgecolor='white', width=0.5)
for bar,val in zip(bars,c_times):
    plt.text(bar.get_x()+bar.get_width()/2, bar.get_height()+0.05,
             f'{val:.4f}s', ha='center', fontsize=10, fontweight='bold')
plt.ylabel('Execution Time (s)')
plt.title('Comparative: Best Execution Time')
plt.grid(axis='y', linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('comparative_time.png', dpi=150); plt.close()

plt.figure(figsize=(9,5))
bars = plt.bar(labels, c_spd, color=colors, edgecolor='white', width=0.5)
for bar,val in zip(bars,c_spd):
    plt.text(bar.get_x()+bar.get_width()/2, bar.get_height()+0.5,
             f'{val:.1f}x', ha='center', fontsize=10, fontweight='bold')
plt.ylabel('Speedup vs Serial')
plt.title('Comparative: Best Speedup')
plt.grid(axis='y', linestyle='--', alpha=0.6)
plt.tight_layout(); plt.savefig('comparative_speedup.png', dpi=150); plt.close()

print('All graphs generated successfully!')
"

# ── Step 6: Done ──────────────────────────────────────
echo ""
echo "[6/6] Done! All files generated."
echo ""
echo "Source files  : *.c"
echo "Graphs        : *.png"
echo "Timing data   : *_timing.csv"
echo "Signal data   : signal_x.csv signal_y.csv"
echo "================================================="