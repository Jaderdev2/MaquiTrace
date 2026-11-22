import { useEffect } from 'react';
import { Download, LogIn } from 'lucide-react';
import brandLogo from '../../assets/media/logos/logo_bg.png';
import './download.css';

const apkUrl = import.meta.env.VITE_ANDROID_APK_URL?.trim();

const steps = [
  { number: '01', title: 'Descarga', text: 'Guarda el archivo APK en tu teléfono Android.' },
  { number: '02', title: 'Instala', text: 'Abre el archivo y, si Android te lo pide, permite la instalación desde tu navegador.' },
  { number: '03', title: 'Ingresa', text: 'Inicia sesión con las credenciales de tu equipo.' },
];

export function DownloadPage() {
  useEffect(() => {
    document.title = 'Descargar MaquiTrace · App para Android';
    return () => { document.title = 'MaquiTrace · Plataforma de Supervisión'; };
  }, []);

  return (
    <main className="download-page">
      <section className="download-hero" aria-labelledby="download-title">
        <header className="download-header">
          <a className="download-brand" href="/descargar" aria-label="MaquiTrace, inicio">
            <img src={brandLogo} alt="MaquiTrace" />
          </a>
          <a className="download-panel-link" href="/login">
            <span>Acceder al panel</span><LogIn size={17} aria-hidden="true" />
          </a>
        </header>

        <div className="download-hero-inner">
          <div className="download-copy">
            <h1 id="download-title">MaquiTrace<br /><em>para Android</em></h1>
            <p className="download-description">Registra el alistamiento, adjunta fotos y reporta novedades en ruta desde tu celular.</p>

            <div className="download-actions">
              {apkUrl ? (
                <a className="download-primary" href={apkUrl}>
                  <Download size={20} aria-hidden="true" /><span>Descargar app para Android</span>
                </a>
              ) : (
                <button className="download-primary" type="button" disabled>
                  <Download size={20} aria-hidden="true" /><span>Descargar app para Android</span>
                </button>
              )}
            </div>
          </div>
        </div>
      </section>

      <section className="download-install" aria-labelledby="install-title">
        <div className="download-install-inner">
          <div className="download-install-heading">
            <h2 id="install-title">Instala la app en tres pasos</h2>
          </div>
          <ol className="download-steps">
            {steps.map((step) => (
              <li key={step.number}>
                <span className="download-step-number">{step.number}</span>
                <div><h3>{step.title}</h3><p>{step.text}</p></div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <footer className="download-footer">
        <img src={brandLogo} alt="MaquiTrace" />
      </footer>
    </main>
  );
}
