#!/bin/bash
# Native superbblas build, numerical tests, and runtime dependency check.
# Usage: bash tests/macos-accelerate-smoke.sh /absolute/path/to/scratch
set -euo pipefail
[ "$(uname -s)" = Darwin ] || { echo 'This test requires macOS'; exit 1; }
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=${1:?Supply a fresh scratch directory}
mkdir -p "$scratch"
scratch=$(cd "$scratch" && pwd)
omp_prefix=$(brew --prefix libomp)
"$root/chromaform" superbblas --superb --mpi=no --blas=accelerate --openmp=yes \
  --source-dir="$scratch/src" --build-dir="$scratch/build" --install-dir="$scratch/install" \
  CC=clang CXX=clang++ MAKE_JN=4
make -C "$scratch/src/superbblas/tests" blas_cpu_lib dense_cpu_lib \
  CXX=clang++ BUILDDIR="$scratch/install/superbblas-cpu" \
  CXXFLAGS="-O2 -std=c++20 -Xpreprocessor -fopenmp -I$omp_prefix/include" \
  LDFLAGS="-L$omp_prefix/lib -lomp -framework Accelerate"
export OMP_NUM_THREADS=4 VECLIB_MAXIMUM_THREADS=1
cat > "$scratch/openmp-check.cpp" <<'CPP'
#include <omp.h>
#include <iostream>
int main() {
    int threads = 0;
    #pragma omp parallel reduction(+:threads)
    threads += 1;
    std::cout << "OpenMP team size: " << threads << std::endl;
    return threads == 4 ? 0 : 1;
}
CPP
clang++ -Xpreprocessor -fopenmp -I"$omp_prefix/include" \
  "$scratch/openmp-check.cpp" -L"$omp_prefix/lib" -lomp -o "$scratch/openmp-check"
"$scratch/openmp-check"
"$scratch/src/superbblas/tests/blas_cpu_lib" --size=10000 --rep=1
"$scratch/src/superbblas/tests/dense_cpu_lib" --dim='2 2 2 2 4 2'
linked=$(otool -L "$scratch/src/superbblas/tests/dense_cpu_lib")
printf '%s\n' "$linked"
[[ "$linked" == *Accelerate.framework* && "$linked" == *libomp.dylib* ]]
[[ "$linked" != *openblas* ]]
echo 'Accelerate + OpenMP superbblas smoke test passed'
