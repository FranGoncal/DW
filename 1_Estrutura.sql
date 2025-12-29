--com procedures
USE dw8_2526_DW_Energia;


-------------------------------------------------
---------------- Create Schema ------------------
-------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
    EXEC('CREATE SCHEMA dw');

-------------------------------------------------
------------------- Particoes -------------------
-------------------------------------------------
ALTER DATABASE dw8_2526_DW_Energia  ADD FILEGROUP FG_DIM;
ALTER DATABASE dw8_2526_DW_Energia  ADD FILEGROUP FG_PK;
ALTER DATABASE dw8_2526_DW_Energia  ADD FILEGROUP FG_FACT_1;
ALTER DATABASE dw8_2526_DW_Energia  ADD FILEGROUP FG_FACT_2;

ALTER DATABASE dw8_2526_DW_Energia  ADD FILE (
    NAME = dw_dim_20221849,
    FILENAME = 'f:\fgf\dw_dim_20221849.ndf',
    SIZE = 10MB,
    FILEGROWTH = 10MB
) TO FILEGROUP FG_DIM;

ALTER DATABASE dw8_2526_DW_Energia  ADD FILE (
    NAME = dw_pk_20221849,
    FILENAME = 'g:\fgg\dw_pk_20221849.ndf',
    SIZE = 10MB,
    FILEGROWTH = 10MB
) TO FILEGROUP FG_PK;

ALTER DATABASE dw8_2526_DW_Energia  ADD FILE (
    NAME = dw_fact_1_20221849,
    FILENAME = 'h:\fgh\dw_fact_1_20221849.ndf',
    SIZE = 20MB,
    FILEGROWTH = 20MB
) TO FILEGROUP FG_FACT_1;

ALTER DATABASE dw8_2526_DW_Energia  ADD FILE (
    NAME = dw_fact_2_20221849,
    FILENAME = 'i:\fgi\dw_fact_2_20221849.ndf',
    SIZE = 20MB,
    FILEGROWTH = 20MB
) TO FILEGROUP FG_FACT_2;


-------------------------------------------------
---------------- Create Tables ------------------
-------------------------------------------------
CREATE TABLE dw.dim_tempo (
    id_tempo INT NOT NULL,
    ano INT NOT NULL,
    mes INT NOT NULL,
    trimestre INT NOT NULL,
    semestre INT NOT NULL,
    nome_mes VARCHAR(20)
) ON FG_DIM;
ALTER TABLE dw.dim_tempo
ADD CONSTRAINT pk_dim_tempo
PRIMARY KEY (id_tempo)
ON FG_PK;

CREATE TABLE dw.dim_localizacao (
    id_localizacao INT NOT NULL IDENTITY(1,1),
    distrito VARCHAR(200),
    concelho VARCHAR(200),
    freguesia VARCHAR(200)
) ON FG_DIM;
ALTER TABLE dw.dim_localizacao
ADD CONSTRAINT pk_dim_localizacao
PRIMARY KEY (id_localizacao)
ON FG_PK;

CREATE TABLE dw.dim_voltagem (
    id_voltagem INT NOT NULL IDENTITY(1,1),
    nivel_voltagem VARCHAR(50)
) ON FG_DIM;
ALTER TABLE dw.dim_voltagem
ADD CONSTRAINT pk_dim_voltagem
PRIMARY KEY (id_voltagem)
ON FG_PK;


-- Partition function usando id_tempo
CREATE PARTITION FUNCTION pf_fact_por_id_tempo(INT)
AS RANGE LEFT
FOR VALUES (0);  -- tudo <=0 vai para FG_FACT_1, >0 vai para FG_FACT_2


-- Partition scheme que associa a partition function aos filegroups
CREATE PARTITION SCHEME ps_fact_por_id_tempo
AS PARTITION pf_fact_por_id_tempo
TO (FG_FACT_1, FG_FACT_2);


CREATE TABLE dw.fact_consumo_eletrico (
    id_consumo_eletrico BIGINT NOT NULL IDENTITY(1,1),
    consumo DECIMAL(12,3),
    id_tempo INT NOT NULL,
    id_localizacao INT NOT NULL,
    id_voltagem INT NOT NULL,
    CONSTRAINT pk_fact_consumo PRIMARY KEY CLUSTERED (id_consumo_eletrico, id_tempo)
) ON ps_fact_por_id_tempo(id_tempo);


-- FKs continuam iguais
ALTER TABLE dw.fact_consumo_eletrico
ADD CONSTRAINT fk_fact_tempo
FOREIGN KEY (id_tempo)
REFERENCES dw.dim_tempo(id_tempo);

ALTER TABLE dw.fact_consumo_eletrico
ADD CONSTRAINT fk_fact_localizacao
FOREIGN KEY (id_localizacao)
REFERENCES dw.dim_localizacao(id_localizacao);

ALTER TABLE dw.fact_consumo_eletrico
ADD CONSTRAINT fk_fact_voltagem
FOREIGN KEY (id_voltagem)
REFERENCES dw.dim_voltagem(id_voltagem);



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






-- Check Particoes
SELECT 
    object_name(object_id) AS TableName,
    partition_number,
    rows,
    data_compression_desc
FROM sys.partitions
WHERE object_id = object_id('dw.fact_consumo_eletrico');