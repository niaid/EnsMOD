# EnsMOD app
# Jian Song
# 1/3/2023
#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
options(scipen = 999)

## Check to see if required R packages installed
# Check and install 'limma' package if needed
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

if (!require("limma"))
  BiocManager::install("limma")

# Check and install other packages if needed
list.of.packages <- c("shiny", "shinyjs", "xfun", "DT", "factoextra", "readr", "dplyr", "data.table", "reshape2", "htmltools", "readxl", "stats", "rrcov", "cluster", "ggraph", "RColorBrewer", "tidyverse", "gplots", "fitdistrplus")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Load required R packages
library(shiny)
library(shinyjs)
library(xfun)
library(DT)
library(factoextra)
library(readr)
library(dplyr)
library(data.table)
library(reshape2)
library(htmltools)
library(readxl)
library(stats)
library(rrcov)
Sys.setenv(R_ZIPCMD="/usr/bin/zip")

#setting
#override scientific notation to avoid numeric mis assignments
options(scipen = 999)

# Set the maximum input file size to 30Mb
options(shiny.maxRequestSize = 30*1024^2)

#################################
# Define UI for application
ui <- fluidPage(
  
  # Capture user access information
  tags$head(
    tags$title("EnsMOD - Ensemble Methods for Outlier Detection")
  ),
  
  # Show a header using the header style
  headerPanel(includeHTML("header.html")),
  
  # style
  theme = "./css/ensmod.css",
  
  # use shinyjs
  useShinyjs(), br(),
  
  # Sidebar with a slider input for number of bins
  sidebarLayout(
    
    sidebarPanel(
      tags$body(HTML('<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-56JHMG"
                          height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>'
      )
      ),
      # Parameters to be selected
      selectInput(inputId = "CCC_min",
                  label = "Cophenetic Correlation Coefficient (CCC):",
                  choices = c(0.8, 0.9),
                  selected = 0.8
      ),
      selectInput(inputId = "SC_max",
                  label = "Silhouette Coefficient (SC):",
                  choices = c(0.25, 0.5),
                  selected = 0.25
      ),
      selectInput(inputId = "robpca_prob",
                  label = "Robust Sparse PCA algorithm (robpca) cutoff:",
                  choices = c(0.975, 0.95),
                  selected = 0.975
      ),
      selectInput(inputId = "PcaGrid_prob",
                  label = "Robust PCA algorithm (PcaGrid) cutoff:",
                  choices = c(0.975, 0.95),
                  selected = 0.975
      ),
      fileInput(inputId= "file1",
                label = 'Choose an input file to upload',
                buttonLabel = "Browse...",
                # Select a single file
                multiple = FALSE, 
                # Restrict input file types to .txt, .csv and .xlsx files
                accept=c("txt/csv", "text/comma-separated-values,text/plain", ".csv", ".xlsx")
      ),
      
      actionButton("goButton", "Analyze my data",
                   style="padding:4px; font-size:120%; color: #fff; background-color: rgb(1, 81, 154); border-color: #2e6da4"),
      actionButton("refresh", "Reset", icon("undo"),
                   style="padding:4px; font-size:120%; color: #fff; background-color: rgb(1, 81, 154); border-color: #2e6da4"),
      width = 3
    ),
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(id = "inTabset",
                  tabPanel(title = "Home", value = "landingPage",
                           htmlOutput("spacer1"),
                           h3("EnsMOD: A Software Program for Omics Sample Outlier Detection", align = "center"),
                           br(),
                           p("Detection of omics sample outliers is important for preventing erroneous biological conclusions, 
                                developing robust experimental protocols, and discovering rare biological states. 
                                Two recent publications describe robust algorithms for detecting transcriptomic sample outliers, 
                                but neither algorithm had been incorporated into a software tool for omics scientists. 
                                Ensemble Methods for Outlier Detection (EnsMOD) was developed by incorporating several 
                                different algorithms for robust analysis to identify potential outliers. 
                                EnsMOD calculates how closely the quantitation variation follows a normal distribution, 
                                plots the density curves of each sample to visualize anomalies, performs hierarchical cluster analyses 
                                to calculate how closely the samples cluster with each other, and performs robust principal component analyses 
                                to statistically test if any sample is an outlier. The probabilistic threshold parameters can be 
                                easily adjusted to tighten or loosen the outlier detection stringency. 
                                EnsMOD was used to analyze a simulated proteomics dataset, a multiomic (proteome and transcriptome) dataset, 
                                a single-cell proteomics dataset, and a phosphoproteomics dataset. EnsMOD successfully identified all 
                                of the simulated outliers, and outlier removal improved data quality for downstream statistical analyses.",
                             style = "font-family: Sans-serif; font-size: 16px" 
                           ),
                           br(),
                           HTML("<i>Please refer to the <b>User Guide</b> on how to adjust the cutoff parameters, input file format, and understanding the results.</i>"),
                           br()
                  ),
                  tabPanel(title = "Input", value = "contents",
                           htmlOutput("spacer2"),
                           dataTableOutput("contents"),
                           br()
                  ),
                  tabPanel(title = "Density Plot", value = "densityPlot",
                           htmlOutput("spacer3"),
                           htmlOutput("notes"),
                           plotOutput("densityPlot", width = "100%", height = "700px")
                  ),
                  tabPanel(title = "hClustering", value = "hClustering",
                           htmlOutput("spacer4"),
                           htmlOutput("hClusteringHeader"),
                           plotOutput("hClustering", width = "100%", height = "700px")
                  ),
                  tabPanel(title = "RobustPCA", value = "robustPCA",
                           tabsetPanel(id = 'robustPCA',

                                       # Display RobustPCA (PcaGrid)
                                       tabPanel(title="PcaGrid", value="PcaGrid",
                                                HTML("<div id='PcaGrid'></div>"),
                                                plotOutput("PcaGrid", width = "100%", height = "700px")
                                       ),
                                       # Display Robust Sparse PCA (robpca)
                                       tabPanel(title="robpca", value="robpca",
                                                HTML("<div id='robpca'></div>"),
                                                #htmlOutput("robpca", width = "100%", height = "700px")
                                                uiOutput("robpca")
                                       )
                           )
                  ),
                  tabPanel(title = "Outliers", value = "outliers",
                           htmlOutput("spacer5"),
                           # Show a list of potential outliers identified by different methods
                           htmlOutput("hcOutliers"),
                           uiOutput("hcoutliers"),
                           htmlOutput("robustOutliers"),
                           uiOutput("robustoutliers"),
                           htmlOutput("ensembleOutliers"),
                           uiOutput("ensembleoutliers")
                  ),
                  tabPanel(title = "Rmarkdown", value = "rmarkdown",
                           htmlOutput("spacer7"),
                           htmlOutput("rmarkdown")
                  ),
                  tabPanel(title = "User Guide", value = "userGuide",
                           htmlOutput("spacer8"),
                           uiOutput("userguide")
                  )
      ),
      width = 9
    )
  ),
  
  # Show a footer using the header style
  headerPanel(includeHTML("footer.html"))
)

##################################################
# Define server logic
server <- function(session, input, output){
  
  # Add spacers in the tab panel
  output$spacer1 <- renderUI({
    HTML("<BR><BR>")
  })
  output$spacer2 <- renderUI({
    HTML("<BR><BR>")
  })
  output$spacer3 <- renderUI({
    HTML("<BR>")
  })
  output$spacer4 <- renderUI({
    HTML("<BR>")
  })      
  output$spacer5 <- renderUI({
    HTML("<BR>")
  })  
  output$spacer6 <- renderUI({
    HTML("<BR>")
  })  
  output$spacer7 <- renderUI({
    HTML("<BR>")
  })    
  output$spacer8 <- renderUI({
    HTML("<BR>")
  }) 
  output$spacer9 <- renderUI({
    HTML("<BR>")
  }) 
  # Global environmental variables
  envs <- Sys.getenv()
  env_names <- names(envs)
  
  # Read in the input fie
  output$contents <- renderDataTable({
    inFile <- input$file1
    
    if (is.null(inFile))
      return(NULL)
    
    # Allow CSV, TXT, EXCEL files ONLY
    if(file_ext(inFile$name) == "csv"){
      data <- read.csv(inFile$datapath, stringsAsFactors = FALSE, header=TRUE)
    }
    else if(file_ext(inFile$name) == "txt"){
      data <- read.table(inFile$datapath, sep = "\t", header=TRUE, fill = TRUE)
    }
    else if(file_ext(inFile$name) == "xlsx"){
      data <- read_excel(inFile$datapath, col_names = TRUE)
    }
    else{
      showModal(modalDialog(title="Input File Type Errors:", HTML("<h3><font color=red>Input file type not supported!<br>Only .CSV, .TXT, .XLSX file allowed</font><h3>")))
      return(NULL)
    }
    
    # display the input file dimension
    datatable(data, rownames = FALSE, options = list(paging=TRUE)) 
    
    # Save a copy of data to be used
    input_data <<- data   
  })
  
  # Switch to input tab when file is uploaded
  observeEvent(input$file1, {
    inFile2 <- input$file1
    if(is.null(inFile2)) return (NULL)
    updateTabsetPanel(session, "inTabset", selected = "contents")
  })
  
  # reloads the app
  observeEvent(input$refresh, { 
    session$reload()
  })    
  
  #####################################
  ##### Start performing analysis #####
  #####################################
  observeEvent(input$goButton, {
    ## Check if input file and relevant paremater selected
    ## if not, show an error message
    if(is.null(input$file1)){
      showModal(modalDialog(title="User Input Errors:", HTML("<h3><font color=red>No input file selected!</font><h3>")))
      return(NULL)
    }
    
    ## Show progress bar
    # Create a Progress object
    progress <- shiny::Progress$new()
    # Make sure it closes when we exit this reactive, even if there's an error
    on.exit(progress$close())
    
    progress$set(message = "Performing analysis....", value = 0)
    
    startA = Sys.time()
    
    
    # Display in the Download tab
    outputDir <- "./www/EnsMODoutputs"
    if(!file.exists(outputDir)){
      dir.create(outputDir)
      print(paste0(outputDir, " created"))
    }
    
    # ## Switch to 'Enriched Pathways' tab and display partial results
    # observe({
    #   if(completed) {
    #     updateTabsetPanel(session, "inTabset", selected = "enrichedPathways")
    
    # 
    input_data <- as.data.frame(sapply(input_data, as.numeric))
    # Remove any row (genes/proteins) with one or more invalid values ("NaN")
    input_data_nna <<- input_data[complete.cases(input_data), ]            
    
    # Geneate Hierarchical Clustering for SC
    # Number of samples
    input_data_col <- dim(input_data_nna)[2]
    
    # Transpose the data so the sample will become the rows and genes/proteins will become the columns
    input_data_nna_t <<- t(input_data_nna)
    
    # Calculate distances: Euclidean, Manhattan, Pearson correlation coefficient
    d_e <- dist(input_data_nna_t, method = "euclidean")
    d_m <- dist(input_data_nna_t, method = "manhattan")
    c_2 = cor(input_data_nna, method="pearson")
    d_p <- as.dist(1 - c_2)
    
    # Update the progress
    progress$inc(1/10)
    
    # Linkages: "average" (= UPGMA), "ward.D2", "complete", "single", "centroid" (= UPGMC)
    # Hierarchical clustering using Euclidean distance
    hc_e_a <- hclust(d_e, method = "average" ) 
    hc_e_w <- hclust(d_e, method = "ward.D2" ) 
    hc_e_co <- hclust(d_e, method = "complete" ) 
    hc_e_s <- hclust(d_e, method = "single" ) 
    hc_e_ce <- hclust(d_e, method = "centroid" ) 
    # Hierarchical clustering using Manhattan distance
    hc_m_a <- hclust(d_m, method = "average" ) 
    hc_m_w <- hclust(d_m, method = "ward.D2" ) 
    hc_m_co <- hclust(d_m, method = "complete" ) 
    hc_m_s <- hclust(d_m, method = "single" ) 
    hc_m_ce <- hclust(d_m, method = "centroid" ) 
    # Hierarchical clustering using Pearson correlation coefficient
    hc_p_a <- hclust(d_p, method = "average" )
    hc_p_w <- hclust(d_p, method = "ward.D2" )
    hc_p_co <- hclust(d_p, method = "complete" )
    hc_p_s <- hclust(d_p, method = "single" )
    hc_p_ce <- hclust(d_p, method = "centroid" )
    
    # The Cophenetic Correlation Coefficient (CCC) is a measure of how faithfully a dendrogram preserves the pairwise distances between the original unmodeled data points.
    res.coph_e_a <- cophenetic(hc_e_a)
    res.coph_e_w <- cophenetic(hc_e_w)
    res.coph_e_co <- cophenetic(hc_e_co)
    res.coph_e_s <- cophenetic(hc_e_s)
    res.coph_e_ce <- cophenetic(hc_e_ce)
    
    res.coph_m_a <- cophenetic(hc_m_a)
    res.coph_m_w <- cophenetic(hc_m_w)
    res.coph_m_co <- cophenetic(hc_m_co)
    res.coph_m_s <- cophenetic(hc_m_s)
    res.coph_m_ce <- cophenetic(hc_m_ce)
    
    res.coph_p_a <- cophenetic(hc_p_a)
    res.coph_p_w <- cophenetic(hc_p_w)
    res.coph_p_co <- cophenetic(hc_p_co)
    res.coph_p_s <- cophenetic(hc_p_s)
    res.coph_p_ce <- cophenetic(hc_p_ce)
    
    # Update the progress
    progress$inc(1/5)
    
    # Correlations between the distance matrix and the Cophenetic Correlations
    # are compared for 'euclidean', 'manhattan', and 'pearson' distances to see which
    # one is the best.  The higher the correlation, the better the HCA.
    # Create a dataframe to store the CCC values from each distance and linkage combination
    distance = c("euclidean", "euclidean", "euclidean", "euclidean", "euclidean",
                 'manhattan', 'manhattan', 'manhattan', 'manhattan', 'manhattan', 
                 'pearson', 'pearson', 'pearson', 'pearson', 'pearson')
    linkage = c('average', 'ward.D2', 'complete', 'single', 'centroid',
                'average', 'ward.D2', 'complete', 'single', 'centroid',
                'average', 'ward.D2', 'complete', 'single', 'centroid')
    distance_matrix = c('e_a', 'e_w', 'e_co', 'e_s', 'e_ce',
                        'm_a', 'm_w', 'm_co', 'm_s', 'm_ce',
                        'p_a', 'p_w', 'p_co', 'p_s', 'p_ce')
    CCC = c(
      cor(d_e, res.coph_e_a),
      cor(d_e, res.coph_e_w),
      cor(d_e, res.coph_e_co),
      cor(d_e, res.coph_e_s),
      cor(d_e, res.coph_e_ce),
      
      cor(d_m, res.coph_m_a),
      cor(d_m, res.coph_m_w),
      cor(d_m, res.coph_m_co),
      cor(d_m, res.coph_m_s),
      cor(d_m, res.coph_m_ce),
      
      cor(d_p, res.coph_p_a),
      cor(d_p, res.coph_p_w),
      cor(d_p, res.coph_p_co),
      cor(d_p, res.coph_p_s),
      cor(d_p, res.coph_p_ce))
    
    CCC_df = data.frame(distance, linkage, distance_matrix, CCC)
    CCC_df_ranked = CCC_df[order(-CCC_df$CCC),]
    
    # Find the best distance-linkage combination
    CCC_df_ranked_top = CCC_df_ranked[1,]
    
    # Calculate the maximum possible number of clusters - 20 or fewer
    MaxPosNumClusters <- min(c(20 , (input_data_col - 1) ))
    hc.res_a <<- eclust(input_data_nna_t, FUNcluster = "hclust", k = NULL, k.max = MaxPosNumClusters, stand = FALSE, graph = FALSE, hc_metric = CCC_df_ranked_top$distance, hc_method = CCC_df_ranked_top$linkage, nboot=100, seed=78)
    
    # Update the progress
    progress$inc(2/5)
    
    
    ## Run Rmarkdown
    inFile2 <- input$file1
    rmarkdown::render("./Ensemble_Methods_for_Outlier_Detection_v2_0.Rmd", 
                      output_format = 'html_document', 
                      output_dir = outputDir, 
                      params=list(
                        inputFile=inFile2$datapath,
                        CCC_min=input$CCC_min,
                        SC_max=input$SC_max,
                        robpca_prob=input$robpca_prob,
                        PcaGrid_prob=input$PcaGrid_prob)
    )
    #  Display the HTML file generated from Rmarkdown
    getPage<-function() {
      return(includeHTML("./www/EnsMODoutputs/Ensemble_Methods_for_Outlier_Detection_v2_0.html"))
    }
    output$rmarkdown<-renderUI({getPage()})          
    
    # To be used as global variable 
    PcaGrid_prob <<- as.numeric(input$PcaGrid_prob)
    
    # Update the progress status
    progress$inc(3/5)
  })
  
  
  # Generate and display density plot
  output$notes <- renderUI({
    HTML("<BR><font color=blue>Density Plot</font> is usually an effective way to view the distribution of a variable. <br>
               Here is used to display and contrast the distribution of expression values on different arrays (samples).<BR>")
  })      
  
  output$densityPlot <- renderPlot({
    # Generate density plot
    plotDensities(input_data_nna, main="Densities of the Abundance Values for each Sample", legend = "topright")
  })
  
  
  ## Hierachical Clustering for the Silhouette Coefficients
  output$hClusteringHeader <- renderUI({
    HTML("<font color=blue size=5>Hierachical Clustering for the Silhouette Coefficients:</font><br><br>
                The Silhouette coefficient (SC) is calculated for each sample. 
                A sample with SC < 0.25 (default value; SC_max can be altered above) is a potential outlier because it clustered poorly with the other samples; 
                a sample with SC >= 0.25 is not a potential outlier (<a href=\"https://www.mdpi.com/2227-7390/9/8/882\" target=_blank>Selicato et al 2021</a>)."
    )
  })  
  
  # Dispaly Hierarchical Clustering 
  output$hClustering <- renderPlot({  
    # Display the dendrogram
    plot(hc.res_a)
  }) 
  
  outputOptions(output, "hClustering", suspendWhenHidden = FALSE)
  
  ## Robust Sparse PCA
  output$robpca <- renderUI({
    tags$iframe(style="height:600px; width:100%", src="./EnsMODoutputs/Robust_Sparse_PCA.pdf")
  })
  
  ## PcaGrid
  output$PcaGrid <- renderPlot({
    # Perform a Robust PCA (PcaGrid)
    pc <- PcaGrid(input_data_nna_t, crit.pca.distances = PcaGrid_prob)
    
    # Outliers identified by PcaGrid
    pc_flag <- as.data.frame(pc$flag)
    pc_flag$sample <- row.names(pc_flag)
    colnames(pc_flag) <- c('regular', 'sample')
    pc_flag$regular <- as.numeric(pc_flag$regular)
    
    # Display the outlier sample names
    pcOutliers <<- pc_flag[pc_flag$regular == 0,]$sample
    
    # Diagnositc plot (DD-plot or outlier map)
    diagPlot(pc, title = "Robust PCA (PcaGrid)", pch = 17, col="red", labelOut = TRUE, id = 5)
  })

  ## Outliers
  output$hcOutliers <- renderUI({
    HTML("<font color=blue size=4>Potential Outliers Identified by Different Methods:</font><br><br>
         <b>By Hierarchical Clustering:</b><br>")
  })
  output$hcoutliers <- renderUI({
    hcoutliers <- read.csv("./www/EnsMODoutputs/Outliers_identified_by_HierarchicalClustering.csv")
    p(toString(hcoutliers$x))
  })
  
  output$robustOutliers <- renderUI({
    HTML("<b><br><br><b>By both Robust PCA Methods:</b>")
  })
  output$robustoutliers <- renderUI({
    robustoutliers <- read.csv("./www/EnsMODoutputs/Outliers_identified_by_both_RobustPCAs.csv")
    p(toString(robustoutliers$x))
  })
  
  output$ensembleOutliers <- renderUI({
    HTML("<br><br><b>By Ensemble Methods:</b><br>")
  })
  output$ensembleoutliers <- renderUI({
    ensembleoutliers <- read.csv("./www/EnsMODoutputs/Outliers_identified_by_EnsembleMethods.csv")
    p(toString(ensembleoutliers$x))
  })
  
  
  ## reactive statement for output files to be printed on download tab
  downloadOut <- reactive({
    outputFiles = list.files(path = './EnsMODoutputs/')
    
    out <- c("<br><b>All files from your EnsMOD analysis for download:</font></b><br>")
    
    
    #Main output files
    if(length(outputFiles) > 0){
      for(i in outputFiles){
        out <- paste(out, paste0("<i>", i, "</i>"), sep = "<br>")
      }
    }
    
    out <- paste0(out, "<br><br>")
    return(out)
  })
  
  ## Create the 'Download' tab
  output$downloadFiles <- renderUI({
    updateTabsetPanel(session, "inTabset", selected = "downloads")
    
    outputFiles <- list.files(path = './EnsMODoutputs')
    HTML(downloadOut())
  })
  
  ## Download all output data
  output$downloadButton <- downloadHandler(
    filename = function(){
      paste("EnsMOD_analysis_output", "zip", sep=".")
    },
    content = function(filename){
      
      outputFiles <- list.files(path = './')
      zip(zipfile=filename, files = outputFiles)
    },
    contentType = "application/zip"
  )
  
  # print(paste0("EnsMOD Analysis Time: ", Sys.time() - startA))
  # message("Download content completed")
  
  
  # Contact us by sending email to signal-team@nih.gov
  # Send email using mailR package
  # in order for this to work, set the java path for R on commandline in a terminal
  # $sudo ln -f -s $(/usr/libexec/java_home)/jre/lib/server/libjvm.dylib /usr/local/lib
  output$contactUS <- renderUI({
    
    tagList(
      textInput("userName", "Your Name:", placeholder = "your name"),
      textInput("from", "Your Email Address:", placeholder = "your email address"),
      textInput("subject", "Subject:", placeholder = "Subject"),
      textAreaInput(inputId = "message", label= "Your Email Content:", width = "600px", height = "200px", resize = "vertical", placeholder = "Enter your message here"),
      checkboxInput("contact_not_a_robot", "I'm not a robot*", value = FALSE),
      actionButton("send", " Send email", icon("send-o"), style="padding:4px; font-size:120%; color: #fff; background-color: rgb(1, 81, 154); border-color: #2e6da4")
    )
  })
  
  # Send
  observeEvent(input$send,{
    
    # Send email if the 'Send email!' button is clicked and the 'I am not a robot' checked
    if( is.null(input$send) || input$send==0 || !input$contact_not_a_robot){
      return(NULL)
    }
    
    isolate({
      # Send the email to SIGNAL team
      send.mail(from = input$from,
                to <- c("ensmod-team@nih.gov"),
                subject = input$subject,
                body = paste(paste0("This email is from: ", input$userName, " [", input$from, "]"), input$message, sep="<br/>"),
                smtp = list(host.name = "smtp.gmail.com", port = 465, user.name = "ensmod.lisb@gmail.com", passwd = "LISB@NIH", ssl = TRUE),
                authenticate = TRUE,
                html = TRUE,
                send = TRUE)
      
      # Send email to the user
      send.mail(from = input$from,
                to = input$from,
                subject = input$subject,
                body = paste("Your email was sent!", input$message, sep="<br/>"),
                smtp = list(host.name = "smtp.gmail.com", port = 465, user.name = "ensmod.lisb@gmail.com", passwd = "LISB@NIH", ssl = TRUE),
                authenticate = TRUE,
                html = TRUE,
                send = TRUE)
    })
    
    # Replace the contact me form page with a message after sending the email
    output$contactUS <- renderText({
      "Your email was sent!"
    })
  })
  
  ## User documentation
  output$userguide <- renderUI({
    # tags$iframe(
    #   seamless="seamless",
    #   src="./www/EnsMOD_userguide_V2.pdf",
    #   style="height:700px;width:80010%"
    # )
    HTML("<br><br><h2>To be added...")
  })
  
  # Set this to "force" instead of TRUE for testing locally (without Shiny Server)
  session$allowReconnect(TRUE)
}


#####################
# Run the application
shinyApp(ui = ui, server = server)

