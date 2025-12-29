USE dw8_2526_DW_Energia;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;




-- Indice (Valores especificos dims)
SELECT SUM(f.consumo)
FROM dw.fact_consumo_eletrico f
JOIN dw.dim_tempo t ON f.id_tempo = t.id_tempo
JOIN dw.dim_localizacao l ON f.id_localizacao = l.id_localizacao
WHERE l.freguesia = 'Vila Verde' AND t.mes = 12;
-- LR sem Indices ->580*1288*21 = 15687840
-- LR com Indices ->580*912*20  = 10579200
-- Ganho -> 15687840 - 10579200 = 5108640



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


-- GROUPING SETS: Consumo por Ano e Nível de tensão?
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