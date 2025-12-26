--USE master;
--DROP DATABASE dw8_2526_DW_Energia;
--CREATE DATABASE dw8_2526_DW_Energia;
--USE dw8_2526_DW_Energia;


--CREATE SCHEMA dw;

-------------------------------------------------
-------------------- Drops  ---------------------
-------------------------------------------------
DROP PROCEDURE IF EXISTS dw.sp_popular_dim_localizacao;
DROP PROCEDURE IF EXISTS dw.sp_popular_dim_tempo;
DROP PROCEDURE IF EXISTS dw.sp_popular_dim_voltagem;
DROP PROCEDURE IF EXISTS dw.sp_popular_fact_consumo;
DROP TABLE IF EXISTS dw.fact_consumo_eletrico;
DROP TABLE IF EXISTS dw.dim_tempo;
DROP TABLE IF EXISTS dw.dim_voltagem;
DROP TABLE IF EXISTS dw.dim_localizacao;


-------------------------------------------------
---------------- Create Tables ------------------
-------------------------------------------------
CREATE TABLE dw.dim_tempo (
    id_tempo INT IDENTITY(1,1) PRIMARY KEY,
    ano INT NOT NULL,
    mes INT NOT NULL
);
CREATE TABLE dw.dim_localizacao (
    id_localizacao INT IDENTITY(1,1) PRIMARY KEY,
    distrito VARCHAR(200),
    concelho VARCHAR(200),
    freguesia VARCHAR(200)
);
CREATE TABLE dw.dim_voltagem (
    id_voltagem INT IDENTITY(1,1) PRIMARY KEY,
    nivel_voltagem VARCHAR(50)
);
CREATE TABLE dw.fact_consumo_eletrico (
    id_consumo_eletrico BIGINT IDENTITY(1,1) PRIMARY KEY,
    consumo DECIMAL(12,3),
    id_tempo INT,
    id_localizacao INT,
    id_voltagem INT,
    FOREIGN KEY (id_tempo) REFERENCES dw.dim_tempo(id_tempo),
    FOREIGN KEY (id_localizacao) REFERENCES dw.dim_localizacao(id_localizacao),
    FOREIGN KEY (id_voltagem) REFERENCES dw.dim_voltagem(id_voltagem)
);



-------------------------------------------------
------------------ Popular ----------------------
-------------------------------------------------
INSERT INTO dw.dim_tempo (ano, mes)
SELECT DISTINCT Ano, Mês
FROM staging.consumo_energia_raw;

INSERT INTO dw.dim_localizacao (distrito, concelho, freguesia)
SELECT DISTINCT Distrito, Concelho, Freguesia
FROM staging.consumo_energia_raw;
----------------------------------------------------------------------
INSERT INTO dw.dim_voltagem (nivel_voltagem)
SELECT DISTINCT [Nível_de_Tensão]
FROM staging.consumo_energia_raw;
----------------------------------------------------------------------



INSERT INTO dw.fact_consumo_eletrico (consumo, id_tempo, id_localizacao, id_voltagem)
SELECT 
    TRY_CAST(REPLACE([Energia_Ativa_kWh], ',', '.') AS DECIMAL(12,3)) AS consumo,
    t.id_tempo,
    l.id_localizacao,
    v.id_voltagem
FROM staging.consumo_energia_raw s
JOIN dw.dim_tempo t ON t.ano = s.Ano AND t.mes = s.Mês
JOIN dw.dim_localizacao l ON l.distrito = s.Distrito AND l.concelho = s.Concelho AND l.freguesia = s.Freguesia
JOIN dw.dim_voltagem v ON v.nivel_voltagem = s.[Nível_de_Tensão];





-------------------------------------------------
------------------ SELECTS ----------------------
-------------------------------------------------
SELECT * FROM staging.instalacoes_raw ;
SELECT * FROM staging.consumo_energia_raw WHERE Energia_Ativa_kWh is Null;



SELECT *
FROM staging.instalacoes_raw;

SELECT DISTINCT [Nível_de_Tensão]
FROM staging.consumo_energia_raw;

SELECT DISTINCT nivel_de_tensao
FROM staging.instalacoes_raw;