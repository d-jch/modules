// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided as a string i.e. "options.args"
//               where "params.options" is a Groovy Map that MUST be provided via the addParams section of the including workflow.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. bwa mem | samtools view -B -T ref.fasta to output BAM instead of SAM.
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, "fake files" MAY be used to work around this issue.

params.options = [:]
def options    = initOptions(params.options)

process SEQKIT_SPLIT2 {
    tag "$meta.id"
    label 'process_medium'

    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::seqkit=0.15.0" : null)

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/seqkit:0.15.0--0"
    } else {
        container "quay.io/biocontainers/seqkit:0.15.0--0"
    }

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fq.gz"), emit: reads
    path("*.version.txt")           , emit: version


    script:
    def software = getSoftwareName(task.process)

    //TODO not sure if this is useful here, as the splits need to be named individually, and this would make the prefix the same and the outputname I am afraid.
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"

    // if(meta.single_end){
    """
    seqkit \
        split2 \
        $options.args \
        --threads $task.cpus \
        -1 $reads

    echo \$(seqkit --version 2>&1) | sed 's/^.*seqkit //; s/Using.*\$//' > ${software}.version.txt
    """
    //} else {
    // """
    // seqkit \
    //     split2 \
    //     $options.args \
    //     --threads $task.cpus \
    //     -1 ${reads[0]} \
    //     -2 ${reads[1]}
    // echo \$(seqkit --version 2>&1) | sed 's/^.*seqkit //; s/Using.*\$//' > ${software}.version.txt
    // """
    //}
}
