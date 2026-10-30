Script for testing superb chroma tasks

In particular, it tests

- distillation vectors produced by chroma's `CREATE_COLORVECS_SUPERB` are the same as `laplace_eigs`
- mesons produced by chroma's `MESON_MATELEM_COLORVEC_SUPERB` are the same as harom's `MESON_MATELEM_COLORVEC`
- baryons produced by chroma's `BARYON_MATELEM_COLORVEC_SUPERB` are the same as harom's `BARYON_MATELEM_COLORVEC_OPT`
- props produced by chroma's `PROP_AND_MATELEM_DISTILLATION_SUPERB` are the same as chroma's `PROP_AND_MATELEM_DISTILLATION`
- genprops produced by chroma's `UNSMEARED_HADRON_NODE_DISTILLATION_SUPERB` are the same as chroma's `UNSMEARED_HADRON_NODE_DISTILLATION`
- disconnected loops produced by chroma's `DISCO_PROBING_DEFLATION_SUPERB` and `DISCO_PROBING_3D_DEFLATION_SUPERB` are the same as chroma's `DISCO_PROBING_DEFLATION`
- correlation functions produced by chroma's `CORR_SUPERB` are the same as redstar

Theses tests are combined with other tests:

- Using filehash versus superb storage of distillation vectors, meson, baryons, props, and genprops.
- Storing the full distillation vectors versus storing a subset
- Storing baryon, prop and genprops on multiple files (XML's option `<output_file_is_local>`)
- Using momentum boosting (phasing)
- Redstar changes on the input XML from version 12 to 14

# Prerequisites

Install the following software:

```bash
./chromaform laplace_eigs
./chromaform --float harom chroma
./chromaform --superb redstar

./chromaform --superb redstardl chroma        # for cpu
./chromaform --superb redstardl chroma --hip  # for hip/rocm
./chromaform --superb redstardl chroma --cuda # for cuda
```

Then invoke the script:

```bash
bash tests_distillation.sh --chromaform-dir=<chromaform directory>
```

Example of output:
```
dims= 2 2 2 4 num_vecs= 4 phase= 0 0 1 Nt= 3
dir= out_dims2_2_2_4_mass-0.1_clover1_nvec4.reg
tasks: colorvecs mesons baryons props genprops corr
### Testing colorvecs
Testing generating colorvecs with write_fingerprint=true ... OK
Checking eigenvector file eigs.s3t ... OK
Testing generating colorvecs with write_fingerprint=false ... OK
Testing generating colorvecs with phase ... OK
### Testing mesons with phasing=nop
Computing mesons with chroma with phasing=nop and format=old ... OK
### Testing mesons with phasing=yes
Computing mesons with chroma with phasing=yes and format=old ... OK
### Testing mesons with phasing=nop
Computing mesons with chroma with phasing=nop and format=new ... OK
Comparing mesons created by chroma ... OK
### Testing mesons with phasing=yes
Computing mesons with chroma with phasing=yes and format=new ... OK
### Testing mesons with phasing=mix
Computing mesons with chroma with phasing=mix and format=new ... OK
### Testing mesons with phasing=mix
Computing mesons with chroma with phasing=mix and format=new ... OK
### Testing baryons
Computing baryons with chroma with phasing=nop ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=nop ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=yes ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=yes ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=mix ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=mix ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=nop ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=nop ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=yes ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=yes ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=mix ... OK
Checking baryon files ... OK
Computing baryons with chroma with phasing=mix ... OK
Checking baryon files ... OK
### Testing props
Computing props with new task and nop phasing ... OK
Comparing props created by old and new task ... OK
Computing props with new task and yes phasing ... OK
Comparing props created by old and new task ... OK
Computing props with new task and mix phasing ... OK
### Testing genprops
Computing genprops with new task and nop phasing ... OK
Comparing genprops created by old and new task ... OK
Checking gprop files ... OK
Computing genprops with new task and yes phasing ... OK
Comparing genprops created by old and new task ... OK
Checking gprop files ... OK
Computing genprops with new task and mix phasing ... OK
Checking gprop files ... OK
### Testing corr
redstar corr graph for phasing nop and task new ... OK
redstar npt for phasing nop and task new ... OK
chroma for phasing nop and task new and variant chroma ... OK
compare corr fun for phasing nop for variant chroma ... OK
chroma for phasing nop and task new and variant chroma-fly ... OK
compare corr fun for phasing nop for variant chroma-fly ... OK
compare corr fun for phasing nop ... OK
redstar corr graph for phasing yes and task new ... OK
redstar npt for phasing yes and task new ... OK
chroma for phasing yes and task new and variant chroma ... OK
compare corr fun for phasing yes for variant chroma ... OK
chroma for phasing yes and task new and variant chroma-fly ... OK
compare corr fun for phasing yes for variant chroma-fly ... OK
compare corr fun for phasing yes ... OK
redstar corr graph for phasing mix and task new ... OK
redstar npt for phasing mix and task new ... OK
chroma for phasing mix and task new and variant chroma ... OK
compare corr fun for phasing mix for variant chroma ... OK
chroma for phasing mix and task new and variant chroma-fly ... OK
compare corr fun for phasing mix for variant chroma-fly ... OK
```
