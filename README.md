## Modelo Relacional

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


## Restricciones semánticas que no puede recoger el modelo entidad/relación
- Un pedido no puede ser realizado si no hay productos en stock.
- El stock de un producto no puede ser negativo.
- El importe total de un pedido debe ser mayor a cero.
- El precio de un producto no puede ser negativo.
- Un empleado solo puede trabajar en una única zona durante una época específica del año, una vez terminada su asignación sí puede trabajar en una zona distinta.
- La fecha de fin de asignación de un empleado a una zona debe ser posterior a la fecha de inicio


## Recursos empleados
https://github.com/ull-cs/adbd/blob/main/postgresql-tutorial/index.md#introducci%C3%B3n
