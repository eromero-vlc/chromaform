# chromaform
Automatic installation of JLab's chroma and redstar packages.

## Brochure:

```bash
chromaform [--source-dir=dir] [--build-dir=dir] [--install-dir=dir]                       \\
           [--float] [--cuda|--hip] [--mg] [--master] [--next] [--superb]                 \\
           [--cmake=build|--cmake=system] [--llvm=build|--llvm=system]                    \\
           [--thrust=build|--thrust=system] [--gmp=build|--gmp=system]                    \\
           [--libxml2=build|--libxml2=system] [--tinfo=build|--tinfo=system]              \\
           [--blas=openblas|--blas=openblas-system|--blas=atlas-system|--blas=mkl]        \\
           [-g|-O|-Onone] [--avx|--avx2|--knl|--avx512|--zen2|...|-zen5] [--autoflags=no] \\
           [--std=c++11|--std=c++14|--std=c++17|--std=c++20]                              \\
           [--clean|--install|--update|--download-only] [gcc] [openmpi] [mvapich2]        \\
           [cmake] [llvm] [automake] [cub] [thrust] [openblas] [gmp] [libxml2] [eigen]    \\
           [ncurses] [libfuse3] [anarchofs]                                               \\
           [qmp] [qdp] [superbblas] [primme] [magma] [mgproto] [qphix] [quda] [chroma]    \\
           [datalib] [laplace_eigs] [adat] [colorvec] [tensor] [hadron] [redstar] [redstardl]       \\
           [CC=...] [CFLAGS=...] [CXX=...] [CXXFLAGS=...] [FC=...] [SM=...]               \\
           [CMAKE_EXTRA_FLAGS=...]
```

## Examples:

```bash
# Install chroma with mg_proto/QPhiX
chromaform --mg chroma

# Install chroma with mg_proto/QPhiX with AVX512 support
chromaform --mg --avx512 chroma

# Install chroma with QUDA for arch=sm_70
chromaform --mg --cuda chroma SM=sm_70

# Install redstar and harom
chromaform redstar harom
```
See more examples at the end.

## Location options:
Each installed package will have an entry in the directories indicated
for keeping the source, the compilation, and the installation. 

* `--source-dir=<dir>`:
   Directory where to put the sources; the default is $PWD/src.
* `--build-dir=<dir>`:
   Directory where to build the packages; the default is $PWD/build.
* `--install-dir=<dir>`:
   Directory where to install the packages; the default is $PWD/install.

## Package flavor options:
Some packages have special optional features.

* `--float`:
   Install the single-precision version; the double precision version is installed
   by default. Used by QDP.
* `--cuda`:
   Install the CUDA/JIT version; the CPU version is installed by default. Used by QDP,
   superbblas, and chroma.
* `--hip`:
   Install the HIP/JIT version; the CPU version is installed by default. Used by QDP,
   superbblas, and chroma.
* `--mg`:
   Install multigrid extension of chroma; it isn't installed by default.
* `--superb`:
   Install the superbblas extensions of chroma; it isn't installed by default.
* `--master`:
   Install the master branches of adat, colorvec, redstar, superbblas, chroma; the devel
   branch is installed by default otherwise.
* `--devel-datalib-reorg`:
   Install `rge/devel-datalib-reorg` branches of datalib, adat, colorvec, redstar, QDP++, and chroma.
   Enables SuperbBLAS. Chroma uses MPI, with QDP++ as `parscalar` and QMP with
   `--with-qmp-comms-type=MPI`, and builds standalone datalib (with FILEDB) before ADAT and Chroma.
   Chroma enables `CORR_SUPERB` with `--with-datalib` and `--with-superbblas`.
   Building `chroma` alone does not build ADAT. Colorvec builds against ADAT, which
   uses the same standalone datalib installation.
   MPI and serial package variants use separate installation directories. Datalib
   is always built with the underlying non-MPI compiler and retains its serial I/O API.
   Chroma uses this branch's Autotools interface for standalone datalib.
   The reorganization branch takes precedence over other branch-selection options
   for these six packages. QDP means QDP++ (`--qdpjit=no`); QDP-JIT has no matching
   reorganization branch, so selecting QDP-JIT for this stack is rejected.

* `--mpi=yes|no`:
   Controls optional MPI support in ADAT, Colorvec, and Redstar. The Redstar-chain
   workflow documented below uses `--mpi=no`; MPI support remains available for
   workflows that explicitly require it. Compiler selection is separate from
   enabling MPI routines: choosing an MPI wrapper as `CXX` alone does not enable
   them. Datalib always builds serially, regardless of this option. Reorganized
   Chroma requires MPI and does not depend on ADAT.

Datalib is shared by ADAT and Chroma and never needs an MPI compiler. Chromaform
queries Open MPI wrappers with `--showme:command`, or MPICH/Intel MPI wrappers
with `-show`, and uses the reported compiler without the wrapper's MPI flags.
For example, `CXX=mpicxx` may resolve to `g++`, `icpx`, or `clang++`, depending on
the loaded MPI environment. Use `SERIAL_CC=/path/to/cc SERIAL_CXX=/path/to/c++`
for wrappers that cannot report a single compiler. These compilers must match
the MPI toolchain's C++ ABI and OpenMP runtime. MPI-specific SuperbBLAS defines
are removed only in serial package builds; Chroma retains its MPI settings.
Compiler discovery and scope-isolation checks can be run with
`bash tests/compiler-selection.sh`. Source and branch selection can be checked
without downloading or building with `bash tests/branch-selection.sh`. Macro-guard
and portable source-preparation checks use `bash tests/chroma-mpi-guards.sh` and
`bash tests/source-preparation.sh`, respectively; neither rebuilds any packages.

Build Chroma separately with MPI and OpenBLAS:

```bash
./chromaform --devel-datalib-reorg --mpi=yes --blas=openblas chroma
```

This builds standalone datalib as needed and enables Chroma's `CORR_SUPERB` task
with `--with-datalib` and `--with-superbblas`. It does not build or depend on ADAT.
QDP++ uses `parscalar`, and QMP uses MPI communication.

Build Colorvec separately as part of the serial Redstar chain, using OpenBLAS:

```bash
./chromaform --devel-datalib-reorg --mpi=no --blas=openblas colorvec
```

This builds serial ADAT and standalone datalib as needed, then builds serial
Colorvec against that ADAT installation. The Chroma and Colorvec commands use
`rge/devel-datalib-reorg` for the relevant packages listed above.

Build serial Redstar, Colorvec, and ADAT with OpenBLAS. Redstar also uses
`rge/devel-datalib-reorg`, with a separate source directory from its default
`devel` checkout:

```bash
./chromaform --devel-datalib-reorg --mpi=no --blas=openblas redstar
```

To build serial ADAT and datalib alone:

```bash
./chromaform --devel-datalib-reorg --mpi=no --blas=openblas adat
```


### JLab 24s: GNU compilers and Open MPI

Use one consistent GNU toolchain (GCC, G++, and GFortran) and a matching Open MPI
installation. JLab documents the `mpi/openmpi-x86_64` module in its
[environment-module guidance](https://www.jlab.org/lqcd/software/modules).
Check the available compiler versions on the machine; prefer GCC 13 or newer
when available, and keep the same compiler version for both builds. Avoid
mixing GNU and Intel compiler/OpenMP runtime environments.

```bash
module load mpi/openmpi-x86_64

module list
mpicc --showme:command
mpicxx --showme:command
mpicxx --version
gfortran --version
```

Verify that the MPI wrappers use the intended GCC/G++ toolchain and that
`gcc`, `g++`, and `gfortran` on your PATH belong to that same toolchain. The module
name alone does not establish which compiler version is selected.

Build MPI Chroma with explicit compiler settings:

```bash
./chromaform --devel-datalib-reorg --mpi=yes --blas=openblas \
  chroma CC=mpicc CXX=mpicxx FC=gfortran
```

Build the serial Redstar chain with the corresponding ordinary compilers:

```bash
./chromaform --devel-datalib-reorg --mpi=no --blas=openblas \
  redstar CC=gcc CXX=g++ FC=gfortran
```

Explicit settings avoid inheriting an unintended `CC`, `CXX`, or `FC` from the
shell. `FC=gfortran` selects the Fortran compiler for OpenBLAS. Datalib uses the
underlying non-MPI compiler in both builds; Chroma does not build ADAT. Keep the
compiler and library environment available when running the installed programs.

## CMake, LLVM, BLAS, GMP, LIBXML2:
   Some packages require CMake, LLVM, and BLAS, and this are the options to select
   which implementation to use.

* `--cmake=[build|system]`:
   Use the cmake in $PATH if 'system' is given; otherwise, it builds a recent version.
   By default, it detects the cmake version available, and build cmake if it is not
   recent enough.

* `--llvm=[build|system]`:
   Use the LLVM indicated by llvm-config  in $PATH if 'system' is given; otherwise, it
   builds a recent version. By default, it detects the LLVM version available, and build 
   LLVM if it is not.

* `--thrust=[build|system]`:
   Use the cub/thrust in the CUDA SDK if 'system' is given; otherwise, it
   downloads a recent version. By default, it detects the thrust version available, and
   download cub and thrust if it is not.

* `--blas=[openblas|openblas-system|atlas-system|mkl]`:
   Build OpenBLAS if 'openblas' is given, or use the system OpenBLAS, ATLAS, or MKL if
   'openblas-system', 'atlas-system', 'mkl' is given, respectively. If using MKL, plase
   set the environ variable MKLROOT. By default, it detects if there are flags in LDFLAGS
   and LIBS suggesting the use of MKL, OpenBLAS, and ATLAS, and use that. Otherwise, it
   uses MKL if MKLROOT is set, or OpenBLAS or ATLAS if they have pkg-config sets
   available.

* `--gmp=[build|system]`:
   Use the qmp in the system if 'system' is given; otherwise, it
   downloads a recent version. By default, it detects if they have pkg-config
   configuration available.

* `--libxml2=[build|system]`:
   Use the libxml2 in the system if 'system' is given; otherwise, it
   downloads a recent version. By default, it detects if they have pkg-config
   configuration available.

## Compilation flags:
Control the flags use for building the packages.

* `-g`|`-O`|`-Onone`
   Append '-g3 -O0' to CFLAGS and CXXFLAGS if '-g' is given, of '-O3' if '-O' is given, 
   or no flags are added if '-Onone' is given. By default, '-O3' is appended.

* `--avx`|`--avx2`|`--knl`|`--avx512`|`--zen2`|`--zen3|--zen4|--zen5`
   Append flags in CFLAGS and CXXFLAGS to activate proper extensions in the compiler,
   and set the QphiX isa.

* `--std=c++20|c++23`:
   Append the given flag to CXXFLAGS; --std=c++20 is the default.

* `--autoflags=no`:
   If given, CFLAGS, CXXFLAGS, and LDFLAGS are not modified by the options -g, -O,
   --avx512, --knl, --zen2, --zen3, --zen4, --zen5, and --std, or any automatic heuristic in this script.
   By default, besides setting CFLAGS and CXXFLAGS as described, flags are added to
   activate AVX2 and OpenMP compiler extensions.

## Actions and packages:
An action is either of the flags --clean, --install, or --update, and can be followed by
several packages and other actions. The --update action is implied if no other action was
given before. For instance:

```bash
  chromaform chroma --install openblas
```

marks the package chroma with the flag --update and the package openblas with the flag
--install. The actions are described in the following:

* `--install <pkg> <pkg> ...`:
   Always download the source code, build, and install the packages marked with this
   action. Mark their dependent packages as --update.
* `--update <pkg> <pkg> ...`:
   Download the source code if it is not in the source directory already, and install the
   packages marked with this action if they are not found on the install directory.
   Mark their dependent packages as --update.
* `--clean <pkg> <pkg> ...`:
   Remove the instances in the source, build, and install directories of the packages
   marked with this action.

* `--download-only`:
   If given, no building nor installation is done, only changes on the source directory
   are going to be performed. This is useful to download all the sources required and
   copy them to a machine without external internet access. 

## Set environ variables:
All input options that are not flags or packages described above and contain '='
will be considered a variable assignation. For instance:

```bash
  chromaform chroma CC=icc CXX=icpc PATH=/mypaths:$PATH
```

will export the value of the variables CC, CXX, and PATH to subshells and executed
commands.

## Examples on clusters:

```bash
# JLab 21g (MI100)
# Note: OpenMPI and OpenBLAS are already installed but they are slow
# Note: the zen2 flag is needed when compiling at qcdi2001
module load rocm/5.1.3
./chromaform --hip --zen2 --mg --superb openmpi openblas chroma MAKE_JN=30 AMDGPU_TARGETS='gfx908' --env=env-extra.sh CC=amdclang CXX=amdclang++ FC=amdflang

# JLab 24s (sapphire rapids)
module load mpi/openmpi-x86_64
./chromaform --mg --superb chroma

# JLab's KNLs and qcdi140X
module load gcc-7.1.0 # (the loading of this module may fail while running, just add setenv LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:/dist/gcc-7.1.0/lib)
# For bash compatible shell
source /dist/intel/parallel_studio_2019/parallel_studio_xe_2019/psxevars.sh intel64
# For tcsh
source /dist/intel/parallel_studio_2019/parallel_studio_xe_2019/psxevars.csh intel64
# NOTE: the --knl flag is only needed when running on KNL
./chromaform --mg --knl --superb chroma CC=mpiicc CXX=mpiicpc FC=ifort
./chromaform --knl redstar CC=icc CXX=icpc FC=ifort

# Frontier (MI250)
module load cpe/24.11
module load cce/18.0.1
module load PrgEnv-amd
module load openblas
module load amd
module load rocm
module load craype-accel-amd-gfx90a # loads GTL
module load cmake
./chromaform --hip --mg --superb chroma MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=`which cc` CXX=`which CC` FC=ftn --env=env_extra.sh
# NOTE: unload the following module to avoid compiling issues, see:
#       https://docs.olcf.ornl.gov/systems/frontier_user_guide.html#olcfdev-1806-cce-17-0-0-and-rocm-5-7-1-c-20-complex-and-openmp-offload-breakage
module unload craype-accel-amd-gfx90a
./chromaform redstar --superb --hip MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=`which cc` CXX=`which CC` --env=env_extra0.sh

# Default environment at NERSC (executables work for haswell & KNL)
module load cmake
./chromaform --mg --knl --superb chroma CC=cc CXX=CC

# Lumi (MI250)
module load PrgEnv-amd
module load craype-accel-amd-gfx90a

./chromaform --hip --mg chroma MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=`which cc` CXX=`which CC` FC=ftn --env=env_extra.sh
# NOTE: avoid using cray wrappers, they get confused with -fopenmp flags
./chromaform --hip --mpi=no redstar MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=amdclang CXX=amdclang++ FC=amdflang --env=env_extra.sh

# Adastra (MI250)
module load PrgEnv-amd
module load craype-accel-amd-gfx90a

# NOTE: Avoid compiling on the frontend because it is zen4 but gpu nodes are zen3.
#       Instead, download all necessary packages in the frontend (with --downalod-only)
#       and submit the compilation to a gpu node.

# run on the frontend
./chromaform --hip --mg chroma MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=`which cc` CXX=`which CC` FC=ftn --download-only
# run on a gpu node
./chromaform --hip --mg chroma MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=`which cc` CXX=`which CC` FC=ftn --env=env_extra.sh

# run on the frontend
./chromaform --hip --mpi=no redstar MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=amdclang CXX=amdclang++ FC=amdflang --download-only
# run on a gpu node
# NOTE: avoid using cray wrappers, they get confused with -fopenmp flags
./chromaform --hip --mpi=no redstar MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=amdclang CXX=amdclang++ FC=amdflang --env=env_extra.sh

# TACC Frontera (avx512)
# NOTE: fronetend nodes cannot handle chroma or redstar's compilation; download the source code first
#       and compile on a computing node
module load gcc/13.2.0
module load cmake/3.31.5
./chromaform --mg --superb --download-only chroma # download the source code
./chromaform --mg --superb chroma MAKE_JN=10 # run this on a computing node
./chromaform --download-only redstar # download the source code
./chromaform redstar MAKE_JN=10 # run this on a computing node

# At Jean-Zay
module purge
module load cmake
module load autoconf
module load automake
module load intel-compilers
module load intel-mkl
module load intel-mpi
module load cuda/10.2
./chromaform --mg --cuda --superb chroma SM=sm_70 CC=mpicc CXX=mpicxx MAKE_JN=10

# At Juwels Booster
module load GCC/9.3.0
module load OpenMPI/4.1.0rc1
module load CUDA/11.0
module load CMake/3.18.0
./chromaform --mg --cuda --superb chroma SM=sm_80 FC=gfortran

# Daint.Alps (H100)
uenv start --view=modules prgenv-gnu/26.3
module load cray-mpich
module load cuda
module load gcc
module load openblas
module load cmake
./chromaform --mg --cuda --superb chroma --env=env_extra.sh SM=sm_90 CC=mpicc CXX=mpicxx

# Perlmutter CPU
module load cmake
module load craype-accel-host
./chromaform --mg --superb chroma CC=cc CXX=CC FC=ftn

# Perlmutter GPU
module load cmake
# NOTE: avoid compiling on the frontend on perlmutter, the frontends are zen3 but
#       GPU computing nodes are zen2; adding the --zen2 may suffice thou.
./chromaform --zen2 --mg --cuda --superb chroma redstardl --env=env_extra.sh CC=cc CXX=CC FC=ftn SM=sm_80
./chromaform --zen2 --cuda redstar CC=cc CXX=CC FC=ftn SM=sm_80 CUDADIR_extra=/opt/nvidia/hpc_sdk/Linux_x86_64/24.5/math_libs

# Polaris
module swap PrgEnv-nvhpc PrgEnv-gnu
module load nvhpc-mixed
module load cmake
./chromaform --mg --cuda --superb chroma CC=cc CXX=CC FC=ftn SM=sm_80

# Kuro
module load openmpi-ib/gcc-11.4.1/4.1.6
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/kuro/gcc-11.4.1/openmpi-4.1.6-gt24wp/lib
./chromaform gcc chroma --mg CC=mpicc CXX=mpicxx FC=gfortran OMPI_CC=gcc OMPI_CXX=g++ --env=env_extra.sh

# Femto (W&M)
module purge
module load modules
module load slurm
module load gcc/9.1.0
module load openmpi/3.1.4/gcc-9.1.0
module load isa/skylake
source /usr/local/intel-2019/mkl/bin/mklvars.sh intel64
module load cmake
export LD_LIBRARY_PATH=/usr/local/gcc-9.1.0/lib64:$LD_LIBRARY_PATH
./chromaform --mg --superb chroma

# Cyclops (W&M)
module load intel/2019
module load intel/2019-mpi
source ${MKLROOT}/bin/mklvars.csh intel64
./chromaform --mg --superb chroma redstar CC=mpiicc CXX=mpiicpc

# Navigator+
module load OpenMPI
module load OpenBLAS
module load CMake
module load Python
./chromaform --mg --superb chroma
```
