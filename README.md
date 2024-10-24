## Instrucciones para Usar el Script con Docker

0. **Asegúrate de tener Docker y el cliente postgreSQL instalado en tu máquina.**
```bash
sudo apt update
sudo apt install docker.io
sudo apt install postgresql-client
```

1. **Construir la imagen Docker**:
```bash
docker build -t my-postgres-image .
```

2. **Ejecutar el contenedor Docker**:
```bash
docker run --name my-postgres-container -v $(pwd):/docker-entrypoint-initdb.d -e POSTGRES_USER=nestor -e POSTGRES_PASSWORD=12ab12ab -e POSTGRES_DB=viveros -p 5432:5432 my-postgres-image
```

3. **Conectarse a postgresql**:
```bash
psql -h localhost -U nestor -d postgres
```

4. **Ejecutar el script**:
```sql
\i script.sql
```



## Modelo Relacional

- **Negrita**: clave primaria
- _Cursiva_: clave ajena
- **_Negrita y Cursiva_**: clave ajena y primaria

VIVERO(**id_vivero**, nombre, latitud, longuitud)

ZONA(**_id_vivero_**, **id_zona**, nombre, latitud, longuitud)
- id_vivero: FOREIGN KEY de VIVERO(id_vivero)

PRODUCTO(**id_producto**, nombre, precio)
- precio: atributo calculado, precio = valor_insertado + (valor_insertado * impuestos en IGIC)

STOCK(**_id_vivero_**, **_id_zona_**, **_id_producto_**, stock)
- id_vivero: FOREIGN KEY de VIVERO(id_vivero)
- id_zona: FOREIGN KEY de ZONA(id_zona)
- id_producto: FOREIGN KEY de PRODUCTO(id_producto)

EMPLEADO(**id_empleado**, nombre, email)

TELEFONO(**id_empleado**, telefono)
- id_empleado: FOREIGN KEY de EMPLEADO(id_empleado)

HISTORIAL(**_id_empleado_**, **_id_vivero_**, **_id_zona_**, **fecha_inicio**, fecha_fin, puesto) 
- id_empleado: FOREIGN KEY de EMPLEADO(id_empleado)
- id_vivero: FOREIGN KEY de VIVERO(id_vivero)
- id_zona: FOREIGN KEY de ZONA(id_zona)

CLIENTE(**id_cliente**, nombre, email, fecha_ingreso)

PEDIDO(**id_pedido**, _id_empleado_, _id_cliente_, importe_total, fecha_pedido)
- id_empleado: FOREIGN KEY de EMPLEADO(id_empleado)
- id_cliente: FOREIGN KEY de CLIENTE(id_cliente)
- importe_total: atributo calculado, importe_total = cantidad de cada producto * precio

PRODUCTO-PEDIDO(**_id_pedido_**, **_id_producto_**, cantidad)
- id_producto: FOREIGN KEY de PRODUCTO(id_producto)
- id_pedido: FOREIGN KEY de PEDIDO(id_pedido)



## Restricciones semánticas
- Un pedido no puede ser realizado si no hay productos en stock.
- El stock de un producto no puede ser negativo.
- El importe total de un pedido debe ser mayor a cero.
- El precio de un producto no puede ser negativo.
- La cantidad de producto en un pedido debe ser mayor a 0.
- Un empleado solo puede trabajar en una única zona durante una época específica del año, una vez terminada su asignación sí puede trabajar en una zona distinta.
- La fecha de fin de asignación de un empleado a una zona debe ser posterior a la fecha de inicio.