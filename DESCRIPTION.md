# IOR

## Purpose

Generic IO benchmark https://github.com/hpc/ior

## Source

Archive name: `ior-bench.tar.gz`

The IOR source code is included in `src/ior`, equivalent to version 3.3.0, commit ID 9959a61. Optionally it can be downloaded manually via `src/get_source.sh`.

## Building

The build environment must provide MPI support. Outside of JUBE, IOR can be compiled with an MPI wrapper compiler as follows:

```
./bootstrap
module load Intel ParaStationMPI #or equivalent modules or environment setup
CC=mpicc ./configure --with-posix --with-mpiio
make
```

Important compile flag is `--with-posix` to enable POSIX. MPIIO support was required in a prior version of this benchmark but is not used anymore.

### Modification

The build process or the source code may only be changed, if required, to enable the benchmark on the target platform. The changes are to be reported and must be made available to the upstream developers via the official GitHub repository of [IOR](https://github.com/hpc/ior/) in a compatible license in case of a successful tender.

### JUBE

The JUBE step `compile` takes care of building the benchmark. It configures and builds the benchmark in accordance with the flags outlined above.

If a precompiled binary `src/ior/src/ior` is detected, `make distclean` is called and a fresh build process is started.

An additional tag, `skip_compile`, is optional: If given, the JUBE script will skip the compile step and continue with executing the benchmark with a precompiled IOR binary (`src/ior/src/ior`).

## Parameters and Rules

In this section all parameters are listed, which are either fixed or are allowed to be changed. In the JUBE script, the parameters are located in the corresponding XML files.

There are two basic variants included in this benchmark:
1. **Easy**, which represents an easy IO access pattern 
2. **Hard**, which represents a hard IO access pattern test

The corresponding IOR parameters for the variants are listed in the subsections below, including the name in the JUBE script. It is indicated, which parameter values are fixed, and which ones are allowed to be changed.

The parameters flagged as _not fixed_, can be freely changed to achieve best performance, so long as the following conditions are met:

1. The IOR execution lasts at least one minute
2. The total size of the data set is sufficient to eliminate client- and system-side caching effects, with a hard minimum of `128 GiB` per node  
(Note: `data set size per node = block size * segment count * tasks per node`)
3. The parameter `tasksPerNodeOffset` needs to be always set to the same as number of tasks per node, to further eliminate client side caching effects

### Base Parameters

The following parameters are identical for the two variants shown afterwards:

|     JUBE Parameter     |       JUBE Value       |         Command Line        | Fixed  |
|------------------------|------------------------|-----------------------------|--------|
| `api`                  | `POSIX,MPIIO`          | `-a POSIX`, `-a MPIIO`      | yes    |
| `repetitions`          | `3`                    | `-i 3`                      | yes    |
| `intraTestBarriers`    | `1`                    | `-g`                        | yes    |
| `reorderTasksConstant` | `1`                    | `-C`                        | yes    |
| `writeFile`            | `1`                    | `-w`                        | yes    |
| `readFile`             | `1`                    | `-r`                        | yes    |
| `verbose`              | `1`                    | `-v`                        | yes    |
| `taskPerNodeOffset`    | `$taskspernode`        | `-Q $taskspernode`          | yes    |
| `nodes`                | `16`                   | `srun --nodes=16`           | no     |
| `taskspernode`         | `64`                   | `srun --ntasks-per-node=64` | no     |

### Additional Parameters: _Easy_ Variant

|     JUBE Parameter     |       JUBE Value       |         Command Line        | Fixed  |
|------------------------|------------------------|-----------------------------|--------|
| `filePerProc`          | `1`                    | `-F`                        | yes    |
| `transferSize`         | `16m`                  | `-t 16m`                    | yes    |
| `blockSize`            | `2g`                   | `-b 2g`                     | no     |
| `segmentCount`         | `1`                    | `-s 1`                      | yes    |

### Additional Parameters: _Hard_ Variant

|     JUBE Parameter     |       JUBE Value       |         Command Line        | Fixed  |
|------------------------|------------------------|-----------------------------|--------|
| `filePerProc`          | `0`                    |                             | yes    |
| `transferSize`         | `4k`                   | `-t 4k`                     | yes    |
| `blockSize`            | `4k`                   | `-b 4k`                     | yes    |
| `segmentCount`         | `524288`               | `-s 524288`                 | yes (a)|

(a) Only in case condition 2 (_total size of data set_) is not met, the segment count can be adjusted.

### Node-Variant Combinations

On JUPITER Booster, the _Easy_ and _Hard_ variants are to be executed on 1 node as well as a number of nodes with best throughput. On JUPITER Cluster, the _Easy_ variant is to be executed on 1 node and a number of nodes with best throughput.

The following summarizes the various execution combinations

| Nodes | Easy using POSIX | Hard using POSIX |
|-------|------------------|------------------|
| 1     | ✓°               | ✓                |
| best^ | ✓§°              | ✓                |


- ^: Best possible throughput of storage system on number of nodes of choice, with number > 64 nodes (selected number of nodes to be given)
- °: To be run on both Booster and Cluster, other combinations only to be run on Booster
- §: _Best Easy using POSIX_ taken for quantitative evaluation, rest for qualitative evaluation 

## Execution

The benchmarks can be executed manually or with the help of the [JUBE](http://www.fz-juelich.de/jsc/jube) runtime environment.

The executable of this benchmark is `ior`, which - after the build process is complete - is located in the `src/` sub-folder of the cloned IOR GitHub repository, i.e., `src/ior/src/`.

### Multi-Threading

IOR does not support multi-threading via OpenMP. IOR only supports parallelisation via MPI.

### Command Line

For execution of IOR outside of JUBE, these are an example of IOR commands to perform the required benchmarks:

```
mkdir testdir
# POSIX Easy
 [mpiexec] -n $nodes --ntasks-per-node=$taskspernode ior -a POSIX -C -Q $taskspernode -g -b 2147483648 -t 16777216 -i 3 -o testdir/testFileA -s 1 -r -w  -v -F
# POSIX Hard
  [mpiexec] -n $nodes --ntasks-per-node=$taskspernode ior -a POSIX -C -Q $taskspernode -g -b 4096 -t 4096 -i 3 -o testdir/testFileA -s 100000 -r -w  -v
```

The above should be repeated in accordance with the tests mentioned and to which the relevant parameters are given in the section above.

### JUBE

The JUBE script for the benchmark is located in `benchmark/jube/ior.xml`.

Most of the JSC-specific parameters in the JUBE script are implemented via the system-specific `platform.xml` file. This file needs to be adapted for the system under test.

The default location of the test files written and read by IOR is within each JUBE workpackage directory. A custom location can be selected by setting the parameter `outpath` of the benchmark definition in `benchmark/jube/ior.xml` to relocate the root folder for JUBE benchmark runs.

To run the IOR configuration with the help of JUBE, the following commands must be used:

```
jube run benchmark/jube/ior.xml --tag <test_exaEasy/test_exaHard> [<tag> [...]] # tags listed below
```

The benchmark setup contains a set of individual IOR runs. JUBE configuration files are included within the `benchmark/jube/config/` directory, which includes `test_exaEasy/config.xml` and `test_exaHard/config.xml`.

The tag `test_exaEasy` and `test_exaHard` are prepared for the current procurement. Their specifications are given in section _Parameters and Rules_.

## Verification

The application should run through successfully without any exceptions or error codes generated. A summary indicating successful operation is generated by IOR, similar to the following:

```
Summary of all tests:
Operation   Max(MiB)   Min(MiB)  Mean(MiB)     StdDev   Max(OPs)   Min(OPs)  Mean(OPs)     StdDev    Mean(s) Stonewall(s) Stonewall(MiB) Test# #Tasks tPN reps fPP reord reordoff reordrand seed segcnt   blksiz    xsize aggs(MiB)   API RefNum
write        6987.46    2213.94    4181.27    2037.06     436.72     138.37     261.33     127.32   29.29401         NA            NA     0     48  48    3   1     1       48         0    0      1 2147483648 16777216   98304.0 POSIX      0
read         9744.95    6375.29    8464.99    1490.06     609.06     398.46     529.06      93.13   12.03545         NA            NA     0     48  48    3   1     1       48         0    0      1 2147483648 16777216   98304.0 POSIX      0
Finished            : Thu Sep 15 16:26:44 2022
```

If the benchmark is started via JUBE, then this summary is located in `benchmark/jube/benchmarks/<JUBE ID>/<workpackage ID>_execute/work/job.log`, otherwise it is printed to stdout.

## Results

For each executed test, a summary is printed reporting on the achieved read/write bandwidth, duration and other metrics. The section _Verification_ shows an example result output. 

### JUBE

The JUBE script produces a summary table showing - besides benchmark setup configuration - max, min, and mean read/write throughput (MiB/s) as well as mean duration (seconds) over all iterations of each test.

This final result overview can be generated by using `jube analyse` and a subsequent `jube result`, which can be combined in a single command:

```
jube result -a benchmark/jube/benchmarks
```

A CSV file of this table is stored in `benchmark/jube/benchmarks/<JUBE ID>/result/result.dat`.

An example output of executing the JUBE script of the benchmark looks the following.

  api  | RDbwmax  | RDbwmean | RDbwmin  | RDbmeans[s] | WRbwmax | WRbwmean | WRbwmin | WRbmeans[s]
-------|----------|----------|----------|-------------|---------|----------|---------|------------
 POSIX | 132712.1 | 127639.4 | 118839.4 |        16.5 | 46527.8 |  40103.2 | 35988.8 |       52.9

(For this execution, JURECA DC was picked, using 16 nodes and 1024 tasks. Other parameters as follows: aggregate file size of 2.0 TiB, block size of 2 GiB, transfer size of 16 MiB, segment count of 1, single file per process. Units of reported bandwidths: MiB/s)

## Commitment

The _easy_ and _hard_ variants of the benchmarks are to be executed with POSIX on different numbers of nodes, as per configurations above. Various read and write bandwidths, as well as configuration parameters are to be reported. Quantitative assessment is done using the sum `RDbwmean+WRbwmean`, using node numbers with best throughput in _easy_ configurations (nodes > 64); the other parameters are used for the qualitative assessment.

For execution rules and guidelines, please refer to the dedicated section above. Please provide the chosen parameters for IOR as part of the benchmarking report.
