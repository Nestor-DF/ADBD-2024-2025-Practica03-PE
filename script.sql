-- VARCHAR cuando la distinción entre mayúsculas y minúsculas es relevante.
-- CITEXT cuando la distinción entre mayúsculas y minúsculas no es relevante, como en el caso de correos electrónicos.

-- Creación de la base de datos viveros
DROP DATABASE IF EXISTS viveros;
CREATE DATABASE viveros;
\c viveros;

CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION postgis;

-- Creación de las tablas

-- Tabla VIVERO
CREATE TABLE VIVERO (
    id_vivero SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL CHECK (nombre ~* '^[A-Za-zÀ-ÖØ-öø-ÿ\s\-]+$'),
    ubicacion GEOGRAPHY(POINT, 4326) NOT NULL
);

-- Tabla ZONA
CREATE TABLE ZONA (
    id_zona INT NOT NULL,
    id_vivero INT NOT NULL REFERENCES VIVERO(id_vivero) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL CHECK (nombre ~* '^[A-Za-zÀ-ÖØ-öø-ÿ\s\-]+$'),
    ubicacion GEOGRAPHY(POINT, 4326) NOT NULL,
    PRIMARY KEY (id_vivero, id_zona)
);

-- Tabla PRODUCTO
CREATE TABLE PRODUCTO (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL CHECK (nombre ~* '^[A-Za-zÀ-ÖØ-öø-ÿ\s\-]+$'),
    precio_base NUMERIC(10, 2) CHECK (precio_base > 0) NOT NULL,
    precio_final NUMERIC(10, 2) GENERATED ALWAYS AS (precio_base + (precio_base * 0.07)) STORED
);

-- Tabla STOCK
CREATE TABLE STOCK (
    id_zona INT NOT NULL,
    id_vivero INT NOT NULL,
    id_producto INT NOT NULL,
    stock INT CHECK (stock >= 0),
    PRIMARY KEY (id_zona, id_vivero, id_producto),
    FOREIGN KEY (id_vivero, id_zona) REFERENCES ZONA(id_vivero, id_zona) ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE
);

-- Tabla EMPLEADO
CREATE TABLE EMPLEADO (
    id_empleado SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL CHECK (nombre ~* '^[A-Za-zÀ-ÖØ-öø-ÿ\s\-]+$'),
    email CITEXT UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') NOT NULL
);

-- Crear tabla TELEFONO
CREATE TABLE TELEFONO (
    id_empleado INT NOT NULL,
    telefono VARCHAR(15) NOT NULL CHECK (telefono ~ '^\+?[0-9\s\-]+$'),
    FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado) ON DELETE CASCADE,
    PRIMARY KEY (id_empleado, telefono)
);

-- Crear tabla HISTORIAL
CREATE TABLE HISTORIAL (
    id_empleado INT,
    id_vivero INT NOT NULL,
    id_zona INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio),
    puesto VARCHAR(100),
    FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado) ON DELETE RESTRICT,
    FOREIGN KEY (id_vivero, id_zona) REFERENCES ZONA(id_vivero, id_zona) ON DELETE CASCADE,
    PRIMARY KEY (id_empleado, id_vivero, id_zona, fecha_inicio)
);

-- Tabla CLIENTE
CREATE TABLE CLIENTE (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL CHECK (nombre ~* '^[A-Za-zÀ-ÖØ-öø-ÿ\s\-]+$'),
    email CITEXT UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') NOT NULL,
    fecha_ingreso DATE NOT NULL
);

-- Crear tabla PEDIDO
CREATE TABLE PEDIDO (
    id_pedido SERIAL PRIMARY KEY,
    id_empleado INT,
    id_cliente INT,
    importe_total NUMERIC(10, 2),
    fecha_pedido DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado) ON DELETE RESTRICT,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente) ON DELETE SET NULL
);

-- Tabla PRODUCTO-PEDIDO
CREATE TABLE PRODUCTO_PEDIDO (
    id_pedido INT NOT NULL REFERENCES PEDIDO(id_pedido) ON DELETE CASCADE,
    id_producto INT NOT NULL REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE,
    cantidad INT CHECK (cantidad > 0) NOT NULL,
    PRIMARY KEY (id_pedido, id_producto)
);




CREATE OR REPLACE FUNCTION calcular_importe_total()
RETURNS TRIGGER AS $$
DECLARE
    total NUMERIC(10, 2);
BEGIN
    -- Cálculo del importe total
    SELECT SUM(pp.cantidad * p.precio_final)
    INTO total
    FROM PRODUCTO_PEDIDO pp
    JOIN PRODUCTO p ON pp.id_producto = p.id_producto
    WHERE pp.id_pedido = NEW.id_pedido;

    -- Actualizar el importe total en la tabla PEDIDO
    UPDATE PEDIDO
    SET importe_total = total
    WHERE id_pedido = NEW.id_pedido;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calcular_importe_total
AFTER INSERT OR UPDATE ON PRODUCTO_PEDIDO
FOR EACH ROW
EXECUTE FUNCTION calcular_importe_total();


CREATE OR REPLACE FUNCTION validar_periodo_trabajo()
RETURNS TRIGGER AS $$
DECLARE
    existe_conflicto BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM HISTORIAL
        WHERE id_empleado = NEW.id_empleado
        AND (
            (NEW.fecha_inicio BETWEEN fecha_inicio AND COALESCE(fecha_fin, 'infinity')) OR
            (COALESCE(NEW.fecha_fin, 'infinity') BETWEEN fecha_inicio AND COALESCE(fecha_fin, 'infinity')) OR
            (fecha_inicio BETWEEN NEW.fecha_inicio AND COALESCE(NEW.fecha_fin, 'infinity'))
        )
    ) INTO existe_conflicto;

    IF existe_conflicto THEN
        RAISE EXCEPTION 'El empleado ya tiene un trabajo registrado en ese periodo de tiempo.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_periodo_trabajo
BEFORE INSERT OR UPDATE ON HISTORIAL
FOR EACH ROW
EXECUTE FUNCTION validar_periodo_trabajo();


CREATE OR REPLACE FUNCTION verificar_stock_disponible()
RETURNS TRIGGER AS $$
DECLARE
    stock_disponible INT;
BEGIN
    SELECT stock INTO stock_disponible
    FROM STOCK
    WHERE id_producto = NEW.id_producto
    FOR UPDATE;  -- Bloquear el registro para evitar modificaciones concurrentes

    IF stock_disponible IS NULL THEN
        RAISE EXCEPTION 'Producto no disponible en stock para este vivero/zona.';
    ELSIF stock_disponible < NEW.cantidad THEN
        RAISE EXCEPTION 'No hay suficiente stock disponible. Disponible: %, Requerido: %', stock_disponible, NEW.cantidad;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verificar_stock
BEFORE INSERT ON PRODUCTO_PEDIDO
FOR EACH ROW
EXECUTE FUNCTION verificar_stock_disponible();




-- Insertar datos de prueba

-- Tabla VIVERO
INSERT INTO VIVERO (nombre, ubicacion) VALUES ('Vivero Norte', ST_GeogFromText('POINT(28.4699 -16.2547)'));
INSERT INTO VIVERO (nombre, ubicacion) VALUES ('Vivero Sur', ST_GeogFromText('POINT(27.4699 -15.2547)'));
INSERT INTO VIVERO (nombre, ubicacion) VALUES ('Vivero Este', ST_GeogFromText('POINT(29.4699 -16.6547)'));
INSERT INTO VIVERO (nombre, ubicacion) VALUES ('Vivero Oeste', ST_GeogFromText('POINT(26.4699 -14.2547)'));
INSERT INTO VIVERO (nombre, ubicacion) VALUES ('Vivero Central', ST_GeogFromText('POINT(28.8799 -15.6547)'));

-- Tabla ZONA
INSERT INTO ZONA (id_vivero, id_zona, nombre, ubicacion) VALUES (1, 1, 'Zona A', ST_GeogFromText('POINT(28.4699 -16.2548)'));
INSERT INTO ZONA (id_vivero, id_zona, nombre, ubicacion) VALUES (2, 2, 'Zona B', ST_GeogFromText('POINT(-28.4699 16.2547)'));
INSERT INTO ZONA (id_vivero, id_zona, nombre, ubicacion) VALUES (3, 3, 'Zona C', ST_GeogFromText('POINT(45.0000 90.0000)'));
INSERT INTO ZONA (id_vivero, id_zona, nombre, ubicacion) VALUES (4, 4, 'Zona D', ST_GeogFromText('POINT(-45.0000 -90.0000)'));
INSERT INTO ZONA (id_vivero, id_zona, nombre, ubicacion) VALUES (1, 4, 'Zona D', ST_GeogFromText('POINT(-45.0000 -90.0000)'));
INSERT INTO ZONA (id_vivero, id_zona, nombre, ubicacion) VALUES (5, 5, 'Zona Central', ST_GeogFromText('POINT(0.0000 0.0000)'));
INSERT INTO ZONA (id_vivero, id_zona, nombre, ubicacion) VALUES (5, 6, 'Zona Oeste', ST_GeogFromText('POINT(0.0000 0.0000)'));

-- Tabla PRODUCTO
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Rosa', 5.00);
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Tulipan', 7.50);
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Orquídea', 10.00);
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Girasol', 3.50);
INSERT INTO PRODUCTO (nombre, precio_base) VALUES ('Margarita', 2.00);

-- Tabla STOCK
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (1, 1, 1, 200);
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (2, 2, 2, 150);
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (3, 3, 3, 300);
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (3, 3, 4, 99);
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (4, 4, 4, 250);
INSERT INTO STOCK (id_vivero, id_zona, id_producto, stock) VALUES (5, 5, 5, 500);

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
VALUES (4, 4, 4, '2024-02-01', '2025-01-31', 'Ayudante');
INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
VALUES (5, 5, 5, '2023-07-01', NULL, 'Técnico de Mantenimiento');

-- Tabla CLIENTE
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Juan Lopez', 'juan@example.com', '2020-01-01');
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Maria Garcia', 'maria@example.com', '2021-05-10');
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Jose Gonzalez', 'jose@example.com', '2022-08-15');
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Luisa Fernandez', 'luisa@example.com', '2023-03-20');
INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Pablo Mendez', 'pablo@example.com', '2019-11-25');

-- Tablas PEDIDO y PRODUCTO-PEDIDO
INSERT INTO PEDIDO (id_empleado, id_cliente, fecha_pedido) VALUES (2, 2, '2024-01-02');
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (1, 2, 4);
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (1, 5, 10);
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (1, 4, 1);

INSERT INTO PEDIDO (id_empleado, id_cliente, fecha_pedido) VALUES (3, 3, '2024-01-03');
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (2, 3, 6);

INSERT INTO PEDIDO (id_empleado, id_cliente) VALUES (1, 1); -- No se especifica la fecha pilla la actual
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (3, 3, 5);
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (3, 1, 99);

INSERT INTO PEDIDO (id_empleado, fecha_pedido) VALUES (4, '2024-02-01'); -- No se especifica el cliente (no es miembro de Tajinaste Plus, pilla NULL)
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (4, 4, 10);

INSERT INTO PEDIDO (id_empleado, id_cliente, fecha_pedido) VALUES (5, 5, '2024-03-15');
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (5, 5, 20);
INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (5, 2, 12);




-- -- Tabla VIVERO
-- -- Latitud fuera del rango permitido (-90 a 90)
-- INSERT INTO VIVERO (nombre, ubicacion) 
-- VALUES ('Vivero Latitud Incorrecta', ST_GeogFromText('POINT(30.0000 -91.0000)'));  -- Error: latitud fuera del rango
-- -- Longitud fuera del rango permitido (-180 a 180)
-- INSERT INTO VIVERO (nombre, ubicacion) 
-- VALUES ('Vivero Longitud Incorrecta', ST_GeogFromText('POINT(-181.0000 40.0000)'));  -- Error: longitud fuera del rango
-- -- Latitud y longitud fuera del rango permitido
-- INSERT INTO VIVERO (nombre, ubicacion) 
-- VALUES ('Vivero Coordenadas Incorrectas', ST_GeogFromText('POINT(200.0000 -91.0000)'));  -- Error: latitud y longitud fuera del rango
-- -- Intentar insertar un vivero sin nombre (debería fallar)
-- INSERT INTO VIVERO (ubicacion) 
-- VALUES (ST_GeogFromText('POINT(-16.2547 28.4699)'));  -- Error: el nombre es obligatorio (NOT NULL)

-- -- Tabla ZONA
-- -- Latitud fuera del rango permitido (-90 a 90)
-- INSERT INTO ZONA (id_vivero, nombre, ubicacion) 
-- VALUES (1, 'Zona Latitud Incorrecta', ST_GeogFromText('POINT(30.0000 -91.0000)'));  -- Error: latitud fuera del rango
-- -- Longitud fuera del rango permitido (-180 a 180)
-- INSERT INTO ZONA (id_vivero, nombre, ubicacion) 
-- VALUES (1, 'Zona Longitud Incorrecta', ST_GeogFromText('POINT(-181.0000 40.0000)'));  -- Error: longitud fuera del rango
-- -- Intentar insertar una zona sin nombre (debería fallar)
-- INSERT INTO ZONA (id_vivero, ubicacion) 
-- VALUES (2, ST_GeogFromText('POINT(-16.2548 28.4699)'));  -- Error: el nombre es obligatorio (NOT NULL)
-- -- Intentar insertar una zona asociada a un vivero inexistente (debería fallar)
-- INSERT INTO ZONA (id_vivero, nombre, ubicacion) 
-- VALUES (999, 'Zona Vivero Inexistente', ST_GeogFromText('POINT(-16.2548 28.4699)'));  -- Error: referencia a un id_vivero que no existe

-- -- Tabla PRODUCTO
-- -- Precio base negativo (debería fallar)
-- INSERT INTO PRODUCTO (nombre, precio_base) 
-- VALUES ('Flor Negativa', -10.00);  -- Error: el precio_base no puede ser negativo
-- -- Intentar insertar un producto sin nombre (debería fallar)
-- INSERT INTO PRODUCTO (precio_base) 
-- VALUES (5.00);  -- Error: el nombre es obligatorio (NOT NULL)
-- -- Intentar insertar un producto sin precio_base (debería fallar)
-- INSERT INTO PRODUCTO (nombre) 
-- VALUES ('Producto Sin Precio');  -- Error: el precio_base es obligatorio (NOT NULL)
-- -- Intentar insertar un producto con precio_base no numérico (debería fallar)
-- INSERT INTO PRODUCTO (nombre, precio_base) 
-- VALUES ('Producto No Numérico', 'precio');  -- Error: el precio_base debe ser numérico

-- -- Tabla STOCK
-- -- Stock negativo
-- INSERT INTO STOCK (id_zona, id_vivero, id_producto, stock) VALUES (1, 1, 1, -5);  -- Debe fallar por stock negativo
-- -- Referencias no válidas (id_zona o id_producto no existentes)
-- INSERT INTO STOCK (id_zona, id_vivero, id_producto, stock) VALUES (99, 1, 1, 10);  -- Debe fallar si la zona no existe
-- INSERT INTO STOCK (id_zona, id_vivero, id_producto, stock) VALUES (1, 1, 99, 10);  -- Debe fallar si el producto no existe
-- -- Combinación no válida (id_zona e id_vivero que no existen juntos)
-- INSERT INTO STOCK (id_zona, id_vivero, id_producto, stock) VALUES (2, 99, 1, 10);  -- Debe fallar si el vivero no existe

-- -- Tabla EMPLEADO
-- -- Intento de insertar un empleado con nombre nulo
-- INSERT INTO EMPLEADO (nombre, email) VALUES (NULL, 'juan@example.com'); -- Debe fallar por nombre nulo
-- -- Intento de insertar un empleado con email nulo
-- INSERT INTO EMPLEADO (nombre, email) VALUES ('Juan Perez', NULL); -- Debe fallar por email nulo
-- -- Intento de insertar un empleado con email duplicado
-- INSERT INTO EMPLEADO (nombre, email) VALUES ('Ana Gomez', 'carlos@example.com'); -- Debe fallar por email duplicado

-- -- Tabla TELEFONO
-- -- Intento de insertar un teléfono con id_empleado que no existe
-- INSERT INTO TELEFONO (id_empleado, telefono) VALUES (99, '123456789'); -- Debe fallar si el id_empleado no existe
-- -- Intento de insertar un teléfono con número nulo
-- INSERT INTO TELEFONO (id_empleado, telefono) VALUES (1, NULL); -- Debe fallar por teléfono nulo
-- -- Intento de insertar un teléfono con formato inválido (ejemplo de longitud incorrecta)
-- INSERT INTO TELEFONO (id_empleado, telefono) VALUES (1, '1234567890123456'); -- Debe fallar si hay una restricción de longitud
-- -- Intento de insertar un teléfono duplicado para el mismo empleado
-- INSERT INTO TELEFONO (id_empleado, telefono) VALUES (1, '123456789'); -- Primero insertas un número válido, luego fallarías aquí si intentas insertar el mismo número de teléfono para el mismo empleado.

-- -- Tabla HISTORIAL
-- -- Intentar insertar con una fecha_fin anterior a la fecha_inicio (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (1, 1, 1, '2023-01-01', '2022-12-31', 'Jardinero');  -- fecha_fin < fecha_inicio
-- -- Intentar insertar con un id_empleado inexistente (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (999, 1, 1, '2023-01-01', NULL, 'Jardinero');  -- id_empleado no existe
-- -- Intentar insertar con un id_vivero inexistente (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (1, 999, 1, '2023-01-01', NULL, 'Jardinero');  -- id_vivero no existe
-- -- Intentar insertar con un id_zona inexistente (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (1, 1, 999, '2023-01-01', NULL, 'Jardinero');  -- id_zona no existe
-- -- Intentar insertar una fila duplicada en términos de (id_empleado, id_vivero, id_zona) (debería fallar)
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (1, 1, 1, '2023-01-01', '2023-12-31', 'Jardinero');  -- PK ya existe
-- Intentar insertar un empleado que ya está trabajando en ese periodo de tiempo (debería fallar)
-- -- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- -- VALUES (5, 5, 5, '2023-07-01', NULL, 'Técnico de Mantenimiento');
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (5, 5, 5, '2023-08-01', NULL, 'Técnico de Mantenimiento');
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (5, 5, 5, '2023-07-01', '2023-10-01', 'Técnico de Mantenimiento');
-- INSERT INTO HISTORIAL (id_empleado, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
-- VALUES (5, 5, 5, '2023-06-01', '2023-10-01', 'Técnico de Mantenimiento');

-- -- Tabla CLIENTE
-- -- Intento de insertar un cliente con nombre nulo
-- INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES (NULL, 'cliente@example.com', '2024-01-01'); -- Debe fallar por nombre nulo
-- -- Intento de insertar un cliente con email nulo
-- INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Juan Perez', NULL, '2024-01-01'); -- Debe fallar por email nulo
-- -- Intento de insertar un cliente con fecha de ingreso nula
-- INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Ana Gomez', 'ana@example.com', NULL); -- Debe fallar por fecha_ingreso nula
-- -- Intento de insertar un cliente con email duplicado
-- INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Juan Lopez', 'juan@example.com', '2020-01-01');
-- -- Intento de insertar un cliente con fecha de ingreso en formato incorrecto (si tu base de datos no permite esto)
-- INSERT INTO CLIENTE (nombre, email, fecha_ingreso) VALUES ('Maria Garcia', 'maria@example.com', '2024/01/01'); -- Debe fallar si la fecha no está en el formato adecuado

-- -- Tablas PEDIDO y PRODUCTO-PEDIDO
-- -- Intentar insertar un empleado que no existe
-- INSERT INTO PEDIDO (id_empleado, id_cliente, fecha_pedido) VALUES (69, 4, '2024-02-01');
-- -- Intentar insertar un pedido que no existe
-- INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (69, 4, 10);
-- -- Intentar insertar un cliente que no existe
-- INSERT INTO PEDIDO (id_empleado, id_cliente, fecha_pedido) VALUES (5, 69, '2024-03-15');
-- -- Intentar insertar una cantidad negativa o 0
-- INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (5, 5, 0);
-- INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (5, 5, -7);
-- -- Insertar un producto que no existe
-- INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (5, 69, 12);
-- -- Intentar insertar sin empleado
-- INSERT INTO PEDIDO ( id_cliente, fecha_pedido) VALUES (4, '2024-02-01');
-- -- Intentar insertar cuando no hay stock suficiente
-- INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (5, 5, 9999999);
-- INSERT INTO PRODUCTO_PEDIDO (id_pedido, id_producto, cantidad) VALUES (5, 2, 9999999);




-- -- Operaciones DELETE
-- DELETE FROM VIVERO WHERE id_vivero = 2;
-- DELETE FROM ZONA WHERE id_zona = 1;
-- DELETE FROM PRODUCTO WHERE id_producto = 5;
-- DELETE FROM CLIENTE WHERE id_cliente = 3;
-- DELETE FROM EMPLEADO WHERE id_empleado = 4;