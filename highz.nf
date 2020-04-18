#!/usr/bin/env nextflow

/*
################
NEXTFLOW Global Config
################
*/



/* 
created two conda envs for this analysis

conda create --name emilyn-py3 python=3.7
conda create --name emilyn-py2 python=2.7
*/


conda_emilyn_py3 = "/data1/users/emilyn.costa/.conda/envs/emilyn-py3"
conda_emilyn_py2 = "/data1/users/emilyn.costa/.conda/envs/emilyn-py2"

//output_rdAnalyzer = "$baseDir/output_rdAnalyzer/"
//output_spotyping = "$baseDir/output_spotyping/"
//output_tbProfiler = "$baseDir/output_tbProfiler/"

output_rdAnalyzer = workflow.projectDir
output_spotyping = workflow.projectDir
output_tbProfiler = workflow.projectDir


/*
################
read the files
################
*/

ch_refGbk = Channel.value("$baseDir/NC_002945.4.gb")
ch_refFasta = Channel.value("$baseDir/NC_002945.4")


Channel.fromFilePairs("./*_{R1,R2}.fastq.gz", flat: true)
        .into { ch_fastqGz; ch_snippy; ch_tbProfiler }


/*
################
gzip these files
################
*/


process gzip {

    input:
    tuple genomeName, path(read_1_gz), path(read_2_gz) from ch_fastqGz

    output:
    tuple genomeName, path(genome_1_fq), path(genome_2_fq) into ch_trimmomatic
    tuple genomeName, path(genome_1_fq), path(genome_2_fq) into ch_in_rdAnalyzer
    tuple genomeName, path(genome_1_fq), path(genome_2_fq) into ch_in_spades

    script:
    genome_1_fq = read_1_gz.name.split("\\.")[0] + '.fastq'
    genome_2_fq = read_2_gz.name.split("\\.")[0] + '.fastq'
    """
    gzip -dc ${read_1_gz} > ${genome_1_fq} 
    gzip -dc ${read_2_gz} > ${genome_2_fq}
    """

}


/*
###############
trimmomatic
###############
*/


process trimmomatic {
    conda conda_emilyn_py3 

    input:
    tuple genomeName, path(fq_1), path(fq_2) from ch_trimmomatic

    output: 
    tuple genomeName, path(fq_1_paired) into ch_in_spotyping

    script:
    fq_1_paired = genomeName + '_1_paired.fastq'
    fq_1_unpaired = genomeName + '_1_unpaired.fastq' //single
    fq_2_paired = genomeName + '_2_paired.fastq'
    fq_2_unpaired = genomeName + '_2_unpaired.fastq' //single


    """
    trimmomatic \
    PE -phred33 \
    $fq_1 \
    $fq_2 \
    $fq_1_paired \
    $fq_1_unpaired \
    $fq_2_paired \
    $fq_2_unpaired \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:36
    """
}


/*
#==============================================
# TB_Profiler
#==============================================
*/

/*
process tbProfiler {
    publishDir path: output_tbProfiler, pattern: "./results/*json", mode: "copy"

    conda conda_emilyn_py3 

    input:
    tuple (genomeName, path(read_1_gz), path(read_2_gz)) from ch_tbProfiler

    script:

    """
    tb-profiler profile -1 $read_1_gz -2 $read_2_gz  -t 4 -p $genomeName
    """
}
*/

/*
#==============================================
# RD_Analyzer
#==============================================
*/

process rdAnalyzer {
    publishDir path: output_rdAnalyzer, pattern: "*result", mode: "copy"

    conda conda_emilyn_py2

    input:
    tuple genomeName, path(fq_1), path(fq_2) from ch_in_rdAnalyzer

    script:

    """
    python  ${baseDir}/RD-Analyzer.py  -o ${genomeName}_rdanalyzer ${fq_1} ${fq_2}

    """
}



/*
#==============================================
# Spotyping
#==============================================
*/

process spotyping {
    publishDir path: output_spotyping, pattern: "*txt", mode: "copy"
    publishDir path: output_spotyping, pattern: "*xls", mode: "copy"

    conda conda_emilyn_py2

    input:
    tuple genomeName, path(fq_1_paired) from ch_in_spotyping

    script:

    """
    python ${baseDir}/SpoTyping.py ${fq_1_paired} -o ${genomeName}.txt
    """
}





///*
//###############
//snippy_command
//###############
//*/
//
//process snippy {
//// pre-installed in HighZ
//
//    input:
//    path refGbk from ch_refGbk
//    tuple (genomeName, path(read_1_gz), path(read_2_gz)) from ch_snippy
//
//    script:
//
//    """
//    snippy --outdir $genomeName --ref $refGbk --R1 $read_1_gz --R2 $read_2_gz
//    """
//}


///*
//###############
//Spades
//###############
//*/
//
//process spades {
//    conda conda_emilyn_py2
//
//    input:
//    tuple genomeName, path(fq_1), path(fq_2) from ch_in_spades
//
//    script:
//
//
//    """
//    spades.py -k 21,33,55,77 --careful --only-assembler --pe1-1 ${fq_1} --pe1-2 ${fq_2} -o ${genomeName}_spades -t 2
//
//    """
//}



//
///*
//###############
//prokka_annotation
//###############
//*/
//
//process prokka {
//
//    input:
//    path refFasta from ch_refFasta
//    path bestContig from ch_bestContig
//
//    script:
//    genomeName = bestContig.getName().split("\\_")[0]
//    contigName = bestContig + "_NC_002945.4.fasta"
//
//
//// prokka-- outdir./G04868_prokka --prefix G04868 contigs.fa_NC000962_3.fasta.fasta
//    """
//    prokka --outdir ${genomeName}_prokka --prefix $genomeName $contigName
//    """
//}
//
