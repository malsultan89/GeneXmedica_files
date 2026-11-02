# GeneXmedica

GeneXmedica is an R/Shiny pharmacogenetic decision-support application that retrieves medication-specific recommendations from a curated CPIC-based database. The database contains 317 medication–genotype associations involving 20 medications.

## Package contents

- `app.R`: complete R/Shiny application source code.
- `GeneXmedica_database.xlsx`: curated pharmacogenetic database used by the application.
- `README.md`: software requirements, launch instructions, database documentation, and guideline sources.

Keep all three files in the same directory. The application uses a relative path and does not require a computer-specific Windows path.

## Recorded software environment

- R 4.4.0 (2024-04-24 ucrt)
- Platform: x86_64-w64-mingw32/x64
- Operating system: Windows 11 x64, build 26200
- shiny 1.8.1.1
- readxl 1.4.5
- dplyr 1.2.1

The remaining packages listed in the recorded R session were loaded as dependencies: jsonlite 2.0.0, compiler 4.4.0, promises 1.3.0, tidyselect 1.2.1, Rcpp 1.0.12, later 1.3.2, jquerylib 0.1.4, fastmap 1.2.0, mime 0.12, R6 2.5.1, generics 0.1.3, curl 5.2.1, tibble 3.2.1, openssl 2.2.0, lubridate 1.9.3, bslib 0.7.0, pillar 1.9.0, rlang 1.2.0, utf8 1.2.4, cachem 1.1.0, httpuv 1.6.15, sass 0.4.9, timechange 0.3.0, memoise 2.0.1, cli 3.6.2, withr 3.0.0, magrittr 2.0.3, digest 0.6.35, rstudioapi 0.16.0, xtable 1.8-4, askpass 1.2.0, lifecycle 1.0.5, vctrs 0.7.1, glue 1.7.0, cellranger 1.1.0, rsconnect 1.2.2, fansi 1.0.6, tools 4.4.0, pkgconfig 2.0.3, and htmltools 0.5.8.1.

## Installation

Install the three directly required packages if they are not already available:

```r
install.packages(c("shiny", "readxl", "dplyr"))
```

For exact package-version reproduction, the recorded versions can be installed with an appropriate package-version manager before launching the application.

## Launch instructions

### RStudio

1. Download or clone this package.
2. Confirm that `app.R` and `GeneXmedica_database.xlsx` are in the same directory.
3. Open `app.R` in RStudio.
4. Select **Run App**.

### R console

Set the working directory to the downloaded package directory and run:

```r
shiny::runApp(".")
```

## Database structure

The application reads the `Normalized_Data` worksheet. Each row represents one medication–gene–normalized genotype association. The main fields are:

- Drug
- Therapeutic classification
- Gene
- Genotype
- Normalized genotype key
- Gene–diplotype key
- Predicted phenotype
- Clinical recommendation
- Version-specific guideline reference and URL
- Original source-row identifier

Grouped genotype entries in the source worksheet were separated into individual records. Equivalent representations are normalized for whitespace, allele order, and multiplication symbols. The gene is retained in the matching key so that identical genotype labels associated with different genes are not combined.

## Guideline sources

Every record in the `Reference` field includes the applicable guideline title, publication year or version, PMID, and direct source URL. The database uses the following guideline publications:

- CPIC Guideline for CYP2B6 and Efavirenz-Containing Antiretroviral Therapy (2019; PMID 31006110): https://files.cpicpgx.org/data/guideline/publication/efavirenz/2019/31006110.pdf
- CPIC Guidelines for Ivacaftor Therapy in the Context of CFTR Genotype (2014; PMID 24598717): https://files.cpicpgx.org/data/guideline/publication/ivacaftor/2014/24598717.pdf
- CPIC Guideline for CYP2C19 Genotype and Clopidogrel Therapy: 2022 Update (PMID 35034351): https://files.cpicpgx.org/data/guideline/publication/clopidogrel/2022/35034351.pdf
- CPIC Guideline for CYP2C19 and Proton Pump Inhibitor Dosing (2020 guideline; published 2021; PMID 32770672): https://files.cpicpgx.org/data/guideline/publication/PPI/2020/32770672.pdf
- CPIC Guideline for CYP2C9 and Nonsteroidal Anti-Inflammatory Drugs (2020; PMID 32189324): https://files.cpicpgx.org/data/guideline/publication/NSAID/2020/32189324.pdf
- CPIC Guideline for CYP2D6, OPRM1, and COMT Genotypes and Select Opioid Therapy (2020 guideline; published 2021; PMID 33387367): https://files.cpicpgx.org/data/guideline/publication/opioids/2020/33387367.pdf
- CPIC Guideline for CYP2D6, CYP2C19, CYP2B6, SLC6A4, and HTR2A Genotypes and Serotonin Reuptake Inhibitor Antidepressants (2023; PMID 37032427): https://files.cpicpgx.org/data/guideline/publication/serotonin_reuptake_inhibitor_antidepressants/2023/37032427.pdf
- CPIC Guideline for CYP2D6, ADRB1, ADRB2, ADRA2C, GRK4, and GRK5 Genotypes and Beta-Blocker Therapy (2024; PMID 38951961): https://files.cpicpgx.org/data/guideline/publication/beta_blockers/2024/38951961.pdf

Database review date: October 2026.

## Data availability statement

The curated GeneXmedica pharmacogenetic database, containing 317 medication–genotype associations involving 20 medications, is provided as Supplementary File S1 (`GeneXmedica_database.xlsx`). The complete R/Shiny application source code is provided as Supplementary File S2 (`app.R`), and the software requirements and launch instructions are provided as Supplementary File S3 (`README.md`). The same files will be made publicly available through the project GitHub repository. The specific guideline title, version, publication year, PMID, and source URL supporting each recommendation are documented in the database `Reference` field.

After the GitHub repository is created, add its permanent URL or archived release DOI to the manuscript Data Availability Statement.
