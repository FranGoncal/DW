USE master;
DROP DATABASE dw8_2526_DW_Energia;
CREATE DATABASE dw8_2526_DW_Energia;
USE dw8_2526_DW_Energia;

CREATE SCHEMA staging;


SELECT TOP 10 * FROM staging.consumo_energia_raw;
SELECT TOP 10 * FROM staging.instalacoes_raw;

