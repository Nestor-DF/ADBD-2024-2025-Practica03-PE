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
    precio NUMERIC(10, 2) CHECK (precio >= 0) NOT NULL
);

-- Tabla STOCK
CREATE TABLE STOCK (
    id_zona INT NOT NULL,
    id_vivero INT NOT NULL,
    id_producto INT NOT NULL,
    stock INT CHECK (stock >= 0) DEFAULT 0,
    PRIMARY KEY (id_zona, id_vivero, id_producto),
    FOREIGN KEY (id_zona) REFERENCES ZONA(id_zona) ON DELETE CASCADE,
    FOREIGN KEY (id_vivero) REFERENCES VIVERO(id_vivero) ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE
);

-- Tabla EMPLEADO
CREATE TABLE EMPLEADO (
    id_empleado SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(15) NOT NULL
);

-- Tabla HISTORIAL
CREATE TABLE HISTORIAL (
    id_empleado INT NOT NULL REFERENCES EMPLEADO(id_empleado) ON DELETE CASCADE,
    id_zona INT NOT NULL REFERENCES ZONA(id_zona) ON DELETE CASCADE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    puesto VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_empleado, id_zona, fecha_inicio)
);

-- Tabla CLIENTE
CREATE TABLE CLIENTE (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    fecha_ingreso DATE NOT NULL
);

-- Tabla PEDIDO
CREATE TABLE PEDIDO (
    id_pedido SERIAL PRIMARY KEY,
    id_empleado INT REFERENCES EMPLEADO(id_empleado) ON DELETE SET NULL,
    id_cliente INT REFERENCES CLIENTE(id_cliente) ON DELETE SET NULL,
    importe_total NUMERIC(10, 2) CHECK (importe_total >= 0) NOT NULL,
    fecha_pedido DATE NOT NULL
);

-- Tabla PRODUCTO-PEDIDO
CREATE TABLE PRODUCTO_PEDIDO (
    id_pedido INT NOT NULL REFERENCES PEDIDO(id_pedido) ON DELETE CASCADE,
    id_producto INT NOT NULL REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE,
    cantidad INT CHECK (cantidad > 0) NOT NULL,
    PRIMARY KEY (id_pedido, id_producto)
);

-- Inserción de datos de prueba

-- Insertando VIVEROS
INSERT INTO VIVERO (nombre, latitud, longitud) VALUES
('Vivero Central', 28.123456, -15.654321),
('Vivero Norte', 28.987654, -16.543210),
('Vivero Este', 27.123456, -16.234567),
('Vivero Sur', 27.987654, -17.543210),
('Vivero Oeste', 28.567890, -15.987654);

-- Insertando ZONAS
INSERT INTO ZONA (id_vivero, nombre, latitud, longitud) VALUES
(1, 'Zona A', 28.123456, -15.654321),
(1, 'Zona B', 28.123499, -15.654399),
(2, 'Zona C', 28.987654, -16.543210),
(3, 'Zona D', 27.123456, -16.234567),
(4, 'Zona E', 27.987654, -17.543210);

-- Insertando PRODUCTOS
INSERT INTO PRODUCTO (nombre, precio) VALUES
('Rosa', 3.50),
('Orquídea', 10.00),
('Tulipán', 5.75),
('Cactus', 2.25),
('Bonsái', 30.00);

-- Insertando STOCK
INSERT INTO STOCK (id_zona, id_vivero, id_producto, stock) VALUES
(1, 1, 1, 50),
(2, 1, 2, 20),
(3, 2, 3, 100),
(4, 3, 4, 15),
(5, 4, 5, 10);

-- Insertando EMPLEADOS
INSERT INTO EMPLEADO (nombre, email, telefono) VALUES
('Ana López', 'ana@vivero.com', '600123456'),
('Luis Pérez', 'luis@vivero.com', '600654321'),
('Marta García', 'marta@vivero.com', '600789456'),
('Carlos Díaz', 'carlos@vivero.com', '600987123'),
('Lucía Gómez', 'lucia@vivero.com', '600321789');

-- Insertando HISTORIAL
INSERT INTO HISTORIAL (id_empleado, id_zona, fecha_inicio, fecha_fin, puesto) VALUES
(1, 1, '2022-01-01', '2023-01-01', 'Gerente'),
(2, 2, '2022-06-01', NULL, 'Vendedor'),
(3, 3, '2021-05-15', '2022-05-15', 'Supervisor'),
(4, 4, '2020-08-01', '2023-08-01', 'Jardinero'),
(5, 5, '2019-07-10', NULL, 'Encargado');

-- Insertando CLIENTES
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES
('Pedro Herrera', 'pedro@gmail.com', '2020-01-15'),
('Elena Martín', 'elena@gmail.com', '2021-03-10'),
('Roberto Sánchez', 'roberto@gmail.com', '2019-05-25'),
('Laura Pérez', 'laura@gmail.com', '2022-11-05'),
('Juan Morales', 'juan@gmail.com', '2023-02-14');

-- Insertando PEDIDOS
INSERT INTO PEDIDO (id_empleado, id_cliente, importe_total, fecha_pedido) VALUES
(1, 1, 50.00, '2023-07-01'),
(2, 2, 25.50, '2023-06-15'),
(3, 3, 15.00, '2023-05-10'),
(4, 4, 100.75, '2023-04-20'),
(5, 5, 60.00, '2023-03-30');

-- Insertando PRODUCTO_PEDIDO
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES
(1, 1, 10),
(2, 2, 2),
(3, 3, 1),
(4, 4, 5),
(5, 5, 1);

-- Ejemplo de DELETE

-- Eliminar un vivero (esto eliminará las zonas y el stock relacionado por CASCADE)
DELETE FROM VIVERO WHERE id_vivero = 1;

-- Eliminar un empleado (esto dejará el campo id_empleado en NULL en los pedidos relacionados por SET NULL)
DELETE FROM EMPLEADO WHERE id_empleado = 2;

-- Eliminar un pedido (esto eliminará los productos asociados a ese pedido por CASCADE)
DELETE FROM PEDIDO WHERE id_pedido = 3;
