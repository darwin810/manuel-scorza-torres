'use client';

export default function ConfirmModal({ isOpen, title, message, onConfirm, onCancel, confirmText = 'Confirmar', isDanger = true }) {
  if (!isOpen) return null;
  return (
    <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(3px)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 100000 }}>
       <div style={{ background: 'white', padding: '2rem', borderRadius: '12px', maxWidth: '400px', width: '90%', boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)', borderTop: `5px solid ${isDanger ? '#ef4444' : 'var(--primary)'}` }}>
         <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '10px' }}>
            <i className={`bx ${isDanger ? 'bx-error-circle' : 'bx-question-mark'}`} style={{ fontSize: '1.8rem', color: isDanger ? '#ef4444' : 'var(--primary)' }}></i>
            <h3 style={{ margin: 0, fontSize: '1.2rem', color: '#1e293b' }}>{title || 'Confirmación'}</h3>
         </div>
         <p style={{ margin: '0 0 20px', color: '#475569', fontSize: '0.95rem' }}>{message}</p>
         <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
           <button onClick={onCancel} className="btn btn-outline" style={{ border: '1px solid #cbd5e1', color: '#475569' }}>Cancelar</button>
           <button onClick={onConfirm} className="btn" style={{ background: isDanger ? '#ef4444' : 'var(--primary)', color: 'white', border: 'none' }}>{confirmText}</button>
         </div>
       </div>
    </div>
  );
}
