## -----------------------------------------------------------------------------
##  Calculadora de riesgo - Proyecto PI21/00541 (IRYCIS)
##  Aplicacion Shiny generada por el apartado 1.18 del script maestro y
##  copiada al repositorio por preparar_publicacion.R. No editar a mano.
##  Uso:  shiny::runApp("<carpeta que contiene este fichero>")
##  Requiere: shiny y jsonlite. Lee modelo.json (mismo esquema que la pagina web).
## -----------------------------------------------------------------------------
library(shiny)

f_modelo <- "modelo.json"
if (!file.exists(f_modelo))
  stop("No se encuentra modelo.json. Ejecute shiny::runApp('<carpeta de app.R>').")
CALC <- jsonlite::read_json(f_modelo, simplifyVector = FALSE)
if (FALSE) library(jsonlite)   # dependencia visible para Shinylive
## Version publicada (solo en el repositorio publico): version, huella y enlaces
PUB <- if (file.exists("publicacion.json")) jsonlite::read_json("publicacion.json") else NULL
RANGO_P <- !is.null(CALC$rango_cohorte)   # rango de la cohorte = P1-P99

claves_sets <- vapply(CALC$sets, function(s) s$clave, "")
names(CALC$sets) <- claves_sets
claves_des  <- vapply(CALC$desenlaces, function(d) d$clave, "")
etq_des     <- stats::setNames(vapply(CALC$desenlaces, function(d) d$etiqueta, ""), claves_des)
HORIZ       <- c(30, 90, 365)

## Todas las variables de todos los modelos (una entrada por variable de la base)
VARS <- list()
for (s in CALC$sets) for (m in s$modelos) for (v in m$variables)
  if (is.null(VARS[[v$variable_base]])) VARS[[v$variable_base]] <- v
valor_inicial <- function(v) {
  if (identical(v$tipo, "bin")) return(0)
  x <- if (isTRUE(v$log)) exp(v$media) else v$media
  signif(x, 4)
}
limites <- function(v) if (isTRUE(v$log)) exp(c(v$minimo, v$maximo)) else c(v$minimo, v$maximo)
etiq_limpia <- function(e) sub("^ln\\(([^)]*)\\)", "\\1", sub(" \\(por [^)]*\\)", "", e))
## Etiquetas y unidades en ingles (las mismas que la pagina web); si una
## variable no esta en el diccionario se usa la etiqueta de modelo.json.
LAB_EN <- c(
  edad_hosp = "Age at admission", sexo = "Female sex", tas_ingreso = "Systolic BP at admission",
  urg_pre3m = "HF emergency visits, prior 3 months", nyha34 = "Prior NYHA class III/IV",
  iccharlson_edad = "Age-adjusted Charlson index", ieca_ara2_alta_any = "ACEi/ARB at discharge",
  furo_dia_alta = "Furosemide dose at discharge", ercmodg = "Moderate\u2013severe CKD",
  tfge_alta = "eGFR at discharge", na_alta = "Sodium at discharge", cl_alta = "Chloride at discharge",
  hb_alta = "Haemoglobin at discharge", album_ing = "Albumin at admission",
  vci20mm_vexus_alt = "IVC \u226520 mm / VExUS \u22651 at discharge", frailscore = "FRAIL score",
  bnp_ing = "BNP at admission", ca125_ing = "CA-125 at admission", sst2_alta = "sST2 pre-discharge",
  gdf15_alta = "GDF-15 pre-discharge", gal3_alta = "Galectin-3 pre-discharge")
UNIT_EN <- c(
  edad_hosp = "years", tas_ingreso = "mmHg", iccharlson_edad = "points", furo_dia_alta = "mg/day",
  tfge_alta = "mL/min/1.73m\u00b2", na_alta = "mmol/L", cl_alta = "mmol/L", hb_alta = "g/dL",
  album_ing = "g/dL", frailscore = "0\u20135", bnp_ing = "pg/mL", ca125_ing = "U/mL",
  sst2_alta = "ng/mL", gdf15_alta = "pg/mL", gal3_alta = "ng/mL")
etiq_en <- function(v) {
  b <- v$variable_base
  e <- if (!is.na(LAB_EN[b])) LAB_EN[[b]] else etiq_limpia(v$etiqueta)
  if (!is.na(UNIT_EN[b]) && !identical(v$tipo, "bin")) paste0(e, ", ", UNIT_EN[[b]]) else e
}

riesgo_w <- function(lam, sg, t) 1 - exp(-exp((log(t) - log(lam)) / sg))
rmst_w   <- function(lam, sg, tau) lam * gamma(1 + sg) * stats::pgamma((tau / lam)^(1 / sg), shape = sg)
lam_de   <- function(m, x) {
  lp <- m$mu
  for (v in m$variables) {
    xi <- x[[v$variable_base]]
    if (is.null(xi) || is.na(xi)) xi <- valor_inicial(v)
    lp <- lp + v$gamma_aft * (if (isTRUE(v$log)) log(max(xi, 1e-8)) else xi)
  }
  exp(lp)
}

## Pie de la version publicada: version, huella de modelo.json, DOI y enlaces
pie_pub <- function() {
  if (is.null(PUB)) return(NULL)
  enl <- function(u, t) tags$a(href = u, target = "_blank", rel = "noopener", t)
  tags$p(style = "font-size:12px;color:#6b7680;border-top:1px solid #dde3e8;padding-top:8px",
    sprintf("Version %s \u00b7 model generated %s \u00b7 project PI21/00541. ", PUB$version, CALC$fecha),
    "Model fingerprint (SHA-256 of modelo.json): ",
    tags$code(title = PUB$sha256_modelo, paste0(substr(PUB$sha256_modelo, 1, 16), "\u2026")),
    if (!is.null(PUB$doi)) tagList(" \u00b7 DOI ", enl(paste0("https://doi.org/", PUB$doi), PUB$doi)),
    if (!is.null(PUB$repositorio)) tagList(" \u00b7 ", enl(PUB$repositorio, "source code and test cases")),
    if (!is.null(PUB$url_web)) tagList(" \u00b7 ", enl(PUB$url_web, "web version")))
}

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body{font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif}
    .aviso{background:#fdf1ee;border-left:5px solid #b7472a;padding:10px 14px;margin:10px 0}
    .fuera{color:#b7472a;font-size:12px}"))),
  titlePanel(CALC$titulo),
  div(class = "aviso", tags$b("For research use only. "),
      "Not a CE-marked medical device (Regulation (EU) 2017/745). ",
      sub(" For research use only.", "", CALC$advertencia, fixed = TRUE)),
  sidebarLayout(
    sidebarPanel(width = 4,
      radioButtons("des", "1) Outcome", choices = stats::setNames(claves_des, etq_des),
                   selected = CALC$desenlace_por_defecto),
      radioButtons("set", "2) Model",
                   choices = stats::setNames(claves_sets,
                     vapply(CALC$sets, function(s) s$etiqueta, "")),
                   selected = CALC$set_por_defecto),
      uiOutput("desc_set"),
      tags$hr(), tags$b("3) Patient data"),
      uiOutput("entradas")),
    mainPanel(width = 8,
      tableOutput("tabla"), uiOutput("resumen"), uiOutput("coherencia"),
      plotOutput("curva", height = "320px"),
      tags$p(style = "font-size:12px;color:#6b7680", CALC$regla), pie_pub())))

server <- function(input, output, session) {
  modelo <- reactive(CALC$sets[[input$set]]$modelos[[input$des]])
  output$desc_set <- renderUI(tags$p(style = "font-size:12px;color:#6b7680",
                                     CALC$sets[[input$set]]$descripcion))
  ## Se muestran las variables del modelo elegido; los valores se conservan al
  ## cambiar de modelo porque los inputs no se destruyen (isolate).
  output$entradas <- renderUI({
    m <- modelo(); if (is.null(m)) return(tags$p("Model not available."))
    lapply(m$variables, function(v) {
      id <- paste0("x_", v$variable_base)
      ini <- isolate(if (!is.null(input[[id]])) input[[id]] else valor_inicial(v))
      if (identical(v$tipo, "bin"))
        selectInput(id, etiq_en(v), c(No = 0, Yes = 1), selected = ini)
      else {
        lim <- limites(v)
        tagList(numericInput(id, sprintf(if (RANGO_P) "%s (cohort P1-P99 %s-%s)" else "%s (cohort range %s-%s)", etiq_en(v),
                                         signif(lim[1], 3), signif(lim[2], 3)), ini),
                uiOutput(paste0("w_", v$variable_base)))
      }
    })
  })
  valores <- reactive({
    x <- lapply(names(VARS), function(b) {
      z <- input[[paste0("x_", b)]]; if (is.null(z)) NA_real_ else as.numeric(z) })
    stats::setNames(x, names(VARS))
  })
  output$tabla <- renderTable({
    m <- modelo(); req(m)
    lam <- lam_de(m, valores()); ref <- CALC$referencia[[input$des]]
    data.frame(Horizon = paste(HORIZ, "days"),
               `Predicted risk (%)` = sprintf("%.1f", 100 * riesgo_w(lam, m$sigma, HORIZ)),
               `Cohort incidence (%)` = vapply(as.character(HORIZ), function(h)
                 if (is.null(ref[[h]])) "-" else sprintf("%.1f", ref[[h]]), ""),
               check.names = FALSE)
  }, striped = TRUE)
  output$resumen <- renderUI({
    m <- modelo(); req(m); lam <- lam_de(m, valores())
    med <- lam * log(2)^m$sigma
    tags$p(sprintf("Expected event-free days within the first year (RMST): %.0f of 365. ", rmst_w(lam, m$sigma, 365)),
           if (med > m$seguimiento_maximo_d) "Median: beyond the observed follow-up."
           else sprintf("Median: %.0f days.", med))
  })
  output$coherencia <- renderUI({
    s <- CALC$sets[[input$set]]$modelos
    if (is.null(s$mortalidad) || is.null(s$combIC)) return(NULL)
    x <- valores()
    pm <- riesgo_w(lam_de(s$mortalidad, x), s$mortalidad$sigma, HORIZ)
    pc <- riesgo_w(lam_de(s$combIC, x), s$combIC$sigma, HORIZ)
    if (any(pm > pc + 1e-9))
      div(class = "aviso", tags$b("Internal inconsistency for this profile: "),
          "predicted mortality exceeds the composite risk at ",
          paste(HORIZ[pm > pc + 1e-9], collapse = ", "), " days. Do not use these figures.")
  })
  output$curva <- renderPlot({
    m <- modelo(); req(m); lam <- lam_de(m, valores()); t <- 1:365
    par(mar = c(4.2, 4.2, 1, 1), las = 1)
    plot(t, 100 * riesgo_w(lam, m$sigma, t), type = "l", lwd = 2.4, col = "#1f4e79",
         ylim = c(0, 100), xlab = "Days from discharge", ylab = "Probability of event (%)")
    ref <- CALC$referencia[[input$des]]
    points(HORIZ, vapply(as.character(HORIZ), function(h) ref[[h]] %||% NA_real_, 0),
           pch = 4, lwd = 2, col = "#b7472a")
    legend("topleft", bty = "n", lwd = c(2.4, NA), pch = c(NA, 4),
           col = c("#1f4e79", "#b7472a"), legend = c("This patient", "Cohort (Kaplan-Meier)"))
  })
}
`%||%` <- function(a, b) if (is.null(a)) b else a
shinyApp(ui, server)
