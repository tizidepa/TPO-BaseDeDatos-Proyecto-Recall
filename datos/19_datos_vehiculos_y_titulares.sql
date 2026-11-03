-- 19_datos_vehiculos_y_titulares: Cargar vehículos, titulares y titularidades ficticios.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000015',N'Titular ficticio 1',N'Demo',1,N'Domicilio ficticio 1',-34.670000,-58.370000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000023',N'Titular ficticio 2',N'Demo',1,N'Domicilio ficticio 2',-34.670000,-58.370000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000031',N'Titular ficticio 3',N'Demo',1,N'Domicilio ficticio 3',-34.670000,-58.370000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000049',N'Titular ficticio 4',N'Demo',1,N'Domicilio ficticio 4',-34.670000,-58.370000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000058',N'Titular ficticio 5',N'Demo',1,N'Domicilio ficticio 5',-34.670000,-58.370000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000066',N'Titular ficticio 6',N'Demo',1,N'Domicilio ficticio 6',-34.670000,-58.370000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000074',N'Titular ficticio 7',N'Demo',1,N'Domicilio ficticio 7',-34.670000,-58.370000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000082',N'Titular ficticio 8',N'Demo',1,N'Domicilio ficticio 8',-34.670000,-58.370000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000090',N'Titular ficticio 9',N'Demo',1,N'Domicilio ficticio 9',-38.000000,-57.550000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('30900000109',N'Titular ficticio 10',N'Demo',1,N'Domicilio ficticio 10',-34.670000,-58.370000);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000112',N'Titular ficticio 11',N'Demo',1,N'Domicilio ficticio 11',NULL,NULL);
INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud) VALUES('20900000120',N'Titular ficticio 12',N'Demo',3,N'Domicilio ficticio 12',-31.420000,-64.190000);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA001AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA002AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA003AA',N'Modelo demo',1,2);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA004AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA005AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA006AA',N'Modelo demo',1,2);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA007AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA008AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA009AA',N'Modelo demo',1,2);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA010AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA011AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA012AA',N'Modelo demo',1,2);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA013AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA014AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA015AA',N'Modelo demo',1,2);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA016AA',N'Modelo demo',1,1);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA017AA',N'Modelo demo',2,3);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA018AA',N'Modelo demo',2,3);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA019AA',N'Modelo demo',2,3);
INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId) VALUES('AA020AA',N'Modelo demo',2,3);
INSERT dbo.CodigoRecall VALUES('AA001AA','AIRBAG_CONDUCTOR'),('AA001AA','AIRBAG_ACOMPANANTE'),('AA002AA','AIRBAG_CONDUCTOR');
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA001AA','20900000015',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA002AA','20900000023',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA003AA','20900000031',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA004AA','20900000049',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA005AA','20900000058',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA006AA','20900000066',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA007AA','20900000074',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA008AA','20900000082',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA009AA','20900000090',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA010AA','30900000109',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA011AA','20900000112',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA012AA','20900000120',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA013AA','20900000015',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA014AA','20900000023',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA015AA','20900000031',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA016AA','20900000049',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA017AA','20900000058',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA018AA','20900000066',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA019AA','20900000074',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA020AA','20900000082',DATEADD(day,-30,SYSUTCDATETIME()),1);
INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal) VALUES('AA001AA','20900000023',DATEADD(day,-30,SYSUTCDATETIME()),0);
GO
