library(shiny)
library(readxl)
library(dplyr)

# Normalize genotype notation for matching while retaining a readable display value.
# Star-allele order is treated as equivalent (for example, *1/*2 and *2/*1).
clean_genotype <- function(value) {
  value <- trimws(gsub("[[:space:]]+", " ", as.character(value)))
  value <- gsub("×", "x", value, fixed = TRUE)
  value <- gsub("[[:space:]]*/[[:space:]]*", "/", value)
  value <- sub("xNc$", "xN", value, ignore.case = TRUE)
  value
}

normalize_genotype <- function(value) {
  cleaned <- clean_genotype(value)
  parts <- strsplit(cleaned, "/", fixed = TRUE)[[1]]

  if (length(parts) == 2 && all(startsWith(parts, "*"))) {
    parts <- toupper(parts)
    parts <- gsub("XN", "xN", parts, fixed = TRUE)
    parts <- gsub("X(?=[0-9])", "x", parts, perl = TRUE)
    return(paste(sort(parts, method = "radix"), collapse = "/"))
  }

  toupper(cleaned)
}

make_gene_diplotype_key <- function(gene, genotype) {
  paste(toupper(trimws(gene)), normalize_genotype(genotype), sep = "|")
}

# The normalized worksheet stores one drug-gene-diplotype combination per row.
# The relative path allows the application to run when this script and database
# are placed in the same directory.
data_file <- file.path("GeneXmedica_database.xlsx")
if (!file.exists(data_file)) {
  stop(paste("Required data file was not found:", data_file))
}

data <- read_excel(data_file, sheet = "Normalized_Data") %>%
  mutate(
    Drug = trimws(as.character(Drug)),
    `Gene(s)` = toupper(trimws(as.character(`Gene(s)`))),
    Genotype = vapply(Genotype, clean_genotype, character(1)),
    Genotype_Key = vapply(Genotype, normalize_genotype, character(1)),
    Gene_Diplotype_Key = paste(`Gene(s)`, Genotype_Key, sep = "|")
  )

required_columns <- c(
  "Drug", "Classification", "Gene(s)", "Genotype", "Genotype_Key",
  "Gene_Diplotype_Key", "Phenotype", "Recommendation", "Reference"
)
if (!all(required_columns %in% names(data))) {
  stop("The normalized dataset is missing one or more required columns.")
}

# Startup validation: equivalent notation must match, gene identity must remain
# specific, and each drug-gene-diplotype key must map to one recommendation.
stopifnot(
  identical(normalize_genotype("*1 / *2"), normalize_genotype("*1/*2")),
  identical(normalize_genotype("*1/*2"), normalize_genotype("*2/*1")),
  identical(normalize_genotype("*2×2/*10"), normalize_genotype("*2x2/*10")),
  make_gene_diplotype_key("CYP2B6", "*1/*1") !=
    make_gene_diplotype_key("CYP2C19", "*1/*1")
)

result_signature <- function(gene, genotype) {
  key <- make_gene_diplotype_key(gene, genotype)
  paste(sort(unique(data$Drug[data$Gene_Diplotype_Key == key])), collapse = "|")
}
stopifnot(
  identical(
    result_signature("CYP2C19", "*1/*2"),
    result_signature("CYP2C19", "*2/*1")
  )
)

conflicting_records <- data %>%
  mutate(mapping = paste(Phenotype, Recommendation, sep = "|")) %>%
  group_by(Drug, Gene_Diplotype_Key) %>%
  summarise(mapping_count = n_distinct(mapping), .groups = "drop") %>%
  filter(mapping_count > 1)
if (nrow(conflicting_records) > 0) {
  stop("Conflicting recommendations were found for a drug-gene-diplotype key.")
}
# Define UI
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background: linear-gradient(135deg, #cad8b5, #829a5f); 
        font-family: 'Arial', sans-serif;
        margin: 0;
        padding: 0;
        height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        overflow: hidden;
      }
      h1 {
        font-size: 80px;  /* Increased size */
        font-weight: bold;
        margin-bottom: 10px;
        opacity: 0;
        animation: fadeInTitle 2s forwards;
      }
      p {
        font-size: 24px;  /* Increased size */
        max-width: 600px;
        margin: 20px auto;
        line-height: 1.8;  /* Improved readability */
        color: #f2f2f2;
        opacity: 0;
        animation: fadeInText 3s forwards 0.5s;
      }
      .content {
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        text-align: center;
        padding: 20px;
      }
      .get-started-btn {
        padding: 15px 30px;  /* Increased padding */
        font-size: 22px;  /* Increased font size */
        background-color: #ffffff;
        color: #1E90FF;
        border: none;
        border-radius: 50px;
        cursor: pointer;
        box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.3);
        text-align: center;
        transition: background-color 0.3s ease, color 0.3s ease;
        opacity: 0;
        transform: translateY(20px);
        animation: slideUp 1.5s forwards 1.5s;
        margin-top: 40px;
      }
      .get-started-btn:hover {
        background-color: #1E90FF;
        color: white;
      }
      .back-btn {
        padding: 20px 40px;  /* Increased padding */
        font-size: 22px;  /* Increased size */
        background-color: #6e834f;
        color: white;
        border: none;
        border-radius: 10px;
        cursor: pointer;
        margin-top: 40px;
        margin-right: 10px;
      }
      .back-btn:hover {
        background-color: #829a5f;
      }
      .animated-bg {
        background-image: url('www/landing_background.webp'); 
        background-size: cover;
        background-position: center;
        height: 100%;
        width: 100%;
        position: absolute;
        top: 0;
        left: 0;
        z-index: -1;
        opacity: 0.4;
        animation: zoomIn 10s infinite alternate ease-in-out;
      }

      .breadcrumb {
        position: absolute;
        top: 20px;
        right: 20px;
        background-color: #fff;
        border-radius: 8px;
        padding: 10px 20px;
        box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.3);
        list-style: none;
        display: flex;
        gap: 10px;
        font-size: 18px;  /* Increased size */
      }
      .breadcrumb li {
        display: inline;
      }
      .breadcrumb li a {
        text-decoration: none;
        color: #1E90FF;
      }
      .breadcrumb li a:hover {
        text-decoration: underline;
      }
      .breadcrumb li+li:before {
        content: '>';
        margin: 0 8px;
        color: #888;
      }

      @keyframes fadeInTitle {
        0% { opacity: 0; transform: translateY(-20px); }
        100% { opacity: 1; transform: translateY(0); }
      }
      @keyframes fadeInText {
        0% { opacity: 0; transform: translateY(20px); }
        100% { opacity: 1; transform: translateY(0); }
      }
      @keyframes slideUp {
        0% { opacity: 0; transform: translateY(20px); }
        100% { opacity: 1; transform: translateY(0); }
      }
      @keyframes zoomIn {
        0% { transform: scale(1); }
        100% { transform: scale(1.05); }
      }

      /* Style for the input page form container */
      .input-page {
        font-size: 22px;  /* Increased font size */
        line-height: 1.8;  /* Improved readability */
        font-family: 'Arial', sans-serif;
        color: black;
        background-color: rgba(255, 255, 255, 0.9);  /* Semi-transparent background */
        padding: 50px;  /* Increased padding */
        border-radius: 20px;  /* Larger border-radius */
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.3);  /* Stronger shadow */
        max-width: 1400px;  /* Increased width for the container */
        margin: auto;
        height: auto;  /* Ensure the height is automatically adjusted */
        position: relative;
      }

      table {
        width: 100%;
        background-color: white;  /* Set table background to white */
        color: black;  /* Set text color to black */
        border-collapse: collapse;
        border-radius: 10px;  /* Rounded corners */
        overflow: hidden;
        box-shadow: 0 6px 12px rgba(0, 0, 0, 0.1);  /* Stronger shadow */
        margin-top: 20px;
      }
      table th, table td {
        padding: 18px 20px;  /* Increased padding */
        text-align: left;
        border-bottom: 1px solid #ddd;
      }
      table th {
        background-color: #f8f8f8;  /* Slightly lighter header background */
        font-weight: bold;
        font-size: 20px;  /* Increased font size */
      }
      table tr:nth-child(even) {
        background-color: #f9f9f9;  /* Light gray background for alternating rows */
      }
      table tr:hover {
        background-color: #f1f1f1;  /* Highlight row on hover */
      }
      table td {
        font-size: 18px;  /* Increased font size */
        border: none;  /* Remove cell borders */
      }
      /* Footer section */
      .footer {
        position: relative;
        bottom: 0;
        width: 100%;
        text-align: center;
        font-size: 18px;
        color: #f2f2f2;
        margin-top: 40px;
      }
      .footer a {
        color: #1E90FF;
        text-decoration: none;
      }
      .footer a:hover {
        text-decoration: underline;
      }
    "))
  ),
  
  # Dynamic content based on the current page
  uiOutput("page_content"),
  
  # Add the footer globally across all pages
  uiOutput("footer")
)

# Define server logic
server <- function(input, output, session) {

  page <- reactiveVal("welcome_page")
  selection <- reactiveValues(drug = NULL, gene = NULL, genotype = NULL, genotype_key = NULL)

  observeEvent(input$get_started, page("input_page"))
  observeEvent(input$go_home, page("welcome_page"))
  observeEvent(input$go_input, page("input_page"))
  observeEvent(input$back_to_input, page("input_page"))
  observeEvent(input$go_back, page("welcome_page"))

  output$page_content <- renderUI({
    if (page() == "welcome_page") {
      div(
        class = "content",
        div(class = "animated-bg"),
        h1("Welcome to GeneXmedica"),
        p("Explore personalized treatment recommendations based on the patient's genetic profile. Ready to begin?"),
        actionButton("get_started", "Get Started", class = "get-started-btn")
      )
    } else if (page() == "input_page") {
      fluidPage(
        div(
          class = "input-page",
          h2("Enter by medication name or gene and genotype"),
          fluidRow(
            column(
              3,
              selectInput(
                "input_type", "Choose Input Type:",
                choices = c("Medication Name", "Genotype")
              )
            ),
            column(3, uiOutput("primary_input")),
            column(3, uiOutput("secondary_input")),
            column(3, uiOutput("tertiary_input"))
          ),
          actionButton("submit", "Submit", class = "get-started-btn"),
          br(), br(),
          actionButton("go_back", "Back", class = "back-btn"),
          tags$ul(
            class = "breadcrumb",
            tags$li(actionLink("go_home", "Home")),
            tags$li(actionLink("go_input", "Input")),
            tags$li("Results")
          )
        )
      )
    } else {
      fluidPage(
        div(
          class = "input-page",
          h2("Results"),
          uiOutput("selection_summary"),
          uiOutput("result_table"),
          br(), br(),
          actionButton("back_to_input", "Back to Input", class = "back-btn"),
          tags$ul(
            class = "breadcrumb",
            tags$li(actionLink("go_home", "Home")),
            tags$li(actionLink("go_input", "Input")),
            tags$li("Results")
          )
        )
      )
    }
  })

  # Medication-first search: medication -> gene -> genotype.
  # Genotype-first search: gene -> genotype -> medication.
  output$primary_input <- renderUI({
    req(input$input_type)
    if (input$input_type == "Medication Name") {
      selectInput(
        "primary_selection", "Select Medication:",
        choices = sort(unique(data$Drug))
      )
    } else {
      selectInput(
        "primary_selection", "Select Gene:",
        choices = sort(unique(data$`Gene(s)`))
      )
    }
  })

  output$secondary_input <- renderUI({
    req(input$input_type, input$primary_selection)
    if (input$input_type == "Medication Name") {
      genes <- data %>%
        filter(Drug == input$primary_selection) %>%
        pull(`Gene(s)`) %>%
        unique() %>%
        sort()
      selectInput("secondary_selection", "Select Gene:", choices = genes)
    } else {
      genotype_choices <- data %>%
        filter(`Gene(s)` == input$primary_selection) %>%
        distinct(Genotype_Key, Genotype) %>%
        arrange(Genotype)
      selectInput(
        "secondary_selection", "Select Genotype:",
        choices = setNames(genotype_choices$Genotype_Key, genotype_choices$Genotype)
      )
    }
  })

  output$tertiary_input <- renderUI({
    req(input$input_type, input$primary_selection, input$secondary_selection)
    if (input$input_type == "Medication Name") {
      genotype_choices <- data %>%
        filter(
          Drug == input$primary_selection,
          `Gene(s)` == input$secondary_selection
        ) %>%
        distinct(Genotype_Key, Genotype) %>%
        arrange(Genotype)
      selectInput(
        "tertiary_selection", "Select Genotype:",
        choices = setNames(genotype_choices$Genotype_Key, genotype_choices$Genotype)
      )
    } else {
      drugs <- data %>%
        filter(
          `Gene(s)` == input$primary_selection,
          Genotype_Key == input$secondary_selection
        ) %>%
        pull(Drug) %>%
        unique() %>%
        sort()
      selectInput("tertiary_selection", "Select Medication:", choices = drugs)
    }
  })

  observeEvent(input$submit, {
    req(input$input_type, input$primary_selection, input$secondary_selection, input$tertiary_selection)

    if (input$input_type == "Medication Name") {
      selection$drug <- input$primary_selection
      selection$gene <- input$secondary_selection
      selection$genotype_key <- input$tertiary_selection
    } else {
      selection$gene <- input$primary_selection
      selection$genotype_key <- input$secondary_selection
      selection$drug <- input$tertiary_selection
    }

    genotype_label <- data %>%
      filter(
        Drug == selection$drug,
        `Gene(s)` == selection$gene,
        Genotype_Key == selection$genotype_key
      ) %>%
      pull(Genotype) %>%
      first()

    selection$genotype <- genotype_label
    page("results_page")
  })

  filtered_data <- reactive({
    req(selection$drug, selection$gene, selection$genotype_key)
    data %>%
      filter(
        Drug == selection$drug,
        `Gene(s)` == selection$gene,
        Genotype_Key == selection$genotype_key
      ) %>%
      distinct(
        Drug, Classification, `Gene(s)`, Genotype,
        Phenotype, Recommendation, Reference
      )
  })

  output$selection_summary <- renderUI({
    req(selection$drug, selection$gene, selection$genotype)
    div(
      style = paste(
        "background:#eef4e8; border-left:5px solid #6e834f;",
        "padding:14px 18px; margin:10px 0 18px 0; color:#222;",
        "border-radius:6px; font-size:18px;"
      ),
      tags$strong("Selected medication: "), selection$drug,
      tags$br(),
      tags$strong("Selected gene: "), selection$gene,
      tags$br(),
      tags$strong("Selected genotype: "), selection$genotype
    )
  })

  output$result_table <- renderUI({
    df <- filtered_data() %>%
      rename(Gene = `Gene(s)`)

    if (nrow(df) == 0) {
      return(div(style = "color:#b00020;", "No matching recommendation was found."))
    }

    reference_raw <- ifelse(is.na(df$Reference), "", as.character(df$Reference))
    has_reference_url <- grepl("https?://", reference_raw)
    reference_url <- ifelse(
      has_reference_url,
      sub("^.*[|][[:space:]]*(https?://[^[:space:]]+)[[:space:]]*$", "\\1", reference_raw),
      ""
    )
    reference_label <- ifelse(
      has_reference_url,
      sub("[[:space:]]*[|][[:space:]]*https?://[^[:space:]]+[[:space:]]*$", "", reference_raw),
      reference_raw
    )

    safe_df <- as.data.frame(lapply(df, function(column) {
      as.character(htmltools::htmlEscape(ifelse(is.na(column), "", column)))
    }), stringsAsFactors = FALSE)

    escaped_reference_label <- as.character(htmltools::htmlEscape(reference_label))
    escaped_reference_url <- as.character(
      htmltools::htmlEscape(reference_url, attribute = TRUE)
    )
    safe_df$Reference <- ifelse(
      has_reference_url,
      paste0(
        '<a href="', escaped_reference_url,
        '" target="_blank" rel="noopener noreferrer">',
        escaped_reference_label, "</a>"
      ),
      escaped_reference_label
    )

    recommendation <- safe_df$Recommendation
    recommendation <- ifelse(
      grepl("standard dosing|standard dose|recommended starting dose", recommendation, ignore.case = TRUE),
      paste0('<span style="color:green;">', recommendation, '</span>'),
      ifelse(
        grepl("avoid|not recommended|alternative", recommendation, ignore.case = TRUE),
        paste0('<span style="color:red;">', recommendation, '</span>'),
        ifelse(
          grepl("caution|monitor", recommendation, ignore.case = TRUE),
          paste0('<span style="color:#b36b00;">', recommendation, '</span>'),
          recommendation
        )
      )
    )
    safe_df$Recommendation <- recommendation

    headers <- c("Drug", "Classification", "Gene", "Genotype", "Phenotype", "Recommendation", "Reference")
    body <- paste(
      apply(safe_df[, headers, drop = FALSE], 1, function(row) {
        paste0("<tr>", paste0("<td>", row, "</td>", collapse = ""), "</tr>")
      }),
      collapse = ""
    )

    HTML(paste0(
      "<table class='table'><thead><tr>",
      paste0("<th>", headers, "</th>", collapse = ""),
      "</tr></thead><tbody>", body, "</tbody></table>"
    ))
  })

  output$footer <- renderUI({
    div(
      class = "footer",
      p("Connect Us: ", a("Help@GeneXmedica.com", href = "mailto:Help@GeneXmedica.com"))
    )
  })
}

shinyApp(ui = ui, server = server)
