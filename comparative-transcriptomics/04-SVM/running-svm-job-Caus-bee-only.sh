#!/bin/bash -l

#$ -l h_rt=70:0:0

#$ -l mem=20G

#$ -M ucfaeef@ucl.ac.uk -m abe

#$ -N SVM_20rep_Caus_beeonly

#$ -wd /lustre/home/ucfaeef/projects/MajorTransitionScripts/comparative-transcriptomics/svm

#$ -e /lustre/home/ucfaeef/projects/MajorTransitionScripts/comparative-transcriptomics/svm

#$ -o /lustre/home/ucfaeef/projects/MajorTransitionScripts/comparative-transcriptomics/svm

# Run svm with bee only training data

module unload compilers
module unload mpi
module load r/recommended

Rscript leave-one-species-out-svm.R Ceratina_australensis SVM_bees_only Ceratina_calcarata Megalopta_genalis

