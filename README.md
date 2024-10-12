VIVERO(**id_vivero**, nombre, latitud, longuitud)

ZONA(**id_zona**, **_id_vivero_**, nombre, latitud, longuitud)

PRODUCTO(**id_producto**, nombre, precio)

ZONA-PRODUCTO(**id_zona**, _id_vivero_, _id_producto_, stock)

EMPLEADO(**id_empleado**, nombre, email, teléfono)

HISTORIAL-EMPLEADO(**id_historial**, _id_empleado_, _id_zona_, fecha_inicio, fecha_fin, puesto)

PEDIDO(**id_pedido**, _id_empleado_, _id_cliente_ importe_total, fecha_pedido)

CLIENTE(**id_cliente**, nombre, email, fecha_ingreso)
