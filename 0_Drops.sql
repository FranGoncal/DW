-------------------------------------------------
-------------------- Drops  ---------------------
-------------------------------------------------

-- remover procedures
DROP PROCEDURE IF EXISTS dw.sp_popular_dim_localizacao;
DROP PROCEDURE IF EXISTS dw.sp_popular_dim_tempo;
DROP PROCEDURE IF EXISTS dw.sp_popular_dim_voltagem;
DROP PROCEDURE IF EXISTS dw.sp_popular_fact_consumo;
-- remover tabelas
DROP TABLE IF EXISTS dw.fact_consumo_eletrico;
DROP TABLE IF EXISTS dw.dim_tempo;
DROP TABLE IF EXISTS dw.dim_voltagem;
DROP TABLE IF EXISTS dw.dim_localizacao;
-- remover partições
-- Dropar Partition Scheme se existir
IF EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'ps_fact_por_id_tempo')
    DROP PARTITION SCHEME ps_fact_por_id_tempo;
-- Dropar Partition Function se existir
IF EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'pf_fact_por_id_tempo')
    DROP PARTITION FUNCTION pf_fact_por_id_tempo;
-- remover ficheiros (só se existirem)
IF EXISTS (SELECT 1 FROM sys.database_files WHERE name = 'dw_dim_20221849')
    ALTER DATABASE dw8_2526_DW_Energia REMOVE FILE dw_dim_20221849;
IF EXISTS (SELECT 1 FROM sys.database_files WHERE name = 'dw_pk_20221849')
    ALTER DATABASE dw8_2526_DW_Energia REMOVE FILE dw_pk_20221849;
IF EXISTS (SELECT 1 FROM sys.database_files WHERE name = 'dw_fact_1_20221849')
    ALTER DATABASE dw8_2526_DW_Energia REMOVE FILE dw_fact_1_20221849;
IF EXISTS (SELECT 1 FROM sys.database_files WHERE name = 'dw_fact_2_20221849')
    ALTER DATABASE dw8_2526_DW_Energia REMOVE FILE dw_fact_2_20221849;
-- remover filegroups (só se existirem)
IF EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'FG_DIM')
    ALTER DATABASE dw8_2526_DW_Energia REMOVE FILEGROUP FG_DIM;
IF EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'FG_PK')
    ALTER DATABASE dw8_2526_DW_Energia REMOVE FILEGROUP FG_PK;
IF EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'FG_FACT_1')
    ALTER DATABASE dw8_2526_DW_Energia REMOVE FILEGROUP FG_FACT_1;
IF EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'FG_FACT_2')
    ALTER DATABASE dw8_2526_DW_Energia REMOVE FILEGROUP FG_FACT_2;
-- remover schema dw
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
    EXEC('DROP SCHEMA dw');








-- Remover índices da fact table se existirem
IF EXISTS (SELECT 1 
           FROM sys.indexes 
           WHERE name = 'idx_fact_time' AND object_id = OBJECT_ID('dw.fact_consumo_eletrico'))
    DROP INDEX idx_fact_time ON dw.fact_consumo_eletrico;
IF EXISTS (SELECT 1 
           FROM sys.indexes 
           WHERE name = 'idx_fact_location' AND object_id = OBJECT_ID('dw.fact_consumo_eletrico'))
    DROP INDEX idx_fact_location ON dw.fact_consumo_eletrico;
IF EXISTS (SELECT 1 
           FROM sys.indexes 
           WHERE name = 'idx_fact_voltage' AND object_id = OBJECT_ID('dw.fact_consumo_eletrico'))
    DROP INDEX idx_fact_voltage ON dw.fact_consumo_eletrico;
-- Remover índices das dimensões se existirem
IF EXISTS (SELECT 1 
           FROM sys.indexes 
           WHERE name = 'idx_dim_location' AND object_id = OBJECT_ID('dw.dim_localizacao'))
    DROP INDEX idx_dim_location ON dw.dim_localizacao;
IF EXISTS (SELECT 1 
           FROM sys.indexes 
           WHERE name = 'idx_dim_time' AND object_id = OBJECT_ID('dw.dim_tempo'))
    DROP INDEX idx_dim_time ON dw.dim_tempo;