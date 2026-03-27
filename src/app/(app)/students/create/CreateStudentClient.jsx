'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { saveStudent, searchStudentByDni } from '../actions';
import { getDepartamentos, getProvinciasByDeptId, getDistritosByProvId } from '@/lib/ubigeo';

export default function CreateStudentClient() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [formData, setFormData] = useState({
    id: '', dni: '', apellido_paterno: '', apellido_materno: '', nombres: '', 
    fecha_nacimiento: '', departamento_nacimiento: '', provincia_nacimiento: '', distrito_nacimiento: '', 
    domicilio: '', reporte: '', 
    padre_dni: '', padre_celular: '', padre_apellidos: '', padre_nombres: '',
    madre_dni: '', madre_celular: '', madre_apellidos: '', madre_nombres: ''
  });
  
  const [isUpdateMode, setIsUpdateMode] = useState(false);
  const [showAutoFillAlert, setShowAutoFillAlert] = useState(false);
  const [suggestions, setSuggestions] = useState([]);
  
  const [provincias, setProvincias] = useState([]);
  const [distritos, setDistritos] = useState([]);
  const [departamentos, setDepartamentos] = useState([]);

  useEffect(() => {
    getDepartamentos().then(setDepartamentos);
  }, []);

  useEffect(() => {
    const defaultDni = searchParams.get('dni');
    if (defaultDni) {
      setFormData(prev => ({ ...prev, dni: defaultDni }));
      searchStudentByDni(defaultDni).then(student => {
        if (student) handleSelectSuggestion(student);
      });
    }
  }, [searchParams, departamentos]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));

    if (name === 'dni') {
      if (value.length >= 1) {
        // Buscqueda inmediata
        searchStudentByDni(value).then(student => {
           if(student) setSuggestions([student]);
           else setSuggestions([]);
        });
      } else {
        setSuggestions([]);
        resetFormMode();
      }
    }
  };

  const handleSelectSuggestion = async (student) => {
    setFormData({
      id: student.id,
      dni: student.dni || '',
      apellido_paterno: student.apellido_paterno || '',
      apellido_materno: student.apellido_materno || '',
      nombres: student.nombres || '',
      fecha_nacimiento: student.fecha_nacimiento ? (new Date(student.fecha_nacimiento).toISOString().slice(0, 10)) : '',
      departamento_nacimiento: student.departamento_nacimiento || '',
      provincia_nacimiento: student.provincia_nacimiento || '',
      distrito_nacimiento: student.distrito_nacimiento || '',
      domicilio: student.domicilio || '',
      reporte: student.reporte || '',
      padre_dni: student.padre_dni || '',
      padre_celular: student.padre_celular || '',
      padre_apellidos: student.padre_apellidos || '',
      padre_nombres: student.padre_nombres || '',
      madre_dni: student.madre_dni || '',
      madre_celular: student.madre_celular || '',
      madre_apellidos: student.madre_apellidos || '',
      madre_nombres: student.madre_nombres || ''
    });
    setSuggestions([]);
    setIsUpdateMode(true);
    setShowAutoFillAlert(true);
    
    // Cargar ubigeo
    if (student.departamento_nacimiento) {
      const dep = departamentos.find(d => d.nombre_ubigeo === student.departamento_nacimiento);
      if (dep) {
        const provs = await getProvinciasByDeptId(dep.id_ubigeo);
        setProvincias(provs);
        if (student.provincia_nacimiento) {
           const prov = provs.find(p => p.nombre_ubigeo === student.provincia_nacimiento);
           if (prov) setDistritos(await getDistritosByProvId(prov.id_ubigeo));
        }
      }
    }
  };

  const handleDeptChange = async (e) => {
    const dep = departamentos.find(d => d.nombre_ubigeo === e.target.value);
    setFormData(prev => ({ ...prev, departamento_nacimiento: e.target.value, provincia_nacimiento: '', distrito_nacimiento: '' }));
    setProvincias([]); setDistritos([]);
    if (dep) setProvincias(await getProvinciasByDeptId(dep.id_ubigeo));
  };

  const handleProvChange = async (e) => {
    const prov = provincias.find(p => p.nombre_ubigeo === e.target.value);
    setFormData(prev => ({ ...prev, provincia_nacimiento: e.target.value, distrito_nacimiento: '' }));
    setDistritos([]);
    if (prov) setDistritos(await getDistritosByProvId(prov.id_ubigeo));
  };

  const resetFormMode = () => {
    setIsUpdateMode(false);
    setShowAutoFillAlert(false);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    await saveStudent(formData);
    setTimeout(() => {
      router.push('/students');
    }, 300);
  };

  return (
    <div className="card" style={{ maxWidth: '900px', margin: '0 auto' }}>
      <div className="card-header d-flex justify-between align-center" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2 style={{ fontSize: '1.5rem', marginBottom: '1rem' }}>Registrar Estudiante</h2>
        <Link href="/students" className="btn btn-sm" style={{ background: 'var(--text-muted)', color: 'white', textDecoration: 'none' }}>
          <i className='bx bx-arrow-back'></i> Volver
        </Link>
      </div>

      {showAutoFillAlert && (
        <div className="alert alert-info py-2" style={{ backgroundColor: '#E0F2FE', color: '#0369A1', border: '1px solid #7DD3FC', marginBottom: '1.5rem', borderRadius: '4px', padding: '10px' }}>
          <i className='bx bx-info-circle'></i> <b>Estudiante encontrado.</b> Los datos se han autocompletado para su actualización o matrícula.<br/>
          <div className="mt-2" style={{ fontSize: '0.85rem', fontWeight: 'bold', color: 'var(--primary)' }}>Apoderado Actualizado</div>
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="grid grid-cols-2 gap-3">
          <div className="form-group" style={{ gridColumn: 'span 2' }}>
            <label className="form-label" htmlFor="dni">DNI del Estudiante (Autocompleta nombre y apoderados)</label>
            <div style={{ position: 'relative' }}>
              <input type="text" className="form-control" id="dni" name="dni" required autoComplete="off" placeholder="Ingresa DNI para buscar..." value={formData.dni} onChange={handleInputChange} />
              
              {suggestions.length > 0 && (
                <div className="autocomplete-suggestions" style={{ position: 'absolute', top: '100%', left: 0, right: 0, background: 'white', border: '1px solid #ddd', padding: '10px', zIndex: 10 }}>
                  {suggestions.map(student => (
                    <div key={student.id} onClick={() => handleSelectSuggestion(student)} style={{ cursor: 'pointer', padding: '5px', borderBottom: '1px solid #eee' }}>
                      <b>{student.dni}</b> - {student.apellido_paterno} {student.apellido_materno}, {student.nombres}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="apellido_paterno">Apellido Paterno</label>
            <input type="text" className="form-control" id="apellido_paterno" name="apellido_paterno" value={formData.apellido_paterno} onChange={handleInputChange} required />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="apellido_materno">Apellido Materno</label>
            <input type="text" className="form-control" id="apellido_materno" name="apellido_materno" value={formData.apellido_materno} onChange={handleInputChange} required />
          </div>

          <div className="form-group" style={{ gridColumn: 'span 2' }}>
            <label className="form-label" htmlFor="nombres">Nombres</label>
            <input type="text" className="form-control" id="nombres" name="nombres" value={formData.nombres} onChange={handleInputChange} required />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="fecha_nacimiento">Fecha de Nacimiento</label>
            <input type="date" className="form-control" id="fecha_nacimiento" name="fecha_nacimiento" value={formData.fecha_nacimiento} onChange={handleInputChange} /> 
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="departamento_nacimiento">Departamento Nac.</label>
            <select className="form-control" name="departamento_nacimiento" value={formData.departamento_nacimiento} onChange={handleDeptChange}>
              <option value="">-- Seleccione Dpto --</option>
              {departamentos.map(d => <option key={d.id_ubigeo} value={d.nombre_ubigeo}>{d.nombre_ubigeo}</option>)}
            </select>
          </div>
          
          <div className="form-group">
            <label className="form-label" htmlFor="provincia_nacimiento">Provincia Nac.</label>
            <select className="form-control" name="provincia_nacimiento" value={formData.provincia_nacimiento} onChange={handleProvChange} disabled={provincias.length === 0}>
              <option value="">-- Seleccione Prov --</option>
              {provincias.map(p => <option key={p.id_ubigeo} value={p.nombre_ubigeo}>{p.nombre_ubigeo}</option>)}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="distrito_nacimiento">Distrito Nac.</label>
            <select className="form-control" name="distrito_nacimiento" value={formData.distrito_nacimiento} onChange={handleInputChange} disabled={distritos.length === 0}>
              <option value="">-- Seleccione Dist --</option>
              {distritos.map(d => <option key={d.id_ubigeo} value={d.nombre_ubigeo}>{d.nombre_ubigeo}</option>)}
            </select>
          </div>

          <div className="form-group" style={{ gridColumn: 'span 2' }}>
            <label className="form-label" htmlFor="domicilio">Domicilio</label>
            <input type="text" className="form-control" id="domicilio" name="domicilio" value={formData.domicilio} onChange={handleInputChange} />
          </div>

          <div className="form-group" style={{ gridColumn: 'span 2' }}>
            <label className="form-label" htmlFor="reporte">Reporte / Observaciones</label>
            <textarea className="form-control" id="reporte" name="reporte" rows="3" placeholder="Información adicional o reporte del estudiante..." value={formData.reporte} onChange={handleInputChange}></textarea>
          </div>

          <div className="form-group" style={{ gridColumn: 'span 2', marginTop: '1.5rem' }}>
            <h4 style={{ color: 'var(--primary)', borderBottom: '2px solid var(--border-color)', paddingBottom: '0.5rem' }}><i className='bx bx-male'></i> Datos del Padre</h4>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="padre_dni">DNI del Padre</label>
            <input type="text" className="form-control" id="padre_dni" name="padre_dni" value={formData.padre_dni} onChange={handleInputChange} />
          </div>
          
          <div className="form-group">
            <label className="form-label" htmlFor="padre_celular">Celular del Padre</label>
            <input type="text" className="form-control" id="padre_celular" name="padre_celular" value={formData.padre_celular} onChange={handleInputChange} />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="padre_apellidos">Apellidos del Padre</label>
            <input type="text" className="form-control" id="padre_apellidos" name="padre_apellidos" value={formData.padre_apellidos} onChange={handleInputChange} />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="padre_nombres">Nombres del Padre</label>
            <input type="text" className="form-control" id="padre_nombres" name="padre_nombres" value={formData.padre_nombres} onChange={handleInputChange} />
          </div>

          <div className="form-group" style={{ gridColumn: 'span 2', marginTop: '1.5rem' }}>
            <h4 style={{ color: 'var(--primary)', borderBottom: '2px solid var(--border-color)', paddingBottom: '0.5rem' }}><i className='bx bx-female'></i> Datos de la Madre</h4>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="madre_dni">DNI de la Madre</label>
            <input type="text" className="form-control" id="madre_dni" name="madre_dni" value={formData.madre_dni} onChange={handleInputChange} />
          </div>
          
          <div className="form-group">
            <label className="form-label" htmlFor="madre_celular">Celular de la Madre</label>
            <input type="text" className="form-control" id="madre_celular" name="madre_celular" value={formData.madre_celular} onChange={handleInputChange} />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="madre_apellidos">Apellidos de la Madre</label>
            <input type="text" className="form-control" id="madre_apellidos" name="madre_apellidos" value={formData.madre_apellidos} onChange={handleInputChange} />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="madre_nombres">Nombres de la Madre</label>
            <input type="text" className="form-control" id="madre_nombres" name="madre_nombres" value={formData.madre_nombres} onChange={handleInputChange} />
          </div>
        </div>

        <div className="text-right mt-4" style={{ textAlign: 'right' }}>
          <button type="submit" className="btn btn-primary">
            {isUpdateMode ? <><i className='bx bx-refresh'></i> Actualizar Datos</> : <><i className='bx bx-save'></i> Guardar Estudiante</>}
          </button>
        </div>
      </form>
    </div>
  );
}
