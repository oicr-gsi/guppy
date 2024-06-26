# guppy

Workflow to run guppy basecaller and barcoder for nanopore data

## Overview

## Dependencies

* [bgzip](http://www.htslib.org/doc/bgzip.html)
* [guppy](https://nanoporetech.com)


## Usage

### Cromwell
```
java -jar cromwell.jar run guppy.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`inputPath`|String|{'description': 'Input directory (directory of the nanopore run)', 'vidarr_type': 'directory'}
`flowcell`|String|flowcell used in nanopore sequencing
`kit`|String|kit used in nanopore sequencing
`samples`|Array[Sample]+|an array of pairs: barcode and sample name


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`barcodeKits`|String?|None|barcode kit used in demultiplexing


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`convert2Fastq.basecallerOutput`|String|"basecaller_output"|Path to save the guppy basecaller output
`convert2Fastq.modules`|String|"guppy/4.0.14"|Environment module names and version to load (space separated) before command execution.
`convert2Fastq.basecallerAdditionalParameters`|String?|None|Additional parameters to be added to the guppy basecaller command
`convert2Fastq.numCallers`|Int|8|Number of parallel basecallers to create.
`convert2Fastq.chunksPerRunner`|Int|512|Maximum chunks per runner.
`convert2Fastq.gpuRunnerPerDevice`|Int|4|Number of gpu runner per device.
`convert2Fastq.barcoderOutput`|String|"barcoder_output"|Path to save the guppy barcoder output
`convert2Fastq.barcoderAdditionalParameters`|String?|None|Additional parameters to be added to the guppy barcoder command
`convert2Fastq.workerThread`|Int|12|Number of worker threads for guppy barcoder.
`convert2Fastq.gpuCount`|Int|2|Number of gpu count.
`convert2Fastq.gpuType`|String|"Tesla*"|gpu type.
`convert2Fastq.gpuDevice`|String|'"cuda:0 cuda:1"'|Specify basecalling device: 'auto', or 'cuda:<device_id>'.
`convert2Fastq.gpuQueue`|String|"gpu.q"|gpu queue.
`convert2Fastq.memory`|Int|63|Memory (in GB) allocated for job.
`convert2Fastq.timeout`|Int|32|Maximum amount of time (in hours) the task can run for.
`mergeFastq.modules`|String|"tabix/0.2.6"|Required environment modules.
`mergeFastq.jobMemory`|Int|24|Memory allocated to job (in GB).
`mergeFastq.threads`|Int|4|Requested CPU threads.
`mergeFastq.timeout`|Int|24|Maximum amount of time (in hours) the task can run for.


### Outputs

Output | Type | Description | Labels
---|---|---|---
`seqSummary`|File|sequencing summary of the basecalling|vidarr_label: seqSummary
`barcodeSummary`|File?|barcoding summary of the demultiplexing|vidarr_label: barcodeSummary
`outputGroups`|Array[OutputGroup]+|Array of objects with sample name and the merged fastq.|vidarr_label: outputGroups


## Commands
This section lists command(s) run by guppy workflow
 
* Running guppy

### Wrapped guppy basecaller and barcoder
 
```
         set -euo pipefail
 
         $GUPPY_ROOT/bin/guppy_basecaller \
         --num_callers ~{numCallers} \
         --gpu_runners_per_device ~{gpuRunnerPerDevice} \
         --chunks_per_runner ~{chunksPerRunner} \
         --recursive \
         --input_path ~{inputPath} \
         --save_path ~{basecallerOutput}  \
         --flowcell ~{flowcell} \
         --kit ~{kit} ~{basecallerAdditionalParameters} \
         -x ~{gpuDevice}
 
         if ~{runBarcoder}; then
 
           $GUPPY_ROOT/bin/guppy_barcoder \
           --recursive \
           --worker_threads  ~{workerThread} \
           --require_barcodes_both_ends \
           --input_path ~{basecallerOutput} \
           --save_path ~{barcoderOutput}  ~{barcoderAdditionalParameters} \
           --barcode_kits ~{barcodeKits}
      
           readlink -f ~{barcoderOutput} > "guppy_output_dir_path.txt"
         else 
           readlink -f ~{basecallerOutput} > "guppy_output_dir_path.txt"
         fi
```

### Post-processing fastq files

```
     set -euo pipefail
 
     find ~{inputPath} -name "*.fastq" | xargs -I {} cat {} | paste - - - - | sort -k6,6 -k4,4 -V -S 3G | tr '\t' '\n' | bgzip > ~{outputFileNamePrefix}.fastq.gz
 
```
## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_
