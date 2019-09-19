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
        File guppyOutput = convert2Fastq.guppyOutput
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
        zip -r guppyOutput.zip output
    >>>

    output {
        File guppyOutput = "./guppyOutput.zip"
    }
    runtime {
        modules: "~{modules}"
        memory: "~{memory} G"
    }
}