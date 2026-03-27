'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { fetchGuardiansData, deleteGuardian } from './actions';
import ConfirmModal from '../ConfirmModal';

export default function GuardiansIndexClient() {
  const [data, setData] = useState({ data: [], total: 0, from: 0, to: 0, last_page: 1, links: [] });
  const [loading, setLoading] = useState(true);
  const [confirmConfig, setConfirmConfig] = useState({ isOpen: false });
  const [filters, setFilters] = useState({ search: '', page: 1 });

  useEffect(() => {
    let debounceTimer = setTimeout(() => {
      loadData(filters);
    }, 400);
    return () => clearTimeout(debounceTimer);
  }, [filters]);

  const loadData = async (activeFilters) => {
    setLoading(true);
    const result = await fetchGuardiansData(activeFilters);
    setData(result);
    setLoading(false);
  };

  const handleFilterChange = (e) => {
    setFilters(prev => ({ ...prev, [e.target.name]: e.target.value, page: 1 }));
  };

  const handlePageChange = (page) => {
    setFilters(prev => ({ ...prev, page }));
  };

  const handleDelete = (id) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Eliminar Apoderado',
      message: '¿Eliminar apoderado permanentemente? Se desvinculará de sus estudiantes.',
      isDanger: true,
      confirmText: 'Sí, eliminar',
      onConfirm: async () => {
        setConfirmConfig({ isOpen: false });
        await deleteGuardian(id);
        loadData(filters);
      },
      onCancel: () => setConfirmConfig({ isOpen: false })
    });
  };

  return (
    <div className="card">
      <div className="card-header d-flex justify-between align-center" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h2 id="mainTitle">Gestión de Familiares y Apoderados</h2>
        <div className="d-flex gap-2">
          <Link href="/guardians/create" className="btn btn-primary" style={{ textDecoration: 'none' }}>
            <i className='bx bx-plus'></i> Registrar Apoderado
          </Link>
        </div>
      </div>

      <div className="filters-container mb-4 p-3" style={{ background: '#f8fafc', borderRadius: '8px', border: '1px solid #e2e8f0', marginBottom: '1.5rem', padding: '1rem' }}>
        <form className="grid grid-cols-1" style={{ display: 'grid', gridTemplateColumns: 'repeat(1, minmax(0, 1fr))' }}>
          <div className="form-group mb-0">
            <label className="form-label"><i className='bx bx-search'></i> Búsqueda por texto</label>
            <input type="text" name="search" className="form-control" placeholder="Buscar por DNI, Nombres o Apellidos..." value={filters.search} onChange={handleFilterChange} autoComplete="off" />
          </div>
        </form>
      </div>

      <div className="table-responsive">
        {loading && (
          <div className="text-center p-4" style={{ textAlign: 'center', padding: '1rem' }}>
            <i className='bx bx-loader-alt bx-spin' style={{ fontSize: '2rem', color: 'var(--primary)' }}></i>
            <p>Cargando datos...</p>
          </div>
        )}

        {!loading && (
          <table className="table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ borderBottom: '2px solid #e2e8f0' }}>
                <th style={{ padding: '10px' }}>DNI</th>
                <th style={{ padding: '10px' }}>Apoderado</th>
                <th style={{ padding: '10px' }}>Contacto</th>
                <th style={{ padding: '10px' }}>Parentesco</th>
                <th style={{ padding: '10px' }}>Estudiantes Vinculados</th>
                <th style={{ padding: '10px' }}>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {data.data.length === 0 ? (
                <tr>
                  <td colSpan="6" className="text-center text-muted" style={{ textAlign: 'center', padding: '1rem' }}>No se encontraron apoderados registrados.</td>
                </tr>
              ) : (
                data.data.map(item => (
                  <tr key={item.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                    <td style={{ padding: '10px' }}><b>{item.dni}</b></td>
                    <td style={{ padding: '10px' }}>{item.apellido_paterno} {item.apellido_materno}, {item.nombres}</td>
                    <td style={{ padding: '10px' }}>
                      <div style={{ fontSize: '0.85rem' }}><i className='bx bx-phone'></i> {item.celular || '-'}</div>
                      <div style={{ fontSize: '0.85rem' }}><i className='bx bx-envelope'></i> {item.correo || '-'}</div>
                    </td>
                    <td style={{ padding: '10px' }}>{item.parentesco || 'Otro'}</td>
                    <td style={{ padding: '10px', fontSize: '0.85rem' }}>
                      {item.estudiantes?.length > 0 ? (
                        item.estudiantes.map(e => <div key={e.id}><i className='bx bxs-graduation'></i> {e.nombres} {e.apellido_paterno} ({e.dni})</div>)
                      ) : (
                        <span className="text-muted">No vinculados</span>
                      )}
                    </td>
                    <td style={{ padding: '10px' }}>
                      <div className="d-flex gap-1" style={{ display: 'flex', gap: '4px' }}>
                        <button className="btn btn-sm" style={{ background: 'var(--primary)', color: 'white' }} title="Editar"><i className='bx bx-edit'></i></button>
                        <button className="btn btn-danger btn-sm" style={{ background: '#dc2626', color: 'white' }} title="Eliminar" onClick={() => handleDelete(item.id)}>
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
        <div className="mt-4 d-flex justify-between align-center" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '1rem' }}>
          <div className="text-muted" style={{ fontSize: '0.9rem' }}>
            Mostrando {data.from || 0} a {data.to || 0} de {data.total} registros
          </div>
          <div className="d-flex gap-1" style={{ display: 'flex', gap: '4px' }}>
            {data.links.map((link, idx) => (
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
      <ConfirmModal {...confirmConfig} />
    </div>
  );
}
