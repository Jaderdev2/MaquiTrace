import { useEffect, useRef } from 'react';
import brandLogo from '../../assets/media/logos/logo_bg.png';
import './download.css';

const apkUrl = import.meta.env.VITE_ANDROID_APK_URL?.trim();
const apkSize = import.meta.env.VITE_ANDROID_APK_SIZE?.trim();

const steps = [
  {
    title: 'Descarga el APK',
    text: 'Guarda el archivo en tu teléfono Android.',
  },
  {
    title: 'Ábrelo e instálalo',
    text: 'Si Android te lo pide, autoriza la instalación desde este archivo.',
  },
  {
    title: 'Inicia sesión',
    text: 'Entra con las credenciales que te dio el administrador.',
  },
];

function AndroidIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M17.6 9.48l1.84-3.18c.16-.31.04-.69-.26-.85-.29-.15-.65-.06-.83.22l-1.88 3.24c-2.86-1.21-6.08-1.21-8.94 0L5.65 5.67c-.19-.29-.58-.38-.87-.2-.28.18-.37.54-.22.83L6.4 9.48C3.3 11.25 1.28 14.44 1 18h22c-.28-3.56-2.3-6.75-5.4-8.52zM7 15.25c-.69 0-1.25-.56-1.25-1.25s.56-1.25 1.25-1.25 1.25.56 1.25 1.25-.56 1.25-1.25 1.25zm10 0c-.69 0-1.25-.56-1.25-1.25s.56-1.25 1.25-1.25 1.25.56 1.25 1.25-.56 1.25-1.25 1.25z" />
    </svg>
  );
}

/* Siempre se puede presionar. Sin URL configurada no navega a ningún lado. */
function DownloadButton() {
  return (
    <a
      className="download-button"
      href={apkUrl || '#'}
      onClick={(event) => {
        if (!apkUrl) event.preventDefault();
      }}
    >
      <AndroidIcon />
      <span className="download-button-text">
        <small>Descargar APK de {apkSize || '35 MB'}</small>
        <strong>App para Android</strong>
      </span>
    </a>
  );
}

export function DownloadPage() {
  const pageRef = useRef<HTMLElement>(null);

  useEffect(() => {
    document.title = 'Descargar MaquiTrace · Trazabilidad de maquinaria';
    return () => {
      document.title = 'MaquiTrace · Plataforma de Supervisión';
    };
  }, []);

  // Los pasos aparecen una sola vez al llegar a ellos.
  useEffect(() => {
    const nodes = pageRef.current?.querySelectorAll('.download-reveal');
    if (!nodes || nodes.length === 0) return;

    if (!('IntersectionObserver' in window)) {
      nodes.forEach((node) => node.classList.add('is-visible'));
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.25 },
    );
    nodes.forEach((node) => observer.observe(node));
    return () => observer.disconnect();
  }, []);

  return (
    <main className="download-page" ref={pageRef}>
      <section className="download-hero">
        <header className="download-nav">
          <a className="download-wordmark" href="/descargar" aria-label="MaquiTrace, inicio">
            <img src={brandLogo} alt="" />
          </a>
          <a className="download-admin-link" href="/login">
            Administración
          </a>
        </header>

        <div className="download-hero-copy">
          <h1>
            <span className="download-line">
              <span>Tu maquinaria,</span>
            </span>
            <span className="download-line">
              <span>siempre a la vista.</span>
            </span>
          </h1>
          <div className="download-cta">
            <DownloadButton />
          </div>
        </div>
      </section>

      <section className="download-install" aria-labelledby="install-title">
        <div className="download-install-head">
          <h2 id="install-title">Instálala en tres pasos</h2>

        </div>

        <ol className="download-steps">
          {steps.map((step, index) => (
            <li
              className="download-reveal"
              key={step.title}
              style={{ transitionDelay: `${index * 90}ms` }}
            >
              <span className="download-step-num">{index + 1}</span>
              <h3>{step.title}</h3>
              <p>{step.text}</p>
            </li>
          ))}
        </ol>
      </section>

      <footer className="download-footer">
        <a className="download-wordmark" href="/descargar" aria-label="MaquiTrace">
          <img src={brandLogo} alt="" />
        </a>
        <span>Trazabilidad para maquinaria pesada.</span>
      </footer>
    </main>
  );
}