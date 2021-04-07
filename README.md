# chromaform
Automatic installation of JLab's chroma and redstar packages.

## Brochure:

```bash
chromaform [--source-dir=dir] [--build-dir=dir] [--install-dir=dir] [--download-only] \
           [--float] [--jit] [--mg] [--pdf] [--next] [--llvm=build|--llvm=system] \
           [--blas=[openblas|openblas-system|mkl| \
           [-g|-O] [--knl] [--avx512] [--autoflags=no] \
           [--install|--update] [llvm|openblas|eigen|qmp|qdp|superbblas|primme|mgproto|qphix|chroma]+ \
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
