-- ============================================================
--  SmartCase — Script completo de creación de base de datos
--  Ejecutar una sola vez sobre una base de datos vacía
-- ============================================================
 
-- ── Extensión para UUIDs automáticos ────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
 
-- ── 1. Clínica ───────────────────────────────────────────────
CREATE TABLE clinica (
    id_clinica  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR     NOT NULL
);
 
-- ── 2. Sede ──────────────────────────────────────────────────
CREATE TABLE sede (
    id_sede     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    id_clinica  UUID        NOT NULL REFERENCES clinica(id_clinica),
    nombre      VARCHAR     NOT NULL
);
 
-- ── 3. Usuario ───────────────────────────────────────────────
CREATE TABLE usuario (
    id_usuario      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    id_sede         UUID        REFERENCES sede(id_sede),          -- nullable para admin
    nombre_completo VARCHAR     NOT NULL,
    rol             VARCHAR     NOT NULL CHECK (rol IN ('coductor', 'receptor', 'admin')),
    email           VARCHAR     UNIQUE NOT NULL,
    password        VARCHAR     NOT NULL
);
 
-- ── 4. SmartCase (Caja) ──────────────────────────────────────
CREATE TABLE smartcase (
    id_caja           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    estado_solenoide  VARCHAR NOT NULL CHECK (estado_solenoide IN ('bloqueado', 'desbloqueado')),
    organo            VARCHAR NOT NULL
);
 
-- ── 5. Ambulancia ────────────────────────────────────────────
CREATE TABLE ambulancia (
    id_ambulancia  UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    placa          VARCHAR NOT NULL,
    tipo           VARCHAR NOT NULL CHECK (tipo IN ('moto', 'ambulancia'))
);
 
-- ── 6. Viaje ─────────────────────────────────────────────────
CREATE TABLE viaje (
    id_viaje              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    id_caja               UUID        NOT NULL REFERENCES smartcase(id_caja),
    id_usuario_conductor  UUID        NOT NULL REFERENCES usuario(id_usuario),
    id_usuario_receptor   UUID        REFERENCES usuario(id_usuario),
    id_sede_origen        UUID        NOT NULL REFERENCES sede(id_sede),
    id_sede_destino       UUID        NOT NULL REFERENCES sede(id_sede),
    id_ambulancia         UUID        NOT NULL REFERENCES ambulancia(id_ambulancia),
    fecha_inicio          TIMESTAMP   NOT NULL,
    fecha_llegada         TIMESTAMP,
    estado_viaje          VARCHAR     CHECK (estado_viaje IN ('transito', 'entregado', 'muestra comprometida')),
    pin_entrega           VARCHAR(6)  NOT NULL 
);
 
-- ── 7. Telemetría ────────────────────────────────────────────
CREATE TABLE telemetria (
    id_telemetria       UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),
    id_viaje            UUID                     NOT NULL REFERENCES viaje(id_viaje),
    temperatura_interna FLOAT,
    temperatura_ambiente DECIMAL(5,2),
    humedad             DECIMAL(5,2),
    lux                 DECIMAL(10,2),
    altitud             DECIMAL(8,2),
    latitud_actual      DECIMAL                  NOT NULL,
    longitud_actual     DECIMAL                  NOT NULL,
    fuerza_g_impacto    DECIMAL,
    alerta_generada     VARCHAR,
    desde_bluetooth     BOOLEAN                  DEFAULT TRUE,
    registrado_en       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

SELECT * FROM viaje
SELECT * FROM telemetria

UPDATE viaje 
SET estado_viaje = 'transito' 
WHERE id_viaje = '9395a38d-e4f5-4578-bfc3-da32b0e56c9b';