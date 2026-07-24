-- flotillas-henrys — esquema base (Railway Postgres)
-- Reemplaza al proyecto de Supabase de GAGA que se dio de baja por
-- inactividad (ver memoria feedback_dar_raiz_a_proyectos). Mismas tablas
-- y columnas que ya esperan flotilla.html / index.html / proyeccion.html,
-- para no tener que tocar el frontend.

CREATE TABLE IF NOT EXISTS kilometrajes (
  eco                text PRIMARY KEY,
  km_actual           integer,
  km_ultimo_servicio  integer,
  fecha_captura       timestamptz DEFAULT now()
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

-- Rol anónimo de solo-lectura (+ escritura de kilometraje) para exponer
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
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO web_anon;

-- El rol de conexión de PostgREST necesita poder cambiar (SET ROLE) a web_anon.
GRANT web_anon TO postgres;
