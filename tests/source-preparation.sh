#!/bin/bash
# Check the portable text transformations; no package compilation is performed.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
sed -n '/^prepare_superbblas_split() {/,/^# Add extra flags/{ /^# Add extra flags/d; p; }' "$repo_dir/chromaform" > "$test_dir/helpers.sh"
source "$test_dir/helpers.sh"
for lines in 0 1 2 3 10 11 25; do
    for ending in newline unterminated; do
        case_dir="$test_dir/case-$lines-$ending"
        mkdir -p "$case_dir/src"
        awk -v count="$lines" 'BEGIN { for (i=1; i<=count; ++i) printf "line %d\n", i }' > "$case_dir/src/source"
        if [ "$ending" = unterminated ] && [ "$lines" -gt 0 ]; then
            awk -v count="$lines" 'BEGIN { for (i=1; i<=count; ++i) { printf "line %d", i; if(i<count) printf "\n" } }' > "$case_dir/src/source"
        fi
        cat > "$case_dir/src/Makefile" <<'MAKEFILE'
LIB_SOURCE_STEM := source
chunks: $(LIB_SOURCE_STEM)
	split -d -n l/10 -a 1 $< $(LIB_SOURCE_STEM)_
MAKEFILE
        prepare_superbblas_split "$case_dir"
        cp "$case_dir/src/Makefile" "$case_dir/Makefile.once"
        prepare_superbblas_split "$case_dir"
        cmp "$case_dir/src/Makefile" "$case_dir/Makefile.once"
        # Execute only the chunking recipe in the fixture, not any library build.
        make -s -C "$case_dir/src" chunks
        cat "$case_dir/src"/source_? > "$case_dir/combined"
        cmp "$case_dir/src/source" "$case_dir/combined"
        for ((i=0; i<10; ++i)); do
            expected=$((lines*(i+1)/10-lines*i/10))
            actual="$(awk 'END {print NR+0}' "$case_dir/src/source_$i")"
            [ "$expected" -eq "$actual" ]
        done
    done
done
printf 'hadron_cxxld="@CXXLD@"\nunchanged\n' > "$test_dir/hadron-config.in"
chmod 640 "$test_dir/hadron-config.in"
fix_hadron_cxxld "$test_dir/hadron-config.in"
printf 'hadron_cxxld="@CXX@"\nunchanged\n' > "$test_dir/hadron-expected"
cmp "$test_dir/hadron-config.in" "$test_dir/hadron-expected"
fix_hadron_cxxld "$test_dir/hadron-config.in"
cmp "$test_dir/hadron-config.in" "$test_dir/hadron-expected"
printf 'Portable SuperbBLAS chunking and Hadron substitutions passed; no packages rebuilt\n'
