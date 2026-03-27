'use client';
import { useState } from 'react';
import { deleteEnrollment } from './actions';
import ConfirmModal from '../ConfirmModal';
import Link from 'next/link';

export default function EnrollmentsClient({ initialData }) {
  const [confirmConfig, setConfirmConfig] = useState({ isOpen: false });

  const handleDelete = (id) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Cancelar Matrícula',
      message: '¿Estás seguro de cancelar y eliminar esta matrícula? Esta acción es irreversible.',
      isDanger: true,
      confirmText: 'Sí, cancelar matrícula',
      onConfirm: async () => {
        setConfirmConfig({ isOpen: false });
        await deleteEnrollment(id);
        window.location.reload(); 
      },
      onCancel: () => setConfirmConfig({ isOpen: false })
    });
  };

  return (
    <div className="card">
      <div className="card-header d-flex justify-between align-center" style={{ marginBottom: '1rem', display: 'flex', justifyContent: 'space-between' }}>
        <h2 style={{ fontSize: '1.5rem' }}>Últimas Matrículas</h2>
        <Link href="/enrollments/create" className="btn btn-primary" style={{ textDecoration: 'none' }}><i className='bx bx-plus'></i> Nueva Matrícula</Link>
      </div>
      <table className="table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid #e2e8f0' }}>
            <th style={{ padding: '10px' }}>Fecha</th>
            <th style={{ padding: '10px' }}>Estudiante</th>
            <th style={{ padding: '10px' }}>Año</th>
            <th style={{ padding: '10px' }}>Aula</th>
            <th style={{ padding: '10px' }}>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {initialData.length === 0 ? (
            <tr>
              <td colSpan="5" style={{ padding: '10px', textAlign: 'center', color: '#666' }}>No hay matrículas registradas.</td>
            </tr>
          ) : (
            initialData.map(item => (
              <tr key={item.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                <td style={{ padding: '10px' }}>{item.fecha_matricula ? new Date(item.fecha_matricula).toISOString().split('T')[0] : '-'}</td>
                <td style={{ padding: '10px' }}>{item.dni} - {item.apellido_paterno} {item.apellido_materno}, {item.nombres}</td>
                <td style={{ padding: '10px' }}>{item.anio}</td>
                <td style={{ padding: '10px' }}>{item.nivel} {item.grado} "{item.seccion}"</td>
                <td style={{ padding: '10px' }}>
                  <button className="btn btn-danger btn-sm" style={{ background: '#dc2626', color: 'white' }} onClick={() => handleDelete(item.id)}>
                    Cancelar Matrícula
                  </button>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
      <ConfirmModal {...confirmConfig} />
    </div>
  );
}
