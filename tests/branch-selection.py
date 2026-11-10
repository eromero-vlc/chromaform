#!/usr/bin/env python3
"""Check source selection and branch mappings without downloading or building."""
from pathlib import Path
import itertools
import subprocess

script = (Path(__file__).resolve().parents[1] / 'chromaform').read_text()
start = script.index('if [ x${qmp}x != xx ]; then\n\tqmp_src=')
selection = script[start:script.index('cat << EOF | while read act proj', start)]
packages = {'datalib': 'JeffersonLab/datalib', 'adat': 'JeffersonLab/adat',
            'colorvec': 'JeffersonLab/colorvec', 'redstar': 'JeffersonLab/redstar',
            'qdp': 'usqcd-software/qdpxx', 'chroma': 'JeffersonLab/chroma'}
rows = {}
for line in script.splitlines():
    fields = line.split()
    if len(fields) == 3 and fields[1].startswith('https://github.com/'):
        rows.setdefault(fields[0], []).append(fields[1:])

def setup(arch, master, restructure, next_branch, reorg='yes', jit='nop'):
    values = dict(use_arch=arch, use_master=master, use_restructure=restructure,
                  use_superb_next=next_branch, use_devel_datalib_reorg=reorg,
                  use_qdpjit=jit, **{p: 'update' for p in packages})
    return ''.join(f'{key}={value}\n' for key, value in values.items())

# Use the actual shell selection code, including branch-option precedence.
for arch, master, flavor in itertools.product(('cpu', 'cuda', 'hip'),
                                              ('nop', 'yes'), ('normal', 'restructure', 'next')):
    init = setup(arch, master, 'yes' if flavor == 'restructure' else 'nop',
                 'yes' if flavor == 'next' else 'nop')
    output = ''.join(f'printf "{p} %s\\n" "${{{p}_src}}"\n' for p in packages)
    result = subprocess.check_output(['bash', '-c', init + selection + output], text=True)
    chosen = dict(line.split() for line in result.splitlines())
    for package, repo in packages.items():
        expected_name = ('qdpxx' if package == 'qdp' else package) + '-devel-datalib-reorg'
        assert chosen[package] == expected_name, (arch, master, flavor, package, chosen)
        assert rows[expected_name] == [[f'https://github.com/{repo}', 'rge/devel-datalib-reorg']]

# A conflicting QDP-JIT request must fail before downloads, rather than use devel.
start = script.index('# QDP-JIT has no matching reorganization branch;')
guard = script[start:script.index('\nfi', start) + 3]
for arch in ('cpu', 'cuda', 'hip'):
    result = subprocess.run(['bash', '-c', setup(arch, 'nop', 'nop', 'nop', jit='yes') + guard],
                            capture_output=True, text=True)
    assert result.returncode == 1 and 'QDP-JIT has no matching' in result.stdout

# Preserve the ordinary CPU source choices without the flag.
init = setup('cpu', 'nop', 'nop', 'nop', reorg='nop')
output = ''.join(f'printf "{p} %s\\n" "${{{p}_src}}"\n' for p in packages)
chosen = dict(line.split() for line in subprocess.check_output(
    ['bash', '-c', init + selection + output], text=True).splitlines())
for package in ('adat', 'colorvec', 'redstar', 'chroma'):
    assert chosen[package] == package
assert chosen['qdp'] == 'qdpxx'
print('All six reorganization branches, source isolation, option precedence, and QDP-JIT rejection verified; no builds run')
