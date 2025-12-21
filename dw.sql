USE master;
DROP DATABASE dw8_2526_DW_Energia;
CREATE DATABASE dw8_2526_DW_Energia;
USE dw8_2526_DW_Energia;


CREATE SCHEMA dw;


CREATE TABLE dw.dim_time (
    TIME_ID INT IDENTITY(1,1) PRIMARY KEY,
    YEAR_ID INT NOT NULL,
    MONTH_ID INT NOT NULL
);

SELECT * FROM dw.dim_time;

CREATE TABLE dw.dim_location (
    LOCATION_ID INT IDENTITY(1,1) PRIMARY KEY,
    DISTRICT VARCHAR(200),
    MUNICIPALITY VARCHAR(200),
    PARISH VARCHAR(200)
);
CREATE TABLE dw.dim_voltage (
    VOLTAGE_ID INT IDENTITY(1,1) PRIMARY KEY,
    LEVEL VARCHAR(50)
);
CREATE TABLE dw.fact_consumption (
    ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    CONSUMPTION DECIMAL(12,3),
    TIME_ID INT,
    LOCATION_ID INT,
    VOLTAGE_ID INT,
    FOREIGN KEY (TIME_ID) REFERENCES dw.dim_time(TIME_ID),
    FOREIGN KEY (LOCATION_ID) REFERENCES dw.dim_location(LOCATION_ID),
    FOREIGN KEY (VOLTAGE_ID) REFERENCES dw.dim_voltage(VOLTAGE_ID)
);



-- Dimensão Tempo
INSERT INTO dw.dim_time (YEAR_ID, MONTH_ID)
SELECT DISTINCT Ano, Mês
FROM staging.consumo_energia_raw;

-- Dimensão Location
INSERT INTO dw.dim_location (DISTRICT, MUNICIPALITY, PARISH)
SELECT DISTINCT Distrito, Concelho, Freguesia
FROM staging.consumo_energia_raw;

-- Dimensão Voltage
INSERT INTO dw.dim_voltage (LEVEL)
SELECT DISTINCT [Nível_de_Tensão]
FROM staging.consumo_energia_raw;

-- Fact Table
INSERT INTO dw.fact_consumption (CONSUMPTION, TIME_ID, LOCATION_ID, VOLTAGE_ID)
SELECT 
    TRY_CAST(REPLACE([Energia_Ativa_kWh], ',', '.') AS DECIMAL(12,3)) AS CONSUMPTION,
    t.TIME_ID,
    l.LOCATION_ID,
    v.VOLTAGE_ID
FROM staging.consumo_energia_raw s
JOIN dw.dim_time t ON t.YEAR_ID = s.Ano AND t.MONTH_ID = s.Mês
JOIN dw.dim_location l ON l.DISTRICT = s.Distrito AND l.MUNICIPALITY = s.Concelho AND l.PARISH = s.Freguesia
JOIN dw.dim_voltage v ON v.LEVEL = s.[Nível_de_Tensão];



INSERT INTO dw.dim_voltage (LEVEL)
SELECT DISTINCT nivel_de_tensao
FROM staging.instalacoes_raw;


INSERT INTO dw.dim_location (DISTRICT, MUNICIPALITY, PARISH)
SELECT DISTINCT Distrito, Concelho, Freguesia
FROM staging.instalacoes_raw
WHERE NOT EXISTS (
    SELECT 1 FROM dw.dim_location l
    WHERE l.DISTRICT = staging.instalacoes_raw.Distrito
      AND l.MUNICIPALITY = staging.instalacoes_raw.Concelho
      AND l.PARISH = staging.instalacoes_raw.Freguesia
);


INSERT INTO dw.fact_consumption (CONSUMPTION, TIME_ID, LOCATION_ID, VOLTAGE_ID)
SELECT 
    TRY_CAST(REPLACE(c.[Energia_Ativa_kWh], ',', '.') AS DECIMAL(12,3)) AS CONSUMPTION,
    t.TIME_ID,
    l.LOCATION_ID,
    v.VOLTAGE_ID
FROM staging.consumo_energia_raw c
JOIN dw.dim_time t
    ON t.YEAR_ID = c.Ano AND t.MONTH_ID = c.Mês
JOIN dw.dim_location l
    ON l.DISTRICT = c.Distrito
   AND l.MUNICIPALITY = c.Concelho
   AND l.PARISH = c.Freguesia
JOIN staging.instalacoes_raw i
    ON i.Distrito = c.Distrito
   AND i.Concelho = c.Concelho
   AND i.Freguesia = c.Freguesia
JOIN dw.dim_voltage v
    ON v.LEVEL = i.nivel_de_tensao;





