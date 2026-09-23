################################################################################
##
##  CASOS DE PRUEBA DE LA CALCULADORA  -  PI21/00541
##
##  Calcula, SOLO a partir de modelo.json y con las formulas publicadas, el
##  riesgo a 30, 90 y 365 dias (y el RMST a 365 dias) de tres perfiles de
##  paciente fijos en los tres modelos (Sets 1-3) y los dos desenlaces. Es una
##  implementacion independiente de las dos interfaces: si la pagina web o la
##  aplicacion Shiny devuelven otras cifras para estos perfiles, hay un error.
##
##  Requiere R (>= 4.0) y el paquete jsonlite.
##
##  Uso desde la raiz del repositorio:
##    Rscript verificacion/casos_prueba.R              # imprime la tabla
##    Rscript verificacion/casos_prueba.R --comprobar  # compara con casos_prueba.csv
##
################################################################################

## --- Perfiles (escala natural, las unidades son las de la calculadora) --------
##  Valores redondos, clinicamente plausibles y dentro del rango P1-P99 de la
##  cohorte, elegidos para que P(muerte) < P(combinado) en los tres horizontes
##  (sin aviso de incoherencia). Las binarias: 1 = si, 0 = no.
PERFILES <- list(
  A = list(descripcion = "Riesgo bajo",
           tas_ingreso = 150, iccharlson_edad = 6, frailscore = 1,
           album_ing = 3.6, sst2_alta = 15,
           urg_pre3m = 0, vci20mm_vexus_alt = 0, ieca_ara2_alta_any = 0, ercmodg = 0),
  B = list(descripcion = "Riesgo intermedio",
           tas_ingreso = 130, iccharlson_edad = 8, frailscore = 3,
           album_ing = 3.1, sst2_alta = 30,
           urg_pre3m = 1, vci20mm_vexus_alt = 0, ieca_ara2_alta_any = 0, ercmodg = 0),
  C = list(descripcion = "Riesgo alto",
           tas_ingreso = 115, iccharlson_edad = 10, frailscore = 4,
           album_ing = 3.0, sst2_alta = 50,
           urg_pre3m = 1, vci20mm_vexus_alt = 0, ieca_ara2_alta_any = 0, ercmodg = 0)
)
HORIZONTES <- c(30, 90, 365)

## --- Modelo Weibull AFT (formulas de modelo.json) ------------------------------
##  S(t|x) = exp(-exp((log t - mu - sum(gamma_j x_j)) / sigma)), con x_j en la
##  escala del modelo (logaritmo natural cuando la variable tiene log = TRUE).
predictor_lineal <- function(m, perfil) {
  lp <- m$mu
  for (v in m$variables) {
    x <- perfil[[v$variable_base]]
    if (is.null(x)) stop("El perfil no define ", v$variable_base, call. = FALSE)
    lp <- lp + v$gamma_aft * (if (isTRUE(v$log)) log(x) else x)
  }
  lp
}
riesgo <- function(lp, sigma, t) 1 - exp(-exp((log(t) - lp) / sigma))
rmst   <- function(lp, sigma, tau) {
  lam <- exp(lp)
  lam * gamma(1 + sigma) * stats::pgamma((tau / lam)^(1 / sigma), shape = sigma)
}

calcular_casos <- function(CALC, perfiles = PERFILES) {
  filas <- list()
  for (p in names(perfiles)) for (s in CALC$sets) for (d in CALC$desenlaces) {
    m <- s$modelos[[d$clave]]
    if (is.null(m)) next
    lp <- predictor_lineal(m, perfiles[[p]])
    r  <- 100 * riesgo(lp, m$sigma, HORIZONTES)
    filas[[length(filas) + 1]] <- data.frame(
      perfil = p, set = s$clave, desenlace = d$clave,
      riesgo_30d = round(r[1], 1), riesgo_90d = round(r[2], 1),
      riesgo_365d = round(r[3], 1),
      rmst_365d = round(rmst(lp, m$sigma, 365)),
      stringsAsFactors = FALSE)
  }
  out <- do.call(rbind, filas); rownames(out) <- NULL
  out
}

## --- Ejecucion directa (Rscript) ------------------------------------------------
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  f_modelo <- if (file.exists("web/modelo.json")) "web/modelo.json" else "modelo.json"
  CALC <- jsonlite::read_json(f_modelo, simplifyVector = FALSE)
  tab <- calcular_casos(CALC)
  if ("--comprobar" %in% args) {
    f_csv <- if (file.exists("verificacion/casos_prueba.csv"))
      "verificacion/casos_prueba.csv" else "casos_prueba.csv"
    ref <- utils::read.csv(f_csv, stringsAsFactors = FALSE)
    ref <- ref[, names(tab)]
    clave <- function(z) paste(z$perfil, z$set, z$desenlace)
    ref <- ref[match(clave(tab), clave(ref)), ]
    num <- c("riesgo_30d", "riesgo_90d", "riesgo_365d", "rmst_365d")
    dif <- max(abs(as.matrix(tab[, num]) - as.matrix(ref[, num])))
    if (anyNA(dif) || dif > 0.05)
      stop("Los casos de prueba NO coinciden con ", f_csv,
           " (diferencia maxima ", dif, ").", call. = FALSE)
    cat("Casos de prueba: coinciden con", f_csv, "(", nrow(tab), "filas ).\n")
  } else {
    print(tab, row.names = FALSE)
  }
}
