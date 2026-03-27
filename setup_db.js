import fs from 'fs';
import pkg from 'pg';
const { Pool } = pkg;

const envFile = fs.readFileSync('.env.local', 'utf8');
const dbUrlMatch = envFile.match(/DATABASE_URL="([^"]+)"/);
let dbUrl = '';
if (dbUrlMatch) {
  dbUrl = dbUrlMatch[1];
}

const pool = new Pool({
  connectionString: dbUrl,
});

async function setup() {
  try {
    const queryText = `
      CREATE TABLE IF NOT EXISTS niveles (
        id     SERIAL PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL UNIQUE
      );

      CREATE TABLE IF NOT EXISTS grados (
        id       SERIAL PRIMARY KEY,
        nivel_id INT         NOT NULL,
        nombre   VARCHAR(20) NOT NULL,
        CONSTRAINT fk_grados_nivel    FOREIGN KEY (nivel_id) REFERENCES niveles(id),
        CONSTRAINT uq_grado_por_nivel UNIQUE (nivel_id, nombre)
      );

      CREATE TABLE IF NOT EXISTS secciones (
        id       SERIAL PRIMARY KEY,
        grado_id INT        NOT NULL,
        nombre   VARCHAR(5) NOT NULL,
        CONSTRAINT fk_secciones_grado   FOREIGN KEY (grado_id) REFERENCES grados(id),
        CONSTRAINT uq_seccion_por_grado UNIQUE (grado_id, nombre)
      );

      CREATE TABLE IF NOT EXISTS estudiantes (
        id                      SERIAL PRIMARY KEY,
        apellido_paterno        VARCHAR(100),
        apellido_materno        VARCHAR(100),
        nombres                 VARCHAR(150),
        dni                     VARCHAR(15)  UNIQUE,
        celular                 VARCHAR(15),
        email                   VARCHAR(150),
        fecha_nacimiento        DATE,
        departamento_nacimiento VARCHAR(100),
        provincia_nacimiento    VARCHAR(100),
        distrito_nacimiento     VARCHAR(100),
        domicilio               TEXT,
        reporte                 TEXT,
        egresado                BOOLEAN      DEFAULT FALSE,
        padre_dni               VARCHAR(15),
        padre_nombres           VARCHAR(150),
        padre_apellidos         VARCHAR(150),
        padre_celular           VARCHAR(15),
        madre_dni               VARCHAR(15),
        madre_nombres           VARCHAR(150),
        madre_apellidos         VARCHAR(150),
        madre_celular           VARCHAR(15)
      );

      CREATE TABLE IF NOT EXISTS anios_escolares (
        id   SERIAL PRIMARY KEY,
        anio INT UNIQUE NOT NULL
      );

      CREATE TABLE IF NOT EXISTS matriculas (
        id              SERIAL PRIMARY KEY,
        estudiante_id   INT  NOT NULL,
        grado_id        INT  NOT NULL,
        seccion_id      INT  NOT NULL,
        anio_id         INT  NOT NULL,
        fecha_matricula DATE,
        CONSTRAINT fk_matriculas_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id) ON DELETE CASCADE,
        CONSTRAINT fk_matriculas_grado      FOREIGN KEY (grado_id)      REFERENCES grados(id),
        CONSTRAINT fk_matriculas_seccion    FOREIGN KEY (seccion_id)    REFERENCES secciones(id),
        CONSTRAINT fk_matriculas_anio       FOREIGN KEY (anio_id)       REFERENCES anios_escolares(id),
        CONSTRAINT uq_matricula_anual       UNIQUE (estudiante_id, anio_id)
      );

      CREATE TABLE IF NOT EXISTS apoderados (
        id                  SERIAL PRIMARY KEY,
        apellido_paterno    VARCHAR(100),
        apellido_materno    VARCHAR(100),
        nombres             VARCHAR(150),
        dni                 VARCHAR(15)  UNIQUE,
        celular             VARCHAR(15),
        correo              VARCHAR(150),
        domicilio           TEXT,
        parentesco          VARCHAR(50) NOT NULL DEFAULT 'otro',
        vive_con_estudiante BOOLEAN
      );

      CREATE TABLE IF NOT EXISTS estudiante_apoderado (
        id            SERIAL PRIMARY KEY,
        estudiante_id INT NOT NULL,
        apoderado_id  INT NOT NULL,
        CONSTRAINT fk_ea_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id) ON DELETE CASCADE,
        CONSTRAINT fk_ea_apoderado  FOREIGN KEY (apoderado_id)  REFERENCES apoderados(id)  ON DELETE CASCADE,
        CONSTRAINT uq_est_apoderado UNIQUE (estudiante_id, apoderado_id)
      );

      CREATE TABLE IF NOT EXISTS contacto_emergencia (
        id             SERIAL PRIMARY KEY,
        estudiante_id  INT,
        telefono       VARCHAR(15),
        con_quien_vive TEXT,
        CONSTRAINT fk_ce_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id) ON DELETE CASCADE
      );
    `;
    await pool.query(queryText);
    console.log('Tablas creadas en PostgreSQL con éxito');
  } catch (error) {
    console.error('Error creando tablas:', error);
  } finally {
    pool.end();
  }
}

setup();
