version 1.0

workflow guppy {
    input {
        String inputPath
        String flowcell
        String kit
    }
    parameter_meta {
        inputPath: "Input directory (directory of the nanopore run)"
        flowcell: "flowcell used in nanopore sequencing"
        kit: "kit used in nanopore sequencing"
    }

    meta {
        author: "Matthew Wong"
        email: "m2wong@oicr.on.ca"
        description: "Workflow to run guppy basecaller for nanopore data"
        dependencies: [{
            name: "nvidia-docker2",
            url: "https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(version-2.0)"
        },{
            name: "bgzip",
            url: "http://www.htslib.org/doc/bgzip.html"
        }]
    }
    call convert2Fastq {
        input:
            inputPath = inputPath,
            flowcell = flowcell,
            kit = kit
    }
    output {
        File mergedFastqFile = convert2Fastq.mergedFastqFile
        File seqSummary = convert2Fastq.seqSummary
        File seqTelemetry = convert2Fastq.seqTelemetry
    }
}

task convert2Fastq {
    input {
        String? guppy = "guppy_basecaller"
        String inputPath
        String flowcell
        String kit
        String? savePath = "./output"
        String? modules = "guppy/3.2.4"
        String? basecallingDevice = '"cuda:0 cuda:1"'
        Int? memory = 63
        Int? numCallers = 16
        Int? chunksPerRunner = 3328
    }
    parameter_meta {
        guppy: "guppy_basecaller name to use."
        inputPath: "Input directory (directory of the nanopore run)"
        flowcell: "flowcell used in nanopore sequencing"
        kit: "kit used in nanopore sequencing"
        savePath: "Input file (bam or sam)."
        modules: "Environment module names and version to load (space separated) before command execution."
        basecallingDevice: "Specify basecalling device: 'auto', or 'cuda:<device_id>'."
        memory: "Memory (in GB) allocated for job."
        chunksPerRunner: "Maximum chunks per runner."
        numCallers: "Number of parallel basecallers to create."
    }
    meta {
        output_meta : {
            mergedFastqFile: "merged output of all the fastq's gzipped",
            seqSummary: "sequencing summary of the basecalling",
            seqTelemetry: "sequencing telemetry of the basecalling"
        }
    }
    command <<<
        ~{guppy} \
        --num_callers ~{numCallers} \
        --chunks_per_runner ~{chunksPerRunner} \
        -r \
        --input_path ~{inputPath} \
        --save_path ~{savePath}  \
        --flowcell ~{flowcell} \
        --kit ~{kit} \
        -x ~{basecallingDevice} \
        --disable_pings
        cat ~{savePath}/*.fastq | paste - - - - | sort -k1,1 -S 3G | tr '\t' '\n' | bgzip > ~{savePath}/mergedFastqFile.fastq.gz
    >>>

    output {
        File mergedFastqFile = "~{savePath}/mergedFastqFile.fastq.gz"
        File seqSummary = "~{savePath}/sequencing_summary.txt"
        File seqTelemetry = "~{savePath}/sequencing_telemetry.js"
    }
    runtime {
        modules: "~{modules}"
        memory: "~{memory} GB"
        gpuCount: 2
        gpuType: "nvidia-tesla-v100"
        nvidiaDriverVersion: "396.26.00"
        docker: "guppy_nvidia_docker:1.0"
        dockerRuntime: "nvidia"
    }
}