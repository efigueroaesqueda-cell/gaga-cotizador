-- flotillas-henrys — esquema base (Railway Postgres)
-- Reemplaza al proyecto de Supabase de GAGA que se dio de baja por
-- inactividad (ver memoria feedback_dar_raiz_a_proyectos). Mismas tablas
-- y columnas que ya esperan flotilla.html / index.html / proyeccion.html,
-- para no tener que tocar el frontend.

CREATE TABLE IF NOT EXISTS kilometrajes (
  eco                text PRIMARY KEY,
  km_actual           integer,
  km_ultimo_servicio  integer,
  fecha_captura       timestamptz DEFAULT now(),
  motor               text  -- capturado por quien atiende la unidad si el motor sigue "Pendiente confirmar"
);

CREATE TABLE IF NOT EXISTS precios_gaga (
  id                serial PRIMARY KEY,
  tipo_vehiculo     text NOT NULL,
  km_intervalo      integer NOT NULL,
  tipo              text NOT NULL,      -- 'Refacción' | 'Mano de obra' | 'Cortesía'
  descripcion       text NOT NULL,
  descripcion_sub   text,
  cantidad          integer NOT NULL DEFAULT 1,
  precio_unitario   numeric(10,2) NOT NULL DEFAULT 0,
  total             numeric(10,2) NOT NULL DEFAULT 0,
  es_estimado       boolean NOT NULL DEFAULT true,  -- true = precio de referencia, no oficial
  UNIQUE (tipo_vehiculo, km_intervalo, tipo, descripcion)
);

CREATE INDEX IF NOT EXISTS idx_precios_gaga_tipo_km
  ON precios_gaga (tipo_vehiculo, km_intervalo);

CREATE TABLE IF NOT EXISTS citas (
  id                    serial PRIMARY KEY,
  eco                   text,               -- NULL si es unidad_desc (unidad nueva sin dar de alta)
  unidad_desc           text,               -- armadora + modelo + año cuando la unidad no esta registrada
  operador              text,               -- quien trae/maneja la unidad
  fecha                 date NOT NULL,
  hora                  text NOT NULL,
  km_reportado          integer,
  descripcion_problema  text,               -- queja/observacion del operador
  extras                text,               -- items adicionales que el cliente pidio agregar al servicio de ese km
  compania              text,               -- de la sesion (usuarios.compania) si inicio sesion
  estado                text NOT NULL DEFAULT 'pendiente',
  creado_en             timestamptz NOT NULL DEFAULT now()
);

-- Compañía/usuario/contraseña por cliente de flotilla (ej. GAGA), no solo
-- por email — mismo patrón de login que HenryLeads. Contraseñas SIEMPRE
-- cifradas con pgcrypto (bcrypt), nunca en texto plano.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS usuarios (
  id            serial PRIMARY KEY,
  compania      text NOT NULL,
  usuario       text NOT NULL,
  password_hash text NOT NULL,
  nombre        text,
  activo        boolean NOT NULL DEFAULT true,
  creado_en     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (compania, usuario)
);

-- Expuesta vía PostgREST como POST /rpc/login. Compara con crypt() —
-- nunca compara el hash directo ni regresa password_hash al cliente.
CREATE OR REPLACE FUNCTION login(p_compania text, p_usuario text, p_password text)
RETURNS TABLE(id int, compania text, usuario text, nombre text)
LANGUAGE sql SECURITY DEFINER
AS $$
  SELECT u.id, u.compania, u.usuario, u.nombre
  FROM usuarios u
  WHERE lower(u.compania) = lower(p_compania)
    AND lower(u.usuario) = lower(p_usuario)
    AND u.activo = true
    AND u.password_hash = crypt(p_password, u.password_hash);
$$;

-- Rol anónimo de solo-lectura (+ escritura de kilometraje/citas) para exponer
-- vía PostgREST, equivalente al "anon key" de Supabase.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'web_anon') THEN
    CREATE ROLE web_anon NOLOGIN;
  END IF;
END $$;

GRANT USAGE ON SCHEMA public TO web_anon;
GRANT SELECT ON precios_gaga TO web_anon;
GRANT SELECT, INSERT, UPDATE ON kilometrajes TO web_anon;
GRANT SELECT, INSERT, UPDATE ON citas TO web_anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO web_anon;
GRANT EXECUTE ON FUNCTION login(text,text,text) TO web_anon;

-- El rol de conexión de PostgREST necesita poder cambiar (SET ROLE) a web_anon.
GRANT web_anon TO postgres;
