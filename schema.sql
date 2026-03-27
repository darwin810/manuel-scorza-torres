-- ============================================================
--  mannuel_scorza — PostgreSQL / Neon
-- ============================================================

-- Extensión para encriptación (opcional, si usas pgcrypto)
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- usuarios
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
  id             SERIAL          PRIMARY KEY,
  nombre_usuario VARCHAR(50)     UNIQUE NOT NULL,
  contrasena     VARCHAR(255)    NOT NULL
);

-- ------------------------------------------------------------
-- niveles
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS niveles (
  id     SERIAL       PRIMARY KEY,
  nombre VARCHAR(50)  NOT NULL,
  CONSTRAINT uq_nivel_nombre UNIQUE (nombre)
);

-- ------------------------------------------------------------
-- grados
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS grados (
  id       SERIAL       PRIMARY KEY,
  nivel_id INT          NOT NULL,
  nombre   VARCHAR(20)  NOT NULL,
  CONSTRAINT fk_grados_nivel    FOREIGN KEY (nivel_id) REFERENCES niveles(id),
  CONSTRAINT uq_grado_por_nivel UNIQUE (nivel_id, nombre)
);

-- ------------------------------------------------------------
-- secciones
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS secciones (
  id       SERIAL      PRIMARY KEY,
  grado_id INT         NOT NULL,
  nombre   VARCHAR(5)  NOT NULL,
  CONSTRAINT fk_secciones_grado   FOREIGN KEY (grado_id) REFERENCES grados(id),
  CONSTRAINT uq_seccion_por_grado UNIQUE (grado_id, nombre)
);

-- ------------------------------------------------------------
-- estudiantes
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS estudiantes (
  id                      SERIAL        PRIMARY KEY,
  apellido_paterno        VARCHAR(100),
  apellido_materno        VARCHAR(100),
  nombres                 VARCHAR(150),
  dni                     VARCHAR(15)   UNIQUE,
  celular                 VARCHAR(15),
  email                   VARCHAR(150),
  fecha_nacimiento        DATE,
  departamento_nacimiento VARCHAR(100),
  provincia_nacimiento    VARCHAR(100),
  distrito_nacimiento     VARCHAR(100),
  domicilio               TEXT,
  reporte                 TEXT,
  egresado                BOOLEAN       DEFAULT FALSE,
  padre_dni               VARCHAR(15),
  padre_nombres           VARCHAR(150),
  padre_apellidos         VARCHAR(150),
  padre_celular           VARCHAR(15),
  madre_dni               VARCHAR(15),
  madre_nombres           VARCHAR(150),
  madre_apellidos         VARCHAR(150),
  madre_celular           VARCHAR(15)
);

-- ------------------------------------------------------------
-- anios_escolares
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS anios_escolares (
  id   SERIAL  PRIMARY KEY,
  anio INT     UNIQUE NOT NULL
);

-- ------------------------------------------------------------
-- matriculas
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS matriculas (
  id              SERIAL  PRIMARY KEY,
  estudiante_id   INT     NOT NULL,
  grado_id        INT     NOT NULL,
  seccion_id      INT     NOT NULL,
  anio_id         INT     NOT NULL,
  fecha_matricula DATE,
  CONSTRAINT fk_matriculas_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id) ON DELETE CASCADE,
  CONSTRAINT fk_matriculas_grado      FOREIGN KEY (grado_id)      REFERENCES grados(id),
  CONSTRAINT fk_matriculas_seccion    FOREIGN KEY (seccion_id)    REFERENCES secciones(id),
  CONSTRAINT fk_matriculas_anio       FOREIGN KEY (anio_id)       REFERENCES anios_escolares(id),
  CONSTRAINT uq_matricula_anual       UNIQUE (estudiante_id, anio_id)
);

-- ------------------------------------------------------------
-- Trigger: validar que seccion pertenece al grado (INSERT)
-- En PostgreSQL los triggers requieren una función separada
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_validar_seccion_grado()
RETURNS TRIGGER AS $$
DECLARE
  v_grado INT;
BEGIN
  SELECT grado_id INTO v_grado
  FROM secciones
  WHERE id = NEW.seccion_id;

  IF v_grado IS DISTINCT FROM NEW.grado_id THEN
    RAISE EXCEPTION 'La seccion no corresponde al grado indicado.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para INSERT
CREATE OR REPLACE TRIGGER trg_matricula_seccion_insert
BEFORE INSERT ON matriculas
FOR EACH ROW EXECUTE FUNCTION fn_validar_seccion_grado();

-- Trigger para UPDATE
CREATE OR REPLACE TRIGGER trg_matricula_seccion_update
BEFORE UPDATE ON matriculas
FOR EACH ROW EXECUTE FUNCTION fn_validar_seccion_grado();

-- ------------------------------------------------------------
-- apoderados
-- En PostgreSQL se usa un tipo personalizado para el ENUM
-- ------------------------------------------------------------
CREATE TYPE parentesco_tipo AS ENUM (
  'padre','madre','abuelo','abuela','tio','tia',
  'hermano','hermana','tutor_legal','otro'
);

CREATE TABLE IF NOT EXISTS apoderados (
  id                  SERIAL           PRIMARY KEY,
  apellido_paterno    VARCHAR(100),
  apellido_materno    VARCHAR(100),
  nombres             VARCHAR(150),
  dni                 VARCHAR(15)      UNIQUE,
  celular             VARCHAR(15),
  correo              VARCHAR(150),
  domicilio           TEXT,
  parentesco          parentesco_tipo  NOT NULL DEFAULT 'otro',
  vive_con_estudiante BOOLEAN
);

-- ------------------------------------------------------------
-- estudiante_apoderado
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS estudiante_apoderado (
  id            SERIAL  PRIMARY KEY,
  estudiante_id INT     NOT NULL,
  apoderado_id  INT     NOT NULL,
  CONSTRAINT fk_ea_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id) ON DELETE CASCADE,
  CONSTRAINT fk_ea_apoderado  FOREIGN KEY (apoderado_id)  REFERENCES apoderados(id)  ON DELETE CASCADE,
  CONSTRAINT uq_est_apoderado UNIQUE (estudiante_id, apoderado_id)
);

-- ------------------------------------------------------------
-- contacto_emergencia
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS contacto_emergencia (
  id             SERIAL  PRIMARY KEY,
  estudiante_id  INT,
  telefono       VARCHAR(15),
  con_quien_vive TEXT,
  CONSTRAINT fk_ce_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- Usuario admin por defecto
-- (hash bcrypt idéntico al original)
-- ------------------------------------------------------------
INSERT INTO usuarios (nombre_usuario, contrasena)
VALUES ('admin', '$2y$12$6Nl8XlO.X2hVfRQmF.MtxOmf7D7zIn05WvQ3VzC54vPq8fL5aT3s6')
ON CONFLICT (nombre_usuario) DO NOTHING;



SELECT * from usuarios;

CREATE TABLE IF NOT EXISTS usuarios (
  id             SERIAL PRIMARY KEY,
  nombre_usuario VARCHAR(50)  UNIQUE NOT NULL,
  contrasena     VARCHAR(255) NOT NULL
);
-- Insertar o actualizar el usuario admin con la contraseña encriptada ('admin')
INSERT INTO usuarios (nombre_usuario, contrasena)
VALUES ('admin', '$2b$10$B3eRHHlkd7P9tkXiUTjcye8n6Y0c/g/ZNbhH.UR05QzX2x7U6EKtG')
ON CONFLICT (nombre_usuario) DO UPDATE 
SET contrasena = EXCLUDED.contrasena;




-- ============================================================
--  DATOS INICIALES — mannuel_scorza (Neon / PostgreSQL)
--  Niveles → Grados → Secciones (A y B) → Año escolar 2026
--  + 5 estudiantes de ejemplo ya matriculados
-- ============================================================


-- ------------------------------------------------------------
-- 1. NIVELES
-- ------------------------------------------------------------
INSERT INTO niveles (nombre) VALUES
  ('Primaria'),
  ('Secundaria')
ON CONFLICT (nombre) DO NOTHING;


-- ------------------------------------------------------------
-- 2. GRADOS
--    Primaria  → 1ro a 6to
--    Secundaria → 1ro a 5to
-- ------------------------------------------------------------
INSERT INTO grados (nivel_id, nombre) VALUES
  -- Primaria (nivel_id = 1)
  (1, '1ro'),
  (1, '2do'),
  (1, '3ro'),
  (1, '4to'),
  (1, '5to'),
  (1, '6to'),
  -- Secundaria (nivel_id = 2)
  (2, '1ro'),
  (2, '2do'),
  (2, '3ro'),
  (2, '4to'),
  (2, '5to')
ON CONFLICT (nivel_id, nombre) DO NOTHING;


-- ------------------------------------------------------------
-- 3. SECCIONES — solo A y B por grado
--    Primaria  grado_id 1..6
--    Secundaria grado_id 7..11
-- ------------------------------------------------------------
INSERT INTO secciones (grado_id, nombre) VALUES
  -- Primaria 1ro
  (1,'A'),(1,'B'),
  -- Primaria 2do
  (2,'A'),(2,'B'),
  -- Primaria 3ro
  (3,'A'),(3,'B'),
  -- Primaria 4to
  (4,'A'),(4,'B'),
  -- Primaria 5to
  (5,'A'),(5,'B'),
  -- Primaria 6to
  (6,'A'),(6,'B'),
  -- Secundaria 1ro
  (7,'A'),(7,'B'),
  -- Secundaria 2do
  (8,'A'),(8,'B'),
  -- Secundaria 3ro
  (9,'A'),(9,'B'),
  -- Secundaria 4to
  (10,'A'),(10,'B'),
  -- Secundaria 5to
  (11,'A'),(11,'B')
ON CONFLICT (grado_id, nombre) DO NOTHING;


-- ------------------------------------------------------------
-- 4. AÑOS ESCOLARES
-- ------------------------------------------------------------
INSERT INTO anios_escolares (anio) VALUES
  (2026),
  (2027),
  (2028)
ON CONFLICT (anio) DO NOTHING;


-- ------------------------------------------------------------
-- 5. ESTUDIANTES DE EJEMPLO
-- ------------------------------------------------------------
INSERT INTO estudiantes (
  apellido_paterno, apellido_materno, nombres,
  dni, celular, email, fecha_nacimiento,
  departamento_nacimiento, provincia_nacimiento, distrito_nacimiento,
  domicilio, egresado
) VALUES
  ('García',  'López',  'Lucía Fernanda', '74100001', '951000001', 'lucia.garcia@gmail.com',   '2012-03-15', 'Arequipa', 'Arequipa', 'Arequipa',       'Av. Los Rosales 123',  FALSE),
  ('Mamani',  'Quispe', 'Carlos Andrés',  '74100002', '951000002', 'carlos.mamani@gmail.com',  '2011-07-22', 'Arequipa', 'Arequipa', 'Cerro Colorado', 'Jr. Bolívar 456',      FALSE),
  ('Torres',  'Huanca', 'Valeria Sofia',  '74100003', '951000003', 'valeria.torres@gmail.com', '2013-11-05', 'Arequipa', 'Arequipa', 'Yanahuara',      'Calle Lima 789',       FALSE),
  ('Condori', 'Flores', 'Diego Alonso',   '74100004', '951000004', 'diego.condori@gmail.com',  '2010-01-30', 'Arequipa', 'Arequipa', 'Miraflores',     'Av. Parra 321',        FALSE),
  ('Vargas',  'Medina', 'Camila Beatriz', '74100005', '951000005', 'camila.vargas@gmail.com',  '2009-06-18', 'Arequipa', 'Arequipa', 'Cayma',          'Urb. La Florida 654',  FALSE)
ON CONFLICT (dni) DO NOTHING;


-- ------------------------------------------------------------
-- 6. MATRÍCULAS (año 2026)
-- ------------------------------------------------------------

-- Lucía García → Primaria 4to sección A
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='74100001'
  AND n.nombre='Primaria'   AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;

-- Carlos Mamani → Primaria 6to sección B
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='74100002'
  AND n.nombre='Primaria'   AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;

-- Valeria Torres → Secundaria 1ro sección A
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='74100003'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;

-- Diego Condori → Secundaria 3ro sección A
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='74100004'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;

-- Camila Vargas → Secundaria 5to sección B
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='74100005'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;


-- ------------------------------------------------------------
-- 7. VERIFICAR
-- ------------------------------------------------------------
SELECT
  e.apellido_paterno || ' ' || e.apellido_materno AS apellidos,
  e.nombres,
  n.nombre  AS nivel,
  g.nombre  AS grado,
  s.nombre  AS seccion,
  a.anio
FROM matriculas m
JOIN estudiantes     e ON e.id = m.estudiante_id
JOIN grados          g ON g.id = m.grado_id
JOIN niveles         n ON n.id = g.nivel_id
JOIN secciones       s ON s.id = m.seccion_id
JOIN anios_escolares a ON a.id = m.anio_id
ORDER BY n.nombre, g.nombre, s.nombre;




-- ============================================================
--  INSERT estudiantes de primaria (209 alumnos)
--  + matrículas 2026 con grado y sección
-- ============================================================

-- ------------------------------------------------------------
-- 1. ESTUDIANTES
-- ------------------------------------------------------------
INSERT INTO estudiantes (apellido_paterno, apellido_materno, nombres, dni, fecha_nacimiento, egresado)
VALUES
  ('APAZA', 'HUACO', 'EMILY ROMINA', '91263829', '2019-04-01', FALSE),
  ('CALLA', 'HUANCA', 'ARELY RUTH', '91410015', '2019-07-12', FALSE),
  ('CARDOSO', 'ARNICA', 'CHRISTOPHER ALAN', '91538470', '2019-10-09', FALSE),
  ('CASTRO', 'APAZA', 'ALEJANDRA ESTHER ANGELA', '91748426', '2020-02-27', FALSE),
  ('CCANRE', 'CONDORI', 'ANYELIS MELANY', '91476018', '2019-08-29', FALSE),
  ('CHAIÑA', 'SILVA', 'GERALD SMITH', '91692770', '2020-01-22', FALSE),
  ('CORNEJO', 'HUILLCA', 'JHOE SAMUEL', '92947110', '2019-09-08', FALSE),
  ('HEREDIA', 'MONTESINOS', 'EZEQUIEL ALFREDO', '91305222', '2019-04-24', FALSE),
  ('JIMENEZ', 'QUISPE', 'YOHANNYZ ALESSIA', '91571364', '2019-11-01', FALSE),
  ('LOPE', 'QUISPE', 'THAISA MASHIELL', '91458350', '2019-08-14', FALSE),
  ('LOPE', 'VERA', 'KAROLAYND', '91353360', '2019-06-02', FALSE),
  ('MALLCOHUACCHA', 'CUTIRE', 'XIOMARA ARLET', '91309723', '2019-05-05', FALSE),
  ('MENDOZA', 'DIAZ', 'JENKO RAFAEL', '91717567', '2020-02-07', FALSE),
  ('PANCCA', 'QUISPE', 'CÉSAR AUGUSTO', '91744485', '2020-02-24', FALSE),
  ('PARIAPAZA', 'MAMANI', 'YEIKO THAYLOR', '91806486', '2020-03-21', FALSE),
  ('RODRIGUEZ', 'QUISPE', 'LUIS SANTIAGO GIUSSEPE', '91693404', '2020-01-22', FALSE),
  ('ROSAS', 'LIZANA', 'MELODY IVANNA', '91532743', '2019-10-03', FALSE),
  ('SOTO', 'MOSCOSO', 'THAIZA ASTRID', '91342870', '2019-05-27', FALSE),
  ('CAYRO', 'MAQUERA', 'DANJHEL OSCAR', '91513516', '2019-09-01', FALSE),
  ('CHISI', 'GOMEZ', 'MARIA JESUS', '91571665', '2019-11-01', FALSE),
  ('CHOCCATA', 'HOLGUIN', 'CAMILA HAILEY', '91292504', '2019-04-24', FALSE),
  ('CUSILAIME', 'APAZA', 'ELIEL SAID', '91326990', '2019-05-14', FALSE),
  ('DAHUA', 'CCORAHUA', 'EDUARDO MATEO ERIC', '91712232', '2020-02-04', FALSE),
  ('HUILLCA', 'ARAGOTE', 'JHEYSON GABRIEL', '91493128', '2019-09-09', FALSE),
  ('ILASACA', 'PAMPA', 'ADISSON ISAÍ', '91315097', '2019-05-01', FALSE),
  ('MADARIAGA', 'YDME', 'THIAGO VALENTIN', '91624993', '2019-12-07', FALSE),
  ('PACCO', 'QUISPE', 'ALICE DÁNAE', '91347607', '2019-05-28', FALSE),
  ('PIZARRO', 'VILCAPAZA', 'JOSHUA EMANUEL', '91657607', '2019-12-30', FALSE),
  ('QUEA', 'BEDOYA', 'SEGUNDO VALENTINO', '91666694', '2020-01-05', FALSE),
  ('QUISPE', 'MAMANI', 'BRIGUITTE DIANA', '91641038', '2019-12-06', FALSE),
  ('RAMOS', 'CCOTO', 'CAMILA NAISHA', '91373231', '2019-06-09', FALSE),
  ('RIVERA', 'CALCINA', 'THIAGO JEYKO', '91686664', '2020-01-18', FALSE),
  ('ROA', 'SUCASAIRE', 'DYLAN ADRIANO', '91774681', '2020-03-14', FALSE),
  ('RUIZ', 'BRACAMONTE', 'ENRIQUE RAFAEL', '91757364', '2020-03-04', FALSE),
  ('SEDANO', 'QUISPE', 'JHON ANDERZON', '80790672', '2019-07-13', FALSE),
  ('TIPO', 'PACHA', 'FABIANA ALESSIA', '91434130', '2019-07-30', FALSE),
  ('ALARCON', 'VARGAS', 'HELIO ZAID', '91189284', '2019-02-17', FALSE),
  ('AUQUILLA', 'FONSECA', 'LUANA CRISTAL', '90829887', '2018-06-12', FALSE),
  ('AVILA', 'USKA', 'LIAM MAEL', '91042025', '2018-10-15', FALSE),
  ('CAMACHO', 'QQUECCAÑO', 'AILÉN KIMBERLY', '91099470', '2018-12-14', FALSE),
  ('CANALES', 'ORMACHEA', 'EMILIA BETSABÉ', '90971291', '2018-08-24', FALSE),
  ('COLQUE', 'TUNQUI', 'VALERIA NATHALY', '91114071', '2018-12-27', FALSE),
  ('CUNO', 'PALOMINO', 'SUHAIL YEONGSU', '91245826', '2019-03-23', FALSE),
  ('FRISANCHO', 'MEDINA', 'LUANA KALIESCA', '90243966', '2017-05-28', FALSE),
  ('LOPEZ', 'MAMANI', 'MILAN GAEL', '91564605', '2019-01-28', FALSE),
  ('MACHACA', 'COTRADO', 'LIZ DANA', '91248050', '2019-03-24', FALSE),
  ('MAQQUERA', 'APAZA', 'MEREDITH APRIL', '90714928', '2018-04-04', FALSE),
  ('RIVERA', 'CALCINA', 'JOSHUA GUSTAVO', '90656744', '2018-02-21', FALSE),
  ('SEDANO', 'QUISPE', 'YHONIOR', '80790667', '2017-07-26', FALSE),
  ('TORRES', 'CADENAS', 'FABIANA NOHELEE', '90887365', '2018-07-29', FALSE),
  ('ANCCORI', 'CCOLQUE', 'THAIS ELIETH', '90884751', '2018-07-24', FALSE),
  ('CCANSAYA', 'HOLGUIN', 'FREDY EVERT', '90949615', '2018-09-05', FALSE),
  ('COAQUIRA', 'GUTIERREZ', 'BRAND EZIO', '90835578', '2018-06-19', FALSE),
  ('CONDORI', 'PUMA', 'REY DAVID', '91191726', '2019-02-15', FALSE),
  ('HERRERA', 'VENTURA', 'TAISSA CHRISTHELL', '90956976', '2018-08-23', FALSE),
  ('HUAMAN', 'AMANQUI', 'THIAGO DONATITO', '90928484', '2018-08-23', FALSE),
  ('JARA', 'ZAPATA', 'LEE JANG DAYIRO', '90742174', '2018-04-24', FALSE),
  ('MENDOZA', 'LAZARO', 'JOSHUÉ MANUEL', '90212355', '2017-05-09', FALSE),
  ('RIOS', 'VILCA', 'ANTONIO THIAGO', '90874795', '2018-07-13', FALSE),
  ('TICAHUANCA', 'MERLIN', 'MESLY AYDE', '90984544', '2018-10-01', FALSE),
  ('VENTURA', 'MACHACA', 'LIAM ULISES', '90799634', '2018-05-26', FALSE),
  ('YUCRA', 'HUALLPA', 'LIZBETH DIANA', '91026479', '2018-10-28', FALSE),
  ('BARRIENTOS', 'MACHACCA', 'BRIANA XIOMARA', '90416988', '2017-09-08', FALSE),
  ('CARLOS', 'QUISPE', 'SEBASTIAN SAUL', '90207203', '2017-04-23', FALSE),
  ('CHURA', 'BELIZARIO', 'ALLISON ARIANA', '90704175', '2018-03-31', FALSE),
  ('CONDORI', 'PACHECO', 'GAEL SANTOS', '90704915', '2018-03-31', FALSE),
  ('CORDOVA', 'ALARCON', 'JAZMIN ALEXSIA', '90697250', '2018-03-24', FALSE),
  ('DAVILA', 'HUMPIRI', 'SERGIO MATEO', '90429059', '2017-06-21', FALSE),
  ('GOMEZ', 'QUISPE', 'SANTIAGO ALONSO', '90453369', '2017-08-10', FALSE),
  ('GONZALES', 'APAZA', 'LUIS FERNANDO', '90478120', '2017-11-03', FALSE),
  ('MALLMA', 'MAZA', 'ANGELA ROMINA', '90525485', '2017-11-30', FALSE),
  ('MAMANI', 'ARAPA', 'ALEXIS DAVID', '90260838', '2017-06-07', FALSE),
  ('MAMANI', 'JARA', 'EDMIT MOISES', '90243932', '2017-05-28', FALSE),
  ('MAMANI', 'MACEDO', 'ERICK ENRIQUE', '90584697', '2018-01-14', FALSE),
  ('ORDOÑEZ', 'CALDERON', 'BRIDNY ANYELY', '90294284', '2017-07-01', FALSE),
  ('PIZANGO', 'GEMAN', 'LUCIA KATTANIA', '90241540', '2017-05-29', FALSE),
  ('QUISPE', 'BELIZARIO', 'DYLAN RODRIGO', '90649467', '2018-02-06', FALSE),
  ('ROJAS', 'LOPEZ', 'KENETH YHAMIR', '90196369', '2017-05-01', FALSE),
  ('VILCA', 'CONDORI', 'SANTIAGO PATRICIO', '90561391', '2017-12-26', FALSE),
  ('ALFERES', 'TOROCAHUA', 'MATEO RUBEN', '90418476', '2017-09-14', FALSE),
  ('BERNAL', 'ESPINOZA', 'ABIGAIL MILENA', '90457889', '2017-10-20', FALSE),
  ('CCACCASACA', 'FOLLANO', 'LUZ MASHIEL', '90562326', '2018-01-02', FALSE),
  ('CISNEROS', 'ARANDA', 'FERNANDA ELIZABETH', '90221665', '2017-05-14', FALSE),
  ('CRISPIN', 'SULLCARAY', 'JHOANNA LIZ', '81386087', '2017-09-07', FALSE),
  ('DELGADO', 'FLORES', 'LENA CRISTINE', '90487864', '2017-11-05', FALSE),
  ('HUAYLLAPUMA', 'BUSTINCIO', 'DOMINIC LIONEL', '90207555', '2017-05-04', FALSE),
  ('HUILLCA', 'VILCA', 'SALOMON ISAI', '90389917', '2017-08-16', FALSE),
  ('MAMANI', 'JILAJA', 'CRISTIAN LIONEL', '90479331', '2017-10-11', FALSE),
  ('MAMANI', 'PACCO', 'DYLAN BENJAMIN', '90391809', '2017-08-28', FALSE),
  ('MIRANDA', 'FERNANDEZ', 'ZULLY NOEMI', '92572417', '2017-08-15', FALSE),
  ('PACCO', 'LLAMOCA', 'THAIS SHARUMY', '90544034', '2017-12-15', FALSE),
  ('QUISPE', 'QUISPE', 'OLIVER LIAN', '90213210', '2017-05-02', FALSE),
  ('SEVILLANOS', 'RODRIGO', 'ZULEMA THAYSA', '90298627', '2017-07-05', FALSE),
  ('SULLCARAY', 'TAIPE', 'SHEYLA ROSMERI', '81386086', '2017-07-21', FALSE),
  ('ANCULLE', 'CAMARGO', 'MARIA FERNANDA', '79881852', '2016-09-04', FALSE),
  ('APAZA', 'HUACO', 'ALONDRA SAMIRA', '79996790', '2016-12-24', FALSE),
  ('CANALES', 'ORMACHEA', 'DANIELA SOFIA', '79562178', '2016-02-17', FALSE),
  ('CHAMBI', 'HUAMAN', 'EIMY MADELEYNE', '79854920', '2016-09-14', FALSE),
  ('CHIPA', 'HUAMANI', 'LUIS DANIEL', '79734408', '2016-06-18', FALSE),
  ('CONDORI', 'CARY', 'ARJEN NALDO', '79816357', '2016-08-20', FALSE),
  ('CONDORI', 'DIAZ', 'ELIZABETH RIHANA', '79850175', '2016-09-13', FALSE),
  ('CUTI', 'HUILLCA', 'THIAGO JEAN PIERRE', '79751714', '2016-06-10', FALSE),
  ('MENDOZA', 'LAZARO', 'JOSHUA CALEB', '81630580', '2015-09-01', FALSE),
  ('PACCO', 'CCANCHILLO', 'ASHLY ANDREA', '79979480', '2016-12-04', FALSE),
  ('PEÑA', 'VALVERDE', 'ANAHI AMANDA', '79836890', '2016-09-03', FALSE),
  ('PONCE', 'BEDOYA', 'MARIA DEL PILAR ROSANGELA', '79745967', '2016-07-04', FALSE),
  ('QUISPE', 'VALENCIA', 'ADRIANA ABIGAIL', '79710259', '2016-06-11', FALSE),
  ('RODRIGUEZ', 'ANCO', 'KALEB YEREMY JUNIOR', '79973041', '2016-11-20', FALSE),
  ('SEDANO', 'REGINALDO', 'JINIA ZOLYMAR', '79994340', '2016-12-23', FALSE),
  ('SULLCA', 'HANCCO', 'CHRISTIAN SAUL', '90058648', '2017-02-03', FALSE),
  ('UGARTE', 'SUNE', 'MILETT LUANA', '90128319', '2017-03-17', FALSE),
  ('ACHULLI', 'RODRIGO', 'VALENTINA CRISTEL', '79705436', '2016-05-11', FALSE),
  ('ANCCORI', 'CCOLQUE', 'DAIRA SHANTALE', '79898105', '2016-10-12', FALSE),
  ('CHOQUEHUANCA', 'SUMIRE', 'JHOSEP ALEXANDER', '79864145', '2016-09-20', FALSE),
  ('CHUMBES', 'SERRANO', 'YAIR JUNIOR', '90981845', '2017-03-28', FALSE),
  ('CONTRERAS', 'SANTILLANA', 'BRIANNA VALERIA', '90069728', '2017-02-02', FALSE),
  ('FAIJO', 'OVANDO', 'ADELIZ', '79647699', '2016-04-26', FALSE),
  ('GÜERE', 'HUARCA', 'BERNHARD NEYTAN', '79884929', '2016-10-01', FALSE),
  ('HUALLPA', 'MALLMA', 'THIAGO MATHIAS', '79878370', '2016-09-28', FALSE),
  ('HUANACUNI', 'HUAMAN', 'ARIANA ASENET', '90058572', '2017-01-26', FALSE),
  ('MACHACA', 'MAMANI', 'HABBIE LUANA', '90059387', '2017-01-17', FALSE),
  ('MAMANI', 'AGUIRRE', 'JHON PATRICIO', '90032168', '2017-01-10', FALSE),
  ('MIRANDA', 'RODRIGUEZ', 'IAN ADRIEL KEFREN', '90002899', '2016-12-28', FALSE),
  ('PACHECO', 'RANGEL', 'JORGE', '002510532', '2016-04-07', FALSE),
  ('PANDIA', 'PARICAHUA', 'BRYSSNEY MERLYN', '79648436', '2016-04-29', FALSE),
  ('PROVINCIA', 'CHUQUIMAMANI', 'ESTEBAN GAEL', '90001791', '2016-12-27', FALSE),
  ('QUISPE', 'HOLGUIN', 'DIEGO JAEL', '90050322', '2017-01-28', FALSE),
  ('YUJRA', 'INCACUTIPA', 'LUIS ANTHONY', '79783432', '2016-08-01', FALSE),
  ('ZAMATA', 'LAGOS', 'ESTEFANY YAMILETT', '79977015', '2016-11-30', FALSE),
  ('ARCE', 'QUISPE', 'MIGUEL ANGEL MATEO', '79487332', '2016-01-22', FALSE),
  ('BALBIN', 'AGÜERO', 'ALIZZ STHEFANI', '79252941', '2015-08-17', FALSE),
  ('CHAVEZ', 'CONDORI', 'CARLOS NARCISO', '79677980', '2015-08-13', FALSE),
  ('CONDORI', 'PUMA', 'NEYMAR WILLIAN', '79436436', '2015-12-06', FALSE),
  ('CORDOVA', 'ALARCON', 'DALESKA FERNANDA', '79192119', '2015-06-22', FALSE),
  ('CORNEJO', 'HUILLCA', 'SILA DAYANA', '90223138', '2015-09-19', FALSE),
  ('FIGUEROA', 'GOMEZ', 'ALEJANDRO SEBASTIAN', '81629452', '2015-05-27', FALSE),
  ('FRISANCHO', 'MEDINA', 'PABLO ESTEFANO', '79417320', '2015-11-26', FALSE),
  ('HEREDIA', 'MONTESINOS', 'EDUARDO PAOLO', '79426747', '2015-10-30', FALSE),
  ('HUAMAN', 'SILUPU', 'JOAQUIN ALADINO', '79141369', '2015-05-28', FALSE),
  ('HUAYHUA', 'CCORAHUA', 'LIONO ANDRIW SANTIAGO', '81629231', '2015-05-17', FALSE),
  ('MENDOZA', 'SERRANO', 'EDDY GABRIEL', '81648405', '2014-08-13', FALSE),
  ('MIRANDA', 'CONDORI', 'KARELY ROSABEL', '79579451', '2016-03-20', FALSE),
  ('PARI', 'CONDORI', 'JEREMY ALDAIR', '79336795', '2015-10-05', FALSE),
  ('PAZ', 'PERALTA', 'GINEBRA BRIHANNA', '79198111', '2015-06-25', FALSE),
  ('PONCE', 'BEDOYA', 'BRIELLA PIERINA', '79085525', '2015-04-24', FALSE),
  ('PORTUGAL', 'OVIEDO', 'ADRIANO FACUNDO', '79167128', '2015-06-16', FALSE),
  ('POVIS', 'PACCO', 'LISHA ISABEL', '79275315', '2015-08-07', FALSE),
  ('QUISPE', 'BELIZARIO', 'MAYTE ADRIANA', '79550987', '2016-02-11', FALSE),
  ('QUISPE', 'CCALLO', 'ALIZ ANYELA', '79205443', '2015-06-02', FALSE),
  ('TULA', 'SONCCO', 'ANDREA YHOSELYN', '79219530', '2015-07-24', FALSE),
  ('VERA', 'HANCCO', 'MERCEDES KATHERINE', '79553072', '2016-03-03', FALSE),
  ('YUPA', 'QUISPE', 'ANTHONY FRANCISCO ALEXANDER', '79489610', '2016-01-23', FALSE),
  ('ALARCON', 'MATUTE', 'GABRIEL ANDRE', '79094828', '2015-04-27', FALSE),
  ('ARAPA', 'LLAVE', 'EVELYN KATALEYA', '81629051', '2015-05-05', FALSE),
  ('CABANA', 'PUMA', 'SILVANA ANDREA', '79533533', '2016-02-11', FALSE),
  ('CHIPANA', 'QUISPE', 'XHAVI ELISON', '81376057', '2016-02-18', FALSE),
  ('CONDORI', 'BEJARANO', 'ADRIANO ANGEL', '79505173', '2016-02-03', FALSE),
  ('GROVAS', 'PACCO', 'ABIGAIL MELANY', '79458372', '2016-01-03', FALSE),
  ('HANCCO', 'APAZA', 'ANDREE ORLANDO', '79087574', '2015-04-23', FALSE),
  ('HUANACUNI', 'HUAMAN', 'LIAN BENJAMIN', '79141962', '2015-05-29', FALSE),
  ('LOPE', 'QUISPE', 'STELLA RISU', '79570234', '2016-03-11', FALSE),
  ('MORALES', 'AVILES', 'GINO JHOSMANI', '79131814', '2015-05-10', FALSE),
  ('MOTTOCCANCHI', 'AYAMAMANI', 'AXEL GAEL', '79099592', '2015-05-09', FALSE),
  ('NAHUE', 'YALLERCCO', 'BRUNELLA ARLETH', '81523912', '2016-02-11', FALSE),
  ('OJEDA', 'SALAS', 'NIKOLAS EZEL', '79312956', '2015-09-26', FALSE),
  ('PACCO', 'LLAMOCA', 'FABIAN GADIEL', '79599655', '2016-03-24', FALSE),
  ('PACHECO', 'SANCHEZ', 'BRYANA MERLYA', '79270295', '2015-08-09', FALSE),
  ('PERALTA', 'MAMANI', 'KIARA MILAGROS', '79392791', '2015-11-19', FALSE),
  ('ROQUE', 'TOROCAHUA', 'MARIANNE FRANCHESCA', '79243694', '2015-08-12', FALSE),
  ('ROSAS', 'AGUILAR', 'YOSELIN CAMILA', '79565066', '2016-03-04', FALSE),
  ('SALAS', 'BARRIOS', 'CATHALEYA VALENTINA', '79537794', '2016-02-03', FALSE),
  ('SEDANO', 'QUISPE', 'YOLANDA', '80790662', '2015-08-13', FALSE),
  ('SONCCO', 'COLQUE', 'TRISTAN MILAN', '79440332', '2015-12-17', FALSE),
  ('SOTO', 'LUICHO', 'THIAGO ANDREII', '79130726', '2015-05-01', FALSE),
  ('SULLCARAY', 'TAIPE', 'DIANA', '81292026', '2015-05-13', FALSE),
  ('TITO', 'ALMONTE', 'INGRID ARACELY', '81639357', '2015-06-07', FALSE),
  ('ZAPANA', 'RIVERA', 'XIOMARA RAFAELA', '79725584', '2016-03-29', FALSE),
  ('ALEJOS', 'COSAR', 'LIAM SAYCAR', '78763866', '2014-08-03', FALSE),
  ('BARRIOS', 'MENDEZ', 'MATHEO IGNACIO', '115948927', '2014-11-13', FALSE),
  ('BETANCUR', 'BERROCAL', 'ERICK JOHAO', '81592131', '2014-06-02', FALSE),
  ('CABANA', 'PUMA', 'ANGEL ARMANDO', '81594627', '2014-09-04', FALSE),
  ('CHIPANE', 'PORTILLO', 'ANTHONY JEIKO', '81592940', '2014-07-19', FALSE),
  ('CHUIMA', 'HUAMAN', 'MARIA ALEJANDRA', '81224009', '2014-09-11', FALSE),
  ('HACHA', 'CONDORI', 'JONATHAN MATÍAZ', '81194877', '2013-09-14', FALSE),
  ('HUANCA', 'CCAMA', 'NORICK SEBASTIAN', '81607687', '2014-12-06', FALSE),
  ('MAMANI', 'MAMANI', 'MICHELLE SHARMELY', '78739807', '2014-07-17', FALSE),
  ('MASCO', 'CEREZO', 'YAMILA FERNANDA', '78733856', '2014-08-24', FALSE),
  ('PACCO', 'MENDOZA', 'HAFID ERICK', '79005661', '2015-03-03', FALSE),
  ('PACHA', 'MEDINA', 'LUCIANA GUADALUPE', '81592868', '2014-07-23', FALSE),
  ('PACO', 'ZUÑIGA', 'DANILO JOSÉ', '79024345', '2015-03-19', FALSE),
  ('PEÑA', 'VALVERDE', 'LEYDI YANIRA', '78916158', '2014-12-18', FALSE),
  ('ROQUE', 'CCORAHUA', 'BRITHANI VALERIA', '78747362', '2014-08-30', FALSE),
  ('TARIFA', 'SURCO', 'FLOR KARELY', '81630667', '2014-09-27', FALSE),
  ('VALDIVIA', 'CHUQUITAYPE', 'DAYRON HENRRY', '78211225', '2013-07-22', FALSE),
  ('YUPANQUI', 'MAMANI', 'JUDITH KATIA', '79030875', '2015-03-21', FALSE),
  ('APFATA', 'BUSTINCIO', 'ROY BENJAMIN', '81603582', '2014-12-01', FALSE),
  ('BORJA', 'VARGAS', 'GIOVANNI ELAR', '78710269', '2014-08-08', FALSE),
  ('CHAMPI', 'CUTIRE', 'JHORDAN ALDAIR', '81594820', '2014-10-03', FALSE),
  ('ESPINOZA', 'BETANCUR', 'MAX JOSUÉ', '78985024', '2015-02-15', FALSE),
  ('HERRERA', 'VENTURA', 'VALENTINA JAZMIN', '78774815', '2014-08-15', FALSE),
  ('HUARMIYURI', 'SILVA', 'ALEXIS ADRIANO', '79137760', '2015-01-22', FALSE),
  ('LAURA', 'ADRIAN', 'PRISCILA', '81550127', '2014-06-13', FALSE),
  ('LOPEZ', 'MAMANI', 'ANGEL URIEL', '78862650', '2013-08-05', FALSE),
  ('MAMANI', 'CCANSAYA', 'GARET NEYMAR', '78601988', '2014-05-20', FALSE),
  ('MAYTA', 'MACHACCA', 'SOELENG GEORGHET', '81594240', '2014-07-24', FALSE),
  ('SOLORZANO', 'SAMATA', 'LEYDI YOELINA', '78586368', '2014-04-29', FALSE),
  ('TINOCO', 'CALCINA', 'MIGUEL ALBERTO', '81594436', '2014-06-26', FALSE),
  ('UTURUNCO', 'INQUILLAY', 'ROGER', '79063886', '2014-04-30', FALSE),
  ('VALENCIA', 'MALLMA', 'LIAM RAFAEL', '78731961', '2014-08-25', FALSE)
ON CONFLICT (dni) DO NOTHING;

-- ------------------------------------------------------------
-- 2. MATRÍCULAS 2026
-- ------------------------------------------------------------
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91263829'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91410015'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91538470'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91748426'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91476018'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91692770'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='92947110'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91305222'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91571364'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91458350'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91353360'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91309723'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91717567'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91744485'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91806486'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91693404'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91532743'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91342870'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91513516'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91571665'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91292504'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91326990'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91712232'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91493128'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91315097'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91624993'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91347607'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91657607'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91666694'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91641038'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91373231'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91686664'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91774681'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91757364'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='80790672'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91434130'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91189284'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90829887'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91042025'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91099470'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90971291'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91114071'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91245826'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90243966'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91564605'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91248050'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90714928'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90656744'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='80790667'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90887365'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90884751'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90949615'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90835578'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91191726'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90956976'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90928484'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90742174'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90212355'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90874795'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90984544'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90799634'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='91026479'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90416988'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90207203'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90704175'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90704915'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90697250'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90429059'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90453369'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90478120'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90525485'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90260838'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90243932'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90584697'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90294284'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90241540'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90649467'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90196369'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90561391'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90418476'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90457889'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90562326'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90221665'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81386087'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90487864'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90207555'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90389917'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90479331'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90391809'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='92572417'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90544034'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90213210'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90298627'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81386086'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79881852'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79996790'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79562178'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79854920'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79734408'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79816357'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79850175'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79751714'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81630580'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79979480'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79836890'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79745967'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79710259'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79973041'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79994340'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90058648'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90128319'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79705436'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79898105'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79864145'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90981845'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90069728'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79647699'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79884929'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79878370'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90058572'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90059387'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90032168'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90002899'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='002510532'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79648436'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90001791'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90050322'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79783432'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79977015'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79487332'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79252941'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79677980'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79436436'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79192119'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90223138'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81629452'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79417320'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79426747'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79141369'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81629231'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81648405'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79579451'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79336795'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79198111'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79085525'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79167128'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79275315'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79550987'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79205443'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79219530'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79553072'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79489610'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79094828'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81629051'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79533533'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81376057'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79505173'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79458372'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79087574'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79141962'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79570234'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79131814'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79099592'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81523912'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79312956'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79599655'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79270295'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79392791'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79243694'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79565066'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79537794'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='80790662'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79440332'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79130726'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81292026'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81639357'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79725584'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78763866'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='115948927'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81592131'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81594627'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81592940'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81224009'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81194877'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81607687'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78739807'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78733856'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79005661'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81592868'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79024345'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78916158'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78747362'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81630667'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78211225'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79030875'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81603582'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78710269'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81594820'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78985024'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78774815'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79137760'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81550127'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78862650'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78601988'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81594240'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78586368'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81594436'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79063886'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-10'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78731961'
  AND n.nombre='Primaria' AND g.nivel_id=n.id AND g.nombre='6to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;

-- Verificar
SELECT
  e.apellido_paterno || ' ' || e.apellido_materno AS apellidos,
  e.nombres, n.nombre AS nivel, g.nombre AS grado, s.nombre AS seccion, a.anio
FROM matriculas m
JOIN estudiantes e ON e.id=m.estudiante_id
JOIN grados g ON g.id=m.grado_id
JOIN niveles n ON n.id=g.nivel_id
JOIN secciones s ON s.id=m.seccion_id
JOIN anios_escolares a ON a.id=m.anio_id
ORDER BY g.nombre, s.nombre, e.apellido_paterno;




--====================================================================================
-- secundaria
-- ==============================================================
-- SECUNDARIA 2026 — Neon / PostgreSQL
-- 243 estudiantes + matrículas
-- ==============================================================

-- ------------------------------------------------------------
-- 1. ESTUDIANTES
-- ------------------------------------------------------------
INSERT INTO estudiantes (apellido_paterno, apellido_materno, nombres, dni, fecha_nacimiento, egresado)
VALUES
  ('ALANIA', 'VICHATA', 'DAYIRO ALEXIS', '63153927', '2013-07-21', FALSE),
  ('AVILA', 'USKA', 'ARIANA GUADALUPE', '81228111', '2013-08-19', FALSE),
  ('BORDA', 'CALSINA', 'RAFAEL YASMANI', '78478089', '2014-03-04', FALSE),
  ('CALCINA', 'NOA', 'KIARA MAYTE', '78081538', '2013-04-11', FALSE),
  ('CHAVEZ', 'MAMANI', 'ABAD ALAIN', '78292861', '2013-08-20', FALSE),
  ('CHILE', 'QUISPE', 'WILLY RODRIGO', '78352131', '2013-12-03', FALSE),
  ('CHOQUEMAQUE', 'COLQUE', 'EBANDRO YONATHAN', '78329575', '2013-10-25', FALSE),
  ('CHUMBES', 'DEVERA', 'ANDY JOSHUA', '63073431', '2013-06-22', FALSE),
  ('CONDORI', 'DIAZ', 'THIAGO MYLAN', '81196156', '2013-10-03', FALSE),
  ('GÜERE', 'HUARCA', 'ANGELO EMANUEL', '78435507', '2014-01-29', FALSE),
  ('HUAMAN', 'AGUIRRE', 'JORGE ERASMO', '81228357', '2013-07-26', FALSE),
  ('HUAMAN', 'MENDEZ', 'ROYER YENKO', '78211766', '2013-06-19', FALSE),
  ('HUAYCANI', 'CALISAYA', 'GUSTAVO ALEJANDRO', '78511532', '2014-03-24', FALSE),
  ('ILASACA', 'PAMPA', 'MILAGROS ESPERANZA', '78305980', '2013-06-02', FALSE),
  ('MUÑA', 'TOROCAHUA', 'DILAND ANDREE', '81118551', '2013-04-26', FALSE),
  ('OVIEDO', 'CASAZOLA', 'FABIANA DAYNÉ', '81197024', '2013-10-11', FALSE),
  ('PANDIA', 'QUISPE', 'AMY', '78440075', '2014-01-16', FALSE),
  ('PIZARRO', 'VILCAPAZA', 'ADRIANO JOAQUIN', '78263838', '2013-09-10', FALSE),
  ('SALHUA', 'CCOROPUNA', 'DIEGO SEBASTIAN', '78235058', '2013-07-07', FALSE),
  ('SEDANO', 'QUISPE', 'WILIAN', '78392718', '2013-12-22', FALSE),
  ('SONCCO', 'CALCINA', 'FLOR MARILY', '78153451', '2013-05-27', FALSE),
  ('TAIPE', 'DIAZ', 'ALANIS DASHA', '81228148', '2013-09-01', FALSE),
  ('TORRES', 'LUQUE', 'FIORELA YESENIA', '78420925', '2014-01-22', FALSE),
  ('TULA', 'MAMANI', 'FRANCO AARON', '81539952', '2014-01-27', FALSE),
  ('VERA', 'HANCCO', 'NAYELI MISHELL', '81539445', '2014-01-22', FALSE),
  ('YANA', 'RODRIGUEZ', 'MARIA BELEN', '78646536', '2014-02-25', FALSE),
  ('ALEJO', 'GAMARRA', 'RUTH AYUMI', '78132929', '2013-05-18', FALSE),
  ('AMANCA', 'TTITO', 'EDUARDO EFRAIN', '81560158', '2013-05-25', FALSE),
  ('BUENDIA', 'MENDOZA', 'LUCAS JANO', '78218966', '2013-08-10', FALSE),
  ('CCALLO', 'CHINCHERCOMA', 'JOEL VICTOR', '81169449', '2013-08-17', FALSE),
  ('CHACO', 'BARANDIARAN', 'YHERIK AUGUSTO YSBAIL', '78722246', '2013-02-28', FALSE),
  ('CHIPANA', 'QUISPE', 'AARON CRHISTIAN ABIERY', '80931057', '2014-01-26', FALSE),
  ('CHOQUECABANA', 'CALLOHUANCA', 'MILLET IVANA', '78268274', '2013-09-03', FALSE),
  ('CHUMBES', 'SERRANO', 'JACK NEYMAR', '79208199', '2013-04-14', FALSE),
  ('COPARA', 'HUAYNA', 'NEVENKA JAKELINE', '78051687', '2013-04-04', FALSE),
  ('DIAZ', 'TICONA', 'LUHANA KEYLA', '81114430', '2013-05-05', FALSE),
  ('HUACHO', 'AGUILAR', 'KELY MARINA', '78838410', '2014-01-21', FALSE),
  ('JAEN', 'CUTIPA', 'CARLOS DANIEL', '81539484', '2014-01-23', FALSE),
  ('LEON', 'BEDOYA', 'KENYA KELEEN', '78096942', '2013-04-02', FALSE),
  ('LUQUE', 'PALOMINO', 'HANSEL ISMAEL', '81190234', '2013-12-17', FALSE),
  ('MARURE', 'MAMANI', 'ASHLY JAHAIRA', '78492780', '2014-03-06', FALSE),
  ('MENDEZ', 'RIVAS', 'JEANPIERE MAYCOL', '81558691', '2014-02-28', FALSE),
  ('PACCO', 'CALCINA', 'NEYMAR RODRIGO', '78221020', '2013-07-27', FALSE),
  ('PANCCA', 'QUISPE', 'ORLANDO JESUS', '81558783', '2014-03-02', FALSE),
  ('PORTUGAL', 'OVIEDO', 'ARANTZA KEISHLA', '81194454', '2013-09-21', FALSE),
  ('QUISPE', 'PALACIOS', 'MIRIAM FERNANDA', '78133506', '2013-05-24', FALSE),
  ('RAMOS', 'CUTIRE', 'DIEGO ARNULFO', '81540347', '2014-02-23', FALSE),
  ('ROJO', 'QUISPE', 'BRITTANY NIKOLE', '90187002', '2013-07-04', FALSE),
  ('SALAS', 'BARRIOS', 'BENJAMIN EMANUEL', '81539239', '2014-01-14', FALSE),
  ('SANDI', 'BALTA', 'LUCIANA ANABEL', '78161153', '2013-06-17', FALSE),
  ('SEVILLANOS', 'RODRIGO', 'ADRIANO JOEL', '81558831', '2014-03-05', FALSE),
  ('TIPULA', 'DIAZ', 'EMANUEL JORGE', '78176027', '2013-07-12', FALSE),
  ('VELASQUEZ', 'TULA', 'FREDY ANGEL', '81444212', '2013-11-04', FALSE),
  ('VILLAFUERTE', 'POVEA', 'LIAM NEYMAR', '90276763', '2014-02-01', FALSE),
  ('ASCENCIOS', 'CCAHUA', 'DANIEL ELIAS', '81195564', '2012-10-04', FALSE),
  ('ASCENCIOS', 'GARCIA', 'LUIS CARLOS', '81377787', '2012-06-10', FALSE),
  ('BERNAL', 'ESPINOZA', 'MELANI JULIETA', '62146335', '2012-09-22', FALSE),
  ('CARCAUSTO', 'YARICE', 'NHILA ABIGAIL', '63244994', '2012-05-04', FALSE),
  ('CCOSCCO', 'CEREZO', 'ANGIE YUDELY', '63533332', '2012-10-19', FALSE),
  ('CHAISA', 'VILCA', 'YANDY ALICIA', '81052155', '2012-11-11', FALSE),
  ('CHIPANE', 'PORTILLO', 'ANA GRAYLIN', '62819420', '2011-04-17', FALSE),
  ('CORNEJO', 'HUILLCA', 'JUAN GABRIEL', '63535664', '2012-06-13', FALSE),
  ('FLORES', 'MAMANI', 'SULLY NAOMI', '81113858', '2013-03-27', FALSE),
  ('GARCIA', 'ILLACUTIPA', 'ARIANA ZAHORY', '77875829', '2012-11-13', FALSE),
  ('GOMEZ', 'QUISPE', 'FABRIZIO JEDAM', '81112330', '2013-02-09', FALSE),
  ('HUAMANI', 'CHURATA', 'ALEXANDRO YEFERSSON', '62958658', '2011-10-03', FALSE),
  ('NAHUE', 'LEON', 'PAMELA MASIEL', '81093756', '2012-12-14', FALSE),
  ('PARI', 'CONDORI', 'THAYZ KEYRA', '63735811', '2013-01-02', FALSE),
  ('PUMA', 'YUPANQUI', 'CINTIA ANABEL', '81078343', '2012-10-20', FALSE),
  ('PUSACLLA', 'VELA', 'MICAELA', '63429546', '2012-11-20', FALSE),
  ('RUIZ', 'ZEVALLOS', 'ERICK GHAEL', '63735801', '2012-12-07', FALSE),
  ('SALAS', 'MEDINA', 'GABRIEL MATEO', '77862645', '2012-06-25', FALSE),
  ('SANCHEZ', 'BELTRAN', 'BRITNEY MELANY', '63727904', '2012-04-11', FALSE),
  ('SANCHEZ', 'BELTRAN', 'DANY JHOSHIMAR', '63727905', '2012-04-11', FALSE),
  ('SARMIENTO', 'SARMIENTO', 'DANIEL STHIPF', '81132770', '2013-01-05', FALSE),
  ('SONCCO', 'APAZA', 'YEAN CARLOS HUBER', '78032709', '2013-02-23', FALSE),
  ('BELIZARIO', 'CCALLO', 'KELLY MASHIEL', '77653181', '2012-05-18', FALSE),
  ('BOZA', 'PORTILLA', 'DAYIRO BENJAMIN', '81063789', '2012-10-31', FALSE),
  ('CALLA', 'HUANCA', 'SERGIO ADOLFO', '81047810', '2012-07-13', FALSE),
  ('CCORAHUA', 'DIAZ', 'LUIS GABRIEL', '80857111', '2012-08-24', FALSE),
  ('CCORPUNA', 'TURPO', 'TANIA NICOL', '80868132', '2013-03-23', FALSE),
  ('CCOTO', 'CAYANI', 'MATHIAS JULIAN', '80985895', '2012-10-29', FALSE),
  ('CENTENO', 'IQUIAPAZA', 'ZULLY BELLA DULZE', '77824702', '2012-09-12', FALSE),
  ('JAYO', 'HUAHUACONDORI', 'LUIS FERNANDO', '77724737', '2012-06-18', FALSE),
  ('KAIRA', 'HUAYTA', 'LUIS FERNANDO', '81093190', '2012-08-13', FALSE),
  ('LOPEZ', 'ZUÑIGA', 'ENDERSON ALEXANDER', '77886247', '2012-10-29', FALSE),
  ('MAMANI', 'JARA', 'ARTUR JHENRRY', '77879158', '2012-11-13', FALSE),
  ('MEDINA', 'DIAZ', 'ANGELA GABRIELA', '81093307', '2012-11-30', FALSE),
  ('MELO', 'CHILO', 'LEONEL YORDY', '81156174', '2013-02-10', FALSE),
  ('OVIEDO', 'CASAZOLA', 'TATIANA ANDREA', '77728816', '2012-05-22', FALSE),
  ('PACHA', 'GONZALES', 'ADRIANO ALBERT YOSIMAR', '63232353', '2012-05-10', FALSE),
  ('PAPEL', 'HOLGUIN', 'ABRYL JAMYLET', '63244987', '2012-05-13', FALSE),
  ('PASTOR', 'MATUTE', 'JHARETH ANTONELA', '63762206', '2012-07-24', FALSE),
  ('QUISPE', 'HUAMANI', 'YEISON HEYNER', '63423127', '2012-08-08', FALSE),
  ('RIOS', 'VILCA', 'ADRIANA BELEN ESTRELLA', '81094308', '2013-01-06', FALSE),
  ('TAMO', 'COAGUILA', 'LUIS FERNANDO', '77759868', '2012-07-26', FALSE),
  ('TRUJILLO', 'CORREA', 'THIAGO LINCOL', '62832079', '2013-01-19', FALSE),
  ('URBINA', 'MAMANI', 'ESTER ANTONELA', '77980612', '2013-01-28', FALSE),
  ('ZAPANA', 'RIVERA', 'DAYIRO JOSUE', '81094442', '2012-11-16', FALSE),
  ('AYALA', 'MEZA', 'BELTSASAR', '62222818', '2010-10-05', FALSE),
  ('CCACCASACA', 'FOLLANO', 'RUTH KAREN', '63114715', '2012-03-16', FALSE),
  ('CHAMBI', 'CALDERON', 'LEYDY MILAGROS', '62939917', '2011-12-01', FALSE),
  ('CHIPA', 'HUAMANI', 'PAOLA ALEXANDRA', '63093662', '2012-02-17', FALSE),
  ('CHUMBES', 'SERRANO', 'FELIPE ARMANDO', '63084913', '2011-11-26', FALSE),
  ('COA', 'CAMPERO', 'RICGIAN DANIEL', '34292571', '2011-01-30', FALSE),
  ('DIAZ', 'PACCI', 'BRAYAN ALONSO', '63084451', '2011-12-08', FALSE),
  ('FERNANDEZ', 'HANCCO', 'MIGUEL ANGEL', '62701495', '2010-10-18', FALSE),
  ('FLORES', 'MAMANI', 'LUANA KONY NANCY', '62818924', '2011-04-04', FALSE),
  ('GARATE', 'YLLANES', 'CARLOS FRANCISCO', '62960498', '2011-10-11', FALSE),
  ('HUIRMA', 'VALENCIA', 'JHON RONALDO', '62819999', '2011-04-24', FALSE),
  ('LAURA', 'QUISPE', 'JOSELITO SEBASTIAN', '62888790', '2011-09-03', FALSE),
  ('LOPEZ', 'ZUÑIGA', 'JENNIFER BRIGITH DE LOS ANGELES', '77109365', '2011-05-23', FALSE),
  ('MAMANI', 'JILAJA', 'FIORELLA MILAGROS', '62831191', '2011-07-11', FALSE),
  ('MAMANI', 'ZAMATA', 'LIZBETH MARYORI', '63693766', '2012-02-26', FALSE),
  ('MASCO', 'CEREZO', 'KAREN MILAGROS', '62702152', '2010-12-09', FALSE),
  ('PACHECO', 'RAMOS', 'BETSY YAMILA', '62886488', '2011-06-28', FALSE),
  ('PALLI', 'ENRIQUEZ', 'JAMES OXFORD', '62858901', '2011-07-03', FALSE),
  ('PUMA', 'CONDORI', 'PATRIK DASHYRO', '62254243', '2011-06-02', FALSE),
  ('QUISPE', 'REAÑO', 'ANGELO HAIR', '62888332', '2011-08-08', FALSE),
  ('QUISPE', 'URURI', 'ALVARO JHAIR', '63174354', '2012-01-03', FALSE),
  ('RAMOS', 'CUTIRE', 'NAYELI', '62259227', '2011-08-13', FALSE),
  ('RIVAS', 'BENITES', 'LUCERO', '63293139', '2011-07-11', FALSE),
  ('SUAREZ', 'MANGO', 'RICARDO GEANFRANCO', '62958754', '2011-08-27', FALSE),
  ('TALAVERA', 'ZEVALLOS', 'ANDRE YAREL', '63093666', '2012-03-06', FALSE),
  ('TORRES', 'AGUIRRE', 'LUIS JAVIER', '62810398', '2011-04-24', FALSE),
  ('UTURUNCO', 'INQUILLAY', 'ROSYLINDA', '63047429', '2012-01-10', FALSE),
  ('VILCA', 'PACHA', 'MATEO ALEXANDER', '63083855', '2011-12-05', FALSE),
  ('VILLEGAS', 'CHAVEZ', 'HUGO DANIEL ALEJANDRO', '77598280', '2012-03-18', FALSE),
  ('YUJRA', 'INCACUTIPA', 'LIZ KATHERIN', '62231011', '2011-04-01', FALSE),
  ('ALANIA', 'VICHATA', 'KATERIN SARA', '62083883', '2011-04-04', FALSE),
  ('ANCCO', 'CAHUANA', 'BRENDA IVET', '63230264', '2012-02-19', FALSE),
  ('ARAPA', 'TUPAC', 'ALDANA KARELI', '63084478', '2011-12-21', FALSE),
  ('ARREDONDO', 'BORDA', 'DAYANA MARIBEL', '63084979', '2012-01-01', FALSE),
  ('BOLIVAR', 'MARIN', 'VICTOR EDUARDO', 'V33870371', '2011-05-22', FALSE),
  ('CALLA', 'CCAYAVILCA', 'KRIS ANGELA', '62985471', '2011-12-01', FALSE),
  ('CATACORA', 'ASTO', 'ANYELI DANIELA', '62959570', '2011-10-12', FALSE),
  ('CEVALLOS', 'ALVAREZ', 'NAOMY CLARIBET', '62887421', '2011-07-23', FALSE),
  ('CONDORI', 'VALLEJOS', 'SOFIA BELEN', '81195532', '2011-06-22', FALSE),
  ('FLORES', 'MAMANI', 'MARK JUDA', '63795128', '2011-07-05', FALSE),
  ('GOMEZ', 'CCORIMANYA', 'NADIA PATRICIA', '77621858', '2012-02-28', FALSE),
  ('HUAMAN', 'CHINO', 'JEFFERSON', '62702567', '2010-12-21', FALSE),
  ('LOPEZ', 'TACO', 'IAN FRANCO', '62959817', '2011-10-02', FALSE),
  ('MADALENA', 'HERNANDEZ', 'VICTORIA SARAI', '058691605', '2011-01-07', FALSE),
  ('MURO', 'LOPEZ', 'VALERIA SOLANGE MILAGROS', '74792828', '2010-10-11', FALSE),
  ('PACO', 'ZUÑIGA', 'SEBASTIAN JOSUE', '62886247', '2011-07-11', FALSE),
  ('PEÑARANDA', 'VILCA', 'FABIAN ALONSO', '62886066', '2011-05-30', FALSE),
  ('QUIRITA', 'UMASI', 'RODRIGO ALDAIR', '63414442', '2011-10-10', FALSE),
  ('QUISPE', 'QUISPE', 'DAYANA MAYLY', '62834588', '2012-01-20', FALSE),
  ('ROJAS', 'CRUZ', 'LUCIANA ANDREA', '63135837', '2012-01-19', FALSE),
  ('ROJAS', 'RODRIGO', 'MAYFER CLARET', '63535863', '2011-09-20', FALSE),
  ('SILVANO', 'HUALINGA', 'CINTIA ALEXIS', '77625615', '2012-03-25', FALSE),
  ('TAIPE', 'DIAZ', 'HARVEY FABIAN', '62886988', '2011-08-02', FALSE),
  ('TEJADA', 'FLORES', 'JAIRO RAMIRO', '78359951', '2010-08-15', FALSE),
  ('TULA', 'MAMANI', 'XAVIER DARONY', '63170608', '2012-01-09', FALSE),
  ('TULA', 'SONCCO', 'CARLOS RODRIGO', '63093682', '2012-03-24', FALSE),
  ('CALACHUA', 'NUÑEZ', 'MARGARET BALERY', '62594545', '2010-04-22', FALSE),
  ('CASTRO', 'VALDERRAMA', 'KASSANDRA SOLANGE', '62701576', '2010-11-25', FALSE),
  ('CHAMBILLA', 'CHOQUEMAMANI', 'JOSUE MANUEL', '62678747', '2010-11-16', FALSE),
  ('CORNEJO', 'MARIN', 'RODRIGO JAIR', '62583534', '2010-04-03', FALSE),
  ('FERNANDEZ', 'CCAMO', 'RUTH ZUNILDA', '62473332', '2011-01-21', FALSE),
  ('HUAMAN', 'CCOTO', 'JOSE MANUEL', '62652295', '2010-05-31', FALSE),
  ('JACINTO', 'RAMOS', 'JACOB', '62113144', '2010-05-12', FALSE),
  ('MACHACA', 'MINGA', 'ANDREA LUZMIEL', '62551783', '2010-04-10', FALSE),
  ('MAMANI', 'CHOQUE', 'MELISSA FERNANDA', '61991528', '2010-11-06', FALSE),
  ('MAMANI', 'CHUCTAYA', 'JIMENA NICOLL', '62171699', '2010-04-22', FALSE),
  ('MAMANI', 'MACEDO', 'SHAMIR ENRIQUE', '62457907', '2010-07-16', FALSE),
  ('MAMANI', 'MAMANI', 'LEONEL', '61816540', '2009-07-28', FALSE),
  ('MENDEZ', 'RIVAS', 'ANGEL PIERO', '62677663', '2010-10-06', FALSE),
  ('PARI', 'QUISPE', 'CARLOS EDUARDO', '62385734', '2010-05-27', FALSE),
  ('RODRIGO', 'PORTUGAL', 'MARIA VALENTINA', '62137341', '2010-11-03', FALSE),
  ('RODRIGUEZ', 'MAMANI', 'JUAN DIEGO', '62702395', '2010-11-26', FALSE),
  ('SURCO', 'FLORES', 'ALEXANDER WILLY', '62638235', '2010-05-10', FALSE),
  ('URBINA', 'MAMANI', 'ERICK ANTONNY', '62508870', '2010-08-19', FALSE),
  ('VILCA', 'HUACO', 'GIMENA DARIANA', '62678773', '2010-11-05', FALSE),
  ('YANA', 'RODRIGUEZ', 'LETICIA DANUZKA', '62740840', '2010-12-28', FALSE),
  ('AGUILAR', 'CCAPA', 'JANETH MARELY', '62732730', '2011-01-09', FALSE),
  ('ALVAREZ', 'CHOQUE', 'DANIELA BRIYIT', '61991545', '2011-03-30', FALSE),
  ('ARREDONDO', 'BORDA', 'NEYELY ANGELICA', '81093200', '2010-10-25', FALSE),
  ('BALBIN', 'AGÜERO', 'ANYELI PAMELA', '60661685', '2008-06-10', FALSE),
  ('BALBIN', 'AGÜERO', 'CARLOS THAYLOR', '63188702', '2010-04-11', FALSE),
  ('CACERES', 'TULA', 'CARLOS JOSHUE', '62516332', '2010-12-31', FALSE),
  ('CHILE', 'QUISPE', 'JONATAN JUVER', '77987002', '2010-06-06', FALSE),
  ('CONDORI', 'DIAZ', 'ANGELA YUREMY', '62457644', '2010-06-24', FALSE),
  ('FLORES', 'GONZALES', 'TELMA VALENTINA', '62741619', '2011-03-01', FALSE),
  ('HUALLPA', 'MALLMA', 'ALEXIS GUDIEL', '74785420', '2010-09-28', FALSE),
  ('JANAMPA', 'SERRANO', 'LEONARD', '62458461', '2010-08-10', FALSE),
  ('LUQUE', 'GUZMAN', 'ARACELY DAYANA', '62756624', '2011-03-09', FALSE),
  ('MORA', 'QUISPE', 'LUNA URPI', '62436895', '2010-07-05', FALSE),
  ('PASTOR', 'MATUTE', 'ENITH ANEL', '62454839', '2010-08-15', FALSE),
  ('PEREZ', 'PAYE', 'YADHIRA MIRELLA', '62446091', '2010-08-07', FALSE),
  ('QUISPE', 'HUAMANI', 'LUZ BRISAYDA', '62361178', '2011-01-20', FALSE),
  ('SULLCA', 'HANCCO', 'ABRAHAN EDU', '62784002', '2011-03-28', FALSE),
  ('TARIFA', 'SURCO', 'YAHIR', '61824998', '2009-06-16', FALSE),
  ('VILCAPE', 'MAMANI', 'FRANK DIEGO', '61825862', '2009-06-03', FALSE),
  ('ANAHUA', 'QUISPE', 'EHIDAN VICTOR', '61414103', '2008-07-26', FALSE),
  ('APAZA', 'YANARICO', 'FIORELA BRIGGITTE', '62593600', '2010-02-20', FALSE),
  ('CABRERA', 'MARTINEZ', 'LUJAN DEL ROCIO', '61826064', '2009-06-22', FALSE),
  ('CHOQUE', 'CASA', 'JUAN GABRIEL', '63535839', '2010-03-27', FALSE),
  ('CHOQUEMAQUE', 'COLQUE', 'MELISSA NIKOL', '61921783', '2010-03-13', FALSE),
  ('DAVILA', 'HUMPIRI', 'MARIANA LIZETH', '78592709', '2009-07-18', FALSE),
  ('GUILLEN', 'CCORAHUA', 'JULIO RODRIGO', '61800695', '2009-05-22', FALSE),
  ('HUIRMA', 'VALENCIA', 'HUGO ARMANDO', '61824969', '2009-06-03', FALSE),
  ('MAMANI', 'TITO', 'AVRIL ANYELI', '61800493', '2009-04-22', FALSE),
  ('MENDOZA', 'FIGUEROA', 'VALERI ALESSANDRA', '61054171', '2007-07-16', FALSE),
  ('OCHOA', 'FERNANDEZ', 'JOSE MANUEL', '61928865', '2009-12-17', FALSE),
  ('ORDOÑEZ', 'LABAN', 'TONNY AXEL', '61802117', '2009-06-30', FALSE),
  ('ORTIZ', 'TAIPE', 'YEIKO ANYELO', '61883814', '2010-02-01', FALSE),
  ('PACHA', 'OBANDO', 'ESTEFANY KASANDRA', '61892497', '2009-08-28', FALSE),
  ('QUISPE', 'SULLO', 'JULIO CESAR', '61574960', '2009-08-30', FALSE),
  ('RAYME', 'AGUILAR', 'RONY', '61708669', '2009-09-01', FALSE),
  ('ROQUE', 'CCORAHUA', 'GABRIEL ALEXANDER', '62562461', '2010-01-17', FALSE),
  ('SALAS', 'MEDINA', 'JOAN JOSUE', '61894606', '2009-11-29', FALSE),
  ('SIFUENTES', 'QUISPE', 'NICOLAS AUGUSTO', '62347602', '2009-12-04', FALSE),
  ('TORRES', 'HANCCO', 'DANIELA MICHELL', '62818330', '2010-02-27', FALSE),
  ('UNSUETA', 'SERRANO', 'FRANK DEIVIS', '62765923', '2009-10-07', FALSE),
  ('VALLEJO', 'CCOYLLULLI', 'FLOR ARELI', '61630787', '2009-12-16', FALSE),
  ('VERA', 'CONDORI', 'LI CAROLINA', '61938187', '2009-05-01', FALSE),
  ('YUPA', 'QUISPE', 'DAVID RICARDO JUNIOR', '61897571', '2009-10-06', FALSE),
  ('ALDUDE', 'CENTENO', 'JHOSEP FERNANDO', '61758827', '2009-05-19', FALSE),
  ('ANQUISE', 'YANA', 'MIGUEL ANGEL RAUL', '62562842', '2010-02-23', FALSE),
  ('ARAPA', 'TUPAC', 'ANTHONY BERNY', '61799346', '2009-05-09', FALSE),
  ('ARMA', 'CCALLUCHE', 'YALU ARACELY', '61893790', '2009-10-11', FALSE),
  ('ARREDONDO', 'BORDA', 'MARIA FERNANDA', '62469641', '2009-11-24', FALSE),
  ('BEDOYA', 'QUISPE', 'ANGEL YEYSON', '61459634', '2008-12-25', FALSE),
  ('CCANCHILLO', 'GUZMAN', 'ROBINHO', '61455977', '2008-09-15', FALSE),
  ('CCOTO', 'CAYANI', 'NIKOL TAYRA', '61968741', '2009-07-14', FALSE),
  ('CONDORI', 'MAMANI', 'CARLOS DANIEL', '61893892', '2009-11-13', FALSE),
  ('CUTIPA', 'CHISE', 'RICARDO MAXIMO', '62820387', '2009-05-15', FALSE),
  ('FARFAN', 'PUMA', 'MIGUEL BRANDO', '61847829', '2009-08-05', FALSE),
  ('FLORES', 'SOTO', 'MENLY JHONSO', '60330186', '2009-11-30', FALSE),
  ('HUAMAN', 'AMANQUI', 'TANIA CAMILA', '61800319', '2009-05-07', FALSE),
  ('IDME', 'IDME', 'ERICK SALVADOR', '62516300', '2009-08-02', FALSE),
  ('MAMANI', 'ARAPA', 'DAISY', '61635477', '2009-07-22', FALSE),
  ('MASCO', 'AYVAR', 'EVO ESTANISLAO', '61974414', '2009-11-27', FALSE),
  ('MOTTOCCANCHI', 'AYAMAMANI', 'PIERINA MIZU', '61938176', '2009-04-10', FALSE),
  ('NUÑONCA', 'FLORES', 'ROBERT ALEXANDER', '61461252', '2009-02-05', FALSE),
  ('PALLI', 'ENRIQUEZ', 'GEORGE RICARDO', '62352132', '2009-12-20', FALSE),
  ('PARI', 'CONDORI', 'IAN FLAVIO CESAR', '62313012', '2009-11-02', FALSE),
  ('PILA', 'QUISPE', 'MISHEYDA', '62372440', '2010-03-09', FALSE),
  ('PUMA', 'YUPANQUI', 'YOSELIN KEILA', '61825377', '2009-07-06', FALSE),
  ('SARMIENTO', 'SARMIENTO', 'SEBASTIAN OLMAR', '61730564', '2009-07-05', FALSE),
  ('TUFIÑO', 'HURTADO', 'NOEMI ESTHER', '73556401', '2009-07-19', FALSE),
  ('YUCRA', 'VALENCIA', 'NAYSHEL CLARIBEHT', '62557422', '2010-02-22', FALSE)
ON CONFLICT (dni) DO NOTHING;

-- ------------------------------------------------------------
-- 2. MATRÍCULAS 2026
-- ------------------------------------------------------------
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63153927'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81228111'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78478089'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78081538'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78292861'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78352131'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78329575'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63073431'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81196156'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78435507'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81228357'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78211766'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78511532'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78305980'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81118551'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81197024'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78440075'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78263838'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78235058'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78392718'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78153451'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81228148'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78420925'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81539952'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81539445'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78646536'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78132929'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81560158'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78218966'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81169449'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78722246'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='80931057'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78268274'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='79208199'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78051687'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81114430'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78838410'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81539484'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78096942'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81190234'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78492780'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81558691'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78221020'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81558783'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81194454'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78133506'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81540347'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90187002'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81539239'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78161153'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81558831'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78176027'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81444212'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='90276763'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='1ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81195564'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81377787'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62146335'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63244994'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63533332'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81052155'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62819420'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63535664'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81113858'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77875829'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81112330'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62958658'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81093756'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63735811'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81078343'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63429546'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63735801'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77862645'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63727904'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63727905'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81132770'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78032709'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77653181'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81063789'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81047810'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='80857111'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='80868132'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='80985895'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77824702'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77724737'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81093190'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77886247'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77879158'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81093307'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81156174'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77728816'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63232353'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63244987'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63762206'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63423127'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81094308'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77759868'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62832079'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77980612'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81094442'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='2do'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62222818'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63114715'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62939917'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63093662'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63084913'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='34292571'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63084451'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62701495'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62818924'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62960498'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62819999'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62888790'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77109365'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62831191'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63693766'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62702152'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62886488'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62858901'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62254243'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62888332'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63174354'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62259227'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63293139'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62958754'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63093666'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62810398'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63047429'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63083855'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77598280'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62231011'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62083883'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63230264'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63084478'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63084979'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='V33870371'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62985471'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62959570'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62887421'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81195532'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63795128'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77621858'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62702567'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62959817'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='058691605'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='74792828'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62886247'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62886066'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63414442'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62834588'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63135837'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63535863'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77625615'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62886988'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78359951'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63170608'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63093682'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='3ro'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62594545'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62701576'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62678747'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62583534'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62473332'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62652295'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62113144'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62551783'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61991528'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62171699'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62457907'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61816540'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62677663'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62385734'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62137341'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62702395'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62638235'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62508870'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62678773'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62740840'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62732730'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61991545'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='81093200'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='60661685'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63188702'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62516332'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='77987002'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62457644'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62741619'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='74785420'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62458461'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62756624'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62436895'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62454839'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62446091'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62361178'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62784002'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61824998'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61825862'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='4to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61414103'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62593600'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61826064'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='63535839'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61921783'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='78592709'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61800695'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61824969'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61800493'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61054171'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61928865'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61802117'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61883814'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61892497'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61574960'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61708669'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62562461'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61894606'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62347602'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62818330'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62765923'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61630787'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61938187'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61897571'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='A'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61758827'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62562842'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61799346'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61893790'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62469641'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61459634'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61455977'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61968741'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61893892'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62820387'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61847829'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='60330186'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61800319'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62516300'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61635477'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61974414'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61938176'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61461252'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62352132'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62313012'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62372440'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61825377'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='61730564'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='73556401'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;
INSERT INTO matriculas (estudiante_id, grado_id, seccion_id, anio_id, fecha_matricula)
SELECT e.id, g.id, s.id, a.id, '2026-03-18'
FROM estudiantes e, niveles n, grados g, secciones s, anios_escolares a
WHERE e.dni='62557422'
  AND n.nombre='Secundaria' AND g.nivel_id=n.id AND g.nombre='5to'
  AND s.grado_id=g.id AND s.nombre='B'
  AND a.anio=2026
ON CONFLICT (estudiante_id, anio_id) DO NOTHING;

-- ------------------------------------------------------------
-- 3. VERIFICAR
-- ------------------------------------------------------------
SELECT
  e.apellido_paterno || ' ' || e.apellido_materno AS apellidos,
  e.nombres, n.nombre AS nivel, g.nombre AS grado, s.nombre AS seccion, a.anio
FROM matriculas m
JOIN estudiantes e ON e.id=m.estudiante_id
JOIN grados g ON g.id=m.grado_id
JOIN niveles n ON n.id=g.nivel_id
JOIN secciones s ON s.id=m.seccion_id
JOIN anios_escolares a ON a.id=m.anio_id
WHERE n.nombre='Secundaria'
ORDER BY g.nombre, s.nombre, e.apellido_paterno;

