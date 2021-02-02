// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process BEDTOOLS_INTERSECT {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::bedtools=2.30.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bedtools:bedtools:2.30.0--hc088bd4_0"
    } else {
        container "quay.io/biocontainers/bedtools:bedtools:2.30.0--hc088bd4_0"
    }

    input:
    tuple val(meta), path(bed1), path(bed2)
    
    output:
        tuple val(meta), path("*.intersect.bed"), emit: bed
        path  "*.version.txt", emit: version

    script: // TODO change script to account for multiple possible intersections
        def software = getSoftwareName(task.process)
        def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
        """
        bedtools \\
            intersect \\
            -a ${bed1} \\
            -b ${bed2} \\
            $options.args \\
            > ${prefix}.intersect.bed
            
        bedtools --version | sed -e "s/bedtools v//g" > ${software}.version.txt
        """
}
