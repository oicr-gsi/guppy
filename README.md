# guppy

Workflow to run guppy basecaller for nanopore data

## Installation

### Installing nvidia-docker2

Note: nvidia docker 2 MUST be installed first in order to perform the guppy basecalling.
https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0)

### Building Docker image

Builds docker image with the version of 1.0
```
cd guppy
docker build -t guppy_nvidia_docker:1.0 -f Dockerfile .
```

### Saving Docker Image

Once you built the container and you want to transport the image to a `.tar.gz` use this command. Saves all the images with the name guppy_nvidia_docker
```
docker save guppy_nvidia_docker | gzip > guppy_nvidia_docker.tar.gz
```

### Loading Docker Image

If you want to load an image to your local images from your `.tar.gz` file use this command
```
docker load < guppy_nvidia_docker.tar.gz
```

## Overview

## Dependencies

* [nvidia-docker2](https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(version-2.0))
* [bgzip](http://www.htslib.org/doc/bgzip.html)


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
`outputFileNamePrefix`|String|Variable used to set the name of the mergedfastqfile


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`additionalParameters`|String?|None|Additional parameters to be added to the guppy command


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`convert2Fastq.guppy`|String|"guppy_basecaller"|guppy_basecaller name to use.
`convert2Fastq.savePath`|String|"./output"|Path to save the guppy output
`convert2Fastq.modules`|String|"guppy/3.2.4"|Environment module names and version to load (space separated) before command execution.
`convert2Fastq.basecallingDevice`|String|'"cuda:0 cuda:1"'|Specify basecalling device: 'auto', or 'cuda:<device_id>'.
`convert2Fastq.memory`|Int|63|Memory (in GB) allocated for job.
`convert2Fastq.numCallers`|Int|16|Number of parallel basecallers to create.
`convert2Fastq.chunksPerRunner`|Int|3328|Maximum chunks per runner.


### Outputs

Output | Type | Description
---|---|---
`mergedFastqFile`|File|merged output of all the fastq's gzipped
`seqSummary`|File|sequencing summary of the basecalling
`seqTelemetry`|File|sequencing telemetry of the basecalling


## Niassa + Cromwell

This WDL workflow is wrapped in a Niassa workflow (https://github.com/oicr-gsi/pipedev/tree/master/pipedev-niassa-cromwell-workflow) so that it can used with the Niassa metadata tracking system (https://github.com/oicr-gsi/niassa).

* Building
```
mvn clean install
```

* Testing
```
mvn clean verify -Djava_opts="-Xmx1g -XX:+UseG1GC -XX:+UseStringDeduplication" -DrunTestThreads=2 -DskipITs=false -DskipRunITs=false -DworkingDirectory=/path/to/tmp/ -DschedulingHost=niassa_oozie_host -DwebserviceUrl=http://niassa-url:8080 -DwebserviceUser=niassa_user -DwebservicePassword=niassa_user_password -Dcromwell-host=http://cromwell-url:8000
```

## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with wdl_doc_gen (https://github.com/oicr-gsi/wdl_doc_gen/)_
