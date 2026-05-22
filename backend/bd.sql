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
-- NOTA: id_sede es nullable para usuarios administrativos
--       que no pertenecen a una sede específica.
CREATE TABLE usuario (
    id_usuario      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    id_sede         UUID        REFERENCES sede(id_sede),          -- nullable (admin sin sede fija)
    nombre_completo VARCHAR     NOT NULL,
    rol             VARCHAR     NOT NULL CHECK (rol IN ('conductor', 'receptor', 'admin')),
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
    id_usuario_receptor   UUID        REFERENCES usuario(id_usuario),   -- nullable hasta entrega
    id_sede_origen        UUID        NOT NULL REFERENCES sede(id_sede),
    id_sede_destino       UUID        NOT NULL REFERENCES sede(id_sede),
    id_ambulancia         UUID        NOT NULL REFERENCES ambulancia(id_ambulancia),
    fecha_inicio          TIMESTAMP   NOT NULL,
    fecha_llegada         TIMESTAMP,
    estado_viaje          VARCHAR     CHECK (estado_viaje IN ('transito', 'entregado', 'muestra comprometida'))
);
 
 
-- ── 7. Telemetría ────────────────────────────────────────────
CREATE TABLE telemetria (
    id_telemetria       UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
    id_viaje            UUID                        NOT NULL REFERENCES viaje(id_viaje),
    -- Sensores ambientales internos
    temperatura_interna FLOAT,
    temperatura_ambiente DECIMAL(5,2),
    humedad             DECIMAL(5,2),
    lux                 DECIMAL(10,2),
    altitud             DECIMAL(8,2),
    -- Posición y evento
    latitud_actual      DECIMAL                     NOT NULL,
    longitud_actual     DECIMAL                     NOT NULL,
    fuerza_g_impacto    DECIMAL,
    alerta_generada     VARCHAR,
    -- Metadatos de registro
    desde_bluetooth     BOOLEAN                     DEFAULT TRUE,
    registrado_en       TIMESTAMP WITH TIME ZONE    DEFAULT CURRENT_TIMESTAMP
);
 