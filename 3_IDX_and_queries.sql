USE dw8_2526_DW_Energia;

--SET STATISTICS PROFILE ON;
--SET STATISTICS PROFILE OFF;
SET STATISTICS IO ON;
--SET STATISTICS IO OFF;
SET STATISTICS TIME ON;
--SET STATISTICS TIME OFF;


-- Índices na fact table e dimensões
CREATE NONCLUSTERED INDEX idx_fact_time
ON dw.fact_consumo_eletrico (id_tempo);
CREATE NONCLUSTERED INDEX idx_fact_location
ON dw.fact_consumo_eletrico (id_localizacao);
CREATE NONCLUSTERED INDEX idx_fact_voltage
ON dw.fact_consumo_eletrico (id_voltagem);
CREATE NONCLUSTERED INDEX idx_dim_location
ON dw.dim_localizacao (distrito, concelho, freguesia);
CREATE NONCLUSTERED INDEX idx_dim_time
ON dw.dim_tempo (ano, mes);




-- CTE: Qual é o consumo por distrito e ano?
WITH ConsumoPorDistritoAno AS (
    SELECT 
        l.distrito,
        t.ano,
        SUM(f.consumo) AS Total_Consumo,
        AVG(f.consumo) AS Media_Consumo
    FROM dw.fact_consumo_eletrico f
    JOIN dw.dim_localizacao l ON f.id_localizacao = l.id_localizacao
    JOIN dw.dim_tempo t ON f.id_tempo = t.id_tempo
    GROUP BY l.distrito, t.ano
)
SELECT *
FROM ConsumoPorDistritoAno
ORDER BY distrito, ano;
-- LR sem Indices ->
-- LR com Indices ->


-- ROLLUP: Qual é consumo total por distrito e mês, incluindo subtotais?
SELECT 
    l.distrito,
    t.mes,
    SUM(f.consumo) AS Total_Consumo
FROM dw.fact_consumo_eletrico f
JOIN dw.dim_localizacao l ON f.id_localizacao = l.id_localizacao
JOIN dw.dim_tempo t ON f.id_tempo = t.id_tempo
GROUP BY ROLLUP (l.distrito, t.mes)
ORDER BY l.distrito, t.mes;
-- LR sem Indices ->
-- LR com Indices ->


--CUBE: Qual é o consumo por distrito e nível de tensão?
SELECT 
    l.distrito,
    v.nivel_voltagem AS Voltage_Level,
    SUM(f.consumo) AS Total_Consumo
FROM dw.fact_consumo_eletrico f
JOIN dw.dim_localizacao l ON f.id_localizacao = l.id_localizacao
JOIN dw.dim_voltagem v ON f.id_voltagem = v.id_voltagem
GROUP BY CUBE (l.distrito, v.nivel_voltagem)
ORDER BY l.distrito, v.nivel_voltagem;
-- LR sem Indices ->
-- LR com Indices ->


-- GROUPING SETS: Consumo por Ano e Nível de Voltagem?
SELECT
    t.ano,
    v.nivel_voltagem,
    SUM(f.consumo) AS Total_Consumo
FROM dw.fact_consumo_eletrico f
JOIN dw.dim_tempo t
    ON f.id_tempo = t.id_tempo
JOIN dw.dim_voltagem v
    ON f.id_voltagem = v.id_voltagem
GROUP BY GROUPING SETS (
    (t.ano, v.nivel_voltagem),
    (t.ano),
    (v.nivel_voltagem),
    ()
)
ORDER BY t.ano, v.nivel_voltagem;
-- LR sem Indices ->
-- LR com Indices ->
