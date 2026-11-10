#!/usr/bin/env python3
"""Check source guards with preprocessing only; do not build Chroma."""
from pathlib import Path
import os
import subprocess
import sys
import tempfile

script = (Path(__file__).resolve().parents[1] / 'chromaform').read_text()
start = script.index('guard_chroma_mpi_defines() {')
helper = script[start:script.index('\n}\n', start) + 3]
files = ('lib/meas/inline/hadron/inline_corr_superb_w.cc',
         'lib/util/ferm/superb_contractions.h')
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    helper_path = root / 'helper.sh'
    helper_path.write_text(helper)
    originals = ('#ifndef CHROMA_SB_SINGLE\n#    define SUPERBBLAS_USE_MPI\n#endif\n',
                 '// Activate MPI support\n#  define SUPERBBLAS_USE_MPI\n')
    for relative, original in zip(files, originals):
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(original)
    command = ['bash', '-c', 'source "$1"; guard_chroma_mpi_defines "$2"',
               'guard-check', str(helper_path), str(root)]
    environment = dict(os.environ, PYTHON=sys.executable)
    subprocess.run(command, env=environment, check=True)
    guarded = [(root / relative).read_text() for relative in files]
    subprocess.run(command, env=environment, check=True)
    assert guarded == [(root / relative).read_text() for relative in files]

    def preprocess(text, *flags):
        subprocess.run(['cc', '-E', '-P', '-Werror', '-x', 'c', *flags, '-'],
                       input=text, text=True, stdout=subprocess.DEVNULL, check=True)

    combined = ''.join(guarded)
    # Keep the compiler's value, rather than replacing it with an empty macro.
    preprocess(combined + '\n#if SUPERBBLAS_USE_MPI != 1\n#error MPI value changed\n#endif\n',
               '-DSUPERBBLAS_USE_MPI')
    # Source-only users still get the original presence-based definition.
    preprocess(combined + '\n#ifndef SUPERBBLAS_USE_MPI\n#error MPI missing\n#endif\n')
    # Preserve the existing single-process condition in inline_corr_superb_w.cc.
    preprocess(guarded[0] + '\n#ifdef SUPERBBLAS_USE_MPI\n#error single mode changed\n#endif\n',
               '-DCHROMA_SB_SINGLE')
assert '[ $use_mpi == yes ] && CXXFLAGS+=" -DSUPERBBLAS_USE_MPI"' in script
print('MPI source guards preserve command-line definitions and are idempotent; preprocessing only, no rebuild')
