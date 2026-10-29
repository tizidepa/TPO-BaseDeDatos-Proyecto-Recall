-- 01_funciones_validacion_y_distancia: Validar CUIT y celulares y calcular distancias.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION dbo.fn_CUITValido(@cuit varchar(20)) RETURNS bit
WITH SCHEMABINDING AS
BEGIN
    IF LEN(@cuit) <> 11 OR @cuit COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9]%'
       OR LEFT(@cuit,2) NOT IN ('20','23','24','25','26','27','30','33','34') RETURN 0;
    DECLARE @i int=1, @s int=0, @pesos varchar(10)='5432765432', @dv int;
    WHILE @i<=10 BEGIN
        SET @s+=CONVERT(int,SUBSTRING(@cuit,@i,1))*CONVERT(int,SUBSTRING(@pesos,@i,1));
        SET @i+=1;
    END;
    SET @dv=11-(@s%11);
    IF @dv=11 SET @dv=0;
    IF @dv=10 SET @dv=9;
    RETURN IIF(@dv=CONVERT(int,RIGHT(@cuit,1)),1,0);
END;
GO
CREATE FUNCTION dbo.fn_NormalizarCelular(@entrada varchar(100)) RETURNS varchar(10)
WITH SCHEMABINDING AS
BEGIN
    -- Política conservadora: no adivinar un código de área ni truncar dígitos arbitrarios.
    DECLARE @n varchar(100)=LTRIM(RTRIM(@entrada));
    SET @n=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@n,' ',''),'-',''),'(',''),')',''),'+','');
    IF @n IS NULL OR @n='' OR @n COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9]%' RETURN NULL;
    IF LEFT(@n,2)='00' SET @n=SUBSTRING(@n,3,100);
    IF LEN(@n)=13 AND LEFT(@n,3)='549' SET @n=SUBSTRING(@n,4,10);
    ELSE IF LEN(@n)=12 AND LEFT(@n,2)='54' SET @n=SUBSTRING(@n,3,10);
    ELSE IF LEN(@n)=11 AND LEFT(@n,1)='0' SET @n=SUBSTRING(@n,2,10);
    -- Los formatos con prefijo local 15 o 15 intercalado requieren corrección en origen.
    IF LEN(@n)<>10 OR LEFT(@n,1) IN ('0','1') AND LEFT(@n,2)<>'11' RETURN NULL;
    RETURN @n;
END;
GO
CREATE FUNCTION dbo.fn_DistanciaKm(@lat1 float,@lon1 float,@lat2 float,@lon2 float)
RETURNS decimal(10,3) WITH SCHEMABINDING AS
BEGIN
    IF @lat1 IS NULL OR @lon1 IS NULL OR @lat2 IS NULL OR @lon2 IS NULL RETURN NULL;
    DECLARE @a float=POWER(SIN(RADIANS(@lat2-@lat1)/2),2)
      +COS(RADIANS(@lat1))*COS(RADIANS(@lat2))*POWER(SIN(RADIANS(@lon2-@lon1)/2),2);
    IF @a>1 SET @a=1;
    IF @a<0 SET @a=0;
    RETURN CONVERT(decimal(10,3),6371.0088*2*ASIN(SQRT(@a)));
END;
GO
