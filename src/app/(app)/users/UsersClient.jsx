'use client';
import { useState } from 'react';
import { deleteUser } from './actions';
import ConfirmModal from '../ConfirmModal';
import AlertModal from '../AlertModal';

export default function UsersClient({ initialData }) {
  const [confirmConfig, setConfirmConfig] = useState({ isOpen: false });
  const [alertConfig, setAlertConfig] = useState({ isOpen: false });

  const handleDelete = (id) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Eliminar Usuario',
      message: '¿Eliminar usuario del sistema? Esta acción es irreversible.',
      isDanger: true,
      confirmText: 'Sí, eliminar',
      onConfirm: async () => {
        setConfirmConfig({ isOpen: false });
        try {
          await deleteUser(id);
          window.location.reload(); 
        } catch(err) {
          setAlertConfig({
            isOpen: true,
            title: 'Acción Denegada',
            message: 'Error: No se puede eliminar el superadministrador principal.',
            isDanger: true,
            onOk: () => setAlertConfig({ isOpen: false })
          });
        }
      },
      onCancel: () => setConfirmConfig({ isOpen: false })
    });
  };

  return (
    <div className="card" style={{ maxWidth: '600px' }}>
      <div className="card-header d-flex justify-between align-center" style={{ marginBottom: '1rem' }}>
        <h2 style={{ fontSize: '1.5rem' }}>Usuarios Administradores</h2>
        <button className="btn btn-primary"><i className='bx bx-plus'></i> Nuevo Usuario</button>
      </div>
      <table className="table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid #e2e8f0' }}>
            <th style={{ padding: '10px' }}>ID</th>
            <th style={{ padding: '10px' }}>Nombre de Usuario</th>
            <th style={{ padding: '10px' }}>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {initialData.map(item => (
            <tr key={item.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
              <td style={{ padding: '10px' }}>{item.id}</td>
              <td style={{ padding: '10px', fontWeight: 'bold' }}>{item.nombre_usuario}</td>
              <td style={{ padding: '10px' }}>
                <button className="btn btn-danger btn-sm" style={{ background: '#dc2626', color: 'white', opacity: item.id == 1 ? 0.5 : 1 }} disabled={item.id == 1} onClick={() => handleDelete(item.id)}>
                  Eliminar
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <ConfirmModal {...confirmConfig} />
      <AlertModal {...alertConfig} />
    </div>
  );
}
