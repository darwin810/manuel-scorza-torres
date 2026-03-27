'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { getLevels, getGradesByLevel, getSectionsByGrade, saveEnrollment } from '../actions';
import { searchStudentByDni } from '../../students/actions';
import AlertModal from '../../AlertModal';

export default function CreateEnrollmentClient({ activeYear, levels }) {
  const router = useRouter();
  
  const [formData, setFormData] = useState({
    estudiante_id: '',
    nivel_id: '',
    grado_id: '',
    seccion_id: '',
    anio_id: activeYear?.id || ''
  });

  const [grades, setGrades] = useState([]);
  const [sections, setSections] = useState([]);
  
  const [searchUrl, setSearchUrl] = useState('');
  const [suggestions, setSuggestions] = useState([]);
  const [selectedStudent, setSelectedStudent] = useState(null);

  const [errorMsg, setErrorMsg] = useState('');
  const [alertConfig, setAlertConfig] = useState({ isOpen: false });

  const handleSearch = (e) => {
    const v = e.target.value;
    setSearchUrl(v);
    if(v.length >= 1) {
      searchStudentByDni(v).then(s => setSuggestions(s ? [s] : []));
    } else {
      setSuggestions([]);
    }
  };

  const selectStudent = (student) => {
    setSelectedStudent(student);
    setFormData({ ...formData, estudiante_id: student.id });
    setSuggestions([]);
  };

  const unselectStudent = () => {
    setSelectedStudent(null);
    setFormData({ ...formData, estudiante_id: '' });
    setSearchUrl('');
  };

  const handleLevelChange = async (e) => {
    const nivelId = e.target.value;
    setFormData({ ...formData, nivel_id: nivelId, grado_id: '', seccion_id: '' });
    setSections([]);
    if (nivelId) {
      const gs = await getGradesByLevel(nivelId);
      setGrades(gs);
    } else {
      setGrades([]);
    }
  };

  const handleGradeChange = async (e) => {
    const gradoId = e.target.value;
    setFormData({ ...formData, grado_id: gradoId, seccion_id: '' });
    if (gradoId) {
      const sc = await getSectionsByGrade(gradoId);
      setSections(sc);
    } else {
      setSections([]);
    }
  };

  const handleSectionChange = (e) => {
    setFormData({ ...formData, seccion_id: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrorMsg('');
    if (!formData.estudiante_id) {
      setAlertConfig({
        isOpen: true,
        title: 'Selección Necesaria',
        message: 'Debe buscar y seleccionar un estudiante para proseguir con el registro de la matrícula.',
        isDanger: true,
        onOk: () => setAlertConfig({ isOpen: false })
      });
      return;
    }
    
    try {
      await saveEnrollment(formData);
      router.push('/enrollments');
    } catch (err) {
      setErrorMsg(err.message || 'Error al procesar la matrícula.');
    }
  };

  return (
    <div className="card" style={{ maxWidth: '900px', margin: '0 auto' }}>
      <div className="card-header d-flex justify-between align-center" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2 style={{ fontSize: '1.5rem', marginBottom: '1rem' }}>Nueva Matrícula - Año Escolar {activeYear?.anio}</h2>
        <Link href="/enrollments" className="btn btn-sm" style={{ background: 'var(--text-muted)', color: 'white', textDecoration: 'none' }}>
          <i className='bx bx-arrow-back'></i> Volver
        </Link>
      </div>

      {errorMsg && (
        <div style={{ background: '#FEE2E2', color: '#991B1B', padding: '10px', borderRadius: '4px', marginBottom: '15px' }}>
          {errorMsg}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="grid grid-cols-2 gap-3">
          <div className="form-group" style={{ gridColumn: 'span 2', paddingBottom: '1.5rem', borderBottom: '1px solid var(--border-color)' }}>
            <label className="form-label mb-2"><i className='bx bxs-user-detail'></i> Buscar Estudiante a Matricular</label>
            
            {!selectedStudent ? (
              <div style={{ display: 'flex', gap: '0.5rem', position: 'relative' }}>
                <input type="text" className="form-control" placeholder="Buscar estudiante por DNI o Nombre..." value={searchUrl} onChange={handleSearch} autoComplete="off" />
                
                {suggestions.length > 0 && (
                  <div className="autocomplete-suggestions" style={{ position: 'absolute', top: '100%', left: 0, right: 0, background: 'white', border: '1px solid #ddd', padding: '10px', zIndex: 10 }}>
                    {suggestions.map(s => (
                      <div key={s.id} onClick={() => selectStudent(s)} style={{ cursor: 'pointer', padding: '5px', borderBottom: '1px solid #eee' }}>
                        <b>{s.dni}</b> - {s.apellido_paterno} {s.apellido_materno}, {s.nombres}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ) : (
              <div style={{ marginTop: '1rem', padding: '1rem', background: '#f8fafc', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <div>
                    <h4 style={{ color: 'var(--primary)', marginBottom: '5px' }}>{selectedStudent.apellido_paterno} {selectedStudent.apellido_materno}, {selectedStudent.nombres}</h4>
                    <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                      DNI: <span>{selectedStudent.dni}</span> <br/>
                      F. Nac: <span>{selectedStudent.fecha_nacimiento ? new Date(selectedStudent.fecha_nacimiento).toISOString().slice(0, 10) : 'No registrada'}</span>
                    </div>
                  </div>
                  <button type="button" className="btn btn-sm" style={{ background: '#dc2626', color: 'white' }} onClick={unselectStudent}>
                    <i className='bx bx-x'></i> Cambiar
                  </button>
                </div>
              </div>
            )}
          </div>

          <div className="form-group" style={{ gridColumn: 'span 2', marginTop: '1rem' }}>
            <h3 style={{ marginBottom: '1rem', color: 'var(--primary)' }}><i className='bx bx-building'></i> Asignación Académica</h3>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="nivel_id">Nivel</label>
            <select className="form-control" name="nivel_id" required value={formData.nivel_id} onChange={handleLevelChange}>
              <option value="" disabled>Seleccione Nivel</option>
              {levels.map(nivel => (
                <option key={nivel.id} value={nivel.id}>{nivel.nombre}</option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="grado_id">Grado</label>
            <select className="form-control" name="grado_id" required disabled={grades.length === 0} value={formData.grado_id} onChange={handleGradeChange}>
              <option value="" disabled>Primero seleccione nivel...</option>
              {grades.map(g => <option key={g.id} value={g.id}>{g.nombre}</option>)}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="seccion_id">Sección</label>
            <select className="form-control" name="seccion_id" required disabled={sections.length === 0} value={formData.seccion_id} onChange={handleSectionChange}>
              <option value="" disabled>Primero seleccione grado...</option>
              {sections.map(s => <option key={s.id} value={s.id}>"{s.nombre}"</option>)}
            </select>
          </div>
        </div>

        <div className="text-right mt-4 pt-4" style={{ borderTop: '1px solid var(--border-color)', textAlign: 'center' }}>
          <button type="submit" className="btn btn-success btn-block py-3" style={{ fontSize: '1.1rem', background: '#10b981', color: 'white', width: '100%', padding: '12px' }}>
            <i className='bx bx-check-circle'></i> Procesar Matrícula {activeYear?.anio}
          </button>
        </div>
      </form>
      <AlertModal {...alertConfig} />
    </div>
  );
}
