version 1.0

workflow guppy {
    input {
        String inputPath
        String flowcell
        String kit
        String run
        String? barcodeKits
        Array[Pair[String,String]]+ samples
        String? additionalParameters
    }
    parameter_meta {
        inputPath: "Input directory (directory of the nanopore run)"
        flowcell: "flowcell used in nanopore sequencing"
        kit: "kit used in nanopore sequencing"
        run: "sequencer run name"
        barcodeKits: "barcode kit used in demultiplexing"
        additionalParameters: "Additional parameters to be added to the guppy command"
    }

    meta {
        authors: "Matthew Wong, Xuemei Luo"
        email: "xuemei.luo@oicr.on.ca"
        description: "Workflow to run guppy basecaller and barcoder for nanopore data"
        dependencies: [{
            name: "bgzip",
            url: "http://www.htslib.org/doc/bgzip.html"

        },
        {
            name: "guppy",
            url: "https://nanoporetech.com"
        }]
    }
    call basecaller {
        input:
          inputPath = inputPath,
          flowcell = flowcell,
          kit = kit
    }

    if (defined(barcodeKits)) {
      call barcoder {
        input:
          inputPath = basecaller.guppy_basecaller_dir,
          barcodeKits = barcodeKits
      }
    }

    scatter (sample in samples) {
        String barcode = sample.left
        String name = sample.right
        String path = if (defined(barcodeKits)) then "~{barcoder.guppy_barcoder_dir}/~{barcode}/" else  "~{basecaller.guppy_basecaller_dir}"
        call mergeFastq {
            input:
              library = name,
              run = run,
              inputPath = path
        }
    }
    
    output {
        File seqSummary = basecaller.seqSummary
        File? barcodeSummary = barcoder.barcodeSummary
        Array[File]+ fastqs = mergeFastq.mergedfastq
    }
}

task basecaller {
    input {
        String inputPath
        String flowcell
        String kit
        String basecallerOutput = "basecaller_output"
        String modules = "guppy/4.0.14"
        String? additionalParameters
        Int memory = 63
        Int numCallers = 8
        Int chunksPerRunner = 512
        Int gpuRunnerPerDevice = 4
        Int gpuCount = 2
        String gpuType = "Tesla*"
        String gpuDevice = '"cuda:0 cuda:1"'
        String gpuQueue = "gpu.q"
        Int timeout = 24

    }
    parameter_meta {
        inputPath: "Input directory (directory of the nanopore run)"
        flowcell: "flowcell used in nanopore sequencing"
        kit: "kit used in nanopore sequencing"
        basecallerOutput: "Path to save the guppy basecaller output"
        modules: "Environment module names and version to load (space separated) before command execution."
        gpuDevice: "Specify basecalling device: 'auto', or 'cuda:<device_id>'."
        memory: "Memory (in GB) allocated for job."
        chunksPerRunner: "Maximum chunks per runner."
        gpuRunnerPerDevice: "Number of gpu runner per device."
        numCallers: "Number of parallel basecallers to create."
        additionalParameters: "Additional parameters to be added to the guppy command"
        timeout: "Maximum amount of time (in hours) the task can run for."
    }
    meta {
        output_meta : {
            mergedFastqFile: "merged output of all the fastq's gzipped",
            seqSummary: "sequencing summary of the basecalling"
        }
    }

    command <<<
        set -euo pipefail

        $GUPPY_ROOT/bin/guppy_basecaller \
        --num_callers ~{numCallers} \
        --gpu_runners_per_device ~{gpuRunnerPerDevice} \
        --chunks_per_runner ~{chunksPerRunner} \
        --recursive \
        --input_path ~{inputPath} \
        --save_path ~{basecallerOutput}  \
        --flowcell ~{flowcell} \
        --kit ~{kit} ~{additionalParameters} \
        -x ~{gpuDevice}

        readlink -f ~{basecallerOutput} > guppy_basecaller_dir_path.txt

    >>>

    output {
        String guppy_basecaller_dir = read_string("guppy_basecaller_dir_path.txt") 
        File seqSummary = "~{basecallerOutput}/sequencing_summary.txt"
    }
    runtime {
        modules: "~{modules}"
        memory: "~{memory} GB"
        gpuCount: "~{gpuCount}"
        gpuType: "~{gpuType}"
        gpuQueue: "~{gpuQueue}"
        timeout: "~{timeout}"
    }
}

task barcoder {
    input {
        String inputPath
        String? barcodeKits
        String barcoderOutput = "barcoder_output"
        String modules = "guppy/4.0.14"
        String? additionalParameters
        Int memory = 63
        Int workerThread = 12
        Int gpuCount = 2
        String gpuType = "Tesla*"
        String gpuDevice = '"cuda:0 cuda:1"'
        String gpuQueue = "gpu.q"
        Int timeout = 24
    }
    parameter_meta {
        inputPath: "Input directory (directory of the nanopore run)"
        barcodeKits: "barcode kits used for demultiplexing"
        barcoderOutput: "Path to save the guppy barcoder output"
        modules: "Environment module names and version to load (space separated) before command execution."
        workerThread: "Number of worker threads for guppy barcoder."
        memory: "Memory (in GB) allocated for job."
        additionalParameters: "Additional parameters to be added to the guppy command"
        timeout: "Maximum amount of time (in hours) the task can run for."
    }
    meta {
        output_meta : {
            mergedFastqFile: "merged output of all the fastq's gzipped",
            seqSummary: "sequencing summary of the basecalling",
            barcodeSummary: "barcoding summary of the demultiplexing"
        }
    }


    command <<<
        set -euo pipefail

        $GUPPY_ROOT/bin/guppy_barcoder \
        --recursive \
        --worker_threads  ~{workerThread} \
        --require_barcodes_both_ends \
        --input_path ~{inputPath} \
        --save_path ~{barcoderOutput}  \
        --barcode_kits ~{barcodeKits} \
        ~{additionalParameters}

        readlink -f ~{barcoderOutput} > "guppy_barcoder_dir_path.txt"

    >>>

    output {
        String guppy_barcoder_dir = read_string("guppy_barcoder_dir_path.txt") 
        File barcodeSummary = "~{barcoderOutput}/barcoding_summary.txt"
    }
    runtime {
        modules: "~{modules}"
        memory: "~{memory} GB"
        gpuCount: "~{gpuCount}"
        gpuType: "~{gpuType}"
        gpuQueue: "~{gpuQueue}"
        timeout: "~{timeout}"
    }
}

task mergeFastq {
  input {
    String inputPath
    String run
    String library
    String modules = "tabix/0.2.6"
    Int jobMemory = 24
    Int threads = 4
    Int timeout = 24
  }

  command <<<
    set -euo pipefail

    find ~{inputPath} -name "*.fastq" | xargs -I {} cat {} | paste - - - - | sort -k6,6 -k4,4 -V -S 3G | tr '\t' '\n' | bgzip > ~{library}_~{run}.fastq.gz

  >>>

  runtime {
    modules: "~{modules}"
    memory: "~{jobMemory} GB"
    cpu: "~{threads}"
    timeout: "~{timeout}"
  }

  output {
    File mergedfastq = "~{library}_~{run}.fastq.gz"
  }

  parameter_meta {
    mergedfastq: "merged fastq."
    modules: "Required environment modules"
    jobMemory:  "Memory allocated to job (in GB)."
    threads: "Requested CPU threads."
    timeout: "Maximum amount of time (in hours) the task can run for."
  }

  meta {
    output_meta: {
      mergedfastq: "Merged fastq"
    }
  }
}
