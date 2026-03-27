import Link from 'next/link';
import { cookies } from 'next/headers';

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

export default async function HomePage() {
  const user = await getUser();

  return (
    <>
      <style dangerouslySetInnerHTML={{ __html: `
        :root {
            --primary: #0B2545;
            --primary-hover: #133b6e;
            --secondary: #E85D22;
            --light-blue: #E1F4FD;
            --text-dark: #111827;
            --text-light: #F9FAFB;
        }
        
        body { background-color: #fff; color: var(--text-dark); overflow-x: hidden; }
        a { text-decoration: none; color: inherit; }
        
        /* Nav/Header */
        .navbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1rem 5%;
            background: #fff;
            position: sticky;
            top: 0;
            z-index: 1000;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }
        .nav-brand {
            display: flex;
            align-items: center;
            gap: 12px;
            font-weight: 700;
            font-size: 1.4rem;
            color: var(--primary);
        }
        .nav-links {
            display: flex;
            gap: 2.5rem;
            font-weight: 500;
            font-size: 0.95rem;
            color: #4b5563;
        }
        .nav-links a:hover { color: var(--secondary); }
        .nav-actions {
            display: flex;
            align-items: center;
            gap: 1.5rem;
        }
        .btn-login {
            background-color: var(--primary);
            color: white;
            padding: 0.6rem 2rem;
            border-radius: 4px;
            font-weight: 600;
            font-size: 0.95rem;
            transition: 0.3s;
        }
        .btn-login:hover {
            background-color: var(--primary-hover);
            transform: translateY(-2px);
        }
        
        /* Hero */
        .hero {
            background-color: #0f1624;
            color: white;
            padding: 7rem 5%;
            display: flex;
            align-items: center;
            min-height: 550px;
            position: relative;
            overflow: hidden;
        }
        .hero-content {
            max-width: 650px;
            z-index: 2;
            position: relative;
        }
        .hero h1 {
            font-size: 4rem;
            line-height: 1.1;
            margin-bottom: 1.5rem;
        }
        .hero p {
            font-size: 1.2rem;
            margin-bottom: 2.5rem;
            color: #d1d5db;
        }
        .hero-bg-icon {
            position: absolute;
            right: 5%;
            top: 50%;
            transform: translateY(-50%);
            font-size: 30rem;
            color: rgba(255,255,255,0.02);
            z-index: 1;
        }
        .btn-primary-alt {
            background-color: var(--secondary);
            color: white;
            padding: 0.8rem 2.5rem;
            border-radius: 4px;
            font-weight: 600;
            display: inline-block;
            transition: 0.3s;
            font-size: 1.05rem;
        }
        .btn-primary-alt:hover { 
            background-color: #d04d18; 
            transform: translateY(-2px);
        }

        /* Dark Section */
        .section-dark {
            background-color: var(--primary);
            color: white;
            padding: 6rem 5%;
            text-align: center;
        }
        .section-dark h2 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
        }
        .cards-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 2.5rem;
            max-width: 1100px;
            margin: 0 auto;
        }
        .card-alt {
            background: white;
            color: var(--text-dark);
            padding: 3rem;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.15);
            transition: 0.3s;
        }
        .card-alt:hover { transform: translateY(-5px); }
        .card-alt i {
            font-size: 3.5rem;
            color: var(--primary);
            margin-bottom: 1.5rem;
            opacity: 0.9;
        }
        .card-alt h3 {
            font-size: 1.5rem;
            margin-bottom: 1rem;
            color: var(--primary);
        }
        .card-alt p {
            font-size: 0.95rem;
            color: #4b5563;
            margin-bottom: 2rem;
            line-height: 1.6;
        }
        .btn-outline {
            border: 2px solid var(--primary);
            color: var(--primary);
            padding: 0.6rem 2rem;
            border-radius: 4px;
            font-weight: 600;
            display: inline-block;
            transition: 0.3s;
        }
        .btn-outline:hover {
            background-color: var(--primary);
            color: white;
        }

        /* Light Section */
        .section-light {
            background-color: var(--light-blue);
            padding: 6rem 5%;
            text-align: center;
        }
        .features {
            display: flex;
            justify-content: center;
            gap: 3rem;
            flex-wrap: wrap;
            max-width: 1100px;
            margin: 0 auto;
        }
        .feature {
            flex: 1;
            min-width: 280px;
            display: flex;
            align-items: flex-start;
            gap: 1.25rem;
            text-align: left;
        }
        .feature i {
            font-size: 2.2rem;
            color: var(--primary);
            background: white;
            padding: 1rem;
            border-radius: 50%;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }

        /* Second Dark Section (Info/Stats) */
        .section-stats {
            background-color: #0d1b2a;
            color: white;
            padding: 4rem 5%;
            text-align: center;
        }
        
        .stats-container {
            display: flex;
            justify-content: center;
            gap: 2rem;
            flex-wrap: wrap;
            max-width: 1000px;
            margin: auto;
        }

        .stat-box {
            flex: 1;
            min-width: 250px;
            background: rgba(255,255,255,0.05);
            padding: 2rem;
            border-radius: 8px;
            border: 1px solid rgba(255,255,255,0.1);
        }

        .stat-box h3 { font-size: 2.5rem; margin-bottom: 0.5rem; color: var(--secondary); }

        /* Footer */
        .footer {
            background-color: var(--primary);
            color: rgba(255,255,255,0.7);
            padding: 4rem 5% 2rem;
            font-size: 0.95rem;
            border-top: 1px solid rgba(255,255,255,0.05);
        }
        .footer-content {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 2rem;
        }
        .footer-links { display: flex; gap: 2rem; }
        .footer-links a:hover { color: white; }

        @media (max-width: 768px) {
            .nav-links { display: none; }
            .hero h1 { font-size: 2.5rem; }
            .card-alt { padding: 2rem; }
        }
      ` }} />

      {/* Top Navigation */}
      <nav className="navbar">
        <div className="nav-brand">
          <img src="/logo.png" alt="Logo I.E. Manuel Scorza" style={{ height: '48px', width: 'auto' }} />
          <span>I.E. MANUEL SCORZA</span>
        </div>
        <div className="nav-links">
          <a href="#inicio">Inicio</a>
          <a href="#comunidad">Comunidad</a>
          <a href="#academico">Académico</a>
          <Link href="/login">Inscripción</Link>
          <a href="#contacto">Contacto</a>
        </div>
        <div className="nav-actions">
          {user ? (
            <Link href="/dashboard" className="btn-login"><i className='bx bxs-dashboard'></i> Ir al Sistema</Link>
          ) : (
            <Link href="/login" className="btn-login"><i className='bx bx-log-in'></i> Iniciar Sesión</Link>
          )}
        </div>
      </nav>

      <section className="hero" id="inicio">
        <i className='bx bxs-book-reader hero-bg-icon'></i>
        <div className="hero-content">
          <span style={{ fontWeight: '600', fontSize: '1rem', letterSpacing: '1px', color: '#ffbd59', marginBottom: '1rem', display: 'block' }}>EDUCACIÓN CERCANA A TI</span>
          <h1 style={{ color: '#FDE047', textShadow: '2px 2px 8px rgba(0,0,0,0.8)' }}>Caminos personalizados hacia el éxito.</h1>
          <p style={{ fontWeight: '500', color: '#ffffff', textShadow: '1px 1px 3px rgba(0,0,0,0.5)' }}>Descubre un modelo de enseñanza adaptativo y profundo. Brindamos una alternativa equitativa e integral desde Inicial hasta Secundaria para asegurar que tu hijo logre el éxito tanto dentro como fuera de las aulas.</p>
          <a href="#academico" className="btn-primary-alt">Descubrir más información</a>
        </div>
      </section>

      {/* First Academic Level Highlight */}
      <section className="section-dark" id="academico">
        <div style={{ maxWidth: '800px', margin: '0 auto 4rem' }}>
          <p style={{ fontWeight: '600', fontSize: '0.9rem', letterSpacing: '1px', marginBottom: '0.5rem', color: '#94a3b8' }}>NIVELES DE ENSEÑANZA COMPLETA</p>
          <h2>Al servicio de los estudiantes desde 2004</h2>
          <p style={{ fontSize: '1.1rem', color: '#cbd5e1', marginTop: '1.5rem' }}>Las familias confían en nuestros programas educativos para garantizar que los alumnos obtengan todas las herramientas que necesitan para forjar el rumbo de su profesión o llegada al instituto.</p>
        </div>

        <div className="cards-grid">
          <div className="card-alt">
            <i className='bx bx-pencil'></i>
            <h3>Nivel Primaria</h3>
            <p>Nuestra malla curricular fomenta la resiliencia en los más pequeños, enseñando empatía y curiosidad. Contamos con áreas interactivas para una formación cálida.</p>
            <a href="#cualidades" className="btn-outline">SABER MÁS</a>
          </div>
          <div className="card-alt">
            <i className='bx bxs-graduation'></i>
            <h3>Nivel Secundaria</h3>
            <p>Acompañamos a los adolescentes preparándolos para afrontar desafíos reales, potenciando su liderazgo en un entorno inclusivo y enriquecedor.</p>
            <a href="#cualidades" className="btn-outline">SABER MÁS</a>
          </div>
        </div>
      </section>

      {/* Mid Infographic Section */}
      <section className="section-stats" id="comunidad">
        <div className="stats-container">
          <div className="stat-box">
            <i className='bx bx-calendar-star' style={{ fontSize: '3rem', color: 'var(--secondary)', marginBottom: '1rem' }}></i>
            <h3>+18</h3>
            <p>Años de excelencia y trayectoria al servicio de la comunidad educativa formando líderes.</p>
          </div>
          <div className="stat-box">
            <i className='bx bx-user-check' style={{ fontSize: '3rem', color: 'var(--secondary)', marginBottom: '1rem' }}></i>
            <h3>100%</h3>
            <p>Plantel docente y administrativo certificado con capacitación docente continua en todos los niveles.</p>
          </div>
        </div>
      </section>

      {/* Testimonies / Qualities */}
      <section className="section-light" id="cualidades">
        <h2 style={{ fontSize: '2.5rem', color: 'var(--primary)', marginBottom: '1rem' }}>Nuestras diferencias únicas</h2>
        <p style={{ maxWidth: '800px', margin: '0 auto 4rem', color: '#4b5563', fontSize: '1.1rem' }}>La opinión de nuestros expertos y el respaldo de las familias nos posiciona como un bastión escolar integral.</p>
        <div className="features">
          <div className="feature">
            <i className='bx bx-laptop'></i>
            <div>
              <h4 style={{ color: 'var(--text-dark)', marginBottom: '0.5rem', fontSize: '1.2rem' }}>Modernización Digital</h4>
              <p style={{ fontSize: '1rem', color: '#4b5563' }}>Entornos dinámicos preparados para el siglo 21 impulsando a los alumnos hacia un mejor análisis de la información.</p>
            </div>
          </div>
          <div className="feature">
            <i className='bx bx-brain'></i>
            <div>
              <h4 style={{ color: 'var(--text-dark)', marginBottom: '0.5rem', fontSize: '1.2rem' }}>Apoyo Socioemocional</h4>
              <p style={{ fontSize: '1rem', color: '#4b5563' }}>Entendemos profundamente a nuestros estudiantes proveyendo contención y desarrollo de carácter y moral.</p>
            </div>
          </div>
          <div className="feature">
            <i className='bx bx-check-shield'></i>
            <div>
              <h4 style={{ color: 'var(--text-dark)', marginBottom: '0.5rem', fontSize: '1.2rem' }}>Seguridad Garantizada</h4>
              <p style={{ fontSize: '1rem', color: '#4b5563' }}>Zonas de esparcimiento cuidadas y protocolos estrictos de sana convivencia que eliminan riesgos perjudiciales.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer" id="contacto">
        <div className="footer-content mb-4" style={{ marginBottom: '2rem', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '2rem' }}>
          <div className="nav-brand" style={{ color: 'white', flexDirection: 'column', alignItems: 'flex-start', gap: '5px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <img src="/logo.png" alt="Logo I.E. Manuel Scorza" style={{ height: '48px', width: 'auto' }} />
              <span style={{ fontSize: '1.4rem' }}>I.E. MANUEL SCORZA</span>
            </div>
            <span className="text-muted" style={{ fontSize: '0.85rem', paddingLeft: '2.2rem', display: 'block' }}>Educando ciudadanos para un futuro mejor.</span>
          </div>
          <div className="footer-links">
            <Link href="/">Aviso de privacidad</Link>
            <Link href="/">Términos y condiciones</Link>
            <Link href="/">Reglamento int.</Link>
            <Link href="/">Blog</Link>
          </div>
        </div>
        <div style={{ textAlign: 'center', color: 'rgba(255,255,255,0.5)', fontSize: '0.85rem' }}>
          &copy; {new Date().getFullYear()} Institución Educativa Pública Manuel Scorza. Todos los derechos reservados.
        </div>
      </footer>
    </>
  );
}
