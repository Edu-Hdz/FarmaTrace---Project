-- 0. CREACIÓN DE LA BASE DE DATOS

DROP DATABASE IF EXISTS farmatrace;
CREATE DATABASE farmatrace;
USE farmatrace;


-- 1. TABLAS CATÁLOGO (para reemplazar los ENUM)

-- Catálogo: Tipo de cadena de frío
CREATE TABLE CadenaFrio (
    id_cadena_frio INT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);

-- Catálogo: Tipo de almacén
CREATE TABLE TipoAlmacen (
    id_tipo_almacen INT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

-- Catálogo: Estado de los lotes
CREATE TABLE EstadoLote (
    id_estado_lote INT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

-- Catálogo: Estado de orden de compra
CREATE TABLE EstadoOrdenCompra (
    id_estado_oc INT PRIMARY KEY,
    nombre VARCHAR(25) NOT NULL
);

-- Catálogo: Estado de orden de envío
CREATE TABLE EstadoOrdenEnvio (
    id_estado_oe INT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

-- Catálogo: Estado de recepción
CREATE TABLE EstadoRecepcion (
    id_estado_recepcion INT PRIMARY KEY,
    nombre VARCHAR(15) NOT NULL
);

-- Catálogo: Condición del producto recibido
CREATE TABLE CondicionRecepcion (
    id_condicion INT PRIMARY KEY,
    nombre VARCHAR(15) NOT NULL
);

-- Catálogo: Tipo de costo operativo
CREATE TABLE TipoCosto (
    id_tipo_costo INT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

-- Catálogo: Nivel de alerta de vencimiento
CREATE TABLE NivelAlerta (
    id_nivel INT PRIMARY KEY,
    nombre VARCHAR(10) NOT NULL
);

-- Catálogo: Tipo de movimiento en trazabilidad
CREATE TABLE TipoMovimiento (
    id_tipo_movimiento INT PRIMARY KEY,
    nombre VARCHAR(25) NOT NULL
);

-- Catálogo: Estado del transporte
CREATE TABLE EstadoTransporte (
    id_estado_transporte INT PRIMARY KEY,
    nombre VARCHAR(15) NOT NULL
);

-- Catálogo: Tipo de cliente
CREATE TABLE TipoCliente (
    id_tipo_cliente INT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);


-- 2. TABLAS MAESTRAS (CATÁLOGOS PRINCIPALES)


-- 2.1 Categoria de Producto
CREATE TABLE CategoriaProducto (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(80) NOT NULL,
    descripcion VARCHAR(255),
    id_cadena_frio INT NOT NULL,
    FOREIGN KEY (id_cadena_frio) REFERENCES CadenaFrio(id_cadena_frio)
);

-- 2.2 Proveedor
CREATE TABLE Proveedor (
    id_proveedor INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(120) NOT NULL,
    pais VARCHAR(60) NOT NULL,
    contacto VARCHAR(100),
    email VARCHAR(120) NOT NULL,
    telefono VARCHAR(20),
    activo TINYINT NOT NULL DEFAULT 1
);

-- 2.3 Producto
CREATE TABLE Producto (
    id_producto INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(150) NOT NULL,
    registro_sanitario VARCHAR(40) NOT NULL,
    id_categoria INT NOT NULL,
    presentacion VARCHAR(80) NOT NULL,
    concentracion VARCHAR(60),
    precio_unitario DECIMAL(10,2) NOT NULL,
    stock_minimo INT NOT NULL DEFAULT 10,
    requiere_refrigeracion TINYINT NOT NULL DEFAULT 0,
    FOREIGN KEY (id_categoria) REFERENCES CategoriaProducto(id_categoria)
);

-- 2.4 ProveedorProducto (relación N:M)
CREATE TABLE ProveedorProducto (
    id_prov_prod INT PRIMARY KEY AUTO_INCREMENT,
    id_proveedor INT NOT NULL,
    id_producto INT NOT NULL,
    precio_compra DECIMAL(10,2) NOT NULL,
    tiempo_entrega_dias INT NOT NULL DEFAULT 7,
    proveedor_principal TINYINT NOT NULL DEFAULT 0,
    FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id_proveedor),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto)
);

-- 2.5 Bodega
CREATE TABLE Bodega (
    id_bodega INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(60) NOT NULL,
    direccion VARCHAR(200),
    responsable VARCHAR(100),
    activa TINYINT NOT NULL DEFAULT 1
);

-- 2.6 Ubicacion
CREATE TABLE Ubicacion (
    id_ubicacion INT PRIMARY KEY AUTO_INCREMENT,
    id_bodega INT NOT NULL,
    pasillo VARCHAR(10) NOT NULL,
    rack VARCHAR(10) NOT NULL,
    nivel VARCHAR(10) NOT NULL,
    id_tipo_almacen INT NOT NULL DEFAULT 1,
    activa TINYINT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_bodega) REFERENCES Bodega(id_bodega),
    FOREIGN KEY (id_tipo_almacen) REFERENCES TipoAlmacen(id_tipo_almacen)
);

-- 2.7 Cliente
CREATE TABLE Cliente (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(150) NOT NULL,
    id_tipo_cliente INT NOT NULL,
    rfc VARCHAR(15) NOT NULL,
    direccion VARCHAR(200),
    ciudad VARCHAR(60),
    estado_republica VARCHAR(60),
    contacto VARCHAR(100),
    email VARCHAR(120) NOT NULL,
    activo TINYINT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_tipo_cliente) REFERENCES TipoCliente(id_tipo_cliente)
);

-- 2.8 Transporte
CREATE TABLE Transporte (
    id_transporte INT PRIMARY KEY AUTO_INCREMENT,
    placa VARCHAR(10) NOT NULL,
    transportista VARCHAR(100) NOT NULL,
    tipo_vehiculo VARCHAR(60) NOT NULL,
    capacidad_kg DECIMAL(8,2),
    refrigerado TINYINT NOT NULL DEFAULT 0,
    activo TINYINT NOT NULL DEFAULT 1
);


-- 3. TABLAS DE OPERACIÓN


-- 3.1 Lote
CREATE TABLE Lote (
    id_lote INT PRIMARY KEY AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_proveedor INT NOT NULL,
    numero_lote VARCHAR(50) NOT NULL,
    fecha_fabricacion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    cantidad_inicial INT NOT NULL,
    id_estado_lote INT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id_proveedor),
    FOREIGN KEY (id_estado_lote) REFERENCES EstadoLote(id_estado_lote)
);

-- 3.2 Inventario
CREATE TABLE Inventario (
    id_inventario INT PRIMARY KEY AUTO_INCREMENT,
    id_lote INT NOT NULL,
    id_ubicacion INT NOT NULL,
    cantidad_disponible INT NOT NULL DEFAULT 0,
    ultima_actualizacion DATETIME,
    FOREIGN KEY (id_lote) REFERENCES Lote(id_lote),
    FOREIGN KEY (id_ubicacion) REFERENCES Ubicacion(id_ubicacion)
);

-- 3.3 OrdenCompra
CREATE TABLE OrdenCompra (
    id_orden_compra INT PRIMARY KEY AUTO_INCREMENT,
    id_proveedor INT NOT NULL,
    id_bodega INT NOT NULL,
    fecha_orden DATE NOT NULL,
    fecha_entrega_esperada DATE NOT NULL,
    id_estado_oc INT NOT NULL DEFAULT 1,
    total_estimado DECIMAL(12,2),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id_proveedor),
    FOREIGN KEY (id_bodega) REFERENCES Bodega(id_bodega),
    FOREIGN KEY (id_estado_oc) REFERENCES EstadoOrdenCompra(id_estado_oc)
);

-- 3.4 DetalleCompra
CREATE TABLE DetalleCompra (
    id_detalle_compra INT PRIMARY KEY AUTO_INCREMENT,
    id_orden_compra INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad_ordenada INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    cantidad_recibida INT NOT NULL DEFAULT 0,
    FOREIGN KEY (id_orden_compra) REFERENCES OrdenCompra(id_orden_compra),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto)
);

-- 3.5 Recepcion
CREATE TABLE Recepcion (
    id_recepcion INT PRIMARY KEY AUTO_INCREMENT,
    id_orden_compra INT NOT NULL,
    id_bodega INT NOT NULL,
    fecha_recepcion DATE NOT NULL,
    responsable VARCHAR(100) NOT NULL,
    numero_guia VARCHAR(60),
    id_estado_recepcion INT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_orden_compra) REFERENCES OrdenCompra(id_orden_compra),
    FOREIGN KEY (id_bodega) REFERENCES Bodega(id_bodega),
    FOREIGN KEY (id_estado_recepcion) REFERENCES EstadoRecepcion(id_estado_recepcion)
);

-- 3.6 DetalleRecepcion
CREATE TABLE DetalleRecepcion (
    id_det_recepcion INT PRIMARY KEY AUTO_INCREMENT,
    id_recepcion INT NOT NULL,
    id_lote INT NOT NULL,
    id_ubicacion INT NOT NULL,
    cantidad_recibida INT NOT NULL,
    id_condicion INT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_recepcion) REFERENCES Recepcion(id_recepcion),
    FOREIGN KEY (id_lote) REFERENCES Lote(id_lote),
    FOREIGN KEY (id_ubicacion) REFERENCES Ubicacion(id_ubicacion),
    FOREIGN KEY (id_condicion) REFERENCES CondicionRecepcion(id_condicion)
);

-- 3.7 OrdenEnvio
CREATE TABLE OrdenEnvio (
    id_orden_envio INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    id_bodega INT NOT NULL,
    fecha_pedido DATE NOT NULL,
    fecha_requerida DATE NOT NULL,
    fecha_despacho DATE,
    id_estado_oe INT NOT NULL DEFAULT 1,
    total_venta DECIMAL(12,2),
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
    FOREIGN KEY (id_bodega) REFERENCES Bodega(id_bodega),
    FOREIGN KEY (id_estado_oe) REFERENCES EstadoOrdenEnvio(id_estado_oe)
);

-- 3.8 DetalleEnvio
CREATE TABLE DetalleEnvio (
    id_detalle_envio INT PRIMARY KEY AUTO_INCREMENT,
    id_orden_envio INT NOT NULL,
    id_lote INT NOT NULL,
    id_ubicacion INT NOT NULL,
    cantidad_despachada INT NOT NULL,
    precio_unitario_venta DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_orden_envio) REFERENCES OrdenEnvio(id_orden_envio),
    FOREIGN KEY (id_lote) REFERENCES Lote(id_lote),
    FOREIGN KEY (id_ubicacion) REFERENCES Ubicacion(id_ubicacion)
);

-- 3.9 EnvioTransporte
CREATE TABLE EnvioTransporte (
    id_envio_transporte INT PRIMARY KEY AUTO_INCREMENT,
    id_orden_envio INT NOT NULL,
    id_transporte INT NOT NULL,
    fecha_salida DATE NOT NULL,
    fecha_entrega_real DATE,
    evidencia_entrega VARCHAR(200),
    id_estado_transporte INT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_orden_envio) REFERENCES OrdenEnvio(id_orden_envio),
    FOREIGN KEY (id_transporte) REFERENCES Transporte(id_transporte),
    FOREIGN KEY (id_estado_transporte) REFERENCES EstadoTransporte(id_estado_transporte)
);


-- 4. TABLAS DE CONTROL Y AUDITORÍA


-- 4.1 CostoOperacion
CREATE TABLE CostoOperacion (
    id_costo INT PRIMARY KEY AUTO_INCREMENT,
    id_bodega INT NOT NULL,
    id_lote INT,
    id_tipo_costo INT NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha DATE NOT NULL,
    descripcion VARCHAR(255),
    FOREIGN KEY (id_bodega) REFERENCES Bodega(id_bodega),
    FOREIGN KEY (id_lote) REFERENCES Lote(id_lote),
    FOREIGN KEY (id_tipo_costo) REFERENCES TipoCosto(id_tipo_costo)
);

-- 4.2 AlertaVencimiento
CREATE TABLE AlertaVencimiento (
    id_alerta INT PRIMARY KEY AUTO_INCREMENT,
    id_lote INT NOT NULL,
    id_bodega INT NOT NULL,
    dias_para_vencer INT NOT NULL,
    fecha_alerta DATE NOT NULL,
    id_nivel INT NOT NULL,
    resuelta TINYINT NOT NULL DEFAULT 0,
    FOREIGN KEY (id_lote) REFERENCES Lote(id_lote),
    FOREIGN KEY (id_bodega) REFERENCES Bodega(id_bodega),
    FOREIGN KEY (id_nivel) REFERENCES NivelAlerta(id_nivel)
);

-- 4.3 HistorialTrazabilidad
CREATE TABLE HistorialTrazabilidad (
    id_historial INT PRIMARY KEY AUTO_INCREMENT,
    id_lote INT NOT NULL,
    id_orden_envio INT,
    id_recepcion INT,
    id_ubicacion INT,
    id_tipo_movimiento INT NOT NULL,
    cantidad INT NOT NULL,
    fecha_movimiento DATETIME,
    usuario VARCHAR(80),
    observaciones VARCHAR(255),
    FOREIGN KEY (id_lote) REFERENCES Lote(id_lote),
    FOREIGN KEY (id_orden_envio) REFERENCES OrdenEnvio(id_orden_envio),
    FOREIGN KEY (id_recepcion) REFERENCES Recepcion(id_recepcion),
    FOREIGN KEY (id_ubicacion) REFERENCES Ubicacion(id_ubicacion),
    FOREIGN KEY (id_tipo_movimiento) REFERENCES TipoMovimiento(id_tipo_movimiento)
);


-- 5. INSERCIÓN DE DATOS EN CATÁLOGOS 


INSERT INTO CadenaFrio VALUES (1, 'No requiere'), (2, '2-8°C'), (3, '15-25°C'), (4, '-20°C');

INSERT INTO TipoAlmacen VALUES (1, 'Ambiente'), (2, 'Refrigerado'), (3, 'Congelado'), (4, 'Controlado');

INSERT INTO EstadoLote VALUES (1, 'Cuarentena'), (2, 'Disponible'), (3, 'Agotado'), (4, 'Vencido'), (5, 'Retirado');

INSERT INTO EstadoOrdenCompra VALUES (1, 'Borrador'), (2, 'Enviada'), (3, 'Confirmada'), (4, 'Recibida parcial'), (5, 'Completada'), (6, 'Cancelada');

INSERT INTO EstadoOrdenEnvio VALUES (1, 'Pendiente'), (2, 'En preparación'), (3, 'Despachado'), (4, 'Entregado'), (5, 'Devuelto'), (6, 'Cancelado');

INSERT INTO EstadoRecepcion VALUES (1, 'Pendiente'), (2, 'En revisión'), (3, 'Aceptada'), (4, 'Rechazada');

INSERT INTO CondicionRecepcion VALUES (1, 'Óptima'), (2, 'Aceptable'), (3, 'Dañada'), (4, 'Rechazada');

INSERT INTO TipoCosto VALUES (1, 'Almacenaje'), (2, 'Transporte'), (3, 'Merma'), (4, 'Reempaque'), (5, 'Devolución'), (6, 'Horas extra'), (7, 'Otro');

INSERT INTO NivelAlerta VALUES (1, '30 días'), (2, '15 días'), (3, '7 días'), (4, 'Vencido');

INSERT INTO TipoMovimiento VALUES (1, 'Recepción'), (2, 'Traslado interno'), (3, 'Picking'), (4, 'Despacho'), (5, 'Ajuste'), (6, 'Merma'), (7, 'Retiro COFEPRIS');

INSERT INTO EstadoTransporte VALUES (1, 'En tránsito'), (2, 'Entregado'), (3, 'Devuelto'), (4, 'Incidente');

INSERT INTO TipoCliente VALUES (1, 'Farmacia independiente'), (2, 'Cadena farmacéutica'), (3, 'Hospital'), (4, 'Clínica');

INSERT INTO Proveedor (id_proveedor, nombre, pais, contacto, email, telefono, activo) VALUES
(1, 'LabPharma SA', 'México', 'Juan Martínez', 'compras@labpharma.com', '5551234567', 1),
(2, 'Laboratorios Nacionales', 'México', 'Ana Silva', 'ventas@labnacionales.mx', '5559876543', 1),
(3, 'Medicamentos Genéricos del Bajío', 'México', 'Roberto Gómez', 'roberto@medgen.com', '4771237890', 1),
(4, 'BioFarma Internacional', 'Alemania', 'Klaus Richter', 'klaus@biofarma.de', '+49123456789', 1),
(5, 'Farmex SA de CV', 'México', 'Laura Díaz', 'laura@farmex.mx', '5554567890', 1);


INSERT INTO CategoriaProducto (id_categoria, nombre, descripcion, id_cadena_frio) VALUES
(1, 'Analgésicos', 'Medicamentos para el dolor', 1),
(2, 'Antibióticos', 'Medicamentos para infecciones', 1),
(3, 'Antihipertensivos', 'Medicamentos para presión arterial', 1),
(4, 'Antiinflamatorios', 'Medicamentos para inflamación', 1),
(5, 'Vacunas', 'Biológicos para prevención', 2),
(6, 'Insulinas', 'Medicamentos para diabetes', 2);


INSERT INTO Producto (id_producto, nombre, registro_sanitario, id_categoria, presentacion, concentracion, precio_unitario, stock_minimo, requiere_refrigeracion) VALUES
(1, 'Paracetamol 500mg', 'RS-001-2020', 1, 'Tableta', '500mg', 5.50, 1000, 0),
(2, 'Amoxicilina 250mg', 'RS-002-2019', 2, 'Cápsula', '250mg', 8.20, 800, 0),
(3, 'Ibuprofeno 400mg', 'RS-003-2021', 4, 'Tableta', '400mg', 6.75, 500, 0),
(4, 'Enalapril 10mg', 'RS-004-2018', 3, 'Tableta', '10mg', 4.30, 300, 0),
(5, 'Vacuna Influenza', 'RS-005-2022', 5, 'Suspensión inyectable', '0.5ml', 120.00, 200, 1),
(6, 'Insulina Glargina', 'RS-006-2020', 6, 'Solución inyectable', '100UI/ml', 350.00, 150, 1);


INSERT INTO ProveedorProducto (id_prov_prod, id_proveedor, id_producto, precio_compra, tiempo_entrega_dias, proveedor_principal) VALUES
(1, 1, 1, 3.80, 5, 1),
(2, 2, 1, 3.90, 7, 0),
(3, 1, 2, 5.50, 5, 1),
(4, 3, 2, 5.60, 8, 0),
(5, 2, 3, 4.20, 6, 1),
(6, 4, 3, 4.00, 15, 0),
(7, 2, 4, 2.80, 5, 1),
(8, 5, 4, 2.90, 6, 0),
(9, 4, 5, 85.00, 20, 1),
(10, 4, 6, 250.00, 15, 1);


INSERT INTO Bodega (id_bodega, nombre, ciudad, direccion, responsable, activa) VALUES
(1, 'CD Guadalajara', 'Guadalajara', 'Av. Patria 1234, Zona Industrial', 'Carlos Ruiz', 1),
(2, 'CD Ciudad de México', 'Ciudad de México', 'Eje Central 567, Azcapotzalco', 'Sofía Méndez', 1),
(3, 'CD Monterrey', 'Monterrey', 'Carretera Nacional 890, Apodaca', 'Alejandro Torres', 1);


INSERT INTO Ubicacion (id_ubicacion, id_bodega, pasillo, rack, nivel, id_tipo_almacen, activa) VALUES
-- Bodega Guadalajara
(1, 1, 'A', '01', '01', 1, 1),
(2, 1, 'A', '01', '02', 1, 1),
(3, 1, 'A', '03', '02', 1, 1),
(4, 1, 'B', '02', '01', 2, 1),
(5, 1, 'C', '01', '01', 1, 1),
-- Bodega CDMX
(6, 2, 'A', '01', '01', 1, 1),
(7, 2, 'C', '01', '04', 1, 1),
(8, 2, 'C', '02', '01', 2, 1),
(9, 2, 'B', '03', '02', 1, 1),
(10, 2, 'D', '01', '01', 1, 1),
-- Bodega Monterrey
(11, 3, 'A', '01', '01', 1, 1),
(12, 3, 'B', '02', '02', 1, 1),
(13, 3, 'C', '01', '03', 2, 1),
(14, 3, 'A', '02', '01', 1, 1);


INSERT INTO Cliente (id_cliente, nombre, id_tipo_cliente, rfc, direccion, ciudad, estado_republica, contacto, email, activo) VALUES
(1, 'Farmacias del Sureste', 2, 'FSU850101XXX', 'Av. Juárez 234, Centro', 'Mérida', 'Yucatán', 'Luis Fernández', 'compras@farmaciasdelsureste.mx', 1),
(2, 'Hospital General de Occidente', 3, 'HGO780202XXX', 'Calzada Independencia 456', 'Guadalajara', 'Jalisco', 'Dra. Martha Ríos', 'compras@hgoccidente.gob.mx', 1),
(3, 'Farmacia Santa Fe', 1, 'FSF901015XXX', 'Paseo de la Reforma 789', 'Ciudad de México', 'CDMX', 'Miguel Ángel Soto', 'miguel@farmaciasantafe.mx', 1),
(4, 'Clínica Especializada del Norte', 4, 'CEN850303XXX', 'Av. Universidad 101', 'Monterrey', 'Nuevo León', 'Dr. Sergio Ramos', 'sergio@clinicadelnorte.mx', 1),
(5, 'Farmacias Similares Norte', 2, 'FSN901212XXX', 'Av. Juárez 567', 'Monterrey', 'Nuevo León', 'Patricia León', 'compras@farmaciasimilares.mx', 1);


INSERT INTO Transporte (id_transporte, placa, transportista, tipo_vehiculo, capacidad_kg, refrigerado, activo) VALUES
(1, 'ABC123', 'Transportes del Pacífico', 'Camión refrigerado', 3500.00, 1, 1),
(2, 'XYZ789', 'Carga Fácil', 'Furgón', 1200.00, 0, 1),
(3, 'JKL456', 'Transportes del Norte', 'Camión seco', 2500.00, 0, 1),
(4, 'MNO012', 'Logística Frío SA', 'Camión refrigerado', 3000.00, 1, 1);


INSERT INTO Lote (id_lote, id_producto, id_proveedor, numero_lote, fecha_fabricacion, fecha_vencimiento, cantidad_inicial, id_estado_lote) VALUES
-- Lotes de Paracetamol (producto 1)
(1, 1, 1, 'PAR-2023-001', '2023-02-01', '2024-02-01', 5000, 4),  -- Vencido
(2, 1, 1, 'PAR-2023-002', '2023-03-15', '2024-03-15', 3000, 2),  -- Disponible
(3, 1, 2, 'PAR-2023-003', '2023-04-10', '2024-04-10', 4000, 2),  -- Disponible
(4, 1, 1, 'PAR-2023-004', '2023-05-20', '2024-05-20', 2500, 2),  -- Disponible
(5, 1, 1, 'PAR-2024-001', '2024-01-10', '2025-01-10', 6000, 2),  -- Disponible

-- Lotes de Amoxicilina (producto 2)
(6, 2, 1, 'AMX-2023-001', '2023-01-15', '2024-01-15', 3000, 4),  -- Vencido
(7, 2, 3, 'AMX-2023-002', '2023-06-01', '2024-06-01', 2500, 2),  -- Disponible
(8, 2, 1, 'AMX-2023-003', '2023-08-15', '2024-08-15', 2000, 2),  -- Disponible
(9, 2, 1, 'AMX-2024-001', '2024-01-20', '2025-01-20', 3500, 2),  -- Disponible

-- Lotes de Ibuprofeno (producto 3)
(10, 3, 2, 'IBU-2023-001', '2023-03-01', '2024-03-01', 4000, 2),  -- Disponible
(11, 3, 4, 'IBU-2023-002', '2023-07-10', '2024-07-10', 2000, 2),  -- Disponible
(12, 3, 2, 'IBU-2024-001', '2024-01-15', '2025-01-15', 5000, 2),  -- Disponible

-- Lotes de Enalapril (producto 4) - Lote defectuoso que generó la alerta de COFEPRIS
(13, 4, 2, 'ENA-2023-001', '2023-05-01', '2024-05-01', 2000, 5),  -- Retirado por COFEPRIS
(14, 4, 5, 'ENA-2023-002', '2023-09-15', '2024-09-15', 1500, 2),  -- Disponible

-- Lotes de Vacuna Influenza (producto 5) - requieren refrigeración
(15, 5, 4, 'VAC-2023-001', '2023-08-01', '2024-08-01', 800, 2),  -- Disponible

-- Lotes de Insulina Glargina (producto 6) - requieren refrigeración
(16, 6, 4, 'INS-2023-001', '2023-10-01', '2024-10-01', 500, 2);  -- Disponible


INSERT INTO Inventario (id_inventario, id_lote, id_ubicacion, cantidad_disponible, ultima_actualizacion) VALUES
-- Lote 1 (Paracetamol vencido) - aún en inventario porque nadie lo ha retirado físicamente
(1, 1, 1, 800, '2024-02-20 10:30:00'),

-- Lote 2 (Paracetamol disponible)
(2, 2, 2, 1200, '2024-02-15 09:00:00'),
(3, 2, 3, 800, '2024-02-18 14:20:00'),

-- Lote 3 (Paracetamol)
(4, 3, 5, 1800, '2024-02-10 11:00:00'),

-- Lote 4 (Paracetamol)
(5, 4, 1, 2500, '2024-01-05 08:30:00'),

-- Lote 5 (Paracetamol nuevo)
(6, 5, 2, 6000, '2024-02-01 10:00:00'),

-- Lote 6 (Amoxicilina vencido)
(7, 6, 6, 800, '2024-01-16 15:00:00'),

-- Lote 7 (Amoxicilina)
(8, 7, 7, 2500, '2024-01-20 09:30:00'),

-- Lote 8 (Amoxicilina)
(9, 8, 9, 2000, '2024-01-25 12:00:00'),

-- Lote 9 (Amoxicilina nuevo)
(10, 9, 6, 3500, '2024-02-05 08:00:00'),

-- Lote 10 (Ibuprofeno)
(11, 10, 10, 1500, '2024-01-10 10:00:00'),
(12, 10, 11, 2000, '2024-01-12 11:30:00'),

-- Lote 11 (Ibuprofeno)
(13, 11, 12, 2000, '2024-01-18 14:00:00'),

-- Lote 12 (Ibuprofeno nuevo)
(14, 12, 10, 5000, '2024-02-08 09:00:00'),

-- Lote 13 (Enalapril retirado COFEPRIS) - en cuarentena retirado
(15, 13, 8, 2000, '2024-02-20 08:00:00'),

-- Lote 14 (Enalapril)
(16, 14, 14, 1500, '2024-02-10 11:00:00'),

-- Lote 15 (Vacuna) - ubicación refrigerada
(17, 15, 4, 800, '2024-02-01 09:00:00'),

-- Lote 16 (Insulina) - ubicación refrigerada
(18, 16, 13, 500, '2024-02-05 10:00:00');



INSERT INTO OrdenCompra (id_orden_compra, id_proveedor, id_bodega, fecha_orden, fecha_entrega_esperada, id_estado_oc, total_estimado) VALUES
(1, 1, 1, '2024-01-05', '2024-01-15', 5, 27500.00),
(2, 1, 2, '2024-01-10', '2024-01-20', 5, 19000.00),
(3, 2, 3, '2024-01-15', '2024-01-25', 5, 21000.00),
(4, 4, 2, '2024-01-20', '2024-02-10', 5, 68000.00),
(5, 1, 1, '2024-02-01', '2024-02-10', 3, 15000.00);


INSERT INTO DetalleCompra (id_detalle_compra, id_orden_compra, id_producto, cantidad_ordenada, precio_unitario, cantidad_recibida) VALUES
(1, 1, 1, 5000, 3.80, 5000),
(2, 2, 2, 3000, 5.50, 3000),
(3, 3, 3, 4000, 4.20, 4000),
(4, 4, 5, 800, 85.00, 800),
(5, 4, 6, 500, 250.00, 500),
(6, 5, 1, 3000, 3.90, 0);


INSERT INTO Recepcion (id_recepcion, id_orden_compra, id_bodega, fecha_recepcion, responsable, numero_guia, id_estado_recepcion) VALUES
(1, 1, 1, '2024-01-16', 'Carlos Ruiz', 'GUI-001-2024', 3),
(2, 2, 2, '2024-01-21', 'Sofía Méndez', 'GUI-002-2024', 3),
(3, 3, 3, '2024-01-26', 'Alejandro Torres', 'GUI-003-2024', 3),
(4, 4, 2, '2024-02-12', 'Sofía Méndez', 'GUI-004-2024', 3);

INSERT INTO DetalleRecepcion (id_det_recepcion, id_recepcion, id_lote, id_ubicacion, cantidad_recibida, id_condicion) VALUES
(1, 1, 2, 2, 1200, 1),
(2, 1, 2, 3, 800, 1),
(3, 1, 3, 5, 1800, 1),
(4, 1, 4, 1, 2500, 1),
(5, 2, 7, 7, 2500, 1),
(6, 2, 8, 9, 2000, 1),
(7, 3, 10, 10, 1500, 1),
(8, 3, 10, 11, 2000, 1),
(9, 3, 11, 12, 2000, 1),
(10, 4, 15, 4, 800, 1),
(11, 4, 16, 13, 500, 1);


INSERT INTO OrdenEnvio (id_orden_envio, id_cliente, id_bodega, fecha_pedido, fecha_requerida, fecha_despacho, id_estado_oe, total_venta) VALUES
(1, 1, 1, '2024-02-10', '2024-02-15', '2024-02-14', 4, 5500.00),
(2, 2, 1, '2024-02-12', '2024-02-18', '2024-02-17', 4, 8200.00),
(3, 3, 2, '2024-02-13', '2024-02-20', '2024-02-19', 4, 6750.00),
(4, 4, 3, '2024-02-14', '2024-02-21', NULL, 2, 4300.00),
(5, 5, 3, '2024-02-15', '2024-02-22', NULL, 1, 12000.00),
(6, 1, 2, '2024-02-16', '2024-02-23', NULL, 1, 3500.00);


INSERT INTO DetalleEnvio (id_detalle_envio, id_orden_envio, id_lote, id_ubicacion, cantidad_despachada, precio_unitario_venta) VALUES
-- Pedido 1: Farmacias del Sureste (desde GDL)
(1, 1, 2, 2, 500, 5.50),
(2, 1, 3, 5, 500, 5.50),

-- Pedido 2: Hospital General de Occidente (desde GDL)
(3, 2, 2, 3, 800, 8.20),
(4, 2, 1, 1, 200, 8.20),  -- Este es lote vencido (id_lote=1) -> debería haber sido rechazado por el trigger

-- Pedido 3: Farmacia Santa Fe (desde CDMX)
(5, 3, 10, 10, 600, 6.75),
(6, 3, 11, 12, 400, 6.75),

-- Pedido 4: Clínica del Norte (desde MTY) - aún no despachado
(7, 4, 14, 14, 500, 4.30),

-- Pedido 5: Farmacias Similares Norte (desde MTY) - pendiente
(8, 5, 12, 10, 1000, 6.75),
(9, 5, 9, 6, 800, 8.20),

-- Pedido 6: Farmacias del Sureste (desde CDMX) - pendiente
(10, 6, 7, 7, 400, 5.50);


INSERT INTO EnvioTransporte (id_envio_transporte, id_orden_envio, id_transporte, fecha_salida, fecha_entrega_real, evidencia_entrega, id_estado_transporte) VALUES
(1, 1, 2, '2024-02-14', '2024-02-15', 'Firma digital - Recibido por Luis Fernández', 2),
(2, 2, 1, '2024-02-17', '2024-02-18', 'Firma digital - Recibido por Dra. Martha Ríos', 2),
(3, 3, 3, '2024-02-19', '2024-02-20', 'Firma digital - Recibido por Miguel Ángel Soto', 2);


INSERT INTO CostoOperacion (id_costo, id_bodega, id_lote, id_tipo_costo, monto, fecha, descripcion) VALUES
-- Merma por vencimiento (costo tipo 3)
(1, 1, 1, 3, 4500.00, '2024-02-20', 'Desecho de lote PAR-2023-001 por vencimiento - 800 unidades'),
(2, 3, 6, 3, 8000.00, '2024-01-16', 'Desecho de lote AMX-2023-001 por vencimiento - 800 unidades'),

-- Costos de transporte
(3, 1, NULL, 2, 1200.00, '2024-02-14', 'Flete pedido 1 a Farmacias del Sureste'),
(4, 2, NULL, 2, 1500.00, '2024-02-19', 'Flete pedido 3 a Farmacia Santa Fe'),

-- Costos de horas extra
(5, 1, NULL, 6, 800.00, '2024-02-17', 'Horas extra por pedido urgente Hospital Occidental'),

-- Costo por retiro COFEPRIS
(6, 2, 13, 3, 5000.00, '2024-02-20', 'Retiro de lote ENA-2023-001 por alerta sanitaria'),

-- Costo de reempaque
(7, 2, NULL, 4, 350.00, '2024-02-18', 'Reempaque de producto dañado en recepción');

INSERT INTO AlertaVencimiento (id_alerta, id_lote, id_bodega, dias_para_vencer, fecha_alerta, id_nivel, resuelta) VALUES
(1, 1, 1, 20, '2024-01-12', 1, 1),  -- Alerta a 30 días, resuelta (no se pudo despachar a tiempo)
(2, 1, 1, 8, '2024-01-24', 3, 1),  -- Alerta a 7 días, resuelta (no se pudo evitar vencimiento)
(3, 6, 2, 25, '2023-12-22', 1, 1),  -- Alerta a 30 días del lote de amoxicilina
(4, 6, 2, 10, '2024-01-06', 3, 1),  -- Alerta a 7 días
(5, 7, 2, 15, '2024-01-06', 2, 0),  -- Alerta activa para lote AMX-2023-002
(6, 8, 2, 28, '2024-01-18', 1, 0),  -- Alerta a 30 días para lote AMX-2023-003
(7, 10, 3, 28, '2024-02-02', 1, 0), -- Alerta a 30 días para lote IBU-2023-001
(8, 11, 3, 40, '2024-02-01', 1, 0), -- Alerta a 30 días (aunque faltan 40, el trigger lo insertó igual)
(9, 13, 2, 30, '2024-01-20', 1, 1), -- Alerta del lote retirado por COFEPRIS
(10, 15, 2, 60, '2024-02-01', 1, 0); -- Alerta vacuna


INSERT INTO HistorialTrazabilidad (id_historial, id_lote, id_orden_envio, id_recepcion, id_ubicacion, id_tipo_movimiento, cantidad, fecha_movimiento, usuario, observaciones) VALUES
-- Recepciones
(1, 2, NULL, 1, 2, 1, 1200, '2024-01-16 10:30:00', 'Carlos Ruiz', 'Recepción orden OC-1'),
(2, 2, NULL, 1, 3, 1, 800, '2024-01-16 10:35:00', 'Carlos Ruiz', 'Recepción orden OC-1'),
(3, 3, NULL, 1, 5, 1, 1800, '2024-01-16 10:40:00', 'Carlos Ruiz', 'Recepción orden OC-1'),
(4, 4, NULL, 1, 1, 1, 2500, '2024-01-16 10:45:00', 'Carlos Ruiz', 'Recepción orden OC-1'),
(5, 7, NULL, 2, 7, 1, 2500, '2024-01-21 09:00:00', 'Sofía Méndez', 'Recepción orden OC-2'),
(6, 8, NULL, 2, 9, 1, 2000, '2024-01-21 09:15:00', 'Sofía Méndez', 'Recepción orden OC-2'),
(7, 10, NULL, 3, 10, 1, 1500, '2024-01-26 11:00:00', 'Alejandro Torres', 'Recepción orden OC-3'),
(8, 10, NULL, 3, 11, 1, 2000, '2024-01-26 11:05:00', 'Alejandro Torres', 'Recepción orden OC-3'),
(9, 11, NULL, 3, 12, 1, 2000, '2024-01-26 11:10:00', 'Alejandro Torres', 'Recepción orden OC-3'),
(10, 15, NULL, 4, 4, 1, 800, '2024-02-12 10:00:00', 'Sofía Méndez', 'Recepción vacunas'),
(11, 16, NULL, 4, 13, 1, 500, '2024-02-12 10:20:00', 'Sofía Méndez', 'Recepción insulinas'),

-- Despachos
(12, 2, 1, NULL, 2, 4, 500, '2024-02-14 08:00:00', 'Carlos Ruiz', 'Despacho pedido 1'),
(13, 3, 1, NULL, 5, 4, 500, '2024-02-14 08:05:00', 'Carlos Ruiz', 'Despacho pedido 1'),
(14, 2, 2, NULL, 3, 4, 800, '2024-02-17 09:00:00', 'Carlos Ruiz', 'Despacho pedido 2'),
(15, 1, 2, NULL, 1, 4, 200, '2024-02-17 09:10:00', 'Carlos Ruiz', 'ADVERTENCIA: Lote vencido - El sistema debería haberlo evitado pero se registró manualmente para reflejar el error histórico'),
(16, 10, 3, NULL, 10, 4, 600, '2024-02-19 10:00:00', 'Sofía Méndez', 'Despacho pedido 3'),
(17, 11, 3, NULL, 12, 4, 400, '2024-02-19 10:05:00', 'Sofía Méndez', 'Despacho pedido 3'),

-- Traslados internos (el caso de las 600 unidades perdidas en GDL)
(18, 2, NULL, NULL, 2, 2, 600, '2024-02-10 22:30:00', 'Javier López', 'Traslado de ubicación A-01-02 a B-02-01 - NO REGISTRADO EN SISTEMA (error histórico)'),

-- Ajuste por inventario (merma)
(19, 1, NULL, NULL, 1, 6, 800, '2024-02-20 14:00:00', 'Patricia Núñez', 'Ajuste por vencimiento - Lote dado de baja'),
(20, 6, NULL, NULL, 6, 6, 800, '2024-01-16 12:00:00', 'Patricia Núñez', 'Ajuste por vencimiento - Lote dado de baja'),

-- Retiro COFEPRIS
(21, 13, NULL, NULL, 8, 7, 2000, '2024-02-20 09:00:00', 'Patricia Núñez', 'Retiro de lote por alerta sanitaria COFEPRIS');


-- Actualizar estado del lote vencido (id_lote=1) a Vencido (4)
UPDATE Lote SET id_estado_lote = 4 WHERE id_lote = 1;

-- Actualizar estado del lote vencido (id_lote=6) a Vencido (4)
UPDATE Lote SET id_estado_lote = 4 WHERE id_lote = 6;

-- Actualizar estado del lote retirado por COFEPRIS (id_lote=13) a Retirado (5)
UPDATE Lote SET id_estado_lote = 5 WHERE id_lote = 13;

-- Actualizar estado del lote que estaba en cuarentena a Disponible (2)
UPDATE Lote SET id_estado_lote = 2 WHERE id_lote IN (2,3,4,5,7,8,9,10,11,12,14,15,16);


-- Lote de Paracetamol que vence en 25 días (alerta nivel 1)
INSERT INTO Lote (id_lote, id_producto, id_proveedor, numero_lote, fecha_fabricacion, fecha_vencimiento, cantidad_inicial, id_estado_lote) VALUES
(17, 1, 1, 'PAR-2024-002', '2024-01-15', DATE_ADD(CURDATE(), INTERVAL 25 DAY), 5000, 2);

-- Lote de Paracetamol que vence en 12 días (alerta nivel 2)
INSERT INTO Lote (id_lote, id_producto, id_proveedor, numero_lote, fecha_fabricacion, fecha_vencimiento, cantidad_inicial, id_estado_lote) VALUES
(18, 1, 2, 'PAR-2024-003', '2024-02-01', DATE_ADD(CURDATE(), INTERVAL 12 DAY), 3000, 2);

-- Lote de Amoxicilina que vence en 5 días (alerta nivel 3)
INSERT INTO Lote (id_lote, id_producto, id_proveedor, numero_lote, fecha_fabricacion, fecha_vencimiento, cantidad_inicial, id_estado_lote) VALUES
(19, 2, 1, 'AMX-2024-002', '2024-03-10', DATE_ADD(CURDATE(), INTERVAL 5 DAY), 2000, 2);

-- Lote de Ibuprofeno que vence en 8 días (alerta nivel 3)
INSERT INTO Lote (id_lote, id_producto, id_proveedor, numero_lote, fecha_fabricacion, fecha_vencimiento, cantidad_inicial, id_estado_lote) VALUES
(20, 3, 2, 'IBU-2024-002', '2024-03-15', DATE_ADD(CURDATE(), INTERVAL 8 DAY), 4000, 2);

-- Lote de Enalapril que vence en 20 días (alerta nivel 1)
INSERT INTO Lote (id_lote, id_producto, id_proveedor, numero_lote, fecha_fabricacion, fecha_vencimiento, cantidad_inicial, id_estado_lote) VALUES
(21, 4, 2, 'ENA-2024-001', '2024-04-01', DATE_ADD(CURDATE(), INTERVAL 20 DAY), 1500, 2);

-- Lote de Vacuna que vence en 45 días (sin alerta aún - más de 30 días)
INSERT INTO Lote (id_lote, id_producto, id_proveedor, numero_lote, fecha_fabricacion, fecha_vencimiento, cantidad_inicial, id_estado_lote) VALUES
(22, 5, 4, 'VAC-2024-001', '2024-02-01', DATE_ADD(CURDATE(), INTERVAL 45 DAY), 1000, 2);



INSERT INTO Inventario (id_inventario, id_lote, id_ubicacion, cantidad_disponible, ultima_actualizacion) VALUES
(19, 17, 2, 5000, NOW()),
(20, 18, 5, 3000, NOW()),
(21, 19, 7, 2000, NOW()),
(22, 20, 10, 4000, NOW()),
(23, 21, 14, 1500, NOW()),
(24, 22, 4, 1000, NOW());


-- Alertas activas para los lotes próximos a vencer
INSERT INTO AlertaVencimiento (id_alerta, id_lote, id_bodega, dias_para_vencer, fecha_alerta, id_nivel, resuelta) VALUES
(11, 17, 1, 25, CURDATE(), 1, 0),
(12, 18, 1, 12, CURDATE(), 2, 0),
(13, 19, 2, 5, CURDATE(), 3, 0),
(14, 20, 3, 8, CURDATE(), 3, 0),
(15, 21, 3, 20, CURDATE(), 1, 0);

-- Alerta para un lote que ya venció (resuelta como pérdida)
INSERT INTO AlertaVencimiento (id_alerta, id_lote, id_bodega, dias_para_vencer, fecha_alerta, id_nivel, resuelta) VALUES
(16, 1, 1, 30, '2024-01-12', 1, 1),
(17, 1, 1, 7, '2024-01-24', 3, 1),
(18, 6, 2, 30, '2023-12-22', 1, 1);


-- Asegurar que el lote 1 tenga trazabilidad completa con todos los campos NO NULL
INSERT INTO HistorialTrazabilidad (id_historial, id_lote, id_orden_envio, id_recepcion, id_ubicacion, id_tipo_movimiento, cantidad, fecha_movimiento, usuario, observaciones) VALUES
-- Recepción del lote 1 (sin orden_envio, sin ubicación aún)
(22, 1, NULL, 1, NULL, 1, 5000, '2023-02-05 10:00:00', 'Carlos Ruiz', 'Recepción inicial del lote PAR-2023-001'),

-- Ubicación del lote 1 en inventario
(23, 1, NULL, NULL, 1, 2, 5000, '2023-02-05 10:30:00', 'Carlos Ruiz', 'Almacenado en ubicación A-01-01'),

-- Despacho parcial del lote 1 (con orden_envio y cliente)
(24, 1, 2, NULL, 1, 4, 200, '2024-02-17 09:10:00', 'Carlos Ruiz', 'ERROR HISTÓRICO: Despacho de lote vencido - Cliente Hospital Occidental'),

-- Ajuste por vencimiento (merma)
(25, 1, NULL, NULL, 1, 6, 800, '2024-02-20 14:00:00', 'Patricia Núñez', 'Lote dado de baja por vencimiento');


-- Trazabilidad completa para lote 13 (retirado COFEPRIS) - otro ejemplo
INSERT INTO HistorialTrazabilidad (id_historial, id_lote, id_orden_envio, id_recepcion, id_ubicacion, id_tipo_movimiento, cantidad, fecha_movimiento, usuario, observaciones) VALUES
(26, 13, NULL, 3, NULL, 1, 2000, '2023-05-10 11:00:00', 'Alejandro Torres', 'Recepción del lote ENA-2023-001'),
(27, 13, NULL, NULL, 8, 2, 2000, '2023-05-10 11:30:00', 'Alejandro Torres', 'Almacenado en ubicación C-02-01'),
(28, 13, NULL, NULL, NULL, 7, 2000, '2024-02-20 09:00:00', 'Patricia Núñez', 'RETIRO COFEPRIS - Lote defectuoso, no se despachó a ningún cliente');



-- Lotes con fecha pasada deben estar Vencidos (id_estado_lote = 4)
UPDATE Lote SET id_estado_lote = 4 
WHERE fecha_vencimiento < CURDATE() AND id_estado_lote = 2;

-- Lote 13 (retirado COFEPRIS) debe estar Retirado (5)
UPDATE Lote SET id_estado_lote = 5 WHERE id_lote = 13;


-- 6. TRIGGERS


DELIMITER $$

-- TRIGGER 1: Actualizar inventario cuando se recibe un lote
CREATE TRIGGER actualizar_inventario_recepcion
AFTER INSERT ON DetalleRecepcion
FOR EACH ROW
BEGIN
    DECLARE existe INT;
    
    -- Verificar si ya existe el lote en esa ubicación
    SELECT COUNT(*) INTO existe FROM Inventario 
    WHERE id_lote = NEW.id_lote AND id_ubicacion = NEW.id_ubicacion;
    
    IF existe > 0 THEN
        UPDATE Inventario 
        SET cantidad_disponible = cantidad_disponible + NEW.cantidad_recibida,
            ultima_actualizacion = NOW()
        WHERE id_lote = NEW.id_lote AND id_ubicacion = NEW.id_ubicacion;
    ELSE
        INSERT INTO Inventario (id_lote, id_ubicacion, cantidad_disponible, ultima_actualizacion)
        VALUES (NEW.id_lote, NEW.id_ubicacion, NEW.cantidad_recibida, NOW());
    END IF;
    
    -- Cambiar estado del lote a Disponible si estaba en Cuarentena
    UPDATE Lote SET id_estado_lote = 2 
    WHERE id_lote = NEW.id_lote AND id_estado_lote = 1;
    
    -- Registrar en historial
    INSERT INTO HistorialTrazabilidad (id_lote, id_recepcion, id_ubicacion, id_tipo_movimiento, cantidad, fecha_movimiento, usuario)
    VALUES (NEW.id_lote, NEW.id_recepcion, NEW.id_ubicacion, 1, NEW.cantidad_recibida, NOW(), 'sistema');
END$$

-- TRIGGER 2: Verificar stock y FEFO antes de despachar
CREATE TRIGGER verificar_despacho
BEFORE INSERT ON DetalleEnvio
FOR EACH ROW
BEGIN
    DECLARE stock_actual INT;
    DECLARE fecha_venc DATE;
    DECLARE producto_id INT;
    DECLARE lote_fefo INT;
    
    -- Obtener stock actual
    SELECT cantidad_disponible INTO stock_actual FROM Inventario 
    WHERE id_lote = NEW.id_lote AND id_ubicacion = NEW.id_ubicacion;
    
    -- Si no hay suficiente stock, cancelar
    IF stock_actual < NEW.cantidad_despachada THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR: Stock insuficiente';
    END IF;
    
    -- Obtener fecha de vencimiento del lote
    SELECT fecha_vencimiento, id_producto INTO fecha_venc, producto_id 
    FROM Lote WHERE id_lote = NEW.id_lote;
    
    -- Verificar si el lote está vencido
    IF fecha_venc < CURDATE() THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'ERROR: No se puede despachar lote vencido';
    END IF;
    
    -- Buscar el lote más viejo (FEFO) para este producto
    SELECT l.id_lote INTO lote_fefo
    FROM Lote l
    JOIN Inventario i ON l.id_lote = i.id_lote
    WHERE l.id_producto = producto_id 
      AND l.id_estado_lote = 2
      AND l.fecha_vencimiento >= CURDATE()
      AND i.cantidad_disponible >= NEW.cantidad_despachada
    ORDER BY l.fecha_vencimiento ASC
    LIMIT 1;
    
    -- Si no se está usando el lote más viejo, registrar advertencia
    IF lote_fefo IS NOT NULL AND lote_fefo != NEW.id_lote THEN
        INSERT INTO HistorialTrazabilidad (id_lote, id_orden_envio, id_ubicacion, id_tipo_movimiento, cantidad, fecha_movimiento, usuario, observaciones)
        VALUES (NEW.id_lote, NEW.id_orden_envio, NEW.id_ubicacion, 4, NEW.cantidad_despachada, NOW(), 'sistema',
                CONCAT('ADVERTENCIA: Se usó lote que NO es el más viejo. El lote correcto era: ', lote_fefo));
    END IF;
END$$

-- TRIGGER 3: Descontar inventario después del despacho
CREATE TRIGGER descontar_inventario_despacho
AFTER INSERT ON DetalleEnvio
FOR EACH ROW
BEGIN
    DECLARE stock_restante INT;
    
    -- Descontar del inventario
    UPDATE Inventario 
    SET cantidad_disponible = cantidad_disponible - NEW.cantidad_despachada,
        ultima_actualizacion = NOW()
    WHERE id_lote = NEW.id_lote AND id_ubicacion = NEW.id_ubicacion;
    
    -- Verificar stock restante del lote
    SELECT SUM(cantidad_disponible) INTO stock_restante FROM Inventario 
    WHERE id_lote = NEW.id_lote;
    
    -- Si el lote se quedó sin stock, marcarlo como Agotado
    IF stock_restante = 0 THEN
        UPDATE Lote SET id_estado_lote = 3 WHERE id_lote = NEW.id_lote;
    END IF;
    
    -- Registrar en historial
    INSERT INTO HistorialTrazabilidad (id_lote, id_orden_envio, id_ubicacion, id_tipo_movimiento, cantidad, fecha_movimiento, usuario)
    VALUES (NEW.id_lote, NEW.id_orden_envio, NEW.id_ubicacion, 4, NEW.cantidad_despachada, NOW(), 'sistema');
END$$

-- TRIGGER 4: Generar alerta de vencimiento
CREATE TRIGGER generar_alerta_vencimiento
AFTER INSERT ON Lote
FOR EACH ROW
BEGIN
    DECLARE dias INT;
    DECLARE nivel_id INT;
    DECLARE bodega_id INT;
    
    SET dias = DATEDIFF(NEW.fecha_vencimiento, CURDATE());
    
    -- Determinar nivel de alerta
    IF dias <= 30 AND dias > 15 THEN
        SET nivel_id = 1;
    ELSEIF dias <= 15 AND dias > 7 THEN
        SET nivel_id = 2;
    ELSEIF dias <= 7 AND dias >= 0 THEN
        SET nivel_id = 3;
    ELSE
        SET nivel_id = NULL;
    END IF;
    
    -- Si hay alerta, insertar para la primera bodega activa
    IF nivel_id IS NOT NULL THEN
        SELECT id_bodega INTO bodega_id FROM Bodega WHERE activa = 1 LIMIT 1;
        
        INSERT INTO AlertaVencimiento (id_lote, id_bodega, dias_para_vencer, fecha_alerta, id_nivel, resuelta)
        VALUES (NEW.id_lote, bodega_id, dias, CURDATE(), nivel_id, 0);
    END IF;
END$$

DELIMITER ;


-- 7. CONSULTAS 


-- Consulta 1: Ingresos totales por mes (ventas a clientes)

SELECT 
    YEAR(oe.fecha_pedido) AS año,
    MONTH(oe.fecha_pedido) AS mes,
    SUM(de.cantidad_despachada * de.precio_unitario_venta) AS ingresos_totales,
    COUNT(DISTINCT oe.id_orden_envio) AS numero_pedidos
FROM OrdenEnvio oe, DetalleEnvio de
WHERE oe.id_orden_envio = de.id_orden_envio
  AND (oe.id_estado_oe = 3 OR oe.id_estado_oe = 4)
GROUP BY YEAR(oe.fecha_pedido), MONTH(oe.fecha_pedido)
ORDER BY año DESC, mes DESC;


-- Consulta 2: Gastos totales por mes (costos operativos)

SELECT 
    YEAR(co.fecha) AS año,
    MONTH(co.fecha) AS mes,
    SUM(co.monto) AS gastos_totales,
    tc.nombre AS tipo_gasto
FROM CostoOperacion co, TipoCosto tc
WHERE co.id_tipo_costo = tc.id_tipo_costo
GROUP BY YEAR(co.fecha), MONTH(co.fecha), tc.nombre
ORDER BY año DESC, mes DESC, tc.nombre;



-- Consulta 3: Ganancias netas por mes (ingresos - gastos)

SELECT 
    i.año,
    i.mes,
    i.ingresos,
    g.gastos,
    (i.ingresos - g.gastos) AS ganancia_neta
FROM (
    SELECT 
        YEAR(oe.fecha_pedido) AS año,
        MONTH(oe.fecha_pedido) AS mes,
        SUM(de.cantidad_despachada * de.precio_unitario_venta) AS ingresos
    FROM OrdenEnvio oe, DetalleEnvio de
    WHERE oe.id_orden_envio = de.id_orden_envio
      AND (oe.id_estado_oe = 3 OR oe.id_estado_oe = 4)
    GROUP BY YEAR(oe.fecha_pedido), MONTH(oe.fecha_pedido)
) AS i,
(
    SELECT 
        YEAR(co.fecha) AS año,
        MONTH(co.fecha) AS mes,
        SUM(co.monto) AS gastos
    FROM CostoOperacion co
    GROUP BY YEAR(co.fecha), MONTH(co.fecha)
) AS g
WHERE i.año = g.año AND i.mes = g.mes
ORDER BY i.año DESC, i.mes DESC;



-- Consulta 4: Utilidad por orden de envío (ingreso - costo del lote)

SELECT 
    oe.id_orden_envio,
    c.nombre AS cliente,
    oe.fecha_pedido,
    SUM(de.cantidad_despachada * de.precio_unitario_venta) AS ingreso_venta,
    SUM(de.cantidad_despachada * pp.precio_compra) AS costo_compra,
    SUM(de.cantidad_despachada * de.precio_unitario_venta) - SUM(de.cantidad_despachada * pp.precio_compra) AS utilidad_bruta
FROM OrdenEnvio oe, Cliente c, DetalleEnvio de, Lote l, ProveedorProducto pp
WHERE oe.id_cliente = c.id_cliente
  AND oe.id_orden_envio = de.id_orden_envio
  AND de.id_lote = l.id_lote
  AND l.id_producto = pp.id_producto
  AND l.id_proveedor = pp.id_proveedor
  AND (oe.id_estado_oe = 3 OR oe.id_estado_oe = 4)
GROUP BY oe.id_orden_envio, c.nombre, oe.fecha_pedido
ORDER BY utilidad_bruta DESC;



-- Consulta 5: Lotes próximos a vencer (alerta 30 días o menos)

SELECT 
    p.nombre AS producto,
    l.numero_lote,
    l.fecha_vencimiento,
    DATEDIFF(l.fecha_vencimiento, CURDATE()) AS dias_restantes,
    SUM(i.cantidad_disponible) AS stock_total,
    b.nombre AS bodega
FROM Lote l
INNER JOIN Producto p ON l.id_producto = p.id_producto
INNER JOIN Inventario i ON l.id_lote = i.id_lote
INNER JOIN Ubicacion u ON i.id_ubicacion = u.id_ubicacion
INNER JOIN Bodega b ON u.id_bodega = b.id_bodega
WHERE l.fecha_vencimiento >= CURDATE()
  AND l.fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
  AND l.id_estado_lote = 2
GROUP BY l.id_lote, b.id_bodega
ORDER BY l.fecha_vencimiento ASC;



-- Consulta 6: Trazabilidad completa de un lote específico (ejemplo id_lote = 1)

SELECT 
    ht.id_historial,
    tm.nombre AS tipo_movimiento,
    ht.cantidad,
    ht.fecha_movimiento,
    ht.usuario,
    ht.observaciones,
    oe.id_orden_envio AS pedido_asociado,
    c.nombre AS cliente_destino,
    r.id_recepcion AS recepcion_asociada
FROM HistorialTrazabilidad ht
INNER JOIN TipoMovimiento tm ON ht.id_tipo_movimiento = tm.id_tipo_movimiento
LEFT JOIN OrdenEnvio oe ON ht.id_orden_envio = oe.id_orden_envio
LEFT JOIN Cliente c ON oe.id_cliente = c.id_cliente
LEFT JOIN Recepcion r ON ht.id_recepcion = r.id_recepcion
WHERE ht.id_lote = 1
ORDER BY ht.fecha_movimiento ASC;


-- Consulta 7: Productos más vendidos (volumen y valor)

SELECT 
    p.nombre AS producto,
    p.registro_sanitario,
    SUM(de.cantidad_despachada) AS unidades_vendidas,
    COUNT(DISTINCT de.id_orden_envio) AS numero_pedidos,
    SUM(de.cantidad_despachada * de.precio_unitario_venta) AS ingresos_totales
FROM DetalleEnvio de, Lote l, Producto p
WHERE de.id_lote = l.id_lote
  AND l.id_producto = p.id_producto
GROUP BY p.id_producto, p.nombre, p.registro_sanitario
ORDER BY ingresos_totales DESC;


-- Consulta 8: Merma por vencimiento (costos acumulados por producto)

SELECT 
    p.nombre AS producto,
    COUNT(l.id_lote) AS lotes_vencidos,
    SUM(i.cantidad_disponible) AS unidades_mermadas,
    SUM(co.monto) AS costo_merma_registrado
FROM Lote l, Producto p, Inventario i, CostoOperacion co
WHERE l.id_producto = p.id_producto
  AND l.id_lote = i.id_lote
  AND l.id_lote = co.id_lote
  AND co.id_tipo_costo = 3
  AND l.id_estado_lote = 4
GROUP BY p.id_producto
ORDER BY unidades_mermadas DESC;


-- Consulta 9: Rotación de inventario por producto (veces que se vendió el stock)

SELECT 
    p.nombre AS producto,
    (SELECT SUM(de2.cantidad_despachada)
     FROM DetalleEnvio de2, Lote l2
     WHERE de2.id_lote = l2.id_lote
       AND l2.id_producto = p.id_producto) AS unidades_vendidas,
    (SELECT SUM(i2.cantidad_disponible)
     FROM Inventario i2, Lote l2
     WHERE i2.id_lote = l2.id_lote
       AND l2.id_producto = p.id_producto
       AND l2.id_estado_lote = 2) AS stock_actual
FROM Producto p
WHERE (SELECT SUM(i2.cantidad_disponible)
       FROM Inventario i2, Lote l2
       WHERE i2.id_lote = l2.id_lote
         AND l2.id_producto = p.id_producto
         AND l2.id_estado_lote = 2) > 0
ORDER BY (SELECT SUM(de2.cantidad_despachada)
          FROM DetalleEnvio de2, Lote l2
          WHERE de2.id_lote = l2.id_lote
            AND l2.id_producto = p.id_producto) DESC;



-- Consulta 10: Alertas activas de vencimiento no resueltas

SELECT 
    av.id_alerta,
    p.nombre AS producto,
    l.numero_lote,
    l.fecha_vencimiento,
    av.dias_para_vencer,
    nl.nombre AS nivel_alerta,
    av.fecha_alerta,
    b.nombre AS bodega,
    DATEDIFF(l.fecha_vencimiento, CURDATE()) AS dias_hoy
FROM AlertaVencimiento av
INNER JOIN Lote l ON av.id_lote = l.id_lote
INNER JOIN Producto p ON l.id_producto = p.id_producto
INNER JOIN NivelAlerta nl ON av.id_nivel = nl.id_nivel
INNER JOIN Bodega b ON av.id_bodega = b.id_bodega
WHERE av.resuelta = 0
ORDER BY av.dias_para_vencer ASC;




