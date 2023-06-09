#!/bin/bash

# Calculate sequence number after Nextflow Trimming step

# Copyright Emeline Favreau, UCL

# files/path needed as input
thispath="/lustre/home/ucfaeef/projects/MajorTransitionScripts/comparative-transcriptomics/rnaseq-qc/Megalopta-genalis/result/Jones2017fwd/qc-after-trim"

alsothispath="/lustre/home/ucfaeef/projects/MajorTransitionScripts/comparative-transcriptomics/rnaseq-qc/Megalopta-genalis/result/Jones2017rev/qc-after-trim"

speciespath="/lustre/home/ucfaeef/projects/MajorTransitionScripts/comparative-transcriptomics/rnaseq-qc/Megalopta-genalis"

# after trimming
thisanalysis="qc-after-trim"

# dataset name
datasetname="Jones2017"

# make a directory for these calculations
mkdir -p tmp/${datasetname}/${thisanalysis}/
mkdir -p result/${datasetname}/${thisanalysis}/

# copy the zip files
cp ${thispath}/*.zip tmp/${datasetname}/${thisanalysis}/.
cp ${alsothispath}/*.zip tmp/${datasetname}/${thisanalysis}/.

# unzip files
cd tmp/${datasetname}/${thisanalysis}

ls > sample-file-names

for filename in `cat sample-file-names`; do
	unzip ${filename}
done

cd ${speciespath}

# obtain list of files eg SRR3948522_1_val_1
ls tmp/${datasetname}/${thisanalysis}/*_fastqc.zip \
	| cut -d "/" -f 4 \
	| cut -d "_" -f 1,2,3,4 \
	> tmp/${datasetname}/${thisanalysis}/file-list

# run a loop to obtain number of reads

for sample in `cat tmp/${datasetname}/${thisanalysis}/file-list`; do
	grep "Total Sequences" tmp/${datasetname}/${thisanalysis}/${sample}_fastqc/fastqc_data.txt >> tmp/${datasetname}/${thisanalysis}/number-reads-in-file
done

# copy information in a summary text file
paste tmp/${datasetname}/${thisanalysis}/file-list \
	tmp/${datasetname}/${thisanalysis}/number-reads-in-file \
	> tmp/${datasetname}/${thisanalysis}/number-reads-in-files


# obtain list of samples eg SRR3948522
cat tmp/${datasetname}/${thisanalysis}/file-list \
	| cut -d "_" -f 1 \
	| uniq > tmp/${datasetname}/${thisanalysis}/samples-list

# run a loop to obtain number of reads 

for sample in `cat tmp/${datasetname}/${thisanalysis}/samples-list`; do
	grep ${sample} tmp/${datasetname}/${thisanalysis}/number-reads-in-files | awk '{sum+=$4}END{print sum}' >> tmp/${datasetname}/${thisanalysis}/number-reads-in-sample

done

paste tmp/${datasetname}/${thisanalysis}/samples-list  tmp/${datasetname}/${thisanalysis}/number-reads-in-sample > result/${datasetname}/${thisanalysis}/number-reads-in-samples

#sum the read number for the whole experiment: 834046400
awk '{sum+=$2}END{print sum}' result/${datasetname}/${thisanalysis}/number-reads-in-samples