# chromaform
Automatic installation of JLab's chroma and redstar packages.

## Brochure:

```bash
chromaform [--source-dir=dir] [--build-dir=dir] [--install-dir=dir]                       \\
           [--float] [--cuda|--hip] [--mg] [--pdf] [--next] [--superb]                    \\
           [--cmake=build|--cmake=system] [--llvm=build|--llvm=system]                    \\
           [--thrust=build|--thrust=system] [--gmp=build|--gmp=system]                    \\
           [--libxml2=build|--libxml2=system] [--tinfo=build|--tinfo=system]              \\
           [--blas=openblas|--blas=openblas-system|--blas=atlas-system|--blas=mkl]        \\
           [-g|-O|-Onone] [--avx|--avx2|--knl|--avx512|--zen2|--zen3] [--autoflags=no]    \\
           [--std=c++11|--std=c++14|--std=c++20]                                          \\
           [--clean|--install|--update|--download-only] [gcc] [openmpi] [mvapich2]        \\
           [cmake] [llvm] [automake] [cub] [thrust] [openblas] [gmp] [libxml2] [eigen]    \\
           [ncurses] [libfuse3] [anarchofs]                                               \\
           [qmp] [qdp] [superbblas] [primme] [magma] [mgproto] [qphix] [quda] [chroma]    \\
           [laplace_eigs] [adat] [colorvec] [tensor] [hadron] [redstar]                   \\
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
* `--pdf`:
   Install the devel-pdf branches of adat, colorvec and redstar; the devel branch is
   installed by default.
* `--next`:
   Install upcoming versions of some packages; the version in devel or master is
   installed by default. Used by:
   - chroma: new disconnected diagram task based on frequency splitting.
   - adat/colorvec/redstar: phasing support and new keys for correlation functions,
     branch `eloy/mix-phasings-with-momclass`.

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

* `--avx`|`--avx2`|`--knl`|`--avx512`|`--zen2`|`--zen3`
   Append flags in CFLAGS and CXXFLAGS to activate proper extensions in the compiler,
   and set the QphiX isa.

* `--std=c++11|c++14|c++20`:
   Append the given flag to CXXFLAGS; --std=c++20 is appended if flag '--hip' or ---cuda'
   is set; otherwise, --std=c++14 is appended by default.

* `--autoflags=no`:
   If given, CFLAGS, CXXFLAGS, and LDFLAGS are not modified by the options -g, -O,
   --avx512, --knl, --zen2, --zen3, and --std, or any automatic heuristic in this script.
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
module load cpe/24.03
module load cce/17.0.1
module load PrgEnv-amd
module load openblas
module load amd/6.0.0
module load rocm/6.0.0
module load zstd
module load craype-accel-amd-gfx90a # loads GTL
module load cmake
./chromaform --hip --mg --superb chroma MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=`which cc` CXX=`which CC` FC=ftn --env=env_extra.sh
# NOTE: don't install chroma and redstar on the same directory, chroma needs c++20 and redstar c++17
./chromaform redstar --std=c++17 --superb --pdf --hip MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=`which cc` CXX=`which CC` --env=env_extra0.sh --install-dir=install-redstar

# Default environment at NERSC (executables work for haswell & KNL)
module load cmake
./chromaform --mg --knl --superb chroma CC=cc CXX=CC

# Lumi (MI250)
module load PrgEnv-amd
module load amd/5.5.1
module load craype-accel-amd-gfx90a

./chromaform --hip --mg chroma MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=`which cc` CXX=`which CC` FC=ftn --env=env_extra.sh
# NOTE: avoid using cray wrappers, they get confused with -fopenmp flags
./chromaform --hip --mpi=no redstar MAKE_JN=30 AMDGPU_TARGETS='gfx90a' CC=amdclang CXX=amdclang++ FC=amdflang --env=env_extra.sh

# Adastra (MI250)
module load PrgEnv-amd
module load amd/5.5.1
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

# Default environment at TACC Frontera
./chromaform --avx512 --mg --superb chroma

# Default environment at TACC Stampede2 (executables work for skylake & KNL)
./chromaform --knl --mg --superb chroma

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

# Perlmutter CPU
module load cmake
module load craype-accel-host
./chromaform --mg --superb chroma CC=cc CXX=CC FC=ftn

# Perlmutter GPU
module load cmake
./chromaform --mg --cuda --superb chroma CC=cc CXX=CC FC=ftn SM=sm_80
./chromaform --cuda --pdf redstar CC=cc CXX=CC FC=ftn SM=sm_80 CUDADIR_extra=/opt/nvidia/hpc_sdk/Linux_x86_64/23.9/math_libs/12.2/targets/x86_64-linux

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
