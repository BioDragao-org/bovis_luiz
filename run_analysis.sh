#==============================================
# Unzip 
#==============================================
gzip -dc ${oldR1Name} > ${newR1Name}.fastq


#==============================================
# Trimmomatic
#==============================================


java -jar /opt/Trimmomatic-0.36/trimmomatic-0.36.jar PE -phred33 \
G04868_1.fastq \ 
G04868_2.fastq  \ 
G04868_1_trimmed_paired.fastq \
G04868_1_trimmed_unpaired.fastq \
G04868_2_trimmed_paired.fastq  \ 
G04868_2_trimmed_unpaired.fastq  \
LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:36


#==============================================
# Snippy
#==============================================

 snippy --cpus 4 --outdir G04868 --ref ./ NC000962_3 . gbk-- R1./G04868_1.fastq.gz --R2 ./ G04868_2 . fastq.gz


#==============================================
# TB_Profiler
#==============================================

#==============================================
# Prokka
# NOTE: prokka requires spades to run first
# Check in the manual or here
# https://github.com/BioDragao-org/tese-nf/blob/master/_resources/G04868_scratch/G04868_vm.nf
#==============================================


## cd ./ G04868_49 && prokka-- outdir./G04868_prokka --prefix G04868 contigs.fa_NC000962_3.fasta.fasta


#==============================================
# RD_Analyzer
#==============================================

#==============================================
# Spotyping
#==============================================


