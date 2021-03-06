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
    container 'centos:8'

    input:
    tuple (genomeName, path(read_1_gz), path(read_2_gz)) from ch_fastqGz

    output:
    tuple genomeName, path(genome_1_fq), path(genome_2_fq) into ch_trimmomatic
    tuple genomeName, path(genome_1_fq), path(genome_2_fq) into ch_in_rdAnalyzer
    tuple genomeName, path(genome_1_fq), path(genome_2_fq) into ch_in_spades

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
    container 'quay.io/biocontainers/trimmomatic:0.35--6'


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

/*
#==============================================
# RD_Analyzer
#==============================================
*/

process rdAnalyzer {
    container 'abhi18av/rdanalyzer'

    input:
    tuple genomeName, path(fq_1), path(fq_2) from ch_in_rdAnalyzer

    script:

    """
    python  /RD-Analyzer/RD-Analyzer.py  -o ./${genomeName}_rdanalyzer ${fq_1} ${fq_2}

    """
}


/*
###############
Spotyping
###############
*/



process spotyping {
    container 'abhi18av/spotyping'

    input:
    tuple genomeName, path(fq_1_paired) from ch_in_spotyping

    script:

    """
    python /SpoTyping-v2.0/SpoTyping-v2.0-commandLine/SpoTyping.py ./${fq_1_paired} -o ${genomeName}.txt
    """
}


/*
###############
Spades
- Run on cloud
- Extremely RAM heavy
###############
*/

process spades {
    container 'quay.io/biocontainers/spades:3.14.0--h2d02072_0'

    input:
    tuple genomeName, path(fq_1), path(fq_2) from ch_in_spades

    script:


    """
    spades.py -k 21,33,55,77 --careful --only-assembler --pe1-1 ${fq_1} --pe1-2 ${fq_2} -o ${genomeName}_spades -t 2

    """
}




///*
//###############
// TODO 
//prokka_annotation
//###############
//*/
//
//// NOTE prokka fails in virtualbox, unless we update tbl2asn
////https://github.com/tseemann/prokka/issues/139#issuecomment-153941842
////https://github.com/tseemann/prokka/issues/303
//
//process prokka {
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
