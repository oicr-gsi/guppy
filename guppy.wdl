version 1.0

struct OutputGroup {
    String barcode
    File fastq
}

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

     output_meta: {
       outputGroups: "Array of objects with barcode and the merged fastq.",
       seqSummary: "sequencing summary of the basecalling",
       barcodeSummary: "barcoding summary of the demultiplexing"
    }       
    }

    Boolean runBarcoder = if (defined(barcodeKits)) then true else false

    call convert2Fastq {
        input:
          inputPath = inputPath,
          flowcell = flowcell,
          kit = kit,
          barcodeKits = barcodeKits,
          runBarcoder = runBarcoder
    }

    scatter (sample in samples) {
        String barcode = sample.left
        String name = sample.right
        String path = if (defined(barcodeKits)) then "~{convert2Fastq.guppy_output_dir}/~{barcode}/" else  "~{convert2Fastq.guppy_output_dir}"
        call mergeFastq {
            input:
              library = name,
              run = run,
              inputPath = path
        }

        OutputGroup outputGroup = { "barcode": barcode,
                          "fastq": mergeFastq.mergedfastq}
    }
    
    output {
        File seqSummary = convert2Fastq.seqSummary
        File? barcodeSummary = convert2Fastq.barcodeSummary
        Array[OutputGroup]+ outputGroups = outputGroup
    }
}

task convert2Fastq {
    input {
        String inputPath
        String flowcell
        String kit
        String basecallerOutput = "basecaller_output"
        String modules = "guppy/4.0.14"
        String? basecallerAdditionalParameters
        Int numCallers = 8
        Int chunksPerRunner = 512
        Int gpuRunnerPerDevice = 4
        String? barcodeKits
        String barcoderOutput = "barcoder_output"
        Boolean runBarcoder
        String? barcoderAdditionalParameters
        Int workerThread = 12
        Int gpuCount = 2
        String gpuType = "Tesla*"
        String gpuDevice = '"cuda:0 cuda:1"'
        String gpuQueue = "gpu.q"
        Int memory = 63
        Int timeout = 32

    }
    parameter_meta {
        inputPath: "Input directory (directory of the nanopore run)"
        flowcell: "flowcell used in nanopore sequencing"
        kit: "kit used in nanopore sequencing"
        basecallerOutput: "Path to save the guppy basecaller output"
        gpuDevice: "Specify basecalling device: 'auto', or 'cuda:<device_id>'."
        chunksPerRunner: "Maximum chunks per runner."
        gpuRunnerPerDevice: "Number of gpu runner per device."
        numCallers: "Number of parallel basecallers to create."
        basecallerAdditionalParameters: "Additional parameters to be added to the guppy basecaller command"
        barcodeKits: "barcode kits used for demultiplexing"
        barcoderOutput: "Path to save the guppy barcoder output"
        runBarcoder: "run barcoder if true"
        workerThread: "Number of worker threads for guppy barcoder."
        barcoderAdditionalParameters: "Additional parameters to be added to the guppy barcoder command"
        modules: "Environment module names and version to load (space separated) before command execution."
        memory: "Memory (in GB) allocated for job."
        timeout: "Maximum amount of time (in hours) the task can run for."
        gpuCount: "Number of gpu count."
        gpuType: "gpu type."
        gpuQueue: "gpu queue."                
    }
    meta {
        output_meta : {
            seqSummary: "sequencing summary of the basecalling",
            barcodeSummary: "barcoding summary of the demultiplexing",
            guppy_output_dir: "Path to the convert2Fastq output"
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
    >>>

    output {
        String guppy_output_dir = read_string("guppy_output_dir_path.txt") 
        File seqSummary = "~{basecallerOutput}/sequencing_summary.txt"
        File? barcodeSummary = "~{barcoderOutput}/barcoding_summary.txt"
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
