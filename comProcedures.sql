--com procedures
USE dw8_2526_DW_Energia;


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
    mes INT NOT NULL,
    trimestre INT NOT NULL,
    semestre INT NOT NULL,
    nome_mes VARCHAR(20)
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



-------------------------------------------------------------
---------------- Procedure dim localizacao ------------------
-------------------------------------------------------------
CREATE PROCEDURE dw.sp_popular_dim_localizacao
AS
BEGIN
    INSERT INTO dw.dim_localizacao (distrito, concelho, freguesia)
    SELECT DISTINCT
        LOWER(Distrito),
        LOWER(Concelho),
        LOWER(Freguesia)
    FROM staging.consumo_energia_raw
    WHERE Distrito IS NOT NULL
      AND Concelho IS NOT NULL
      AND Freguesia IS NOT NULL;
END;


-------------------------------------------------------------
------------------- Procedure dim tempo ---------------------
-------------------------------------------------------------
CREATE PROCEDURE dw.sp_popular_dim_tempo
AS
BEGIN
    INSERT INTO dw.dim_tempo (
        ano,
        mes,
        trimestre,
        semestre,
        nome_mes
    )
    SELECT DISTINCT
        Ano,
        Mês,
        DATEPART(QUARTER, DATEFROMPARTS(Ano, Mês, 1)) AS trimestre,
        CASE 
            WHEN Mês <= 6 THEN 1 
            ELSE 2 
        END AS semestre,
        DATENAME(MONTH, DATEFROMPARTS(Ano, Mês, 1)) AS nome_mes
    FROM staging.consumo_energia_raw
    WHERE Ano IS NOT NULL
      AND Mês IS NOT NULL;
END;




-------------------------------------------------------------
----------------- Procedure dim voltagem --------------------
-------------------------------------------------------------
CREATE PROCEDURE dw.sp_popular_dim_voltagem
AS
BEGIN
    INSERT INTO dw.dim_voltagem (nivel_voltagem)
    SELECT DISTINCT
        LOWER([Nível_de_Tensão])
    FROM staging.consumo_energia_raw
    WHERE [Nível_de_Tensão] IS NOT NULL;
END;




-------------------------------------------------------------
------------------ Procedure Fact table ---------------------
-------------------------------------------------------------
CREATE PROCEDURE dw.sp_popular_fact_consumo
AS
BEGIN
    INSERT INTO dw.fact_consumo_eletrico (
        consumo,
        id_tempo,
        id_localizacao,
        id_voltagem
    )
    SELECT
        -- Conversão de kWh para MWh
        TRY_CAST(REPLACE(s.[Energia_Ativa_kWh], ',', '.') AS DECIMAL(12,3)) / 1000.0 AS consumo_mwh,
        t.id_tempo,
        l.id_localizacao,
        v.id_voltagem
    FROM staging.consumo_energia_raw s
    JOIN dw.dim_tempo t
        ON t.ano = s.Ano AND t.mes = s.Mês
    JOIN dw.dim_localizacao l
        ON l.distrito  = LOWER(s.Distrito)
       AND l.concelho  = LOWER(s.Concelho)
       AND l.freguesia = LOWER(s.Freguesia)
    JOIN dw.dim_voltagem v
        ON v.nivel_voltagem = LOWER(s.[Nível_de_Tensão])
    WHERE s.[Energia_Ativa_kWh] IS NOT NULL;
END;


-- Popular Tabelas
EXEC dw.sp_popular_dim_tempo;
EXEC dw.sp_popular_dim_localizacao;
EXEC dw.sp_popular_dim_voltagem;
EXEC dw.sp_popular_fact_consumo;