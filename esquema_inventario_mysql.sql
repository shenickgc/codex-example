-- Esquema básico indispensable para sistema de inventarios
-- Compatible con MySQL 8+ / MySQL Workbench

CREATE DATABASE IF NOT EXISTS inventario_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE inventario_db;

-- Limpieza opcional para re-importar el script sin errores
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS detalle_venta;
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS inventario;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS sucursales;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS usuario_roles;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE roles (
  id_rol INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion VARCHAR(255) NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE sucursales (
  id_sucursal INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  codigo VARCHAR(20) NOT NULL UNIQUE,
  direccion VARCHAR(255) NULL,
  telefono VARCHAR(20) NULL,
  correo VARCHAR(120) NULL,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE usuarios (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  id_sucursal INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  ultimo_acceso DATETIME NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_usuarios_sucursal
    FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
    ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Relación N:M para permitir múltiples roles por usuario
CREATE TABLE usuario_roles (
  id_usuario INT NOT NULL,
  id_rol INT NOT NULL,
  asignado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario, id_rol),
  CONSTRAINT fk_usuario_roles_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_usuario_roles_rol
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE categorias (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion VARCHAR(255) NULL,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE productos (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  id_categoria INT NULL,
  sku VARCHAR(50) NOT NULL UNIQUE,
  codigo_barras VARCHAR(64) NULL UNIQUE,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT NULL,
  unidad_medida VARCHAR(20) NOT NULL DEFAULT 'pieza',
  costo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  precio_venta DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_productos_categoria
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
    ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Existencia por sucursal
CREATE TABLE inventario (
  id_inventario BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_sucursal INT NOT NULL,
  id_producto INT NOT NULL,
  stock_actual DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  stock_minimo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  stock_maximo DECIMAL(12,2) NULL,
  ubicacion VARCHAR(80) NULL,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_inventario_sucursal_producto UNIQUE (id_sucursal, id_producto),
  CONSTRAINT fk_inventario_sucursal
    FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_inventario_producto
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE ventas (
  id_venta BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_sucursal INT NOT NULL,
  id_usuario INT NOT NULL,
  folio VARCHAR(30) NOT NULL UNIQUE,
  fecha_venta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  impuesto DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  descuento DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  metodo_pago ENUM('EFECTIVO','TARJETA','TRANSFERENCIA','MIXTO') NOT NULL DEFAULT 'EFECTIVO',
  estado ENUM('PAGADA','CANCELADA') NOT NULL DEFAULT 'PAGADA',
  notas VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ventas_sucursal
    FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_ventas_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE detalle_venta (
  id_detalle BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_venta BIGINT NOT NULL,
  id_producto INT NOT NULL,
  cantidad DECIMAL(12,2) NOT NULL,
  precio_unitario DECIMAL(12,2) NOT NULL,
  descuento_linea DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  impuesto_linea DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_linea DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_detalle_venta_venta
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_detalle_venta_producto
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE INDEX idx_usuarios_sucursal ON usuarios(id_sucursal);
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_inventario_producto ON inventario(id_producto);
CREATE INDEX idx_ventas_fecha ON ventas(fecha_venta);
CREATE INDEX idx_ventas_sucursal ON ventas(id_sucursal);
CREATE INDEX idx_detalle_venta_venta ON detalle_venta(id_venta);
CREATE INDEX idx_detalle_venta_producto ON detalle_venta(id_producto);

-- Datos base de ejemplo
INSERT INTO roles (nombre, descripcion) VALUES
  ('ADMIN', 'Acceso total al sistema'),
  ('CAJERO', 'Registra ventas'),
  ('ALMACEN', 'Gestiona inventario');

INSERT INTO sucursales (nombre, codigo, direccion) VALUES
  ('Sucursal Centro', 'CENTRO', 'Av. Principal 123');

INSERT INTO usuarios (id_sucursal, nombre, apellido, email, password_hash) VALUES
  (1, 'Usuario', 'Administrador', 'admin@inventario.local', 'CAMBIAR_POR_HASH_SEGURO');

INSERT INTO usuario_roles (id_usuario, id_rol)
SELECT 1, id_rol FROM roles WHERE nombre = 'ADMIN';

-- Stored Procedure para registrar detalle de venta y descontar inventario
-- Uso recomendado: insertar encabezado en `ventas` y luego cada partida con este SP.
DELIMITER $$
CREATE PROCEDURE sp_registrar_detalle_venta (
  IN p_id_venta BIGINT,
  IN p_id_producto INT,
  IN p_cantidad DECIMAL(12,2),
  IN p_precio_unitario DECIMAL(12,2),
  IN p_descuento_linea DECIMAL(12,2),
  IN p_impuesto_linea DECIMAL(12,2)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  DECLARE v_id_sucursal INT;
  DECLARE v_estado VARCHAR(10);
  DECLARE v_stock_actual DECIMAL(12,2);
  DECLARE v_total_linea DECIMAL(12,2);

  IF p_cantidad <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La cantidad debe ser mayor a cero';
  END IF;

  START TRANSACTION;

  SELECT id_sucursal, estado
    INTO v_id_sucursal, v_estado
  FROM ventas
  WHERE id_venta = p_id_venta
  FOR UPDATE;

  IF v_id_sucursal IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La venta no existe';
  END IF;

  IF v_estado <> 'PAGADA' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Solo se puede afectar inventario en ventas PAGADAS';
  END IF;

  SELECT stock_actual
    INTO v_stock_actual
  FROM inventario
  WHERE id_sucursal = v_id_sucursal
    AND id_producto = p_id_producto
  FOR UPDATE;

  IF v_stock_actual IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No existe registro de inventario para el producto en esta sucursal';
  END IF;

  IF v_stock_actual < p_cantidad THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Stock insuficiente para completar la venta';
  END IF;

  SET v_total_linea = (p_cantidad * p_precio_unitario) - p_descuento_linea + p_impuesto_linea;

  INSERT INTO detalle_venta (
    id_venta,
    id_producto,
    cantidad,
    precio_unitario,
    descuento_linea,
    impuesto_linea,
    total_linea
  ) VALUES (
    p_id_venta,
    p_id_producto,
    p_cantidad,
    p_precio_unitario,
    COALESCE(p_descuento_linea, 0.00),
    COALESCE(p_impuesto_linea, 0.00),
    v_total_linea
  );

  UPDATE inventario
  SET stock_actual = stock_actual - p_cantidad
  WHERE id_sucursal = v_id_sucursal
    AND id_producto = p_id_producto;

  UPDATE ventas
  SET subtotal = subtotal + (p_cantidad * p_precio_unitario),
      descuento = descuento + COALESCE(p_descuento_linea, 0.00),
      impuesto = impuesto + COALESCE(p_impuesto_linea, 0.00),
      total = total + v_total_linea
  WHERE id_venta = p_id_venta;

  COMMIT;
END$$
DELIMITER ;
