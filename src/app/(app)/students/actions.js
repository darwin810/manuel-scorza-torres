'use server'

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function fetchStudentsData(filters) {
  const { search, egresados, anio_id, nivel_id, grado_id, seccion_id, page = 1 } = filters;
  const limit = 10;
  const offset = (page - 1) * limit;

  let baseQuery = ' FROM estudiantes WHERE 1=1';
  const queryParams = [];
  let paramIndex = 1;

  if (egresados) {
    baseQuery += ` AND egresado = $${paramIndex++}`;
    queryParams.push(egresados == '1');
  }

  if (search) {
    baseQuery += ` AND (dni ILIKE $${paramIndex} OR nombres ILIKE $${paramIndex} OR apellido_paterno ILIKE $${paramIndex} OR apellido_materno ILIKE $${paramIndex} OR padre_nombres ILIKE $${paramIndex} OR madre_nombres ILIKE $${paramIndex})`;
    queryParams.push(`%${search}%`);
    paramIndex++;
  }

  // To support anio_id, nivel_id, grado_id, seccion_id we would JOIN with matriculas
  if (anio_id || nivel_id || grado_id || seccion_id) {
    baseQuery += ` AND id IN (SELECT estudiante_id FROM matriculas m`;
    if (nivel_id && !grado_id && !seccion_id) {
       // Si filtra nivel pero no grado, requerimos JOIN con grados para encontrar el nivel
       baseQuery += ` JOIN grados g ON m.grado_id = g.id WHERE 1=1`;
    } else {
       baseQuery += ` WHERE 1=1`;
    }
    
    if (anio_id) { baseQuery += ` AND m.anio_id = $${paramIndex++}`; queryParams.push(anio_id); }
    if (nivel_id && !grado_id && !seccion_id) { baseQuery += ` AND g.nivel_id = $${paramIndex++}`; queryParams.push(nivel_id); }
    if (grado_id) { baseQuery += ` AND m.grado_id = $${paramIndex++}`; queryParams.push(grado_id); }
    if (seccion_id) { baseQuery += ` AND m.seccion_id = $${paramIndex++}`; queryParams.push(seccion_id); }
    baseQuery += `)`;
  }

  const countRes = await query(`SELECT COUNT(*) ${baseQuery}`, queryParams);
  const total = parseInt(countRes.rows[0].count, 10);

  const dataRes = await query(`SELECT * ${baseQuery} ORDER BY id DESC LIMIT $${paramIndex++} OFFSET $${paramIndex++}`, [...queryParams, limit, offset]);

  // Analizar cada estudiante para graduacion
  const data = await Promise.all(dataRes.rows.map(async (st) => {
    // Buscar si tiene matricula para evaluar logica de promocion
    const mRes = await query(`
      SELECT g.nombre as grado_nombre, n.nombre as nivel_nombre
      FROM matriculas m
      JOIN grados g ON m.grado_id = g.id
      JOIN niveles n ON g.nivel_id = n.id
      WHERE m.estudiante_id = $1
      ORDER BY m.id DESC LIMIT 1
    `, [st.id]);
    
    let canGraduate = false;
    let canPassToSecondary = false;
    let gradoActual = '';

    if (mRes.rows.length > 0) {
      const m = mRes.rows[0];
      gradoActual = `${m.grado_nombre} de ${m.nivel_nombre}`;
      const nivel = m.nivel_nombre.toLowerCase();
      const grado = m.grado_nombre.toLowerCase();
      
      const is6toPrimaria = (grado.includes('6') || grado.includes('sexto')) && nivel.includes('primaria');
      const is5toSecundaria = (grado.includes('5') || grado.includes('quinto')) && nivel.includes('secundaria');

      if (is5toSecundaria || is6toPrimaria) canGraduate = true;
      if (is6toPrimaria) canPassToSecondary = true;
    }

    return { ...st, canGraduate, canPassToSecondary, gradoActual };
  }));

  return {
    data,
    total,
    from: offset + 1,
    to: offset + dataRes.rows.length,
    last_page: Math.ceil(total / limit) || 1,
    links: Array.from({ length: Math.ceil(total / limit) || 1 }).map((_, i) => ({
      active: i + 1 === parseInt(page),
      label: String(i + 1),
      url: `?page=${i + 1}`
    }))
  };
}

export async function getFilterOptions() {
  const [anios, niveles, grados, secciones] = await Promise.all([
    query('SELECT * FROM anios_escolares ORDER BY anio DESC'),
    query('SELECT * FROM niveles ORDER BY id ASC'),
    query('SELECT * FROM grados ORDER BY id ASC'),
    query('SELECT * FROM secciones ORDER BY id ASC')
  ]);
  return {
    anios: anios.rows,
    niveles: niveles.rows,
    grados: grados.rows,
    secciones: secciones.rows
  };
}

export async function searchStudentByDni(dni) {
  const res = await query('SELECT * FROM estudiantes WHERE dni = $1', [dni]);
  return res.rows[0] || null;
}

export async function toggleEgresadoStatus(id, status) {
  await query('UPDATE estudiantes SET egresado = $1 WHERE id = $2', [status, id]);
  revalidatePath('/students');
  return { success: true };
}

export async function saveStudent(data) {
  const {
    id, apellido_paterno, apellido_materno, nombres, dni, celular, email,
    fecha_nacimiento, departamento_nacimiento, provincia_nacimiento,
    distrito_nacimiento, domicilio, reporte, padre_dni, padre_nombres,
    padre_apellidos, padre_celular, madre_dni, madre_nombres, madre_apellidos, madre_celular
  } = data;

  if (id) {
    await query(`
      UPDATE estudiantes SET 
        apellido_paterno=$1, apellido_materno=$2, nombres=$3, dni=$4, celular=$5, email=$6,
        fecha_nacimiento=$7, departamento_nacimiento=$8, provincia_nacimiento=$9,
        distrito_nacimiento=$10, domicilio=$11, reporte=$12, padre_dni=$13, padre_nombres=$14,
        padre_apellidos=$15, padre_celular=$16, madre_dni=$17, madre_nombres=$18, madre_apellidos=$19, madre_celular=$20
      WHERE id=$21
    `, [
      apellido_paterno, apellido_materno, nombres, dni, celular, email,
      fecha_nacimiento || null, departamento_nacimiento, provincia_nacimiento,
      distrito_nacimiento, domicilio, reporte, padre_dni, padre_nombres,
      padre_apellidos, padre_celular, madre_dni, madre_nombres, madre_apellidos, madre_celular, id
    ]);
  } else {
    await query(`
      INSERT INTO estudiantes (
        apellido_paterno, apellido_materno, nombres, dni, celular, email,
        fecha_nacimiento, departamento_nacimiento, provincia_nacimiento,
        distrito_nacimiento, domicilio, reporte, padre_dni, padre_nombres,
        padre_apellidos, padre_celular, madre_dni, madre_nombres, madre_apellidos, madre_celular
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20
      )
    `, [
      apellido_paterno, apellido_materno, nombres, dni, celular, email,
      fecha_nacimiento || null, departamento_nacimiento, provincia_nacimiento,
      distrito_nacimiento, domicilio, reporte, padre_dni, padre_nombres,
      padre_apellidos, padre_celular, madre_dni, madre_nombres, madre_apellidos, madre_celular
    ]);
  }
  revalidatePath('/students');
  return { success: true };
}


export async function deleteStudent(id) {
  await query('DELETE FROM estudiantes WHERE id = $1', [id]);
  revalidatePath('/students');
  return { success: true };
}
