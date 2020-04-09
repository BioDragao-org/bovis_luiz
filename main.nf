#!/usr/bin/env nextflow


/*
################
NEXTFLOW Global Config
################
*/

params.outdir = "results"
ch_refGbk = Channel.value("$baseDir/NC000962_3.gbk")
ch_refFasta = Channel.value("$baseDir/NC000962_3.fasta")
ch_snpeffConfig = Channel.value("$baseDir/snpEff.config")

Channel.fromFilePairs("./*_{R1,R2}.fastq.gz", flat: true)
        .into { ch_fastqGz; ch_snippy; ch_tbProfiler }


/*
################
gzip these files
################
*/


process gzip {
//    echo true
    container 'centos:8'

    input:
    tuple (genomeName, path(read_1_gz), path(read_2_gz)) from ch_fastqGz


    output:
    tuple genomeName, path(genome_1_fq), path(genome_2_fq) into ch_trimmomatic

    script:
    genome_1_fq = read_1_gz.name.split("\\.")[0] + '.fastq'
    genome_2_fq = read_2_gz.name.split("\\.")[0] + '.fastq'
    """
    gzip -dc -k ${read_1_gz} > ${genome_1_fq} 
    gzip -dc -k ${read_2_gz} > ${genome_2_fq}
    """

}


/*
###############
trimmomatic
###############
*/


process trimmomatic {
//    echo true
    container 'quay.io/biocontainers/trimmomatic:0.35--6'


    input:
    tuple genomeName, path(fq_1), path(fq_2) from ch_trimmomatic

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
###############
snippy_command
###############
*/

process snippy {

    container 'quay.io/biocontainers/snippy:4.6.0--0'

    input:
    path refGbk from ch_refGbk
    tuple (genomeName, path(read_1_gz), path(read_2_gz)) from ch_snippy

    script:

    """
    snippy --cpus 4 --outdir $genomeName --ref $refGbk --R1 $read_1_gz --R2 $read_2_gz
    """
}

/*
#==============================================
# TB_Profiler
#==============================================
*/


process tbProfiler {

    container 'quay.io/biocontainers/tb-profiler:2.8.6--pypy_0'

    input:
    tuple (genomeName, path(read_1_gz), path(read_2_gz)) from ch_tbProfiler

    script:

    """
    tb-profiler profile -1 $read_1_gz -2 $read_2_gz  -t 4 -p $genomeName
    """
}


///*
//###############
//prokka_annotation
//###############
//*/
//
//// NOTE prokka fails in virtualbox, unless we update tbl2asn
////https://github.com/tseemann/prokka/issues/139#issuecomment-153941842
////https://github.com/tseemann/prokka/issues/303
//
//process prokka {
////    echo true
//
//    container 'quay.io/biocontainers/prokka:1.14.6--pl526_0'
//
//    input:
//    path refFasta from ch_refFasta
//    path bestContig from ch_bestContig
//
//    script:
//    genomeName = bestContig.getName().split("\\_")[0]
//    contigName = bestContig + "_NC000962_3.fasta.fasta"
//
//
//// prokka-- outdir./G04868_prokka --prefix G04868 contigs.fa_NC000962_3.fasta.fasta
//    """
//    prokka --outdir ./${genomeName}_prokka --prefix $genomeName $contigName
//    """
//}
//
//#==============================================
//# RD_Analyzer
//#==============================================
//
//
//process rdAnalyzer {
////    echo true
//
//    input:
//    path refFasta from ch_refFasta
//    path bestContig from ch_bestContig
//    tuple path(fq_1), path(fq_2) from ch_fastq
//
//    script:
//    genomeName = bestContig.getName().split("\\_")[0]
//    contigName = bestContig + "_NC000962_3.fasta.fasta"
//
//
////python2.7 rdanalyzer.py -o  23_rdanalyzer 23_R1.fastq
//    """
//    rdanalyzer --o ./${genomeName}_rdanalyzer --prefix $genomeName $contigName
//
//    """
//}
//
//
//
////###############
//// Spotyping
////###############
//
//process spotyping {
////    echo true
//
//    input:
//    path refFasta from ch_refFasta
//    path bestContig from ch_bestContig
//
//    script:
//    genomeName = bestContig.getName().split("\\_")[0]
//    contigName = bestContig + "_NC000962_3.fasta.fasta"
//
//    """
//    python2.7 SpoTyping.py ./${fq_1_paired} -o {genomeName}.txt
//    """
//}
//
//
//
////###############
//// Spades
////###############
//
//#spades.py -k 21,33,55,77 --careful --only-assembler --pe1-1 23_R1_p.fastq --pe1-2 23_R2_p.fastq -o 23_spades
//
