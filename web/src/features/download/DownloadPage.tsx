import { useEffect } from 'react';
import { ArrowDownToLine, Check, ChevronRight, HardHat, ShieldCheck, Smartphone } from 'lucide-react';
import './download.css';

const apkUrl = import.meta.env.VITE_ANDROID_APK_URL?.trim();
const apkVersion = import.meta.env.VITE_ANDROID_APK_VERSION?.trim();
const apkSize = import.meta.env.VITE_ANDROID_APK_SIZE?.trim();

export function DownloadPage() {
  useEffect(() => {
    document.title = 'Descargar MaquiTrace · Trazabilidad de maquinaria';
    return () => {
      document.title = 'MaquiTrace · Plataforma de Supervisión';
    };
  }, []);

  return (
    <main className="download-page">
      <header className="download-header">
        <a className="download-wordmark" href="/descargar" aria-label="MaquiTrace, inicio">
          <span className="download-brand-mark"><HardHat size={20} strokeWidth={2.2} /></span>
          <span>MAQUI<span>TRACE</span></span>
        </a>
        <a className="download-admin-link" href="/login">
          Acceso de administración <ChevronRight size={16} />
        </a>
      </header>

      <section className="download-hero">
        <div className="download-hero-copy">
          <p className="download-eyebrow"><span /> TRAZABILIDAD EN CAMPO</p>
          <h1>Todo el recorrido de tu maquinaria, <span>en un solo lugar.</span></h1>
          <p className="download-intro">
            MaquiTrace conecta al equipo de operación con el conductor para acompañar cada despacho,
            desde la asignación hasta la entrega.
          </p>

          <div className="download-action">
            {apkUrl ? (
              <a className="download-button" href={apkUrl}>
                <ArrowDownToLine size={21} />
                <span>Descargar APK para Android</span>
              </a>
            ) : (
              <button className="download-button" type="button" disabled>
                <ArrowDownToLine size={21} />
                <span>Descarga próximamente</span>
              </button>
            )}
            <p className="download-file-meta">
              {apkVersion || 'Versión por publicar'}
              {apkSize ? ` · ${apkSize}` : ' · Tamaño por confirmar'}
              {' · Android'}
            </p>
          </div>
        </div>

        <div className="download-device" aria-label="Vista de la aplicación MaquiTrace">
          <div className="download-device-top"><span /></div>
          <div className="download-device-brand">
            <span className="download-brand-mark"><HardHat size={18} /></span>
            <span>MAQUITRACE</span>
          </div>
          <div className="download-device-status">
            <span className="download-status-dot" />
            <span>DESPACHO ASIGNADO</span>
          </div>
          <div className="download-route-line">
            <span className="download-route-origin" />
            <span className="download-route-dash" />
            <span className="download-route-dash" />
            <span className="download-route-dash" />
            <span className="download-route-destination" />
          </div>
          <div className="download-device-trip">
            <span>SEGUIMIENTO DE MAQUINARIA</span>
            <strong>Tu ruta, paso a paso.</strong>
            <div className="download-device-detail"><Check size={15} /> Asignaciones claras</div>
            <div className="download-device-detail"><Check size={15} /> Inicio y cierre de viaje</div>
          </div>
          <div className="download-device-nav">
            <span className="active"><Smartphone size={17} /> Viajes</span>
            <span><ShieldCheck size={17} /> Perfil</span>
          </div>
        </div>
        <div className="download-hero-grid" aria-hidden="true" />
      </section>

      <section className="download-benefits" aria-label="Funciones de MaquiTrace">
        <div>
          <span className="download-benefit-number">01</span>
          <h2>Una asignación clara</h2>
          <p>El administrador prepara el despacho y asigna la ruta al conductor.</p>
        </div>
        <div>
          <span className="download-benefit-number">02</span>
          <h2>Seguimiento del viaje</h2>
          <p>El conductor inicia el recorrido y comparte su avance desde la app.</p>
        </div>
        <div>
          <span className="download-benefit-number">03</span>
          <h2>Entrega registrada</h2>
          <p>El cierre del trayecto queda vinculado al historial de la maquinaria.</p>
        </div>
      </section>

      <section className="download-install">
        <div>
          <p className="download-eyebrow">INSTALACIÓN</p>
          <h2>Empieza en pocos pasos.</h2>
        </div>
        <ol>
          <li><span>1</span> Descarga el archivo APK en tu teléfono Android.</li>
          <li><span>2</span> Abre el archivo y autoriza la instalación si Android lo solicita.</li>
          <li><span>3</span> Inicia sesión con las credenciales que te entregó el administrador.</li>
        </ol>
      </section>

      <footer className="download-footer">
        <a className="download-wordmark" href="/descargar" aria-label="MaquiTrace">
          <span>MAQUITRACE</span>
        </a>
        <span>Trazabilidad para maquinaria pesada.</span>
      </footer>
    </main>
  );
}
