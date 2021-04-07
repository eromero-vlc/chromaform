# chromaform
Automatic installation of JLab's chroma and redstar packages.

## Brochure:

```bash
chromaform [--source-dir=dir] [--build-dir=dir] [--install-dir=dir]                     \
           [--float] [--jit] [--mg] [--pdf] [--next]                                    \
           [--cmake=build|--cmake=system] [--llvm=build|--llvm=system]                  \
           [--blas=openblas|--blas=openblas-system|--blas=atlas-system|--blas=mkl]      \
           [-g|-O|-Onone] [--knl] [--avx512] [--autoflags=no] [--std=c++11|--std=c++14] \
           [--clean|--install|--update|--download-only] [cmake] [llvm] [openblas]       \
           [eigen] [qmp] [qdp] [superbblas] [primme] [mgproto] [qphix] [chroma]         \
           [laplace_eigs] [adat] [colorvec] [tensor] [hadron] [redstar]                 \
           [CC=...] [CFLAGS=...] [CXX=...] [CXXFLAGS=...] [FC=...] [SM=...]
```

## Examples:

```bash
# Install chroma with mg_proto/QPhiX
chromaform --mg chroma

# Install chroma with mg_proto/QPhiX with AVX512 support
chromaform --mg --avx512 chroma

# Install chroma with QUDA for arch=sm_70
chromaform --mg --jit chroma SM=sm_70

# Install redstar and harom
chromaform redstar harom
```

## Location options:
Each installed package will have an entry in the directories indicated
for keeping the source, the compilation, and the installation. 

* `--source-dir=<dir>`:
   Directory where to put the sources; the default is \$PWD/src.
* `--build-dir=<dir>`:
   Directory where to build the packages; the default is \$PWD/build.
* `--install-dir=<dir>`:
   Directory where to install the packages; the default is \$PWD/install.

## Package flavor options:
Some packages have special optional features.

* `--float`:
   Install the single-precision version; the double precision version is installed
   by default. Used by QDP.
* `--jit`:
   Install the CUDA/JIT version; the CPU version is installed by default. Used by QDP,
   superbblas, and chroma.
* `--mg`:
   Install multigrid extension of chroma; it isn't installed by default.
* `--pdf`:
   Install the devel-pdf branches of adat, colorvec and redstar; the devel branch is
   installed by default.
* `--next`:
   Install upcoming versions of some packages; the version in devel or master is
   installed by default. Used by:
   - QPhiX/mg_proto/chroma: multiple right-hand-side inversions and efficient CPU/GPU
     computation of disconnect diagrams, props and genprops with superbblas.
   - colorvec/redstar: smearing elementals on the fly.

## CMake, LLVM, BLAS:
   Some packages require CMake, LLVM, and BLAS, and this are the options to select
   which implementation to use.

* `--cmake=[build|system]`:
   Use the cmake in \$PATH if 'system' is given; otherwise, it builds a recent version.
   By default, it detects the cmake version available, and build cmake if it is not
   recent enough.

* `--llvm=[build|system]`:
   Use the LLVM indicated by llvm-config  in \$PATH if 'system' is given; otherwise, it
   builds a recent version. By default, it detects the LLVM version available, and build 
   LLVM if it is not.

* `--blas=[openblas|openblas-system|atlas-system|mkl]`:
   Build OpenBLAS if 'openblas' is given, or use the system OpenBLAS, ATLAS, or MKL if
   'openblas-system', 'atlas-system', 'mkl' is given, respectively. If using MKL, plase
   set the environ variable MKLROOT. By default, it detects if there are flags in LDFLAGS
   and LIBS suggesting the use of MKL, OpenBLAS, and ATLAS, and use that. Otherwise, it
   uses MKL if MKLROOT is set, or OpenBLAS or ATLAS if they have pkg-config sets
   available.

## Compilation flags:
Control the flags use for building the packages.

* `-g`|`-O`|`-Onone`
   Append '-g3 -O0' to CFLAGS and CXXFLAGS if '-g' is given, of '-O3' if '-O' is given, 
   or no flags are added if '-Onone' is given. By default, '-O3' is appended.

* `--avx512`:
   Append flags in CFLAGS and CXXFLAGS to activate AVX512 extensions in the compiler,
   and set the QphiX isa=avx512. No AVX512 extension is set by default and QPhiX is built
   with isa=avx2.

* `--knl`:
   Append flags in CFLAGS and CXXFLAGS to activate KNL and AVX512 extensions in the
   compiler, and set the QphiX isa=avx512. No AVX512 extension is set by default and
   QPhiX is built with isa=avx2.

* `--std=c++11`|`c++14`:
   Append the given flag to CXXFLAGS; --std=c++14 is appended by default.

* `--autoflags=no`:
   If given, CFLAGS, CXXFLAGS, and LDFLAGS are not modified by the options -g, -O,
   --avx512, --knl, and --std, or any automatic heuristic in this script. By default,
   besides setting CFLAGS and CXXFLAGS as described, flags are added to activate AVX2 and
   OpenMP compiler extensions.

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
   action.
* `--update <pkg> <pkg> ...`:
   Download the source code if it is not the source directory already, and install the
   packages marked with this action if they are not found on the install directory.
* `--clean <pkg> <pkg> ...`:
   Remove the instances in the source, build, and install directories of the packages
   marked with this action.

* `--download-only`:
   If given, no building nor installation is done, only changes on the source directory
   are going to be performed. This is useful to download all the sources required and
   copy them to a machine without external internet access. 

## Set environ variables:
All input options that are not one the flags or packages described before and contain '='
will be considered a variable assignation. For instance:

```bash
  chromaform chroma CC=icc CXX=icpc PATH=/mypaths:\$PATH
```

will export the value of the variables CC, CXX, and PATH to subshells and executed
commands.

