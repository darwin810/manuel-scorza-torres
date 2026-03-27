import { cookies } from 'next/headers';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import Topbar from './Topbar';

async function getUser() {
  const cookieStore = await cookies();
  const token = cookieStore.get('auth_token')?.value;
  if (!token) return null;
  try {
    const { jwtVerify } = await import('jose');
    const secret = new TextEncoder().encode(process.env.JWT_SECRET);
    const { payload } = await jwtVerify(token, secret);
    return payload; // { id, nombre_usuario }
  } catch (error) {
    return null;
  }
}

export default async function DashboardLayout({ children }) {
  const user = await getUser();
  if (!user) {
    redirect('/login');
  }

  return (
    <div className="dashboard-wrapper">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <img src="/logo.png" alt="Logo I.E. Manuel Scorza" style={{ height: '40px', width: 'auto' }} />
          <h2>I.E. Manuel Scorza</h2>
        </div>
        <nav className="sidebar-nav">
          <Link href="/dashboard" className="nav-item">
            <i className='bx bxs-dashboard'></i> Dashboard
          </Link>
          <Link href="/students" className="nav-item">
            <i className='bx bxs-user-detail'></i> Estudiantes
          </Link>
          <Link href="/guardians" className="nav-item">
            <i className='bx bxs-group'></i> Apoderados
          </Link>
          <Link href="/enrollments" className="nav-item">
            <i className='bx bx-clipboard'></i> Matrículas
          </Link>
          <Link href="/classrooms" className="nav-item">
            <i className='bx bxs-chalkboard'></i> Aulas / Secciones
          </Link>
          {user.nombre_usuario === 'admin' && (
            <Link href="/users" className="nav-item">
              <i className='bx bxs-user-account'></i> Usuarios
            </Link>
          )}
        </nav>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        <Topbar user={user} />

        <div className="page-content">
          {children}
        </div>
      </main>
    </div>
  );
}
