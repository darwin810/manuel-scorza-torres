'use client';

import { useState, useEffect } from 'react';
import { getStudents, searchStudentByDni, saveStudent, deleteStudent } from './actions';
import ConfirmModal from '../ConfirmModal';

export default function StudentsClient({ initialStudents }) {
  const [students, setStudents] = useState(initialStudents);
  const [formData, setFormData] = useState({
    id: '', apellido_paterno: '', apellido_materno: '', nombres: '', dni: '', celular: '', email: '',
    fecha_nacimiento: '', departamento_nacimiento: '', provincia_nacimiento: '', distrito_nacimiento: '', domicilio: '',
    padre_dni: '', padre_nombres: '', padre_apellidos: '', padre_celular: '',
    madre_dni: '', madre_nombres: '', madre_apellidos: '', madre_celular: '',
    reporte: ''
  });
  const [isTab, setIsTab] = useState('student'); // student, parents, additional
  const [toastMessage, setToastMessage] = useState('');
  const [confirmConfig, setConfirmConfig] = useState({ isOpen: false });

  const showToast = (msg) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const handleInputChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSearchDni = async () => {
    if (!formData.dni) {
      showToast('Ingresa un DNI para buscar.');
      return;
    }
    const student = await searchStudentByDni(formData.dni);
    if (student) {
      setFormData(student);
      showToast('Estudiante encontrado.');
    } else {
      showToast('No se encontró el estudiante.');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    await saveStudent(formData);
    showToast(formData.id ? 'Estudiante actualizado correctamente.' : 'Estudiante registrado correctamente.');
    handleClear();
    setStudents(await getStudents());
  };

  const handleEdit = (student) => {
    setFormData(student);
    setIsTab('student');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDelete = (id) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Eliminar Estudiante',
      message: '¿Estás seguro de eliminar este estudiante? Se eliminarán también matrículas y vínculos asociados irreversiblemente.',
      isDanger: true,
      confirmText: 'Sí, eliminar',
      onConfirm: async () => {
        setConfirmConfig({ isOpen: false });
        await deleteStudent(id);
        showToast('Estudiante eliminado.');
        setStudents(await getStudents());
      },
      onCancel: () => setConfirmConfig({ isOpen: false })
    });
  };

  const handleClear = () => {
    setFormData({
      id: '', apellido_paterno: '', apellido_materno: '', nombres: '', dni: '', celular: '', email: '',
      fecha_nacimiento: '', departamento_nacimiento: '', provincia_nacimiento: '', distrito_nacimiento: '', domicilio: '',
      padre_dni: '', padre_nombres: '', padre_apellidos: '', padre_celular: '',
      madre_dni: '', madre_nombres: '', madre_apellidos: '', madre_celular: '',
      reporte: ''
    });
  };

  return (
    <div>
      {toastMessage && (
        <div style={{ position: 'fixed', top: '20px', right: '20px', background: '#4caf50', color: '#fff', padding: '10px 20px', borderRadius: '4px', zIndex: 9999 }}>
          {toastMessage}
        </div>
      )}

      <div className="card" style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '1.5rem', marginBottom: '1rem', color: 'var(--primary)' }}>Registro de Estudiante</h2>
        
        {/* Nav Tabs */}
        <div style={{ display: 'flex', borderBottom: '1px solid #ccc', marginBottom: '20px', gap: '10px' }}>
          <button onClick={() => setIsTab('student')} style={{ padding: '10px', background: isTab === 'student' ? 'var(--primary)' : 'transparent', color: isTab === 'student' ? 'white' : 'black', border: 'none', borderRadius: '5px 5px 0 0', cursor: 'pointer' }}>Datos del Alumno</button>
          <button onClick={() => setIsTab('parents')} style={{ padding: '10px', background: isTab === 'parents' ? 'var(--primary)' : 'transparent', color: isTab === 'parents' ? 'white' : 'black', border: 'none', borderRadius: '5px 5px 0 0', cursor: 'pointer' }}>Información de Padres</button>
          <button onClick={() => setIsTab('additional')} style={{ padding: '10px', background: isTab === 'additional' ? 'var(--primary)' : 'transparent', color: isTab === 'additional' ? 'white' : 'black', border: 'none', borderRadius: '5px 5px 0 0', cursor: 'pointer' }}>Información Adicional</button>
        </div>

        <form onSubmit={handleSubmit}>
          {isTab === 'student' && (
            <div className="grid grid-cols-2 gap-3">
              <div className="form-group">
                <label className="form-label">DNI</label>
                <div style={{ display: 'flex', gap: '10px' }}>
                  <input type="text" name="dni" className="form-control" value={formData.dni || ''} onChange={handleInputChange} required />
                  <button type="button" className="btn btn-outline" onClick={handleSearchDni}><i className='bx bx-search'></i> Buscar</button>
                </div>
              </div>
              <div className="form-group">
                <label className="form-label">Nombres</label>
                <input type="text" name="nombres" className="form-control" value={formData.nombres || ''} onChange={handleInputChange} required />
              </div>
              <div className="form-group">
                <label className="form-label">Apellido Paterno</label>
                <input type="text" name="apellido_paterno" className="form-control" value={formData.apellido_paterno || ''} onChange={handleInputChange} required />
              </div>
              <div className="form-group">
                <label className="form-label">Apellido Materno</label>
                <input type="text" name="apellido_materno" className="form-control" value={formData.apellido_materno || ''} onChange={handleInputChange} required />
              </div>
              <div className="form-group">
                <label className="form-label">Fecha de Nacimiento</label>
                <input type="date" name="fecha_nacimiento" className="form-control" value={formData.fecha_nacimiento ? (typeof formData.fecha_nacimiento === 'object' ? formData.fecha_nacimiento.toISOString().slice(0, 10) : formData.fecha_nacimiento.slice(0, 10)) : ''} onChange={handleInputChange} />
              </div>
              <div className="form-group">
                <label className="form-label">Celular Alumno</label>
                <input type="text" name="celular" className="form-control" value={formData.celular || ''} onChange={handleInputChange} />
              </div>
              <div className="form-group">
                <label className="form-label">Email</label>
                <input type="email" name="email" className="form-control" value={formData.email || ''} onChange={handleInputChange} />
              </div>
            </div>
          )}

          {isTab === 'parents' && (
            <div className="grid grid-cols-2 gap-3">
              <div className="card" style={{ boxShadow: 'none', border: '1px solid #ddd' }}>
                <h4 style={{ marginBottom: '10px' }}>Datos del Padre</h4>
                <div className="form-group">
                  <label className="form-label">DNI Padre</label>
                  <input type="text" name="padre_dni" className="form-control" value={formData.padre_dni || ''} onChange={handleInputChange} />
                </div>
                <div className="form-group">
                  <label className="form-label">Nombres</label>
                  <input type="text" name="padre_nombres" className="form-control" value={formData.padre_nombres || ''} onChange={handleInputChange} />
                </div>
                <div className="form-group">
                  <label className="form-label">Apellidos</label>
                  <input type="text" name="padre_apellidos" className="form-control" value={formData.padre_apellidos || ''} onChange={handleInputChange} />
                </div>
                <div className="form-group">
                  <label className="form-label">Celular Padre</label>
                  <input type="text" name="padre_celular" className="form-control" value={formData.padre_celular || ''} onChange={handleInputChange} />
                </div>
              </div>
              
              <div className="card" style={{ boxShadow: 'none', border: '1px solid #ddd' }}>
                <h4 style={{ marginBottom: '10px' }}>Datos de la Madre</h4>
                <div className="form-group">
                  <label className="form-label">DNI Madre</label>
                  <input type="text" name="madre_dni" className="form-control" value={formData.madre_dni || ''} onChange={handleInputChange} />
                </div>
                <div className="form-group">
                  <label className="form-label">Nombres</label>
                  <input type="text" name="madre_nombres" className="form-control" value={formData.madre_nombres || ''} onChange={handleInputChange} />
                </div>
                <div className="form-group">
                  <label className="form-label">Apellidos</label>
                  <input type="text" name="madre_apellidos" className="form-control" value={formData.madre_apellidos || ''} onChange={handleInputChange} />
                </div>
                <div className="form-group">
                  <label className="form-label">Celular Madre</label>
                  <input type="text" name="madre_celular" className="form-control" value={formData.madre_celular || ''} onChange={handleInputChange} />
                </div>
              </div>
            </div>
          )}

          {isTab === 'additional' && (
            <div className="grid grid-cols-2 gap-3">
              <div className="form-group">
                <label className="form-label">Domicilio</label>
                <input type="text" name="domicilio" className="form-control" value={formData.domicilio || ''} onChange={handleInputChange} />
              </div>
              <div className="form-group">
                <label className="form-label">Lugar Nacimiento (Dpto)</label>
                <input type="text" name="departamento_nacimiento" className="form-control" value={formData.departamento_nacimiento || ''} onChange={handleInputChange} />
              </div>
              <div className="form-group" style={{ gridColumn: 'span 2' }}>
                <label className="form-label">Reporte (Información Médica / Relevante)</label>
                <textarea name="reporte" className="form-control" rows="3" value={formData.reporte || ''} onChange={handleInputChange}></textarea>
              </div>
            </div>
          )}

          <div style={{ marginTop: '20px', display: 'flex', gap: '10px' }}>
            <button type="submit" className="btn btn-primary">{formData.id ? 'Actualizar Estudiante' : 'Guardar Nuevo Estudiante'}</button>
            <button type="button" className="btn btn-outline" onClick={handleClear}>Limpiar Campos</button>
          </div>
        </form>
      </div>

      <div className="card">
        <h3 style={{ fontSize: '1.2rem', marginBottom: '15px' }}>Alumnos Registrados</h3>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ background: '#f5f5f5', borderBottom: '2px solid #ddd' }}>
              <th style={{ padding: '10px' }}>DNI</th>
              <th style={{ padding: '10px' }}>Estudiante</th>
              <th style={{ padding: '10px' }}>Padre</th>
              <th style={{ padding: '10px' }}>Madre</th>
              <th style={{ padding: '10px', textAlign: 'center' }}>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {students.map(student => (
              <tr key={student.id} style={{ borderBottom: '1px solid #ddd' }}>
                <td style={{ padding: '10px' }}>{student.dni}</td>
                <td style={{ padding: '10px' }}>{`${student.apellido_paterno} ${student.apellido_materno}, ${student.nombres}`}</td>
                <td style={{ padding: '10px' }}>{student.padre_nombres ? `${student.padre_nombres} (${student.padre_celular || '-'})` : '-'}</td>
                <td style={{ padding: '10px' }}>{student.madre_nombres ? `${student.madre_nombres} (${student.madre_celular || '-'})` : '-'}</td>
                <td style={{ padding: '10px', textAlign: 'center' }}>
                  <button onClick={() => handleEdit(student)} className="btn btn-sm btn-outline" style={{ marginRight: '5px' }}>Editar</button>
                  <button onClick={() => handleDelete(student.id)} className="btn btn-sm" style={{ background: '#dc3545', color: '#fff' }}>Eliminar</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {students.length === 0 && <p style={{ marginTop: '10px', color: '#777' }}>No hay estudiantes registrados.</p>}
      </div>
      <ConfirmModal {...confirmConfig} />
    </div>
  );
}
