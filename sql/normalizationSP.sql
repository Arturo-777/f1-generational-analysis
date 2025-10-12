/* =============================================================
    PROYECTO: Análisis de Generaciones en F1
    PARTE: SQL Server - Preparación y Normalización de Datos
    FUENTE DE DATOS: Kaggle (F1 Drivers Dataset)
    TABLA ORIGINAL: dbo.F1Drivers_Dataset

    OBJETIVO:
    - Validar integridad de los datos.
    - Crear modelo relacional normalizado:
        * Tabla principal de pilotos (Drivers)
        * Tabla de temporadas (Driver_Seasons)
        * Tabla de campeonatos (Driver_Championships)
   ============================================================= */

/* =============================================================
   1. VALIDACIÓN INICIAL DE LA TABLA ORIGINAL
   ============================================================= */

-- Revisar estructura de la tabla importada
EXEC sp_help 'dbo.F1Drivers_Dataset';

-- Validar que no existan pilotos sin nombre (NULL en Driver)
SELECT *
FROM dbo.F1Drivers_Dataset
WHERE Driver IS NULL;

-- Validar que no existan pilotos duplicados
SELECT Driver, COUNT(*) AS DupCount
FROM dbo.F1Drivers_Dataset
GROUP BY Driver
HAVING COUNT(*) > 1;

/* 
   Resultado esperado:
   - Ningún registro con Driver = NULL
   - Ningún registro duplicado de Driver
*/

/* =============================================================
   2. CREACIÓN DEL MODELO NORMALIZADO
   ============================================================= */

-----------------------------------------------------------
-- 2.1 Tabla principal: Drivers
-- Contiene datos generales de cada piloto.
-----------------------------------------------------------
CREATE TABLE dbo.Drivers (
    DriverID INT IDENTITY(1,1) PRIMARY KEY,   -- Clave primaria única
    Driver NVARCHAR(255) NOT NULL,
    Nationality NVARCHAR(100),
    Championships FLOAT,
    Race_Entries FLOAT,
    Race_Starts FLOAT,
    Pole_Positions FLOAT,
    Race_Wins FLOAT,
    Podiums FLOAT,
    Fastest_Laps FLOAT,
    Points FLOAT,
    Active BIT,
    Decade SMALLINT,
    Pole_Rate FLOAT,
    Start_Rate FLOAT,
    Win_Rate FLOAT,
    Podium_Rate FLOAT,
    FastLap_Rate FLOAT,
    Points_Per_Entry FLOAT,
    Years_Active TINYINT,
    Champion BIT
);

-- Insertar datos base desde la tabla importada
INSERT INTO dbo.Drivers (
    Driver, Nationality, Championships, Race_Entries, Race_Starts, 
    Pole_Positions, Race_Wins, Podiums, Fastest_Laps, Points, Active, 
    Decade, Pole_Rate, Start_Rate, Win_Rate, Podium_Rate, FastLap_Rate, 
    Points_Per_Entry, Years_Active, Champion
)
SELECT 
    Driver, Nationality, Championships, Race_Entries, Race_Starts, 
    Pole_Positions, Race_Wins, Podiums, Fastest_Laps, Points, Active, 
    Decade, Pole_Rate, Start_Rate, Win_Rate, Podium_Rate, FastLap_Rate, 
    Points_Per_Entry, Years_Active, Champion
FROM dbo.F1Drivers_Dataset;


-----------------------------------------------------------
-- 2.2 Tabla de temporadas: Driver_Seasons
-- Normaliza la columna "Seasons" (lista de años en JSON).
-----------------------------------------------------------
CREATE TABLE dbo.Driver_Seasons (
    DriverID INT NOT NULL FOREIGN KEY REFERENCES dbo.Drivers(DriverID),
    Season INT NOT NULL
);

-- Extraer temporadas de formato JSON y cargarlas en la tabla
INSERT INTO dbo.Driver_Seasons (DriverID, Season)
SELECT d.DriverID, TRY_CAST([value] AS INT)
FROM dbo.F1Drivers_Dataset f
JOIN dbo.Drivers d ON f.Driver = d.Driver
CROSS APPLY OPENJSON(f.Seasons);


-----------------------------------------------------------
-- 2.3 Tabla de campeonatos: Driver_Championships
-- Normaliza la columna "Championship_Years" (lista de años en JSON).
-----------------------------------------------------------
CREATE TABLE dbo.Driver_Championships (
    DriverID INT NOT NULL FOREIGN KEY REFERENCES dbo.Drivers(DriverID),
    Championship_Year INT NOT NULL
);

-- Extraer años de campeonato de formato JSON y cargarlos en la tabla
INSERT INTO dbo.Driver_Championships (DriverID, Championship_Year)
SELECT d.DriverID, TRY_CAST([value] AS INT)
FROM dbo.F1Drivers_Dataset f
JOIN dbo.Drivers d ON f.Driver = d.Driver
CROSS APPLY OPENJSON(f.Championship_Years);







