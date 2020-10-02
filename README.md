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
`inputPath`|String|Input directory (directory of the nanopore run)
`flowcell`|String|flowcell used in nanopore sequencing
`kit`|String|kit used in nanopore sequencing
`run`|String|sequencer run name
`samples`|Array[Pair[String,String]]+|an array of pairs: barcode and sample name


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

Output | Type | Description
---|---|---
`seqSummary`|File|sequencing summary of the basecalling
`barcodeSummary`|File?|barcoding summary of the demultiplexing
`outputGroups`|Array[OutputGroup]+|Array of objects with sample name and the merged fastq.


## Niassa + Cromwell

This WDL workflow is wrapped in a Niassa workflow (https://github.com/oicr-gsi/pipedev/tree/master/pipedev-niassa-cromwell-workflow) so that it can used with the Niassa metadata tracking system (https://github.com/oicr-gsi/niassa).

* Building
```
mvn clean install
```

* Testing
```
mvn clean verify \
-Djava_opts="-Xmx1g -XX:+UseG1GC -XX:+UseStringDeduplication" \
-DrunTestThreads=2 \
-DskipITs=false \
-DskipRunITs=false \
-DworkingDirectory=/path/to/tmp/ \
-DschedulingHost=niassa_oozie_host \
-DwebserviceUrl=http://niassa-url:8080 \
-DwebserviceUser=niassa_user \
-DwebservicePassword=niassa_user_password \
-Dcromwell-host=http://cromwell-url:8000
```

## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_
