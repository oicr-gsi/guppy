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
        --config ~{config} \
        -x ~{basecallingDevice}
        cat *.fastq > mergedFastqFile.fastq
    >>>

    output {
        File mergedFastqFile = "mergedFastqFile.fastq"
        File seqSummary = "sequencing_summary.txt"
        File seqTelemetry = "sequencing_telemetry.js"
    }
    runtime {
        modules: "~{modules}"
        memory: "~{memory} G"
        runtimeAttr: "nvidia"
        inputData: "~{inputPath}"
        gpuCount: 2
        gpuType: "nvidia-tesla-v100"
        nvidiaDriverVersion: "396.26.00"
        image: "nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04"
    }
}