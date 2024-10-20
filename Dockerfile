# Usa la imagen oficial de PostgreSQL
FROM postgis/postgis:latest

# Configura las variables de entorno necesarias para PostgreSQL
ENV POSTGRES_USER=nestor
ENV POSTGRES_PASSWORD=12ab12ab
ENV POSTGRES_DB=viveros

# Crea una carpeta para almacenar scripts dentro del contenedor
RUN mkdir -p /docker-entrypoint-initdb.d

# # Se ejecutará el script automáticamente al iniciar el contenedor gracias al comportamiento predeterminado de postgres
# # Copia el script SQL desde tu máquina local al contenedor
# COPY ./script.sql /docker-entrypoint-initdb.d/

# Exponemos el puerto de PostgreSQL
EXPOSE 5432