USE dw8_2526_DW_Energia;

-- Índices na fact table e dimensões
CREATE NONCLUSTERED INDEX idx_fact_time
ON dw.fact_consumption (TIME_ID);

CREATE NONCLUSTERED INDEX idx_fact_location
ON dw.fact_consumption (LOCATION_ID);

CREATE NONCLUSTERED INDEX idx_fact_voltage
ON dw.fact_consumption (VOLTAGE_ID);

CREATE NONCLUSTERED INDEX idx_dim_location
ON dw.dim_location (DISTRICT, MUNICIPALITY, PARISH);

CREATE NONCLUSTERED INDEX idx_dim_time
ON dw.dim_time (YEAR_ID, MONTH_ID);


--CTE: Qual é o consumo por distrito e ano?
WITH ConsumoPorDistritoAno AS (
    SELECT 
        l.DISTRICT,
        t.YEAR_ID,
        SUM(f.CONSUMPTION) AS Total_Consumo,
        AVG(f.CONSUMPTION) AS Media_Consumo
    FROM dw.fact_consumption f
    JOIN dw.dim_location l ON f.LOCATION_ID = l.LOCATION_ID
    JOIN dw.dim_time t ON f.TIME_ID = t.TIME_ID
    GROUP BY l.DISTRICT, t.YEAR_ID
)
SELECT *
FROM ConsumoPorDistritoAno
ORDER BY DISTRICT, YEAR_ID;


-- ROLLUP: Qual é o total por distrito e mês, incluindo subtotais?
SELECT 
    l.DISTRICT,
    t.MONTH_ID,
    SUM(f.CONSUMPTION) AS Total_Consumo
FROM dw.fact_consumption f
JOIN dw.dim_location l ON f.LOCATION_ID = l.LOCATION_ID
JOIN dw.dim_time t ON f.TIME_ID = t.TIME_ID
GROUP BY ROLLUP (l.DISTRICT, t.MONTH_ID)
ORDER BY l.DISTRICT, t.MONTH_ID;


--CUBE: Qual é o consumo por distrito e nível de tensão?
SELECT 
    l.DISTRICT,
    v.LEVEL AS Voltage_Level,
    SUM(f.CONSUMPTION) AS Total_Consumo
FROM dw.fact_consumption f
JOIN dw.dim_location l ON f.LOCATION_ID = l.LOCATION_ID
JOIN dw.dim_voltage v ON f.VOLTAGE_ID = v.VOLTAGE_ID
GROUP BY CUBE (l.DISTRICT, v.LEVEL)
ORDER BY l.DISTRICT, v.LEVEL;


-- GROUPING SETS: Qual é o consumo por ano/distrito e total geral?
SELECT 
    t.YEAR_ID,
    l.DISTRICT,
    SUM(f.CONSUMPTION) AS Total_Consumo
FROM dw.fact_consumption f
JOIN dw.dim_location l ON f.LOCATION_ID = l.LOCATION_ID
JOIN dw.dim_time t ON f.TIME_ID = t.TIME_ID
GROUP BY GROUPING SETS (
    (t.YEAR_ID, l.DISTRICT),  -- por ano e distrito
    (t.YEAR_ID),               -- por ano
    (l.DISTRICT),              -- por distrito
    ()                         -- total geral
)
ORDER BY t.YEAR_ID, l.DISTRICT;