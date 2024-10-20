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

#docker build -t my-postgres-image .
#docker run --name my-postgres-container -v $(pwd):/docker-entrypoint-initdb.d -e POSTGRES_USER=nestor -e POSTGRES_PASSWORD=12ab12ab -e POSTGRES_DB=viveros -p 5432:5432 my-postgres-image
