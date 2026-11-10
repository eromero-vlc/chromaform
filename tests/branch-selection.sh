#!/bin/bash
# Check source selection and branch mappings without downloading or building.
set -eo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
script="$repo_dir/chromaform"
awk '/^if \[ x\$\{qmp\}x != xx \]; then/ { selected=1 }
selected && /^cat << EOF \| while read act proj/ { exit }
selected { print }' "$script" > "$test_dir/selection.sh"
# Source selection occurs after compiler/dependency setup; supply those inputs.
check_selection() (
    use_arch="$1" use_master="$2" flavor="$3" use_devel_datalib_reorg="$4"
    use_qdpjit=nop use_restructure=nop use_superb_next=nop
    [ "$flavor" != restructure ] || use_restructure=yes
    [ "$flavor" != next ] || use_superb_next=yes
    datalib=update adat=update colorvec=update redstar=update qdp=update chroma=update
    source "$test_dir/selection.sh"
    for package in datalib adat colorvec redstar qdp chroma; do
        eval 'chosen=${'"$package"'_src}'
        name="$package"
        [ "$package" != qdp ] || name=qdpxx
        if [ "$use_devel_datalib_reorg" == yes ]; then
            expected="$name-devel-datalib-reorg"
            [ "$chosen" = "$expected" ]
            owner=JeffersonLab
            [ "$package" != qdp ] || owner=usqcd-software
            awk -v name="$expected" -v repo="https://github.com/$owner/$name" '
                $1 == name { count++; if (NF != 3 || $2 != repo || $3 != "rge/devel-datalib-reorg") bad=1 }
                END { exit (count != 1 || bad) }
            ' "$script"
        elif [ "$package" != datalib ]; then
            [ "$chosen" = "$name" ]
        fi
    done
)
for arch in cpu cuda hip; do
    for master in nop yes; do
        for flavor in normal restructure next; do
            check_selection "$arch" "$master" "$flavor" yes
        done
    done
done
# Check the actual pre-download rejection, without needing a GPU SDK.
awk '/^# QDP-JIT has no matching reorganization branch;/ { selected=1 }
selected { print }
selected && /^fi$/ { exit }' "$script" > "$test_dir/guard.sh"
for arch in cpu cuda hip; do
    if (use_devel_datalib_reorg=yes; qdp=update; use_qdpjit=yes; use_arch="$arch";
        source "$test_dir/guard.sh") > "$test_dir/rejection.log" 2>&1; then
        echo 'QDP-JIT must be rejected for the reorganization stack' >&2; exit 1
    else
        [ "$?" -eq 1 ]
        grep -q 'QDP-JIT has no matching' "$test_dir/rejection.log"
    fi
done
check_selection cpu nop normal nop
printf 'All six reorganization branches, option precedence, and QDP-JIT rejection verified; no builds run\n'
