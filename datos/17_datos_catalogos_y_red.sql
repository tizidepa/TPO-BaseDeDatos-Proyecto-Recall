-- 17_datos_catalogos_y_red: Cargar catálogos y red de atención ficticios.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Datos ficticios de demostración. CUIT calculados para validar módulo 11; no representan personas reales.
INSERT dbo.Provincia VALUES(1,N'Buenos Aires'),(2,N'Ciudad Autónoma de Buenos Aires'),(3,N'Córdoba');
INSERT dbo.Gestion(Nombre) VALUES(N'Stellantis Airbags'),(N'Toyota Seguridad');
INSERT dbo.Marca(Nombre) VALUES(N'Fiat'),(N'Citroën'),(N'Toyota');
INSERT dbo.GestionMarca VALUES(1,1),(1,2),(2,3);
INSERT dbo.Concesionaria(Nombre) VALUES(N'Red Demo Buenos Aires'),(N'Taller Multimarca Demo'),(N'Red Demo Córdoba');
INSERT dbo.GestionConcesionaria VALUES(1,1),(1,2),(1,3),(2,1),(2,3);
INSERT dbo.Sucursal(ConcesionariaId,ProvinciaId,Nombre,Domicilio,Latitud,Longitud,MaximoMensual,CapacidadSimultanea) VALUES
(1,1,N'Demo Avellaneda',N'Domicilio ficticio 100',-34.663,-58.365,100,2),
(1,1,N'Demo Quilmes',N'Domicilio ficticio 200',-34.720,-58.255,100,1),
(2,1,N'Demo Lanús',N'Domicilio ficticio 300',-34.705,-58.392,80,1),
(2,1,N'Demo Lomas',N'Domicilio ficticio 400',-34.760,-58.400,80,1),
(1,1,N'Demo La Plata',N'Domicilio ficticio 500',-34.920,-57.950,120,2),
(3,3,N'Demo Córdoba',N'Domicilio ficticio 600',-31.420,-64.189,80,1),
(2,1,N'Demo sin coordenadas',N'Domicilio ficticio 700',NULL,NULL,50,1),
(1,2,N'Demo CABA',N'Domicilio ficticio 800',-34.603,-58.381,1,1);
INSERT dbo.SucursalMarca SELECT SucursalId,1 FROM dbo.Sucursal;
INSERT dbo.SucursalMarca SELECT SucursalId,2 FROM dbo.Sucursal WHERE SucursalId IN(1,2,3,4,5,6);
INSERT dbo.SucursalMarca SELECT SucursalId,3 FROM dbo.Sucursal WHERE SucursalId IN(1,2,5,6,8);
INSERT dbo.Horario SELECT s.SucursalId,d.Dia,CONVERT(time(0),'09:00'),CONVERT(time(0),'13:00')
 FROM dbo.Sucursal s CROSS JOIN(VALUES(1),(2),(3),(4),(5))d(Dia);
INSERT dbo.Horario SELECT s.SucursalId,d.Dia,CONVERT(time(0),'14:00'),CONVERT(time(0),'18:00')
 FROM dbo.Sucursal s CROSS JOIN(VALUES(1),(2),(3),(4),(5))d(Dia);
INSERT dbo.Contacto(Nombre,Apellido,Tipo) VALUES(N'Contacto',N'Demo','zonal_posventa'),(N'Agenda',N'Demo','agendador');
INSERT dbo.SucursalContacto VALUES(1,1),(1,2),(2,1);
GO
