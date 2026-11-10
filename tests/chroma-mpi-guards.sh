#!/bin/bash
# Check source guards with preprocessing only; do not build Chroma.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
sed -n '/^guard_chroma_mpi_defines() {/,/^# Replace GNU/{ /^# Replace GNU/d; p; }' "$repo_dir/chromaform" > "$test_dir/helper.sh"
source "$test_dir/helper.sh"
first="$test_dir/lib/meas/inline/hadron/inline_corr_superb_w.cc"
second="$test_dir/lib/util/ferm/superb_contractions.h"
mkdir -p "$(dirname "$first")" "$(dirname "$second")"
printf '#ifndef CHROMA_SB_SINGLE\n#    define SUPERBBLAS_USE_MPI\n#endif\n' > "$first"
printf '// Activate MPI support\n#  define SUPERBBLAS_USE_MPI\n' > "$second"
guard_chroma_mpi_defines "$test_dir"
cp "$first" "$test_dir/first.before"
cp "$second" "$test_dir/second.before"
guard_chroma_mpi_defines "$test_dir"
cmp "$first" "$test_dir/first.before"
cmp "$second" "$test_dir/second.before"
{
    cat "$first" "$second"
    printf '\n#if SUPERBBLAS_USE_MPI != 1\n#error MPI value changed\n#endif\n'
} | cc -E -P -Werror -x c -DSUPERBBLAS_USE_MPI - > /dev/null
{
    cat "$first" "$second"
    printf '\n#ifndef SUPERBBLAS_USE_MPI\n#error MPI missing\n#endif\n'
} | cc -E -P -Werror -x c - > /dev/null
{
    cat "$first"
    printf '\n#ifdef SUPERBBLAS_USE_MPI\n#error single mode changed\n#endif\n'
} | cc -E -P -Werror -x c -DCHROMA_SB_SINGLE - > /dev/null
grep -Fq '[ $use_mpi == yes ] && CXXFLAGS+=" -DSUPERBBLAS_USE_MPI"' "$repo_dir/chromaform"
printf 'MPI source guards preserve command-line definitions and are idempotent; preprocessing only, no rebuild\n'
