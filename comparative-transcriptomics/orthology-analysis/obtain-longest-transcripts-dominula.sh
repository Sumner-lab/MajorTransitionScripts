#!/bin/bash

# Obtain longest transcript for  each gene in Polistes dominula
# Copyright Emeline Favreau, UCL

## Analysis overview
### Step 1: get the gene and protein ids from gff files
### Step 2: get the protein length from the proteomes
### Step 3: obtain the longest isoform for each protein
### Step 4: subset protein fasta file for just those isoforms

#################################################################################
## Step 1: get the gene and protein ids from gff files

# obtain gff
cd inputOnScratch/gff

wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/001/465/965/GCF_001465965.1_Pdom_r1.2/GCF_001465965.1_Pdom_r1.2_genomic.gff.gz

mv GCF_001465965.1_Pdom_r1.2_genomic.gff.gz Polistes_dominula.gff.gz

thisspecies="Polistes_dominula"

cd ../../

# check that gff is NCBI format (RefSeq)
# zcat inputOnScratch/gff/${thisspecies}.gff.gz | head
zcat inputOnScratch/gff/${thisspecies}.gff.gz | grep "CDS" | head
head inputOnScratch/${thisspecies}.faa

# this is specific to each GFF (not a norm unless from Ensembl)
# get gene and protein IDs from GFF file, e.g. 107074703 XP_015171009.1
# use uniq to remove duplicated
# useful link : https://www.biostars.org/p/388936/
# remove in column 9 anything that is before and includes ;Dbxref=GeneID:
# remove in column 9 anything that is after ,BEEBASE;
# remove the string ,Genbank:
zcat inputOnScratch/gff/${thisspecies}.gff.gz | awk '$3=="CDS"{gsub(".+;Dbxref=GeneID:", "", $9); gsub(";Name=.+", "", $9); gsub(",Genbank:", "\t", $9); print $9}' | sort | uniq > inputOnScratch/gff/${thisspecies}.tsv


#################################################################################
## Step 2: get the protein length from the proteomes

# first, tidy fastaa headers by checking first ( head -n 1 inputOnScratch/${thisspecies}.faa | cut -d " " -f 1)
# remove the second part of the sequence header after the gene ID, the delimmiter is space
# fx2tab calculate the sequence length
# sort the result
~/programs/./seqkit fx2tab -n -l inputOnScratch/${thisspecies}.faa \
  | awk 'BEGIN{FS="\t"}{gsub(" .*", "", $1); print}' \
  | sort \
  > inputOnScratch/sequence-length/${thisspecies}-sequence-length.tsv




#################################################################################
## Step 3: obtain the longest isoform for each protein
# based on Anindita's longest_protein_isoform_Step_2.Rmd
module unload compilers
module unload mpi
module load r/recommended


Rscript --vanilla subset-longest-protein-isoform.R inputOnScratch/gff/${thisspecies}.tsv inputOnScratch/sequence-length/${thisspecies}-sequence-length.tsv inputOnScratch/longest-isoform/${thisspecies}_protein_longest_isoform.txt


#################################################################################
## Step 4: subset protein fasta file for just those isoforms
# subset protein sequences for those longest proteins

# update the faa headers for short name (ie just the gene name)
awk '{gsub(" .*", ""); print}' inputOnScratch/${thisspecies}.faa > inputOnScratch/${thisspecies}-short-name.faa

# remove protein sequences that are not the longest isoform
seqtk subseq inputOnScratch/${thisspecies}-short-name.faa \
	inputOnScratch/longest-isoform/${thisspecies}_protein_longest_isoform.txt \
	> inputOnScratch/primary_transcripts/${thisspecies}-longest-isoforms.faa

# this protein fasta has the longest isoform, with headers containing just gene id (i.e. >XP_015171009.1)