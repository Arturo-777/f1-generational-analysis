/* =============================================================
   VISTA: vw_F1_Generation_Performance
   PROPÓSITO: Consolidar información de pilotos, temporadas y
              campeonatos para análisis de desempeño por generación.
   ============================================================= */

CREATE OR ALTER VIEW dbo.vw_F1_Generation_Performance AS
SELECT 
    d.DriverID,
    d.Driver,
    d.Nationality,
    d.Decade AS Generation,
    d.Championships,
    d.Race_Entries,
    d.Race_Starts,
    d.Race_Wins,
    d.Podiums,
    d.Fastest_Laps,
    d.Points,
    d.Win_Rate,
    d.Podium_Rate,
    d.FastLap_Rate,
    d.Points_Per_Entry,
    d.Years_Active,
    d.Champion,
    ds.Season,
    dc.Championship_Year
FROM dbo.Drivers AS d
LEFT JOIN dbo.Driver_Seasons AS ds
    ON d.DriverID = ds.DriverID
LEFT JOIN dbo.Driver_Championships AS dc
    ON d.DriverID = dc.DriverID;


SELECT TOP 20 * FROM dbo.vw_F1_Generation_Performance;
