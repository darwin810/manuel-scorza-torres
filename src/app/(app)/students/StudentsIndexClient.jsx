'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { fetchStudentsData, deleteStudent, toggleEgresadoStatus } from './actions';
import ConfirmModal from '../ConfirmModal';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';

export default function StudentsIndexClient({ initialFiltersParams }) {
  const [studentsData, setStudentsData] = useState({ data: [], total: 0, from: 0, to: 0, last_page: 1, links: [] });
  const [loading, setLoading] = useState(true);
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [confirmConfig, setConfirmConfig] = useState({ isOpen: false });
  const [filters, setFilters] = useState({
    search: '',
    egresados: '0',
    anio_id: '',
    nivel_id: '',
    grado_id: '',
    seccion_id: '',
    page: 1
  });

  const { anios, niveles, grados, secciones } = initialFiltersParams;

  useEffect(() => {
    let debounceTimer = setTimeout(() => {
      loadData(filters);
    }, 400);
    return () => clearTimeout(debounceTimer);
  }, [filters]);

  const loadData = async (activeFilters) => {
    setLoading(true);
    const result = await fetchStudentsData(activeFilters);
    setStudentsData(result);
    setLoading(false);
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    if (name === 'nivel_id') setFilters(p => ({ ...p, nivel_id: value, grado_id: '', seccion_id: '', page: 1 }));
    else if (name === 'grado_id') setFilters(p => ({ ...p, grado_id: value, seccion_id: '', page: 1 }));
    else setFilters(p => ({ ...p, [name]: value, page: 1 }));
  };

  const toggleEgresados = () => {
    setFilters(prev => ({
      ...prev,
      egresados: prev.egresados === '1' ? '0' : '1',
      page: 1
    }));
  };

  const handlePageChange = (page) => {
    setFilters(prev => ({ ...prev, page }));
  };

  const handleDelete = (id) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Eliminar Estudiante',
      message: '¿Eliminar estudiante definitivamente? Esta acción no se puede deshacer.',
      isDanger: true,
      confirmText: 'Sí, eliminar',
      onConfirm: async () => {
        setConfirmConfig({ isOpen: false });
        await deleteStudent(id);
        loadData(filters);
      },
      onCancel: () => setConfirmConfig({ isOpen: false })
    });
  };

  const handleToggleEgresado = (id) => {
    const isEgresado = filters.egresados === '1';
    const msg = isEgresado ? '¿Restaurar estudiante a lista de Activos?' : '¿Mover a este estudiante a la lista de Egresados/Exalumnos? Ya no aparecerá en esta lista.';
    setConfirmConfig({
      isOpen: true,
      title: isEgresado ? 'Restaurar Estudiante' : 'Mover a Egresados',
      message: msg,
      isDanger: !isEgresado,
      confirmText: 'Confirmar',
      onConfirm: async () => {
        setConfirmConfig({ isOpen: false });
        await toggleEgresadoStatus(id, !isEgresado);
        loadData(filters);
      },
      onCancel: () => setConfirmConfig({ isOpen: false })
    });
  };

  const isEgresadosView = filters.egresados === '1';

  // EXPORTS
  const generateExportTitle = () => {
    let title = isEgresadosView ? 'Estudiantes Egresados' : 'Estudiantes Activos';
    if (filters.anio_id) {
       const a = anios?.find(x => x.id == filters.anio_id);
       if (a) title += ` - Año ${a.anio}`;
    }
    if (filters.nivel_id) {
       const n = niveles?.find(x => x.id == filters.nivel_id);
       if (n) title += ` - ${n.nombre}`;
    }
    if (filters.grado_id) {
       const g = grados?.find(x => x.id == filters.grado_id);
       if (g) title += ` - ${g.nombre}`;
    }
    if (filters.seccion_id) {
       const s = secciones?.find(x => x.id == filters.seccion_id);
       if (s) title += ` Seccion "${s.nombre}"`;
    }
    return title;
  };

  const handleExportPDF = () => {
    const doc = new jsPDF('landscape');
    const title = generateExportTitle();
    
    doc.setFontSize(16);
    doc.text(title, 14, 20);
    doc.setFontSize(10);
    doc.text(`Generado el: ${new Date().toLocaleDateString()}`, 14, 28);
    
    // AutoTable
    autoTable(doc, {
      startY: 35,
      head: [['DNI', 'Apellidos y Nombres', 'Celular', 'Apoderados (Nombre)', 'Matrícula (Referencial)']],
      body: studentsData.data.map(st => [
        st.dni,
        `${st.apellido_paterno} ${st.apellido_materno}, ${st.nombres}`,
        st.celular || 'N/A',
        (st.padre_nombres || st.madre_nombres) ? `${st.padre_nombres || ''} / ${st.madre_nombres || ''}` : 'No',
        st.gradoActual || 'Sin matricular'
      ]),
      theme: 'grid',
      headStyles: { fillColor: [16, 185, 129] } // verde primary
    });
    
    doc.save(`${title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.pdf`);
  };

  const handleExportExcel = () => {
    const title = generateExportTitle();
    
    const rows = studentsData.data.map(st => ({
      'DNI': st.dni,
      'Apellidos': `${st.apellido_paterno} ${st.apellido_materno}`,
      'Nombres': st.nombres,
      'F. Nacimiento': st.fecha_nacimiento ? new Date(st.fecha_nacimiento).toLocaleDateString() : '',
      'Celular': st.celular || '',
      'Domicilio': st.domicilio || '',
      'Matrícula Actual': st.gradoActual || '',
      'Estado': isEgresadosView ? 'Egresado' : 'Activo',
      'Reporte Médico': st.reporte || ''
    }));

    const worksheet = XLSX.utils.json_to_sheet(rows);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Estudiantes");

    XLSX.writeFile(workbook, `${title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.xlsx`);
  };

  return (
    <div className="card">
      <div className="card-header d-flex justify-between align-center" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h2 id="mainTitle">{isEgresadosView ? 'Estudiantes Egresados / Exalumnos' : 'Gestión de Estudiantes Activos'}</h2>
        <div className="d-flex gap-2" style={{ display: 'flex', gap: '0.5rem' }}>
          <button id="toggleEgresadosBtn" className="btn" style={{ background: isEgresadosView ? 'var(--primary)' : 'var(--text-color)', color: 'white' }} onClick={toggleEgresados}>
            {isEgresadosView ? <><i className='bx bx-arrow-back'></i> Volver a Activos</> : <><i className='bx bxs-graduation'></i> Ver Egresados</>}
          </button>
          <Link href="/students/create" className="btn btn-primary" style={{ textDecoration: 'none' }}>
            <i className='bx bx-plus'></i> Registrar Estudiante
          </Link>
        </div>
      </div>

      <div className="filters-container mb-4 p-3" style={{ background: '#f8fafc', borderRadius: '8px', border: '1px solid #e2e8f0', marginBottom: '1.5rem', padding: '1rem' }}>
        <form id="filterForm" className="grid grid-cols-1 md-grid-cols-4 gap-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: '1rem' }}>
          <div className="form-group mb-0" style={{ gridColumn: 'span 4' }}>
            <label className="form-label"><i className='bx bx-search'></i> Búsqueda por texto</label>
            <input type="text" name="search" className="form-control" placeholder="Buscar por DNI, Nombres, Apellidos o Apoderado..." value={filters.search} onChange={handleFilterChange} autoComplete="off" />
          </div>

          <div className="form-group mb-0">
            <label className="form-label">Año Escolar</label>
            <select name="anio_id" className="form-control" value={filters.anio_id} onChange={handleFilterChange}>
              <option value="">Todos los años</option>
              {anios?.map(a => <option key={a.id} value={a.id}>{a.anio}</option>)}
            </select>
          </div>

          <div className="form-group mb-0">
            <label className="form-label">Nivel</label>
            <select name="nivel_id" className="form-control" value={filters.nivel_id} onChange={handleFilterChange}>
              <option value="">Todos los niveles</option>
              {niveles?.map(n => <option key={n.id} value={n.id}>{n.nombre}</option>)}
            </select>
          </div>

          <div className="form-group mb-0">
            <label className="form-label">Grado</label>
            <select name="grado_id" className="form-control" value={filters.grado_id} onChange={handleFilterChange} disabled={!filters.nivel_id}>
              <option value="">{filters.nivel_id ? 'Todos los grados' : 'Selecciona un nivel'}</option>
              {grados?.filter(g => g.nivel_id == filters.nivel_id).map(g => <option key={g.id} value={g.id}>{g.nombre}</option>)}
            </select>
          </div>

          <div className="form-group mb-0">
            <label className="form-label">Sección</label>
            <select name="seccion_id" className="form-control" value={filters.seccion_id} onChange={handleFilterChange} disabled={!filters.grado_id}>
              <option value="">{filters.grado_id ? 'Todas las secc' : 'Selecciona grado'}</option>
              {secciones?.filter(s => s.grado_id == filters.grado_id).map(s => <option key={s.id} value={s.id}>"{s.nombre}"</option>)}
            </select>
          </div>
        </form>
      </div>

      <div className="table-responsive">
        {loading && (
          <div id="tableLoader" className="text-center p-4" style={{ textAlign: 'center', padding: '1rem' }}>
            <i className='bx bx-loader-alt bx-spin' style={{ fontSize: '2rem', color: 'var(--primary)' }}></i>
            <p>Cargando datos...</p>
          </div>
        )}

        {!loading && (
          <table className="table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ borderBottom: '2px solid #e2e8f0' }}>
                <th style={{ padding: '10px' }}>DNI</th>
                <th style={{ padding: '10px' }}>Apellidos y Nombres</th>
                <th style={{ padding: '10px' }}>Celular</th>
                <th style={{ padding: '10px' }}>Apoderados</th>
                <th>Matrícula (Última)</th>
                <th style={{ padding: '10px' }}>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {studentsData.data.length === 0 ? (
                <tr>
                  <td colSpan="6" className="text-center text-muted" style={{ textAlign: 'center', padding: '1rem' }}>No se encontraron estudiantes con los filtros aplicados.</td>
                </tr>
              ) : (
                studentsData.data.map(student => (
                  <tr key={student.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                    <td style={{ padding: '10px' }}><b>{student.dni}</b></td>
                    <td style={{ padding: '10px' }}>{student.apellido_paterno} {student.apellido_materno}, {student.nombres}</td>
                    <td style={{ padding: '10px' }}>{student.celular || '-'}</td>
                    <td style={{ padding: '10px', fontSize: '0.85rem' }}>
                      {student.padre_nombres && <div><i className='bx bx-male'></i> {student.padre_apellidos}, {student.padre_nombres}</div>}
                      {student.madre_nombres && <div><i className='bx bx-female'></i> {student.madre_apellidos}, {student.madre_nombres}</div>}
                      {!student.padre_nombres && !student.madre_nombres && <span className="text-muted">No registrados</span>}
                    </td>
                    <td style={{ padding: '10px' }}>
                      <span className="text-muted" style={{ fontSize: '0.85rem' }}>{student.gradoActual ? student.gradoActual : 'No matriculado'}</span>
                    </td>
                    <td style={{ padding: '10px' }}>
                      <div className="d-flex gap-1" style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                        <button onClick={() => setSelectedStudent(student)} className="btn btn-sm" style={{ background: '#10B981', color: 'white' }} title="Ver Perfil"><i className='bx bx-show'></i></button>
                        <Link href={`/students/create?dni=${student.dni}`} className="btn btn-sm" style={{ background: 'var(--primary)', color: 'white' }} title="Editar directamente"><i className='bx bx-edit'></i></Link>
                        
                        {/* BOTÓN EGRESADO (Validado si está en fin de ciclo / egresados view) */}
                        {(student.canGraduate || isEgresadosView) && (
                          <button className="btn btn-sm" style={{ background: isEgresadosView ? '#f59e0b' : '#3b82f6', color: isEgresadosView ? 'black' : 'white' }} title={isEgresadosView ? "Restaurar a Activos" : "Marcar como Egresado"} onClick={() => handleToggleEgresado(student.id)}>
                            {isEgresadosView ? <i className='bx bx-undo'></i> : <><i className='bx bxs-graduation'></i></>}
                          </button>
                        )}

                        {/* BOTÓN PROMOVER A SECUNDARIA (Solo para 6to de primaria) */}
                        {student.canPassToSecondary && !isEgresadosView && (
                          <Link href="/enrollments/create" className="btn btn-sm" style={{ background: '#8b5cf6', color: 'white', textDecoration: 'none' }} title="Promover a Secundaria">
                            <i className='bx bx-trending-up'></i> a Sec
                          </Link>
                        )}

                        <button className="btn btn-danger btn-sm" style={{ background: '#dc2626', color: 'white' }} title="Eliminar" onClick={() => handleDelete(student.id)}>
                          <i className='bx bx-trash'></i>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>
      
      {!loading && (
        <div style={{ marginTop: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          
          <div style={{ display: 'flex', gap: '10px' }}>
             <button onClick={handleExportExcel} className="btn" style={{ background: '#10b981', color: 'white' }}><i className='bx bx-spreadsheet'></i> Exportar Excel</button>
             <button onClick={handleExportPDF} className="btn" style={{ background: '#ef4444', color: 'white' }}><i className='bx bxs-file-pdf'></i> Exportar PDF</button>
          </div>

          <div style={{ textAlign: 'center', color: '#64748b' }}>
            Mostrando {studentsData.from || 0} a {studentsData.to || 0} de {studentsData.total}
          </div>

          <div className="d-flex gap-1" style={{ display: 'flex', gap: '4px' }}>
            {studentsData.links.map((link, idx) => (
              <button key={idx} className="btn btn-sm" 
                disabled={!link.url}
                style={{ 
                  background: link.active ? 'var(--primary)' : 'white', 
                  color: link.active ? 'white' : 'var(--text-color)',
                  border: '1px solid #e2e8f0',
                  opacity: !link.url ? 0.5 : 1
                }} 
                onClick={() => link.url && handlePageChange(parseInt(link.label))}>
                {link.label}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* MODAL PERFIL ALUMNO */}
      {selectedStudent && (
        <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(3px)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 100000 }}>
          <div style={{ background: 'white', padding: '2rem', borderRadius: '12px', maxWidth: '500px', width: '90%', boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)', borderTop: '5px solid #10B981' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
              <h3 style={{ margin: 0, color: 'var(--text-color)', fontSize: '1.4rem' }}><i className='bx bx-user-circle' style={{ color: '#10B981', marginRight: '8px' }}></i>Perfil de Estudiante</h3>
              <button onClick={() => setSelectedStudent(null)} style={{ background: 'transparent', border: 'none', fontSize: '1.5rem', cursor: 'pointer', color: '#64748b' }}>&times;</button>
            </div>
            
            <div style={{ background: '#f8fafc', padding: '15px', borderRadius: '8px', marginBottom: '1rem' }}>
              <p style={{ margin: '0 0 8px', fontSize: '1.1rem' }}><b>{selectedStudent.apellido_paterno} {selectedStudent.apellido_materno}, {selectedStudent.nombres}</b></p>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', fontSize: '0.95rem' }}>
                <div><span style={{ color: '#64748b' }}>DNI:</span> {selectedStudent.dni}</div>
                <div><span style={{ color: '#64748b' }}>Celular:</span> {selectedStudent.celular || 'No registrado'}</div>
                <div style={{ gridColumn: 'span 2' }}><span style={{ color: '#64748b' }}>Domicilio:</span> {selectedStudent.domicilio || 'No especificado'}</div>
              </div>
            </div>

            <div style={{ marginBottom: '1rem' }}>
              <p style={{ fontWeight: 'bold', margin: '0 0 5px', color: '#475569' }}>Apoderados:</p>
              <ul style={{ margin: 0, paddingLeft: '20px', fontSize: '0.95rem', color: '#475569' }}>
                <li><b>Padre:</b> {selectedStudent.padre_nombres || 'No especificado'}</li>
                <li><b>Madre:</b> {selectedStudent.madre_nombres || 'No especificada'}</li>
              </ul>
            </div>

            <div style={{ background: '#fffbeb', border: '1px solid #fde68a', padding: '15px', borderRadius: '8px', color: '#92400e' }}>
              <p style={{ margin: '0 0 5px', fontWeight: 'bold' }}><i className='bx bx-info-circle'></i> Información Médica / Conductual:</p>
              <p style={{ margin: 0, fontSize: '0.95rem' }}>{selectedStudent.reporte || 'El estudiante no presenta observaciones médicas ni conductuales registradas en su ficha actual.'}</p>
            </div>

            <div style={{ marginTop: '1.5rem', textAlign: 'right' }}>
              <button onClick={() => setSelectedStudent(null)} className="btn btn-primary" style={{ padding: '0.5rem 1.5rem', borderRadius: '6px' }}>Cerrar Ficha</button>
            </div>
          </div>
        </div>
      )}



      <ConfirmModal {...confirmConfig} />
    </div>
  );
}
