VIVERO(**id_vivero**, nombre, latitud, longuitud)

ZONA(**id_zona**, **_id_vivero_**, nombre, latitud, longuitud)

PRODUCTO(**id_producto**, nombre, precio)

STOCK(**_id_zona_**, **_id_vivero_**, **_id_producto_**, stock)

EMPLEADO(**id_empleado**, nombre, email, teléfono)

HISTORIAL(**_id_empleado_**, **_id_zona_**, fecha_inicio, fecha_fin, puesto) controlar fechas

PRODUCTO-PEDIDO(**_id_pedido_**, **_id_producto_**, cantidad)

PEDIDO(**id_pedido**, _id_empleado_, _id_cliente_, importe_total, fecha_pedido)

CLIENTE(**id_cliente**, nombre, email, fecha_ingreso)


## Recursos empleados
https://github.com/ull-cs/adbd/blob/main/postgresql-tutorial/index.md#introducci%C3%B3n
