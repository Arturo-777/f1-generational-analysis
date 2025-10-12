/* =============================================================
    PROJECT: F1 Generations Analysis
    PART: SQL Server - Data Preparation and Normalization
    DATA SOURCE: Kaggle (F1 Drivers Dataset)
    ORIGINAL TABLE: dbo.F1Drivers_Dataset

    OBJECTIVE:
    - Validate data integrity.
    - Create a normalized relational model:
        * Main drivers table (Drivers)
        * Seasons table (Driver_Seasons)
        * Championships table (Driver_Championships)
   ============================================================= */

/* =============================================================
   1. INITIAL VALIDATION OF THE ORIGINAL TABLE
   ============================================================= */

-- Review structure of the imported table
EXEC sp_help 'dbo.F1Drivers_Dataset';

-- Validate that no drivers have missing names (NULL in Driver)
SELECT *
FROM dbo.F1Drivers_Dataset
WHERE Driver IS NULL;

-- Validate that there are no duplicate drivers
SELECT Driver, COUNT(*) AS DupCount
FROM dbo.F1Drivers_Dataset
GROUP BY Driver
HAVING COUNT(*) > 1;

/* 
   Expected results:
   - No records with Driver = NULL
   - No duplicate Driver records
*/

/* =============================================================
   2. CREATION OF THE NORMALIZED MODEL
   ============================================================= */

-----------------------------------------------------------
-- 2.1 Main Table: Drivers
-- Contains general data for each driver.
-----------------------------------------------------------
CREATE TABLE dbo.Drivers (
    DriverID INT IDENTITY(1,1) PRIMARY KEY,   -- Unique primary key
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

-- Insert base data from the imported table
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
-- 2.2 Seasons Table: Driver_Seasons
-- Normalizes the "Seasons" column (JSON list of years).
-----------------------------------------------------------
CREATE TABLE dbo.Driver_Seasons (
    DriverID INT NOT NULL FOREIGN KEY REFERENCES dbo.Drivers(DriverID),
    Season INT NOT NULL
);

-- Extract seasons from JSON format and load them into the table
INSERT INTO dbo.Driver_Seasons (DriverID, Season)
SELECT d.DriverID, TRY_CAST([value] AS INT)
FROM dbo.F1Drivers_Dataset f
JOIN dbo.Drivers d ON f.Driver = d.Driver
CROSS APPLY OPENJSON(f.Seasons);


-----------------------------------------------------------
-- 2.3 Championships Table: Driver_Championships
-- Normalizes the "Championship_Years" column (JSON list of years).
-----------------------------------------------------------
CREATE TABLE dbo.Driver_Championships (
    DriverID INT NOT NULL FOREIGN KEY REFERENCES dbo.Drivers(DriverID),
    Championship_Year INT NOT NULL
);

-- Extract championship years from JSON format and load them into the table
INSERT INTO dbo.Driver_Championships (DriverID, Championship_Year)
SELECT d.DriverID, TRY_CAST([value] AS INT)
FROM dbo.F1Drivers_Dataset f
JOIN dbo.Drivers d ON f.Driver = d.Driver
CROSS APPLY OPENJSON(f.Championship_Years);








