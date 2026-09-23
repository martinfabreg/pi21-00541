<!-- Generado por preparar_publicacion.R a partir de plantillas_repo/README.md. No editar a mano. -->

# Calculadora de riesgo tras una hospitalización por insuficiencia cardíaca (IC-FEp, ≥ 80 años) · Proyecto PI21/00541

Versión **1.0.0** · 2026-09-23 · DOI: pendiente de la primera release en Zenodo

> **Uso exclusivo en investigación.** No es un producto sanitario con marcado CE (Reglamento (UE) 2017/745). Modelo desarrollado en una única cohorte (n = 175) sin validación externa: no debe emplearse para tomar decisiones sobre pacientes concretos.

## Acceso

| | Enlace |
|---|---|
| Calculadora web | https://martinfabreg.github.io/pi21-00541/ |
| Aplicación Shiny, ejecutada en el navegador (la primera carga tarda 10-30 s) | https://martinfabreg.github.io/pi21-00541/shiny/ |
| Código, parámetros del modelo y casos de prueba | https://github.com/martinfabreg/pi21-00541 |
| Versión archivada con identificador persistente | DOI: pendiente de la primera release en Zenodo |

Las dos interfaces leen **el mismo fichero de parámetros** (`modelo.json`) y no envían datos a ningún servidor: los valores introducidos se procesan exclusivamente en el navegador del usuario.

## Qué calcula

La probabilidad, a **30, 90 y 365 días desde el alta**, de:

- **mortalidad por cualquier causa**, y
- el **combinado de muerte o reingreso por insuficiencia cardíaca**,

en pacientes de 80 o más años dados de alta tras un ingreso por insuficiencia cardíaca con fracción de eyección preservada. Hay tres modelos anidados, según la información disponible:

| Modelo | Mortalidad | Muerte o reingreso por IC |
| --- | --- | --- |
| Set 1 · Clínico | HF emergency visits, prior 3 months; IVC ≥20 mm / VExUS ≥1 at discharge; Systolic BP at admission (mmHg); ACEi/ARB at discharge; Moderate–severe CKD | HF emergency visits, prior 3 months; Systolic BP at admission (mmHg); Age-adjusted Charlson index (points) |
| Set 2 · A pie de cama (+ FRAIL) | FRAIL score (0-5); HF emergency visits, prior 3 months; Systolic BP at admission (mmHg); Moderate–severe CKD; IVC ≥20 mm / VExUS ≥1 at discharge; Albumin at admission (g/dL) | FRAIL score (0-5); Systolic BP at admission (mmHg); HF emergency visits, prior 3 months; Age-adjusted Charlson index (points) |
| Set 3 · Completo (+ biomarcadores) | FRAIL score (0-5); HF emergency visits, prior 3 months; sST2 pre-discharge (ng/mL); Systolic BP at admission (mmHg); IVC ≥20 mm / VExUS ≥1 at discharge; Moderate–severe CKD | FRAIL score (0-5); Systolic BP at admission (mmHg); HF emergency visits, prior 3 months; Age-adjusted Charlson index (points); sST2 pre-discharge (ng/mL) |

n = 175; eventos: mortalidad 63; muerte o reingreso por IC 93.

Cada modelo es un modelo paramétrico de Weibull de tiempo de fallo acelerado, uno por desenlace y set, del que se leen los tres horizontes cambiando el tiempo:

S(t | x) = exp(−exp((log t − μ − Σ γ<sub>j</sub> x<sub>j</sub>) / σ)),  riesgo(t) = 1 − S(t | x)

con x<sub>j</sub> en la escala del modelo (logaritmo natural en las variables marcadas con `log = true`). Los parámetros se agruparon con las reglas de Rubin sobre 20 conjuntos de imputación múltiple. La aplicación Shiny muestra además el tiempo medio restringido libre de evento a 365 días (RMST). Como la mortalidad y el combinado se ajustan como modelos separados, en perfiles extremos el riesgo de muerte estimado puede superar al del combinado; ambas interfaces lo señalan.

## Cómo verificar la herramienta

1. **Huella del modelo.** El pie de ambas interfaces muestra el inicio de la huella SHA-256 de `modelo.json`. La huella completa de esta versión es

   `fc878f83697d812c139eafcb250ac5d52cf9b05bc2e0dc26dcc0ba71dcb409b8`

   y figura, junto con las de los demás ficheros, en [`verificacion/SHA256SUMS.txt`](verificacion/SHA256SUMS.txt). Para comprobarla, descargue https://martinfabreg.github.io/pi21-00541/modelo.json y ejecute `sha256sum modelo.json` (Linux/macOS) o `certutil -hashfile modelo.json SHA256` (Windows).

2. **Casos de prueba.** Introduzca los perfiles siguientes en cualquiera de las dos interfaces: las cifras deben coincidir con la tabla, salvo el redondeo a un decimal. En la calculadora web, los campos que el modelo elegido no usa aparecen en gris y no intervienen en el cálculo.

   **Perfiles** (nombres de los campos tal como aparecen en ambas interfaces)

   | Variable | A · riesgo bajo | B · riesgo intermedio | C · riesgo alto |
   | --- | --- | --- | --- |
   | Systolic BP at admission (mmHg) | 150 | 130 | 115 |
   | Age-adjusted Charlson index (points) | 6 | 8 | 10 |
   | FRAIL score (0-5) | 1 | 3 | 4 |
   | Albumin at admission (g/dL) | 3.6 | 3.1 | 3.0 |
   | sST2 pre-discharge (ng/mL) | 15 | 30 | 50 |
   | HF emergency visits, prior 3 months | No | Yes | Yes |
   | IVC ≥20 mm / VExUS ≥1 at discharge | No | No | No |
   | ACEi/ARB at discharge | No | No | No |
   | Moderate–severe CKD | No | No | No |

   **Resultados esperados** (riesgo en %; RMST en días, solo en la aplicación Shiny)

   | Perfil | Modelo | Desenlace | 30 d | 90 d | 365 d | RMST 365 d |
   | --- | --- | --- | --- | --- | --- | --- |
   | A | Set 1 | Mortalidad | 2.3 | 5.8 | 18.2 | 328 |
   | A | Set 1 | Muerte o reingreso por IC | 6.1 | 13.2 | 33.1 | 292 |
   | A | Set 2 | Mortalidad | 0.2 | 0.6 | 2.3 | 361 |
   | A | Set 2 | Muerte o reingreso por IC | 2.6 | 6.0 | 17.1 | 329 |
   | A | Set 3 | Mortalidad | 0.3 | 1.0 | 3.5 | 358 |
   | A | Set 3 | Muerte o reingreso por IC | 2.4 | 5.7 | 16.8 | 330 |
   | B | Set 1 | Mortalidad | 9.1 | 21.9 | 56.4 | 240 |
   | B | Set 1 | Muerte o reingreso por IC | 19.3 | 38.5 | 74.8 | 178 |
   | B | Set 2 | Mortalidad | 3.6 | 10.0 | 33.2 | 299 |
   | B | Set 2 | Muerte o reingreso por IC | 13.8 | 29.7 | 65.5 | 210 |
   | B | Set 3 | Mortalidad | 4.2 | 11.2 | 35.9 | 293 |
   | B | Set 3 | Muerte o reingreso por IC | 14.5 | 31.8 | 69.8 | 199 |
   | C | Set 1 | Mortalidad | 11.4 | 26.8 | 64.8 | 218 |
   | C | Set 1 | Muerte o reingreso por IC | 29.0 | 54.0 | 88.9 | 124 |
   | C | Set 2 | Mortalidad | 9.6 | 25.3 | 67.4 | 217 |
   | C | Set 2 | Muerte o reingreso por IC | 31.7 | 59.6 | 93.5 | 105 |
   | C | Set 3 | Mortalidad | 10.9 | 27.8 | 70.3 | 207 |
   | C | Set 3 | Muerte o reingreso por IC | 34.6 | 64.6 | 96.1 |  90 |

   Los mismos valores están en [`verificacion/casos_prueba.csv`](verificacion/casos_prueba.csv).

3. **Recálculo independiente.** [`verificacion/casos_prueba.R`](verificacion/casos_prueba.R) reproduce la tabla solo a partir de `modelo.json` y de la fórmula anterior, sin usar el código de las interfaces:

   ```
   Rscript verificacion/casos_prueba.R              # imprime la tabla
   Rscript verificacion/casos_prueba.R --comprobar  # la compara con casos_prueba.csv
   ```

   El flujo de publicación ([`.github/workflows/publicar.yml`](.github/workflows/publicar.yml)) repite en cada actualización la comprobación de las huellas y de los casos de prueba. Si alguna falla, el sitio no se actualiza.

4. **Aplicación Shiny en local.** Con R, `shiny` y `jsonlite` instalados: `shiny::runApp("app")`.

## Protección de datos

El repositorio **no contiene datos individuales**. `modelo.json` incluye solo parámetros de los modelos (μ, σ, γ), la media y la desviación típica de cada predictor, la incidencia observada (Kaplan-Meier) a 30, 90 y 365 días y, como rango de referencia de la cohorte, los **percentiles 1 y 99** de cada predictor continuo, en lugar de los valores extremos observados. Se trata de información agregada que no permite identificar a ningún participante. Las páginas no usan cookies ni herramientas de analítica.

## Contenido

```
web/                  Calculadora web estática (index.html, modelo.js, modelo.json, publicacion.js)
app/                  Aplicación Shiny (app.R, modelo.json, publicacion.json)
verificacion/         Casos de prueba (CSV y script en R) y huellas SHA-256
.github/workflows/    Construcción y publicación en GitHub Pages (incluye la exportación Shinylive)
CITATION.cff          Metadatos de cita
.zenodo.json          Metadatos para el archivo en Zenodo
LICENSE               Licencia del código (MIT)
```

Todo el contenido se genera desde el script de análisis del proyecto; ninguno de los ficheros de parámetros se edita a mano.

## Cómo citar

Véase [`CITATION.cff`](CITATION.cff) (GitHub ofrece la cita en APA y BibTeX en el botón «Cite this repository»). 

## Licencia

Código (HTML, JavaScript y R): licencia MIT ([`LICENSE`](LICENSE)). Parámetros del modelo (`modelo.json`, `modelo.js`) y documentación: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

## Financiación

Proyecto PI21/00541, financiado por el Instituto de Salud Carlos III (ISCIII) (Acción Estratégica en Salud 2021) y cofinanciado por la Unión Europea.

## Contacto

Martín Fabregate Fuente (IRYCIS)

---

*English summary.* Research-only risk calculator (not CE-marked) for all-cause mortality and for the composite of death or heart-failure readmission at 30, 90 and 365 days after discharge, in patients aged 80 or older hospitalised for heart failure with preserved ejection fraction (single cohort, n = 175, no external validation). Web and in-browser Shiny interfaces share one parameter file (`modelo.json`). Test cases and SHA-256 fingerprints for independent verification are in `verificacion/`.
