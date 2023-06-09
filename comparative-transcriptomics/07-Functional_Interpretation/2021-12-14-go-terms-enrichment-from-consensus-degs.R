# TopGo GO terms enrichment analyses from consensus DEGs
# run this script for the list, without directionality, 3 GO categories (BP, MF and CC)
# TopGo analyses
# Copyright 2021 Emeline Favreau, University College London.

##### Objective of analysis
# Obtaining GO terms that are enriched in the given dataset

##### Analysis steps:
# Obtaining data
# GO term enrichment 
# saving result table

# 
# install packages on myriad personal R path
#install.packages("BiocManager")
#BiocManager::install("topGO", site_repository = "http://cran.us.r-project.org")
#BiocManager::install("biomaRt", site_repository = "http://cran.us.r-project.org")

# load  libraries
library("biomaRt")
library("topGO")


# vector of all categories available
goCategory_vec <- c("BP", "MF", "CC")

# loop over the categories
for(gocat in goCategory_vec){
  
  # set experiment details (GO Category)
  this_goCategory  <- gocat
  
  # set data input (we use C. australensis but we could use any)
  raw_results_file         <- 
    "../inputOnScratch/Ceratina_australensis_DESeq2_results.txt"
  raw_selectionGenes_file  <- "../inputOnScratch/all_DEGs.txt"
  raw_blast_results_file   <- "../resultOnScratch/Ceratina_australensis_filtered"
  hash_table <- "../tmp/Ceratina_australensis_protein_gene_hash_table"
  orthogroup_caus_selection_genes_file <- "../resultOnScratch/all_DEGs_Caus_genes"
  
  
  # import all DEG results 
  # columns: X baseMean log2FoldChange lfcSE stat pvalue padj
  # rows: genes
  raw_results <- read.delim(raw_results_file,
                            stringsAsFactors = FALSE)
  
  # import significant DEG 
  # one column with names of orthogroups
  raw_selectionGenes <- read.table(raw_selectionGenes_file,
                                   quote = "\"",
                                   comment.char = "",
                                   stringsAsFactors = FALSE)
  
  
  # blast results: each Drosophila Orthogroup has a match in 
  # similarity with a species' protein
  raw_blast_results <- read.table(raw_blast_results_file,
                                  stringsAsFactors = FALSE)
  
  # hash table: protein in column 1, gene in column 2
  hash_df <- read.table(hash_table,
                        stringsAsFactors = FALSE)
  
  # columns: X baseMean log2FoldChange lfcSE stat pvalue padj
  # rows: genes
  orthogroup_caus_selection_genes <- read.delim(orthogroup_caus_selection_genes_file,
                                                header = FALSE,
                            stringsAsFactors = FALSE)
  
  
  # add column names 
  colnames(raw_results) <- c("gene", colnames(raw_results)[2:7])
  colnames(raw_selectionGenes) <- "orthogroup"
  colnames(raw_blast_results) <- c("qseqid", "sseqid", "pident", "length",
                                   "mismatch", "gapopen", "qstart",
                                   "qend", "sstart", "send", "evalue",
                                   "bitscore")
  
  colnames(hash_df) <- c("qseqid", "gene")
  colnames(orthogroup_caus_selection_genes) <- c("orthogroup", "gene")
  
  # update blast query sequence id (to gene-LOCXXX, matching DESeq2 result table)
  raw_blast_results$qseqid <- hash_df$gene[match(raw_blast_results$qseqid,
                                                 hash_df$qseqid)]
  
  # r getting gene to go mapping droso
  
  # connect to the genes services
  ensembl <- useEnsembl(biomart = "ensembl",
                        dataset = "dmelanogaster_gene_ensembl")
  
  
  
  # list of droso genes that I want, I think these are transcript id
  droso_gene_list <- raw_blast_results$sseqid
  
  
  gene2Go_raw <- getBM(attributes = c("flybase_translation_id", "go_id"), 
                       filters     = "flybase_translation_id", 
                       values      = droso_gene_list, 
                       mart        = ensembl,
                       useCache    = FALSE)
  
  # Remove the genes without GO terms
  gene2Go_df <- subset(x = gene2Go_raw,
                       subset = !go_id == "")
  
  # update the object to fit topgo
  gene_to_go <- aggregate(go_id ~ flybase_translation_id,
                          data = gene2Go_df,
                          c)
  # vector of GO identifiers
  go_id <- gene_to_go$go_id
  
  # add names to the vector
  gene2go <- setNames(go_id,
                      gene_to_go$flybase_translation_id)
  
  ##### GO term enrichment 
  
  # aim to change species's protein names for drosophila names
  # because the TopGO database does not contain non-model data
  
  # there are NA because blasting droso against the species might have produced no hit
  raw_results$droso_gene <- raw_blast_results$sseqid[match(raw_results$gene,
                              raw_blast_results$qseqid)]
  
  orthogroup_caus_selection_genes$droso_gene <- 
    raw_blast_results$sseqid[match(orthogroup_caus_selection_genes$gene,
                                      raw_blast_results$qseqid)]
  
  
  # remove NA.
  raw_results <- raw_results[!is.na(raw_results$droso_gene), ]
  orthogroup_caus_selection_genes <- 
    orthogroup_caus_selection_genes[!is.na(orthogroup_caus_selection_genes$droso_gene), ]
  
  
  ## make a vector with 0 or 1 values depending if a gene is DE or not
  # results: lists of genes differentially expressed 
  geneList <- rep(0, times = length(rownames(raw_results)))
  
  # name each value with the droso genes names
  names(geneList) <- raw_results$droso_gene
  
  # selectionGenes: list of DEG for selection
  DEGenes <- orthogroup_caus_selection_genes$droso_gene
  
  # for each gene that is the focus of the analysis, change the value 0 for 1
  geneList[DEGenes] <- 1
  
  # change the class to factor
  geneList <-  as.factor(geneList)
  
  
  ## Build the topGO object for biological process ontology
  this_topGOdata <- new("topGOdata",
                        ontology = this_goCategory,
                        allGenes = geneList,
                        geneSel  = DEGenes,
                        nodeSize = 5,
                        annot    = annFUN.gene2GO,
                        gene2GO  = gene2go)
  
  # test for enrichment
  # because we coded the genes 1 or 0 for DEG presence or absence, 
  # Fisher test (gene count) is probably the best algorithm
  # classic: each GO category is tested independently
  this_topGOresult <- runTest(this_topGOdata,
                              algorithm = "classic",
                              statistic = "fisher")
  
  
  
  # create a result table
  # GO Terms identified by fisher test
  # 4170: the number of top GO terms to be included in the table.
  myTable <- GenTable(this_topGOdata,
                      pvalue = this_topGOresult,
                      topNodes = length(this_topGOdata@graph@nodes),
                      numChar = 100)
  
  
  # add columns to specify test details
  myTable$species <- "consensus-degs"
  myTable$goCategory <- this_goCategory
  
  
  
  
  # make a file name
  this_file_name <- paste("../resultOnScratch/topgo_result",
                          "consensus-degs",
                          this_goCategory,
                          sep = "_")
  # save table
  write.table(x          = myTable,
              file       = this_file_name,
              quote      = FALSE,
              row.names  = FALSE,
              sep        = "\t")
  
}   




