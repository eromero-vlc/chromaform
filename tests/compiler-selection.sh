#!/bin/bash
# Exercise wrapper discovery and isolation without requiring multiple MPI installs.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
# Load just the package compiler helpers, without starting an installation.
sed -n '/^underlying_compiler() {/,/^# Add extra flags/{ /^# Add extra flags/d; p; }' "$repo_dir/chromaform" > "$test_dir/helpers.sh"
source "$test_dir/helpers.sh"
info() { :; }
plain_cc="$(command -v cc)"
plain_cxx="$(command -v c++)"
export TEST_PLAIN_CXX="$plain_cxx"
cat > "$test_dir/mpi-openmpi" <<'WRAPPER'
#!/bin/sh
[ "$1" = --showme:command ] || exit 1
printf '%s\n' "$TEST_PLAIN_CXX"
WRAPPER
cat > "$test_dir/mpi-mpich" <<'WRAPPER'
#!/bin/sh
[ "$1" = -show ] || exit 1
printf '%s -I/nonexistent/mpi -L/nonexistent/mpi -lmpi\n' "$TEST_PLAIN_CXX"
WRAPPER
cat > "$test_dir/mpi-launcher" <<'WRAPPER'
#!/bin/sh
printf 'ccache %s\n' "$TEST_PLAIN_CXX"
WRAPPER
cat > "$test_dir/mpi-unknown" <<'WRAPPER'
#!/bin/sh
exit 1
WRAPPER
chmod +x "$test_dir"/mpi-*
[ "$(underlying_compiler "$test_dir/mpi-openmpi" '')" = "$plain_cxx" ]
[ "$(underlying_compiler "$test_dir/mpi-mpich" '')" = "$plain_cxx" ]
[ "$(underlying_compiler "$plain_cxx" '')" = "$plain_cxx" ]
[ "$(underlying_compiler "$test_dir/mpi-unknown" "$plain_cc")" = "$plain_cc" ]
if underlying_compiler "$test_dir/mpi-unknown" '' > /dev/null 2>&1; then
  echo 'Unrecognized MPI wrapper must require an explicit override' >&2; exit 1
fi
if underlying_compiler "$test_dir/mpi-launcher" '' > /dev/null 2>&1; then
  echo 'Compiler launcher must require an explicit override' >&2; exit 1
fi
CC="$test_dir/mpi-openmpi" CXX="$test_dir/mpi-mpich"
CXXFLAGS='-O2 -std=c++20 -DSUPERBBLAS_USE_MPI=1 -DSUPERBBLAS_USE_MPIIO -DSUPERBBLAS_USE_ANARCHOFS=1 -DKEEP=1'
CFLAGS='-DSUPERBBLAS_USE_MPI -DKEEP_C=1'
CPPFLAGS='-DSUPERBBLAS_USE_MPIIO=1 -DKEEP_CPP=1'
(
  use_serial_compilers
  [ "$CC" = "$plain_cxx" ] && [ "$CXX" = "$plain_cxx" ]
  case "$CXXFLAGS $CFLAGS $CPPFLAGS" in *SUPERBBLAS_USE_MPI*|*SUPERBBLAS_USE_ANARCHOFS*|*-lmpi*) exit 1;; esac
  case "$CXXFLAGS" in *'-std=c++20'*'-DKEEP=1'*) ;; *) exit 1;; esac
  case "$CFLAGS" in *'-DKEEP_C=1'*) ;; *) exit 1;; esac
  case "$CPPFLAGS" in *'-DKEEP_CPP=1'*) ;; *) exit 1;; esac
)
# Serial package changes must not alter the MPI toolchain in the parent shell.
[ "$CC" = "$test_dir/mpi-openmpi" ] && [ "$CXX" = "$test_dir/mpi-mpich" ]
case "$CXXFLAGS" in *'-DSUPERBBLAS_USE_MPI=1'*) ;; *) exit 1;; esac
printf 'Compiler discovery, explicit overrides, flag filtering, and subshell isolation passed\n'
