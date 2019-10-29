version 1.0

workflow guppy {
    input {
        String inputPath
        String config
    }
    call convert2Fastq {
        input:
            inputPath = inputPath,
            config = config
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
        String config
        String? savePath = "./output"
        String? modules = "guppy/3.2.4"
        String? basecallingDevice = "cuda:0 cuda:1"
        Int? memory = 31
        Int? numCallers = 16
        Int? chunksPerRunner = 96
    }

    command <<<
        ~{guppy} \
        --num_callers ~{numCallers} \
        --chunks_per_runner ~{chunksPerRunner} \
        -r \
        --input_path ~{inputPath} \
        --save_path ~{savePath}  \
        --config /ont-guppy/data/~{config} \
        -x ~{basecallingDevice} \
        --disable_pings
        cat ~{savePath}/*.fastq > ~{savePath}/mergedFastqFile.fastq
    >>>

    output {
        File mergedFastqFile = "~{savePath}/mergedFastqFile.fastq"
        File seqSummary = "~{savePath}/sequencing_summary.txt"
        File seqTelemetry = "~{savePath}/sequencing_telemetry.js"
    }
    runtime {
        modules: "~{modules}"
        memory_gb: "~{memory} GB"
        gpuCount: 2
        gpuType: "nvidia-tesla-v100"
        nvidiaDriverVersion: "396.26.00"
        docker: "guppy_nvidia_docker:1.0"
        dockerRuntime: "nvidia"
        backend = "SGE-Docker"
    }
}