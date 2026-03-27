import { query } from '@/lib/db';
import Link from 'next/link';
import { cookies } from 'next/headers';

async function getStats() {
  const [est, apo, mat] = await Promise.all([
    query('SELECT COUNT(*) FROM estudiantes'),
    query('SELECT COUNT(*) FROM apoderados'),
    query('SELECT COUNT(*) FROM matriculas'),
  ]);
  return {
    estudiantes: est.rows[0].count,
    apoderados: apo.rows[0].count,
    matriculas: mat.rows[0].count,
  };
}

async function getUser() {
  const cookieStore = await cookies();
  const token = cookieStore.get('auth_token')?.value;
  if (!token) return null;
  try {
    const { jwtVerify } = await import('jose');
    const secret = new TextEncoder().encode(process.env.JWT_SECRET);
    const { payload } = await jwtVerify(token, secret);
    return payload; 
  } catch (error) {
    return null;
  }
}

export default async function DashboardPage() {
  const stats = await getStats();
  const user = await getUser();

  return (
    <>
      <div style={{ marginBottom: '2rem' }}>
        <h2 style={{ fontSize: '1.8rem', color: '#0f172a', marginBottom: '0.5rem' }}>Panel de Control</h2>
        <p className="text-muted">Resumen general académico y administrativo.</p>
      </div>

      <div className="grid grid-cols-3 gap-3 mb-4">
        {/* Stat Card 1 */}
        <div className="stat-card" style={{ borderLeftColor: 'var(--primary)' }}>
          <div>
            <div className="stat-card-title">Total Estudiantes</div>
            <div className="stat-card-value">{stats.estudiantes}</div>
            <Link href="/students" className="text-primary" style={{ fontSize: '0.85rem', display: 'inline-flex', alignItems: 'center', gap: '4px', marginTop: '0.5rem', fontWeight: '500' }}>
              Ver directorio <i className='bx bx-right-arrow-alt'></i>
            </Link>
          </div>
          <div className="stat-card-icon" style={{ background: 'rgba(11, 37, 69, 0.1)', color: 'var(--primary)' }}>
            <i className='bx bxs-user-detail'></i>
          </div>
        </div>

        {/* Stat Card 2 */}
        <div className="stat-card" style={{ borderLeftColor: 'var(--secondary)' }}>
          <div>
            <div className="stat-card-title">Familias / Apoderados</div>
            <div className="stat-card-value">{stats.apoderados}</div>
            <Link href="/guardians" className="text-secondary" style={{ fontSize: '0.85rem', display: 'inline-flex', alignItems: 'center', gap: '4px', marginTop: '0.5rem', fontWeight: '500' }}>
              Gestionar tutores <i className='bx bx-right-arrow-alt'></i>
            </Link>
          </div>
          <div className="stat-card-icon" style={{ background: 'rgba(232, 93, 34, 0.1)', color: 'var(--secondary)' }}>
            <i className='bx bxs-group'></i>
          </div>
        </div>

        {/* Stat Card 3 */}
        <div className="stat-card" style={{ borderLeftColor: 'var(--success)' }}>
          <div>
            <div className="stat-card-title">Matrículas Activas</div>
            <div className="stat-card-value">{stats.matriculas}</div>
            <Link href="/enrollments" style={{ color: 'var(--success)', fontSize: '0.85rem', display: 'inline-flex', alignItems: 'center', gap: '4px', marginTop: '0.5rem', fontWeight: '500' }}>
              Reporte de matrícula <i className='bx bx-right-arrow-alt'></i>
            </Link>
          </div>
          <div className="stat-card-icon" style={{ background: 'rgba(16, 185, 129, 0.1)', color: 'var(--success)' }}>
            <i className='bx bx-clipboard'></i>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 mt-4">
        <div className="card" style={{ marginBottom: '0' }}>
          <h3 style={{ fontSize: '1.15rem', marginBottom: '1.5rem', borderBottom: '1px solid var(--border-color)', paddingBottom: '0.75rem' }}>
            <i className='bx bx-bolt-circle text-secondary'></i> Acciones Rápidas
          </h3>
          <div className="d-flex gap-3">
            <Link href="/students/create" className="btn btn-primary" style={{ flex: '1' }}>
              <i className='bx bx-plus-circle'></i> Nuevo Estudiante
            </Link>
            <Link href="/enrollments/create" className="btn btn-secondary" style={{ flex: '1' }}>
              <i className='bx bx-book-bookmark'></i> Procesar Matrícula
            </Link>
          </div>
        </div>
        
        <div className="card" style={{ marginBottom: '0' }}>
          <h3 style={{ fontSize: '1.15rem', marginBottom: '1rem', borderBottom: '1px solid var(--border-color)', paddingBottom: '0.75rem' }}>
            <i className='bx bx-info-circle text-primary'></i> Sistema y Accesos
          </h3>
          <p className="text-muted" style={{ fontSize: '0.9rem' }}>
            Has iniciado sesión de forma autorizada. Recuerda cerrar sesión al finalizar y no compartir tus credenciales de administrador.
          </p>
          
          {user?.nombre_usuario === 'admin' && (
            <div style={{ marginTop: '1.5rem' }}>
              <Link href="/users" className="btn btn-outline" style={{ border: '1px solid var(--border-color)', color: 'var(--text-color)', background: '#f8fafc', fontSize: '0.85rem' }}>
                <i className='bx bxs-user-account'></i> Administrar Accesos del Personal
              </Link>
            </div>
          )}
        </div>
      </div>
    </>
  );
}
