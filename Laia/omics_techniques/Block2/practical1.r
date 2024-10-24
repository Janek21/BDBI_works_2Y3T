# Install Bioconductor
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(c("GenomicFeatures", "AnnotationDbi"))
BiocManager::install(version = "3.19")


################################################################################
#   EXPRESSION SET
################################################################################
# Install the Biobase package
BiocManager::install("Biobase")
library(Biobase)

exprs <- matrix(rnorm(6 * 10), ncol=6, nrow=10)
exprs

phenoData <- data.frame(sample=factor(1:6),
                        condition=factor(c("A","A","B","B","C","C")),
                        treated=factor(rep(0:1,3)))
phenoData

featureData <- data.frame(geneID=1:10, geneSymbol=letters[1:10])
featureData

# We put the three tables together
eset <- ExpressionSet(exprs,
                      AnnotatedDataFrame(phenoData),
                      AnnotatedDataFrame(featureData))
eset

# The data can be accessed
exprs(eset)
pData(eset)
fData(eset)

# Get a specific column
eset$condition

# Get a subset
idx <- eset$condition %in% c("A","B") # idx és un vector de T of F
eset.sub <- eset[,idx] # s'agafen els que compleixen la condició d'adalt
exprs(eset.sub) # només es mostren els que compleixen la condició 
pData(eset.sub) 

################################################################################
#   GEO
################################################################################
BiocManager::install("GEOquery")
library(GEOquery)

geo <- getGEO("GSE2125", destdir=".")
e <- geo[[1]]

# Look at the phenotypic data
names(pData(e))
e$molecule_ch1
e$contact_city
e$extract_protocol_ch1[1]

# We often care about characteristics_ch1
e$condition <- sub("status: ","",e$characteristics_ch1)
table(e$condition)

exprs(e)[1:5,1:5]
range(exprs(e))
boxplot(exprs(e),range=0, las=2)

# Further info
experimentData(e)
annotation(e) 

################################################################################
#   SUMMARIZED EXPERIMENT
################################################################################
library(SummarizedExperiment)
colData <- data.frame(sample=factor(1:6),
                      condition=factor(c("A","A","B","B","C","C")),
                      treated=factor(rep(0:1,3)))
colData

# BiocManager::install("EnsDb.Hsapiens.v86")
library(EnsDb.Hsapiens.v86)
txdb <- EnsDb.Hsapiens.v86
g <- genes(txdb)
g <- keepStandardChromosomes(g, pruning.mode="coarse")
rowRanges <- g[1:10]

exprs <- matrix(rnorm(6 * 10), ncol=6, nrow=10)
se <- SummarizedExperiment(assay=list("exprs"=exprs),
                           colData=colData,
                           rowRanges=rowRanges)
se

assayNames(se)

mcols(se)$score <- rnorm(10)
mcols(se)

idx <- se$condition %in% c("A","B")
se.sub <-se[, idx]
se.sub

se2 <- makeSummarizedExperimentFromExpressionSet(e)
se2

################################################################################
#   RANGES IN SUMMARIZED EXPERIMENT
################################################################################
query <- GRanges("1", IRanges(25000,40000))
se.sub <- se[overlapsAny(se, query), ]

# Equivalently
se.sub <- se[se %over% query,]
rowRanges(se.sub)
assay(se.sub)
seqinfo(se)
barplot(sort(seqlengths(se)))

################################################################################
#   DOWNLOADING IN SUMMARIZED EXPERIMENT
################################################################################
load(file = file("https://duffel.rail.bio/recount/SRP046226/rse_gene.Rdata"))
rse <- rse_gene
dim(rse)
assay(rse)[1:5,1:5]
colData(rse)[,1:5]
names(colData(rse))

class(rse$characteristics)
rse$characteristics[1:3]
rse$characteristics[[1]]

rse$condition <- sapply(rse$characteristics, `[`, 3)
rse$treatment <- sapply(rse$characteristics, `[`, 4)

rowRanges(rse)
seqinfo(rse)

rse$condition <- factor(sub("-",".", sub("disease state: (.*)","\\1", rse$condition)))
rse$treatment <- factor(sub("treatment: (.*)","\\1",rse$treatment)) 
rse$condition

rse$treatment
rownames(rse[1, ])
boxplot(t(assay(rse[1, ])) ~ rse$condition:rse$treatment)