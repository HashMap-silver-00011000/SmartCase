-- Creación de tablas para el sistema SmartCase

-- 1. Tabla Clinica
CREATE TABLE clinica (
    id_clinica UUID PRIMARY KEY,
    nombre VARCHAR NOT NULL
);

-- 2. Tabla Sede
CREATE TABLE sede (
    id_sede UUID PRIMARY KEY,
    id_clinica UUID NOT NULL REFERENCES clinica(id_clinica),
    nombre VARCHAR NOT NULL
);

-- 3. Tabla Usuario
CREATE TABLE usuario (
    id_usuario UUID PRIMARY KEY,
    nombre_completo VARCHAR NOT NULL,
    -- Restricción de roles según tu solicitud
    rol VARCHAR NOT NULL CHECK (rol IN ('coductor', 'receptor', 'admin')),
    email VARCHAR UNIQUE NOT NULL,
    password VARCHAR NOT NULL
);

-- 4. Tabla SmartCase (Caja)
CREATE TABLE SmartCase (
    id_caja UUID PRIMARY KEY,
    -- Estados definidos en image_765a33.jpg
    estado_solenoide VARCHAR NOT NULL CHECK (estado_solenoide IN ('bloqueado', 'desbloqueado')),
    organo VARCHAR NOT NULL
);

-- 5. Tabla Ambulancia
CREATE TABLE ambulancia (
    id_ambulancia UUID PRIMARY KEY,
    placa VARCHAR NOT NULL,
    -- Tipos definidos en image_7659f9.jpg
    tipo VARCHAR NOT NULL CHECK (tipo IN ('moto', 'ambulancia'))
);

-- 6. Tabla Viaje
CREATE TABLE viaje (
    id_viaje UUID PRIMARY KEY,
    id_caja UUID NOT NULL REFERENCES SmartCase(id_caja),
    id_usuario_conductor UUID NOT NULL REFERENCES usuario(id_usuario),
    id_sede_origen UUID NOT NULL REFERENCES sede(id_sede),
    id_sede_destino UUID NOT NULL REFERENCES sede(id_sede),
    id_ambulancia UUID NOT NULL REFERENCES ambulancia(id_ambulancia),
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_llegada TIMESTAMP,
    -- Estados definidos en image_765a56.jpg
    estado_viaje VARCHAR CHECK (estado_viaje IN ('transito', 'entregado', 'muestra comprometida'))
);

-- 7. Tabla Telemetria
CREATE TABLE telemetria (
    id_telemetria UUID PRIMARY KEY,
    id_viaje UUID NOT NULL REFERENCES viaje(id_viaje),
    temperatura_interna FLOAT,
    latitud_actual DECIMAL NOT NULL,
    longitud_actual DECIMAL NOT NULL,
    fuerza_g_impacto DECIMAL,
    alerta_generada VARCHAR
);


-- 1. Asegurar que tenemos la extensión (necesario en versiones antiguas, opcional en v13+)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Actualizar Tabla Clinica
ALTER TABLE clinica 
ALTER COLUMN id_clinica SET DEFAULT gen_random_uuid();

-- 3. Actualizar Tabla Sede
ALTER TABLE sede 
ALTER COLUMN id_sede SET DEFAULT gen_random_uuid();


-- 5. Actualizar Tabla SmartCase
ALTER TABLE SmartCase 
ALTER COLUMN id_caja SET DEFAULT gen_random_uuid();

-- 6. Actualizar Tabla Ambulancia
ALTER TABLE ambulancia 
ALTER COLUMN id_ambulancia SET DEFAULT gen_random_uuid();

-- 7. Actualizar Tabla Viaje
ALTER TABLE viaje 
ALTER COLUMN id_viaje SET DEFAULT gen_random_uuid();

-- 8. Actualizar Tabla Telemetria
ALTER TABLE telemetria 
ALTER COLUMN id_telemetria SET DEFAULT gen_random_uuid();
