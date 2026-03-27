'use client';

export default function AlertModal({ isOpen, title, message, onOk, okText = 'Entendido', isDanger = false }) {
  if (!isOpen) return null;
  return (
    <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(3px)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 100000 }}>
       <div style={{ background: 'white', padding: '2rem', borderRadius: '12px', maxWidth: '400px', width: '90%', boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)', borderTop: `5px solid ${isDanger ? '#ef4444' : 'var(--primary)'}`, textAlign: 'center' }}>
         <div style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: '60px', height: '60px', borderRadius: '50%', background: isDanger ? '#fee2e2' : '#e0f2fe', color: isDanger ? '#ef4444' : 'var(--primary)', fontSize: '2rem', marginBottom: '1rem' }}>
           <i className={`bx ${isDanger ? 'bx-error-circle' : 'bx-info-circle'}`}></i>
         </div>
         <h3 style={{ margin: '0 0 10px', fontSize: '1.3rem', color: '#1e293b' }}>{title || 'Aviso del Sistema'}</h3>
         <p style={{ color: '#475569', fontSize: '0.95rem', marginBottom: '1.5rem', lineHeight: '1.5' }}>{message}</p>
         
         <div style={{ display: 'flex', justifyContent: 'center' }}>
           <button onClick={onOk} className="btn btn-primary" style={{ background: isDanger ? '#ef4444' : 'var(--primary)', border: 'none', padding: '0.6rem 2rem', borderRadius: '6px', color: 'white' }}>{okText}</button>
         </div>
       </div>
    </div>
  );
}
