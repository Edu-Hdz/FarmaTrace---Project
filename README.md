# 💊 FarmaTrace – Pharmaceutical Supply Chain Database

![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql)
![Status](https://img.shields.io/badge/status-complete-brightgreen)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## 📌 Project Overview

**FarmaTrace** is a MySQL database system designed for a pharmaceutical distribution company. The company was losing **$45,000 USD per year** because:
- ❌ Expired medications were being thrown away
- ❌ Nobody knew where products were stored
- ❌ When a bad batch was recalled, it took 14 days to find affected clients

This project solves those problems with a relational database that tracks **every lot from purchase to final client**.

---

## 🎯 What Problems Does This Solve?

| Problem | Before | After |
|---------|--------|-------|
| **Expired products** | Operators shipped newer lots first. Old lots expired. | System applies **FEFO** (First Expired, First Out) automatically |
| **Lost inventory** | Products moved between locations without updating records | Real-time tracking by **warehouse, aisle, rack, level** |
| **No traceability** | 14 days to find which clients got a bad lot | Less than **1 second** to see full lot history |
| **No expiration alerts** | Nobody checked expiration dates manually | Automatic alerts at **30, 15, and 7 days** |

---

## 🏗️ Database Design

### Key Tables (16 total)

| Table | Description |
|-------|-------------|
| `Proveedor` | Suppliers (LabPharma, Laboratorios Nacionales, etc.) |
| `Producto` | Medications (Paracetamol, Amoxicilina, vaccines, insulin) |
| `Lote` | Each batch with expiration date and unique lot number |
| `Bodega` | Warehouses (Guadalajara, CDMX, Monterrey) |
| `Ubicacion` | Physical location: aisle, rack, level |
| `Inventario` | Links lot + location + available quantity |
| `OrdenCompra` | Purchase orders to suppliers |
| `Recepcion` | Receiving records with quality inspection |
| `OrdenEnvio` | Customer orders |
| `DetalleEnvio` | Which lot and how many units were shipped |
| `HistorialTrazabilidad` | Every movement (receipt, transfer, shipment, adjustment) |
| `AlertaVencimiento` | Expiration alerts (30, 15, 7 days) |
| `CostoOperacion` | Operational costs (transport, overtime, merma, returns) |

---

## ⚙️ Key Features

### 1. FEFO Automation (First Expired, First Out)

When a shipment is created, the system automatically checks which lot expires first and warns if another lot is chosen.


```sql
-- Trigger: verificar_despacho
-- Before inserting a shipment detail, this trigger:
-- 1. Checks if there is enough stock
-- 2. Checks if the lot is expired (rejects if yes)
-- 3. Finds the oldest lot for that product
-- 4. Warns if the selected lot is not the oldest
```

## 2. Real-Time Inventory Updates

Every time products are received or shipped, the inventory updates automatically using triggers.

### How it works:

| Event | Trigger | Action |
|-------|---------|--------|
| New products arrive | `actualizar_inventario_recepcion` (AFTER INSERT on DetalleRecepcion) | Adds stock to the correct location. If the lot is new, creates an inventory record. If it already exists, updates the quantity. |
| Products are shipped | `descontar_inventario_despacho` (AFTER INSERT on DetalleEnvio) | Subtracts stock from the location. If the lot reaches zero stock, changes status to "Agotado" (Out of stock). |

### Why this matters:

Before this system, when a worker moved products to a different shelf at night, nobody updated the records. The next morning, another worker could not find the products. Orders were delayed for hours.

Now, every movement is recorded immediately. The inventory always shows the **real** quantity in **real time**.

```sql
-- Example: When a shipment is registered, this trigger runs automatically
-- It subtracts the shipped quantity and updates the last update time
UPDATE Inventario 
SET cantidad_disponible = cantidad_disponible - NEW.cantidad_despachada,
    ultima_actualizacion = NOW()
WHERE id_lote = NEW.id_lote AND id_ubicacion = NEW.id_ubicacion;
```

## 3. Complete Lot Traceability

Every single movement of every lot is recorded in the `HistorialTrazabilidad` table. This table is **immutable** – once a record is inserted, it is never modified or deleted.

### What is recorded:

| Field | Description |
|-------|-------------|
| `id_lote` | Which lot moved |
| `id_tipo_movimiento` | Type of movement (Reception, Internal transfer, Picking, Shipment, Adjustment, Waste, COFEPRIS recall) |
| `cantidad` | How many units |
| `fecha_movimiento` | When it happened (date and time) |
| `usuario` | Who did it |
| `observaciones` | Optional notes |
| `id_orden_envio` | If it was a shipment, which customer order |
| `id_recepcion` | If it was a reception, which purchase order |
| `id_ubicacion` | Where it was stored |

### Why this matters:

COFEPRIS (the Mexican health authority) once issued a recall for a defective blood pressure medication. The company took **14 days** to find out which customers received the bad lot. They were fined $20,000 USD.

Now, with this traceability system, the same query takes **less than 1 second**.

```sql
-- Query to see the complete history of a specific lot (example: lot #1)
SELECT 
    ht.id_historial,
    tm.nombre AS tipo_movimiento,
    ht.cantidad,
    ht.fecha_movimiento,
    ht.usuario,
    ht.observaciones,
    oe.id_orden_envio AS pedido_asociado,
    c.nombre AS cliente_destino
FROM HistorialTrazabilidad ht
JOIN TipoMovimiento tm ON ht.id_tipo_movimiento = tm.id_tipo_movimiento
LEFT JOIN OrdenEnvio oe ON ht.id_orden_envio = oe.id_orden_envio
LEFT JOIN Cliente c ON oe.id_cliente = c.id_cliente
WHERE ht.id_lote = 1
ORDER BY ht.fecha_movimiento ASC;
```

## 4. Automatic Expiration Alerts

When a new lot is inserted into the database, a trigger automatically calculates how many days remain until expiration and creates an alert.

### Alert levels:

| Days remaining | Level | Color (conceptual) |
|----------------|-------|---------------------|
| 16 – 30 days | 1 (30 días) | 🟡 Warning |
| 8 – 15 days | 2 (15 días) | 🟠 Urgent |
| 0 – 7 days | 3 (7 días) | 🔴 Critical |

### How the trigger works:

```sql
-- This trigger runs AFTER a new lot is inserted
-- It calculates days until expiration and creates an alert record
SET dias = DATEDIFF(NEW.fecha_vencimiento, CURDATE());

IF dias <= 30 AND dias > 15 THEN
    SET nivel_id = 1;   -- 30 days alert
ELSEIF dias <= 15 AND dias > 7 THEN
    SET nivel_id = 2;   -- 15 days alert
ELSEIF dias <= 7 AND dias >= 0 THEN
    SET nivel_id = 3;   -- 7 days alert
END IF;

-- Then inserts into AlertaVencimiento table
INSERT INTO AlertaVencimiento (id_lote, id_bodega, dias_para_vencer, fecha_alerta, id_nivel, resuelta)
VALUES (NEW.id_lote, bodega_id, dias, CURDATE(), nivel_id, 0);
```

## 5. Cost Control by Operation

The `CostoOperacion` table records every operational cost and links it to a specific warehouse, lot, or order.

### Cost types (catalog):

| id_tipo_costo | Name | Example |
|---------------|------|---------|
| 1 | Almacenaje | Warehouse rent, electricity |
| 2 | Transporte | Freight, fuel |
| 3 | Merma | Expired or damaged products |
| 4 | Reempaque | Repackaging damaged boxes |
| 5 | Devolución | Return shipping from customers |
| 6 | Horas extra | Overtime pay for urgent orders |
| 7 | Otro | Miscellaneous |

### Table structure:

```sql
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
```

### Sample data:

```sql
INSERT INTO CostoOperacion (id_costo, id_bodega, id_lote, id_tipo_costo, monto, fecha, descripcion) VALUES
-- Waste from expired products (Merma)
(1, 1, 1, 3, 4500.00, '2024-02-20', 'Desecho de lote PAR-2023-001 por vencimiento - 800 unidades'),
(2, 3, 6, 3, 8000.00, '2024-01-16', 'Desecho de lote AMX-2023-001 por vencimiento - 800 unidades'),

-- Transportation costs
(3, 1, NULL, 2, 1200.00, '2024-02-14', 'Flete pedido 1 a Farmacias del Sureste'),
(4, 2, NULL, 2, 1500.00, '2024-02-19', 'Flete pedido 3 a Farmacia Santa Fe'),

-- Overtime pay
(5, 1, NULL, 6, 800.00, '2024-02-17', 'Horas extra por pedido urgente Hospital Occidental'),

-- COFEPRIS recall cost
(6, 2, 13, 3, 5000.00, '2024-02-20', 'Retiro de lote ENA-2023-001 por alerta sanitaria'),

-- Repackaging cost
(7, 2, NULL, 4, 350.00, '2024-02-18', 'Reempaque de producto dañado en recepción');
```

### Why this matters:

The finance department noticed that transportation costs increased 30% in one quarter, but nobody knew why. Costs were recorded in generic accounts without any link to orders or warehouses.

Now, when a freight invoice arrives, it is registered with the warehouse that originated it. Managers can see exactly which warehouse, which product, or which order generated each cost.

### Key queries:

```sql
-- Query 1: Total expenses by month and type
SELECT 
    YEAR(fecha) AS año,
    MONTH(fecha) AS mes,
    SUM(monto) AS gastos_totales,
    tc.nombre AS tipo_gasto
FROM CostoOperacion co
JOIN TipoCosto tc ON co.id_tipo_costo = tc.id_tipo_costo
GROUP BY YEAR(fecha), MONTH(fecha), tc.nombre
ORDER BY año DESC, mes DESC, tc.nombre;

-- Example output:
-- | año  | mes | gastos_totales | tipo_gasto   |
-- |------|-----|----------------|--------------|
-- | 2024 | 2   | 800.00         | Horas extra  |
-- | 2024 | 2   | 9500.00        | Merma        |
-- | 2024 | 2   | 350.00         | Reempaque    |
-- | 2024 | 2   | 2700.00        | Transporte   |
-- | 2024 | 1   | 8000.00        | Merma        |
```

```sql
-- Query 2: Waste (Merma) by product
SELECT 
    p.nombre AS producto,
    COUNT(l.id_lote) AS lotes_vencidos,
    SUM(i.cantidad_disponible) AS unidades_mermadas,
    SUM(co.monto) AS costo_merma_registrado
FROM Lote l
JOIN Producto p ON l.id_producto = p.id_producto
JOIN Inventario i ON l.id_lote = i.id_lote
JOIN CostoOperacion co ON l.id_lote = co.id_lote
WHERE co.id_tipo_costo = 3
  AND l.id_estado_lote = 4
GROUP BY p.id_producto
ORDER BY unidades_mermadas DESC;

-- Example output:
-- | producto             | lotes_vencidos | unidades_mermadas | costo_merma_registrado |
-- |----------------------|----------------|-------------------|------------------------|
-- | Paracetamol 500mg    | 1              | 800               | 4500.00                |
-- | Amoxicilina 250mg    | 1              | 800               | 8000.00                |
```

```sql
-- Query 3: Total expenses by warehouse
SELECT 
    b.nombre AS bodega,
    tc.nombre AS tipo_gasto,
    SUM(co.monto) AS total_gasto
FROM CostoOperacion co
JOIN Bodega b ON co.id_bodega = b.id_bodega
JOIN TipoCosto tc ON co.id_tipo_costo = tc.id_tipo_costo
GROUP BY b.id_bodega, tc.id_tipo_costo
ORDER BY b.nombre, total_gasto DESC;
```

### Benefits:

| Before | After |
|--------|-------|
| Costs recorded in generic accounts | Each cost linked to specific warehouse, lot, or order |
| Could not explain 30% transportation increase | Can see which warehouse generated each cost |
| No visibility into waste by product | Clear report of merma by product and lot |
| Manual tracking of overtime and repackaging | Automatic registration with descriptions |
```

