-- Creación de la base de datos viveros
CREATE DATABASE viveros;
\c viveros;

-- Creación de las tablas

-- Tabla VIVERO
CREATE TABLE VIVERO (
    id_vivero SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    latitud NUMERIC(9, 6) CHECK (latitud BETWEEN -90 AND 90) NOT NULL,
    longitud NUMERIC(9, 6) CHECK (longitud BETWEEN -180 AND 180) NOT NULL
);

-- Tabla ZONA
CREATE TABLE ZONA (
    id_zona SERIAL PRIMARY KEY,
    id_vivero INT NOT NULL REFERENCES VIVERO(id_vivero) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    latitud NUMERIC(9, 6) CHECK (latitud BETWEEN -90 AND 90) NOT NULL,
    longitud NUMERIC(9, 6) CHECK (longitud BETWEEN -180 AND 180) NOT NULL
);

-- Tabla PRODUCTO
CREATE TABLE PRODUCTO (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio_base NUMERIC(10, 2) CHECK (precio_base >= 0) NOT NULL,
    precio_final NUMERIC(10, 2) GENERATED ALWAYS AS (precio_base + (precio_base * 0.07)) STORED
);

-- Tabla STOCK
CREATE TABLE STOCK (
    id_zona INT NOT NULL,
    id_vivero INT NOT NULL,
    id_producto INT NOT NULL,
    stock INT CHECK (stock >= 0),
    PRIMARY KEY (id_zona, id_vivero, id_producto),
    FOREIGN KEY (id_zona) REFERENCES ZONA(id_zona) ON DELETE CASCADE,
    FOREIGN KEY (id_vivero) REFERENCES VIVERO(id_vivero) ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE
);

-- Tabla EMPLEADO
CREATE TABLE EMPLEADO (
    id_empleado SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- Crear tabla TELEFONO
CREATE TABLE TELEFONO (
    id_empleado INT NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado) ON DELETE CASCADE,
    PRIMARY KEY (id_empleado, telefono)
);

-- Crear tabla HISTORIAL
CREATE TABLE HISTORIAL (
    id_empleado INT NOT NULL,
    id_vivero INT NOT NULL,
    id_zona INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio),
    puesto VARCHAR(100),
    FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado) ON DELETE CASCADE,
    FOREIGN KEY (id_vivero) REFERENCES VIVERO(id_vivero) ON DELETE CASCADE,
    FOREIGN KEY (id_zona) REFERENCES ZONA(id_zona) ON DELETE CASCADE,
    PRIMARY KEY (id_empleado, id_vivero, id_zona)
);

-- Tabla CLIENTE
CREATE TABLE CLIENTE (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    fecha_ingreso DATE NOT NULL
);

-- Crear tabla PEDIDO
CREATE TABLE PEDIDO (
    id_pedido SERIAL PRIMARY KEY,
    id_empleado INT NOT NULL,
    id_cliente INT,
    importe_total NUMERIC(10, 2) CHECK (importe_total > 0) NOT NULL, -- CALCULAR IMPORTE TOTAL
    fecha_pedido DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado) ON DELETE CASCADE,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente) ON DELETE CASCADE
);

-- Tabla PRODUCTO-PEDIDO
CREATE TABLE PRODUCTO_PEDIDO (
    id_pedido INT NOT NULL REFERENCES PEDIDO(id_pedido) ON DELETE CASCADE,
    id_producto INT NOT NULL REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE,
    cantidad INT CHECK (cantidad > 0) NOT NULL,
    PRIMARY KEY (id_pedido, id_producto)
);



-- Insertar datos de prueba

-- Tabla VIVERO
INSERT INTO VIVERO (nombre, latitud, longitud) VALUES ('Vivero Norte', 28.4699, -16.2547);
INSERT INTO VIVERO (nombre, latitud, longitud) VALUES ('Vivero Sur', 27.4699, -15.2547);
INSERT INTO VIVERO (nombre, latitud, longitud) VALUES ('Vivero Este', 29.4699, -16.6547);
INSERT INTO VIVERO (nombre, latitud, longitud) VALUES ('Vivero Oeste', 26.4699, -14.2547);
INSERT INTO VIVERO (nombre, latitud, longitud) VALUES ('Vivero Central', 28.8799, -15.6547);

-- Tabla ZONA
INSERT INTO ZONA (id_vivero, nombre, latitud, longitud) VALUES (1, 'Zona A', 28.4698, -16.2548);
INSERT INTO ZONA (id_vivero, nombre, latitud, longitud) VALUES (2, 'Zona B', 27.4698, -15.2548);
INSERT INTO ZONA (id_vivero, nombre, latitud, longitud) VALUES (3, 'Zona C', 29.4698, -16.6548);
INSERT INTO ZONA (id_vivero, nombre, latitud, longitud) VALUES (4, 'Zona D', 26.4698, -14.2548);
INSERT INTO ZONA (id_vivero, nombre, latitud, longitud) VALUES (5, 'Zona E', 28.8798, -15.6548);

-- Tabla PRODUCTO
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Rosa', 5.00);
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Tulipan', 7.50);
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Orquídea', 10.00);
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Girasol', 3.50);
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Margarita', 2.00);

-- Tabla EMPLEADO
INSERT INTO EMPLEADO (nombre, email) VALUES ('Carlos Perez', 'carlos@example.com');
INSERT INTO EMPLEADO (nombre, email) VALUES ('Ana Gomez', 'ana@example.com');
INSERT INTO EMPLEADO (nombre, email) VALUES ('Luis Ramirez', 'luis@example.com');
INSERT INTO EMPLEADO (nombre, email) VALUES ('Laura Martinez', 'laura@example.com');
INSERT INTO EMPLEADO (nombre, email) VALUES ('Pedro Diaz', 'pedro@example.com');

-- Tabla TELEFONO
INSERT INTO TELEFONO (id_empleado, telefono) VALUES (1, '123456789');
INSERT INTO TELEFONO (id_empleado, telefono) VALUES (2, '987654321');
INSERT INTO TELEFONO (id_empleado, telefono) VALUES (3, '112233445');
INSERT INTO TELEFONO (id_empleado, telefono) VALUES (4, '556677889');
INSERT INTO TELEFONO (id_empleado, telefono) VALUES (5, '998877665');

-- Tabla CLIENTE
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Juan Lopez', 'juan@example.com', '2020-01-01');
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Maria Garcia', 'maria@example.com', '2021-05-10');
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Jose Gonzalez', 'jose@example.com', '2022-08-15');
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Luisa Fernandez', 'luisa@example.com', '2023-03-20');
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Pablo Mendez', 'pablo@example.com', '2019-11-25');

-- Tabla STOCK
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (1, 1, 1, 20);
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (2, 2, 2, 15);
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (3, 3, 3, 30);
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (4, 4, 4, 25);
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (5, 5, 5, 50);

-- Tabla HISTORIAL
INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
VALUES (1, 1, 1, '2023-01-01', '2023-12-31', 'Jardinero');

INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
VALUES (2, 2, 2, '2022-06-01', NULL, 'Supervisor');

INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
VALUES (3, 3, 3, '2021-04-15', '2022-04-14', 'Encargado de Zona');

INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
VALUES (4, 4, 4, '2020-02-01', '2021-01-31', 'Ayudante');

INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
VALUES (5, 5, 5, '2023-07-01', NULL, 'Técnico de Mantenimiento');

-- Tablas PRODUCTO y PRODUCTO-PEDIDO
INSERT INTO PEDIDO (id_empleado, id_cliente, importe_total, fecha_pedido) VALUES (2, 2, 250.00, '2024-01-02');
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (1, 2, 4);
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (1, 5, 10);
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (1, 4, 1);

INSERT INTO PEDIDO (id_empleado, id_cliente, importe_total, fecha_pedido) VALUES (3, 3, 150.00, '2024-01-03');
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (2, 3, 6);

INSERT INTO PEDIDO (id_empleado, id_cliente, importe_total) VALUES (1, 1, 499.99); -- No se especifica la fecha pilla la actual
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (3, 3, 5);
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (3, 1, 99);

INSERT INTO PEDIDO (id_empleado, id_cliente, importe_total, fecha_pedido) VALUES (4, 4, 100.00, '2024-02-01');
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (4, 4, 10);

INSERT INTO PEDIDO (id_empleado, id_cliente, importe_total, fecha_pedido) VALUES (5, 5, 350.00, '2024-03-15');
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (5, 5, 20);
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (5, 2, 12);

-- -- Ejemplo incorrecto: Intentar insertar un producto repetido en un pedido
-- INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (1, 2, 10);

-- -- Ejemplo incorrecto: Intentar insertar un producto con precio negativo (debería fallar)
-- INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Flor Incorrecta', -5);

-- -- Ejemplo incorrecto: Insertar un pedido con una cantidad negativa (debería fallar)
-- INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (2, 2, -2);

-- -- Ejemplo incorrecto: Intentar insertar un cliente con un email duplicado (debería fallar)
-- INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Jose Gonzalez', 'jose@example.com', '2022-08-15');

-- -- Ejemplo incorrecto: Intentar insertar una zona con coordenadas fuera del rango (debería fallar)
-- INSERT INTO ZONA (id_vivero, nombre, latitud, longitud) VALUES (3, 'Zona Invalida', 95.4698, -16.6548);

-- -- Ejemplo incorrecto: Intentar insertar un vivero con coordenadas fuera del rango (debería fallar)
-- INSERT INTO VIVERO (nombre, latitud, longitud) VALUES ('Vivero Invalido', 95.4698, -16.6548);

-- -- Caso 1: Intentar insertar con una fecha_fin anterior a la fecha_inicio (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (1, 1, 1, '2023-01-01', '2022-12-31', 'Jardinero');  -- fecha_fin < fecha_inicio

-- -- Caso 2: Intentar insertar con un id_empleado inexistente (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (999, 1, 1, '2023-01-01', NULL, 'Jardinero');  -- id_empleado no existe

-- -- Caso 3: Intentar insertar con un id_vivero inexistente (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (1, 999, 1, '2023-01-01', NULL, 'Jardinero');  -- id_vivero no existe

-- -- Caso 4: Intentar insertar con un id_zona inexistente (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (1, 1, 999, '2023-01-01', NULL, 'Jardinero');  -- id_zona no existe

-- -- Caso 5: Intentar insertar una fila duplicada en términos de (id_empleado, id_vivero, id_zona) (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (1, 1, 1, '2023-01-01', '2023-12-31', 'Jardinero');  -- PK ya existe



-- Operaciones DELETE

-- Borrar un vivero (esto debería eliminar las zonas y el stock asociado a dicho vivero)
DELETE FROM VIVERO WHERE id_vivero = 2;

-- Borrar un cliente y sus pedidos
DELETE FROM CLIENTE WHERE id_cliente = 3;

-- Borrar un empleado y sus registros en la tabla TELEFONO y PEDIDO
DELETE FROM EMPLEADO WHERE id_empleado = 4;

-- Borrar un producto, eliminando las relaciones en PRODUCTO_PEDIDO y STOCK
DELETE FROM PRODUCTO WHERE id_producto = 5;