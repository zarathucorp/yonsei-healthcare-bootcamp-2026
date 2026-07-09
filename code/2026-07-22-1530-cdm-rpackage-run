## Run renv
renv::restore(prompt = FALSE)

## Install atlas package
install.packages(".", repos = NULL, type = "source")

## Load package
library(htn);htn:::verifyDependencies()

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = file.path(tempdir(), "hypertension_andromeda"))

# Maximum number of cores to be used:
#maxCores <- max(1, parallel::detectCores() - 1)
maxCores <- 3

# Minimum cell count when exporting data:
minCellCount <- 0

# The folder where the study intermediate and result files will be written:
outputFolder <- file.path(getwd(), "output")


connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
                                                                server = "127.0.0.1/mimiciv_cdm",
                                                                user = "cdm_user",
                                                                password = " ",
                                                                port = 5432,
                                                                pathToDriver = "/opt/ohdsi/jdbc/postgresql")

# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- "cdm"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "cdm_results"
cohortTable <- "hypertension_cohort"

# Some meta-information that will be used by the export function:
databaseId <- "MIMIC_IV_CDM"
databaseName <- "mimic-iv-cdm"
databaseDescription <- "MIMIC-IV CDM"

# Schema used when SQL temp table emulation is requested:
tempEmulationSchema <- "temp"
options(sqlRenderTempEmulationSchema = tempEmulationSchema)

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        tempEmulationSchema = tempEmulationSchema,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        verifyDependencies = TRUE,
        createCohorts = TRUE,
        synthesizePositiveControls = TRUE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = maxCores,
        minCellCount = minCellCount)

resultsZipFile <- file.path(outputFolder, "export", paste0("Results_", databaseId, ".zip"))


