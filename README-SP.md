# F1 Generations Analysis

**Resumen ejecutivo**

Proyecto para evaluar el desempeño histórico de pilotos de Fórmula 1 por *generaciones* (1990s, 2000s, 2010s, 2020s) usando un flujo completo de analítica de datos: ingestión y normalización en **SQL Server**, análisis exploratorio y estadístico en **Python**, y visualización final en **Power BI**.  
El objetivo es construir un entregable reproducible que demuestre dominio técnico y criterio analítico. Pudiendo dar una noción sobre la respuesta a la problemática original y concluir de manera clara cual generación es la mas fuerte.

---

## Tabla de contenido

1. [Objetivos](#objetivos)
2. [Dataset & Fuentes](#dataset--fuentes)
3. [Modelo de datos (SQL)](#modelo-de-datos-sql)
4. [Resumen del pipeline SQL (ETL)](#resumen-del-pipeline-sql-etl)
5. [Análisis en Python (resumen de pasos)](#análisis-en-python-resumen-de-pasos)
6. [Power BI — Visualización y storytelling](#power-bi--visualización-y-storytelling)
7. [Estructura de archivos sugerida](#estructura-de-archivos-sugerida)
8. [Cómo reproducir / prerequisitos](#cómo-reproducir--prerequisitos)
9. [Resultados clave (resumen)](#resultados-clave-resumen)
10. [Lecciones Aprendidas](#lecciones-aprendidas)
11. [Contacto y licencia](#contacto-y-licencia)

---

## Objetivos

* Construir un flujo de trabajo completo (SQL → Python → Power BI) que sirva como caso demostrativo de ingeniería y análisis de datos.
* Comparar generaciones de pilotos para identificar cuál fue la **más fuerte**, justificando el resultado con métricas estadísticas y gráficas.
* Documentar cada decisión técnica y analítica para garantizar reproducibilidad.

---

## Dataset & Fuentes

* **Origen**: CSV con registros por piloto (columnas: `Driver`, `Nationality`, `Seasons`, `Championship_Years`, `Championships`, `Race_Wins`, `Fastest_Laps`, `Win_Rate`, etc.). disponible en kaggle: https://www.kaggle.com/datasets/petalme/f1-drivers-dataset/data
* **Estado inicial**: Las columnas `Seasons` y `Championship_Years` venían como listas en formato texto todo agrupado. Se normalizaron a nivel de fila en la etapa de SQL para una mejor manipulacion de los datos en base a los requisitos del proyecto.
* El archivo original se conserva en `/data` para trazabilidad y replicación del análisis.

---

## Modelo de datos (SQL)

Tablas creadas:

* `F1Drivers_Dataset` — tabla *staging* (copia cruda del CSV).
* `Drivers` — tabla limpia, con tipos corregidos.
* `Driver_Seasons` — una fila por piloto-temporada.
* `Driver_Championships` — una fila por piloto-campeonato.

**Razonamiento**: la separación entre tablas *staging* y *clean* facilita depuración, versionado y conexión directa desde Python o Power BI.

---

## Resumen del pipeline SQL (ETL)

1. **Ingesta:** importación del CSV a `F1Drivers_Dataset`.
2. **Validaciones iniciales:** detección de nulos, duplicados, consistencia de métricas (`Race_Wins <= Race_Starts`).
3. **Creación de `DriverID`** y llaves primarias.
4. **Normalización** de `Seasons` y `Championship_Years` usando `STRING_SPLIT` o `OPENJSON`.
5. **Vistas** de análisis `vw_F1_Generation_Performance` para consumo en Python y Power BI.

Scripts disponibles en `/sql`.

---

## Análisis en Python (resumen de pasos)

Notebook: `/python/F1 Analysis.ipynb`

### Extracción y preparación
* Conexión a SQL Server mediante  `pyodbc`.
* Limpieza adicional (tipos, normalización residual, filtrado de generaciones incompletas).

### Cálculo de métricas generacionales
Para cada generación:
* `mean_winrate`, `std_winrate`, `count_pilots`
* **IFG (Índice de Fortaleza Generacional):**
  ```python
  metricas_df["IFG"] = metricas_df["mean_winrate"] * np.log1p(metricas_df["count_pilots"])

* **Coeficiente de variación (CV):**
  ```python
  metricas_df["CV"] = np.where(
    metricas_df["mean_winrate"] != 0,
    metricas_df["std_winrate"] / metricas_df["mean_winrate"],
    np.nan
   )

---

## Visualización argumental para conclusión de análisis 

* Gráfico combinado: barras de `count_pilots` + línea de `IFG`.   
* Librerías utilizadas: `pandas`, `numpy`, `matplotlib`, `seaborn`.

---

## Power BI — Visualización y storytelling

**Objetivo:** replicar y ampliar la interpretación del análisis Python mediante dashboards interactivo que permita la flexibilidad de la curiosidad.

### Métricas definidas en DAX
```DAX
Mean Win Rate = AVERAGE('Pilotos_Filtrados'[Win_Rate])
Count Pilots = DISTINCTCOUNT('Pilotos'[Driver])

IFG = 
VAR currentGen =
    SELECTEDVALUE('Pilotos_Filtrados'[Generation])
VAR meanRate =
    CALCULATE(
        [Mean Win Rate],
        'Pilotos_Filtrados'[Generation] = currentGen
    )
VAR nPilots =
    CALCULATE(
        [Count Pilots],
        'Pilotos_Filtrados'[Generation] = currentGen
    )
RETURN
meanRate * LOG(1 + nPilots)

Color_Piloto_Generacion = 
VAR pilotWR =
    AVERAGE('Pilotos_Filtrados'[Win_Rate])
VAR avgGen =
    CALCULATE(
        AVERAGE('Pilotos_Filtrados'[Win_Rate]),
        ALLEXCEPT('Pilotos_Filtrados', 'Pilotos_Filtrados'[Generation])
    )
VAR stdGen =
    CALCULATE(
        STDEV.P('Pilotos_Filtrados'[Win_Rate]),
        ALLEXCEPT('Pilotos_Filtrados', 'Pilotos_Filtrados'[Generation])
    )
RETURN
IF(
    avgGen = 0 || ISBLANK(avgGen) || stdGen = 0,
    "#808080",  -- gris: sin datos o sin victorias (como generación 2020)
    SWITCH(
        TRUE(),
        pilotWR >= avgGen + stdGen, "#2ECC71",   -- verde: excepcional
        pilotWR < avgGen, "#E74C3C",             -- rojo: bajo el promedio
        "#F1C40F"                                -- amarillo: promedio
    )
)
```
   
- **Gráfico principal:** `Line and stacked column chart` 
- **Eje X:** `'Pilotos_Filtrados'[Generation]`
- **Eje Y:** `'Pilotos_Filtrados'[Driver]`
- **Línea eje  Y:** `'Pilotos_Filtrados'[Driver]`  
- **Tabla de medidas:** `_metrics` (tabla desconectada para controlar el contexto del cálculo).  
- **Resultado visual:** comportamiento del **IFG** alineado al de Python, con ligeras diferencias numéricas atribuibles a redondeo o a la implementación interna de la función `LOG()` en DAX.

---

## Características del dashboard

- **Gráfico principal:** combinación de columnas (conteo de pilotos) y línea (IFG).   
- **Tabla de detalle:** incluye `Driver`, `Win_Rate`, `Generation` con formato condicional para resaltar pilotos destacados.  
- **Regla de color:** verde para pilotos cuyo rendimiento sea claramente superior al promedio de su generación, rojo para los que quedan por debajo; los casos con IFG = 0 (sin victorias) se omiten del resaltado para no dar falso positivo.  

**Archivo final:** `/powerbi/F1Visuals.pbix`

---

## Estructura de archivos 

```bash
F1 Project/
├─ image.png
├─ image-1.png
├─ image-2.png
├─ image-3.png
├─ image-4.png
├─ image-5.png
├─ README-EN.md
├─ README-SP.md
├─ data/
│ └─ F1Drivers_Dataset.csv
├─ sql/
│ └─ normalizationEN.sql
│ └─ normalizationSP.sql  
│ └─ ViewCreationEN.sql
│ └─ ViewCreationSP.sql  
├─ python/
│ └─ F1 AnalysisEN.ipynb
│ └─ F1 AnalysisSP.ipynb  
├─ powerbi/
│ └─ F1Visuals.pbix
```




---

## Cómo reproducir / prerequisitos

### 1. Requisitos del entorno

- **SQL Server** (2019 o superior) con soporte para `STRING_SPLIT()` y `OPENJSON()`.  
- **Python 3.9+** con las siguientes librerías:  
  ```bash
  pandas
  numpy
  matplotlib
  sqlalchemy
  pyodbc
  seaborn
- **Power BI Desktop** (versión actual o superior a junio 2024).

---

## 2. Carga y normalización de datos en SQL Server

 **Crear la base de datos** y ejecutar los scripts en `/sql/` en este orden:
   - `normalization.sql` → crea las tablas base normalizadas.
   - `views.sql` → define las vistas intermedias y de análisis.
---

## 3. Análisis en Python

Abrir el archivo `/python/F1 Analysis.ipynb` y ejecutar cada celda en orden.

### Conexión a SQL Server
```python
import pyodbc

conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost;'
    'DATABASE=F1 Drivers;'
    'Trusted_Connection=yes;'
)

query = "SELECT * FROM dbo.vw_F1_Generation_Performance;"
df = pd.read_sql(query, conn)
```


## Cálculo de métricas

### Índice de Fortaleza Generacional (IFG)

El **Índice de Fortaleza Generacional (IFG)** se define como una medida compuesta que busca capturar tanto el rendimiento medio de los pilotos de una generación como la profundidad del grupo (Evaluar el colectivo dividido pro generación).  
En Python se calculó con la siguiente fórmula:

```python
metricas_df["IFG"] = metricas_df["mean_winrate"] * np.log1p(metricas_df["count_pilots"])
```

En Power BI, la implementación equivalente en DAX es:

```DAX
IFG = 
VAR meanRate = CALCULATE([Mean Win Rate], ALLEXCEPT('Pilotos', 'Pilotos'[Generation]))
VAR nPilots  = CALCULATE([Count Pilots], ALLEXCEPT('Pilotos', 'Pilotos'[Generation]))
RETURN
meanRate * LOG(1 + nPilots)
```
> 💡 **Nota:** aunque los valores no son idénticos entre Python y Power BI, el comportamiento general del IFG se mantiene coherente.  
> Las ligeras diferencias se atribuyen a redondeos internos y a la implementación específica de `LOG()` en DAX frente a `np.log1p()` en Python.

---

### Coeficiente de variación (CV)

El **Coeficiente de Variación (CV)** se utiliza para evaluar la **consistencia** dentro de cada generación,  
indicando el nivel de dispersión relativa del rendimiento de los pilotos.  
Se define como la relación entre la desviación estándar y la media del `Win_Rate`:

```python
metricas_df["CV"] = np.where(
    metricas_df["mean_winrate"] != 0,
    metricas_df["std_winrate"] / metricas_df["mean_winrate"],
    np.nan
)

- **CV alto →** mayor variabilidad entre pilotos (menos consistencia).  
- **CV bajo →** rendimiento más uniforme dentro de la generación.
```
---

## Integración en Power BI

Cargar la data desde SQL server y cargar la vista  **vw_F1_Generation_Performance.**

 - Creacion de la tabla **Pilotos:**
```DAX
Pilotos = 
SUMMARIZE(
    'vw_F1_Generation_Performance',
    'vw_F1_Generation_Performance'[Driver],
    "Debut_Year", MIN('vw_F1_Generation_Performance'[Season]),
    "Win_Rate", MAX('vw_F1_Generation_Performance'[Win_Rate])
)
```
 - Creacion de la tabla **Pilotos_Filtrados:** 
```DAX
Pilotos_Filtrados = 
FILTER(
    'Pilotos',
    NOT ISBLANK('Pilotos'[Generation])
)
```
 ### Uso de grafico principal (Line and stacked columna chart) y visual de tabla
- **Eje X:** `'Pilotos_Filtrados'[Generation]`  
- **Tabla de medidas:** `_metrics` (tabla desconectada para controlar el contexto del cálculo).  
- **Resultado visual:** el comportamiento del IFG se alinea con el de Python,  
  presentando pequeñas diferencias atribuibles a redondeo o a la función logarítmica en DAX.

### configuracion de **Line and stacked columna chart**
![alt text](image.png)
  
### configuracion de **Line and stacked columna chart**
![alt text](image-2.png)

### Para la clasificación de los pilotos por colores, aplicar su respectiva métrica al color de fondo de la columna Driver:
![alt text](image-3.png)

![alt text](image-4.png)

### Para un correcto funcionamiento de los filtros, es necesario crear una relación bidireccional entre `vw_F1_Generation_Performance` y `Pilotos_Filtrados` de uno a muchos mediante la columna `Driver`

![alt text](image-5.png)

---

### Características del Dashboard

- **Gráfico principal:** combinación de columnas (conteo de pilotos) y línea (IFG).   
- **Tabla de detalle:** incluye `Driver`, `Win_Rate`, `Generation` con formato condicional para resaltar pilotos destacados.  
- **Regla de color:**  
  - 🟩 Verde → IFG superior al promedio de su generación.  
  - 🟥 Rojo → IFG inferior al promedio.  
  - Sin color → IFG igual a 0.  

**Archivo final:** `/powerbi/F1Visuals.pbix`

---

## Estructura de los visual


![alt text](image-1.png)

> 💡 **Nota:** Fuera de las tablas principales, las demás son agregados interactivos para profundizar mas en caso de que se guste, que estan incluidos en el archivo `F1Visuals.pbix`.

---

## Resultados clave (resumen)

| Generación | Mean Win Rate | Count Pilots | IFG    | CV   |
|-------------|----------------|--------------:|--------:|------:|
| 1990        | 0.0129         | 66            | 0.0379 | 3.52 |
| 2000        | 0.0202         | 49            | 0.0595 | 2.82 |
| 2010        | 0.0101         | 41            | 0.0297 | 3.52 |
| 2020        | 0.0000         | 10            | 0.0000 | —    |

---

## Conclusiones

- **Generación 2000:** presenta el **mayor IFG**, reflejando un equilibrio entre número y calidad de pilotos.  
- **Generación 1990:** destaca por volumen de pilotos, aunque con menor efectividad promedio.  
- **Generación 2010:** muestra gran dispersión en el rendimiento, sin figuras dominantes claras.  
- **Generación 2020:** aún no ofrece suficientes datos para un análisis representativo.

---

### Ranking de Fortaleza Generacional

| 🏁 Ranking | Generación | Interpretación |
|------------|-------------|----------------|
| 🥇 **1** | **2000** | Mayor fortaleza generacional — balance ideal entre cantidad y rendimiento |
| 🥈 **2** | **1990** | Amplia participación, menor consistencia |
| ⚠️ **3** | **2010** | Desempeño irregular y variable |
| 🚧 **4** | **2020** | Generación en desarrollo, datos limitados |

---

### Análisis General

El **Índice de Fortaleza Generacional (IFG)** demuestra ser una métrica estable y representativa para comparar el desempeño agregado de pilotos entre décadas.  
Aunque pequeñas diferencias numéricas surgen entre Python y Power BI —debido a variaciones en el manejo del logaritmo y el redondeo interno—, **la tendencia general se conserva**, validando la consistencia del pipeline completo.

Se concluye que:

- Las **décadas 1990–2000** representan el punto más competitivo de la Fórmula 1 moderna.  
- El **descenso observado desde 2010** podría explicarse por el dominio de pocos pilotos y la reducción del número total de competidores sobresalientes.  
- La **generación 2020**, aún en desarrollo, requiere más temporadas para una evaluación robusta.

> En conjunto, el flujo **SQL → Python → Power BI** permitió cuantificar y visualizar objetivamente la evolución de la competitividad por generación, mostrando un ejemplo reproducible de integración analítica de datos históricos en entornos empresariales o de investigación.

---


## Lecciones Aprendidas

Este proyecto permitió demostrar una **cadena analítica completa** combinando:
- **SQL Server** para estructurar y normalizar los datos.
- **Python (Pandas, NumPy, SciPy)** para la exploración estadística y generación de indicadores avanzados como el IFG y el coeficiente de variación.
- **Power BI** para la creación de un **storytelling visual** que comunique las conclusiones con claridad.

El proceso evidenció cómo **las diferencias entre motores de cálculo (NumPy vs DAX)** pueden alterar ligeramente los valores absolutos, pero sin comprometer la validez analítica ni la interpretación de tendencias.

---


## Conclusión General

El análisis combinado de **profundidad (número de pilotos competitivos)** y **calidad (Win Rate medio)** permitió construir un índice sintético, el **IFG (Índice de Fortaleza Generacional)**, que resume la competitividad global de cada década.  
A través del pipeline SQL → Python → Power BI, se logró un proceso **reproducible, documentado y escalable**, ideal para portafolios de análisis de datos o proyectos académicos.

> En síntesis, **la generación 2000** se consolida como la más fuerte según el IFG, seguida por la **1990**, mientras que las generaciones más recientes muestran un descenso atribuible a la concentración de victorias en pocos pilotos.

---

## Contacto

**Autor:** Arturo Carreras  

 
> [ LinkedIn: www.linkedin.com/in/arturo-carreras-18549a1b4 / GitHub / Correo: arturoc211995@gmail.com ]

---

*Este README resume el proceso técnico y analítico completo del proyecto de análisis generacional de Fórmula 1, integrando SQL, Python y Power BI bajo un enfoque profesional y reproducible.*
