"""Configuration regressions; no dependency downloads or builds.
Run: python3 -m unittest discover -s tests -v
"""
import os
from pathlib import Path
import platform
import subprocess
import tempfile
import unittest

SCRIPT = (Path(__file__).resolve().parents[1] / 'chromaform').read_text()
PREFIX = SCRIPT.split('# Download\n', 1)[0]


@unittest.skipUnless(platform.system() == 'Darwin', 'native macOS configuration')
class MacOSConfiguration(unittest.TestCase):
    def configure(self, *args):
        env = os.environ.copy()
        for key in ('LIBS', 'LDFLAGS', 'CFLAGS', 'CXXFLAGS', 'MKLROOT'):
            env.pop(key, None)
        result = subprocess.run(
            ['bash', '-s', '--', *args, 'CC=clang', 'CXX=clang++'],
            input=PREFIX + '\necho "DEPS superbblas=$superbblas openblas=$openblas adat=$adat redstardl=$redstardl"\n',
            text=True, capture_output=True, env=env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_default_accelerate(self):
        out = self.configure('redstar', '--superb', '--mpi=no', '--openmp=no')
        self.assertIn('Using BLAS: accelerate', out)
        self.assertIn('-framework Accelerate', out)
        self.assertIn('DEPS superbblas=update openblas= adat=update', out)

    def test_chroma_superbblas(self):
        out = self.configure('chroma', '--superb', '--mpi=yes', '--blas=accelerate', '--openmp=no')
        self.assertIn('DEPS superbblas=update openblas= adat=', out)
        self.assertIn('-framework Accelerate', out)

    def test_chroma_corr_superb_dependency(self):
        out = self.configure('chroma', '--superb-next', '--mpi=yes', '--blas=accelerate', '--openmp=no')
        self.assertIn('superbblas=update', out)
        self.assertIn('redstardl=update', out)

    def test_explicit_openmp(self):
        if not any(Path(p).is_dir() for p in ('/opt/homebrew/opt/libomp', '/usr/local/opt/libomp')):
            self.skipTest('Homebrew libomp required')
        out = self.configure('redstar', '--superb', '--mpi=no', '--blas=accelerate', '--openmp=yes')
        self.assertIn('-Xpreprocessor -fopenmp', out)
        self.assertIn('-lomp', out)
        self.assertNotIn('Using CXXFLAGS= -fopenmp', out)

    def test_openmp_disabled(self):
        out = self.configure('redstar', '--mpi=no', '--openmp=no', '--blas=accelerate')
        self.assertNotIn('-fopenmp', out)
        self.assertNotIn('-lomp', out)

    def test_explicit_openblas_preserved(self):
        out = self.configure('redstar', '--superb', '--mpi=no', '--openmp=no', '--blas=openblas')
        self.assertIn('Using BLAS: openblas', out)
        self.assertIn('DEPS superbblas=update openblas=update', out)
        self.assertNotIn('-framework Accelerate', out)


class PortableSplit(unittest.TestCase):
    def test_accelerate_rejected_on_non_macos(self):
        result = subprocess.run(
            ['bash', '-s', '--', '--blas=accelerate', '--mpi=no', 'CC=clang', 'CXX=clang++'],
            input='uname() { echo Linux; }\n' + PREFIX,
            text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('--blas=accelerate requires macOS', result.stdout)

    def test_ten_chunks_preserve_lines(self):
        patch = SCRIPT.split("<<'PY_SPLIT' || exit $?\n", 1)[1].split('\nPY_SPLIT', 1)[0]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            makefile = root / 'Makefile'
            makefile.write_text('all:\n\tsplit -d -n l/10 -a 1 $< $(LIB_SOURCE_STEM)_\n')
            subprocess.run(['python3', '-', str(makefile)], input=patch, text=True, check=True)
            command = makefile.read_text().split('\t', 1)[1]
            command = command.replace('$(PYTHON)', 'python3').replace('$<', str(root / 'input'))
            command = command.replace('$(LIB_SOURCE_STEM)_', str(root / 'chunk_'))
            for lines in ([], ['only\n'], [f'{i}\n' for i in range(103)]):
                (root / 'input').write_text(''.join(lines))
                subprocess.run(['bash', '-c', command], check=True)
                chunks = [root / f'chunk_{i}' for i in range(10)]
                self.assertTrue(all(p.exists() for p in chunks))
                self.assertEqual(''.join(p.read_text() for p in chunks), ''.join(lines))


if __name__ == '__main__':
    unittest.main()
