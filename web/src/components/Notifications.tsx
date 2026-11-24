import { useCallback, useEffect, useRef, useState } from 'react';
import {
  Bell,
  Check,
  Volume2,
  VolumeX,
  X,
  Truck,
  CheckCircle2,
  AlertTriangle,
  Sparkles,
  Wrench,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import '../styles/notifications.css';

type Notice = {
  id: string;
  type?: string;
  title: string;
  message: string;
  createdAt: string;
  readAt: string | null;
};
type Inbox = { items: Notice[]; unreadCount: number };

const base = import.meta.env.VITE_API_URL || 'https://maquitrace-backend.onrender.com/api/v1';

const PASTEL_VARIANTS = [
  'pastel-sky',
  'pastel-mint',
  'pastel-rose',
  'pastel-lavender',
  'pastel-peach',
] as const;

/**
 * Genera un sonido corto y minimalista de notificación usando Web Audio API
 * (dos tonos suaves tipo campana de ~220 ms sin depender de archivos externos).
 */
function playShortNotificationSound() {
  try {
    const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioCtx) return;
    const ctx = new AudioCtx();

    const playTone = (freq: number, startTime: number, duration: number, peakGain: number) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, startTime);

      gain.gain.setValueAtTime(0.001, startTime);
      gain.gain.exponentialRampToValueAtTime(peakGain, startTime + 0.015);
      gain.gain.exponentialRampToValueAtTime(0.0001, startTime + duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(startTime);
      osc.stop(startTime + duration);
    };

    const now = ctx.currentTime;
    playTone(587.33, now, 0.12, 0.14); // D5
    playTone(880.0, now + 0.09, 0.18, 0.16); // A5

    setTimeout(() => {
      ctx.close().catch(() => {});
    }, 350);
  } catch {
    // Si el navegador aún no ha recibido interacción del usuario para audio
  }
}

function getPastelClassAndIcon(item: Notice, index: number) {
  const text = `${item.type || ''} ${item.title} ${item.message}`.toLowerCase();

  if (text.includes('novedad') || text.includes('incidencia') || text.includes('incident') || text.includes('alerta')) {
    return { pastelClass: 'pastel-rose', Icon: AlertTriangle };
  }
  if (text.includes('entregad') || text.includes('delivered') || text.includes('completad')) {
    return { pastelClass: 'pastel-mint', Icon: CheckCircle2 };
  }
  if (text.includes('taller') || text.includes('fase') || text.includes('alistamiento')) {
    return { pastelClass: 'pastel-peach', Icon: Wrench };
  }
  if (text.includes('reasignad') || text.includes('usuario')) {
    return { pastelClass: 'pastel-lavender', Icon: Sparkles };
  }
  if (text.includes('viaje') || text.includes('ruta') || text.includes('traslado') || text.includes('trip')) {
    return { pastelClass: 'pastel-sky', Icon: Truck };
  }

  const fallbackClass = PASTEL_VARIANTS[index % PASTEL_VARIANTS.length];
  return { pastelClass: fallbackClass, Icon: Bell };
}

export function Notifications() {
  const { token } = useAuth();
  const [open, setOpen] = useState(false);
  const [inbox, setInbox] = useState<Inbox | null>(null);
  const [error, setError] = useState(false);
  const [soundEnabled, setSoundEnabled] = useState(true);

  const seenUnreadIdsRef = useRef<Set<string>>(new Set());
  const isInitialLoadRef = useRef<boolean>(true);
  const wrapperRef = useRef<HTMLDivElement>(null);

  const load = useCallback(async () => {
    if (!token) return;
    try {
      const response = await fetch(`${base}/notifications`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!response.ok) throw new Error();
      const data: Inbox = await response.json();

      // Detectar si llegó alguna notificación nueva sin leer
      const currentUnreadItems = (data.items || []).filter((n) => !n.readAt);
      let hasNewUnread = false;

      for (const item of currentUnreadItems) {
        if (!seenUnreadIdsRef.current.has(item.id)) {
          seenUnreadIdsRef.current.add(item.id);
          hasNewUnread = true;
        }
      }

      if (!isInitialLoadRef.current && hasNewUnread && soundEnabled) {
        playShortNotificationSound();
      }
      isInitialLoadRef.current = false;

      setInbox(data);
      setError(false);
    } catch {
      setError(true);
    }
  }, [token, soundEnabled]);

  useEffect(() => {
    void load();
    const timer = window.setInterval(load, 15000);
    return () => window.clearInterval(timer);
  }, [load]);

  // Cerrar panel al hacer clic fuera
  useEffect(() => {
    const handleOutsideClick = (e: MouseEvent) => {
      if (open && wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleOutsideClick);
    return () => document.removeEventListener('mousedown', handleOutsideClick);
  }, [open]);

  async function markRead(id: string) {
    try {
      const response = await fetch(`${base}/notifications/${id}/read`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!response.ok) throw new Error();
      await load();
    } catch {
      setError(true);
    }
  }

  return (
    <div className="notifications-wrapper" ref={wrapperRef}>
      <button
        className={`notifications-trigger ${open ? 'is-open' : ''}`}
        type="button"
        aria-label={`Notificaciones${inbox?.unreadCount ? `, ${inbox.unreadCount} sin leer` : ''}`}
        aria-expanded={open}
        onClick={() => {
          setOpen(!open);
          if (!open) void load();
        }}
      >
        <Bell size={19} />
        {!!inbox?.unreadCount && (
          <span className="notifications-count">
            {inbox.unreadCount > 99 ? '99+' : inbox.unreadCount}
          </span>
        )}
      </button>

      {open && (
        <section className="notifications-panel" aria-label="Notificaciones">
          <div className="notifications-heading">
            <div className="notifications-heading-left">
              <strong>Notificaciones</strong>
              {!!inbox?.unreadCount && (
                <span className="notifications-unread-pill">{inbox.unreadCount} nuevas</span>
              )}
            </div>

            <div className="notifications-heading-actions">
              <button
                type="button"
                className="notif-icon-action-btn"
                onClick={() => {
                  const next = !soundEnabled;
                  setSoundEnabled(next);
                  if (next) playShortNotificationSound();
                }}
                title={soundEnabled ? 'Sonido activo (clic para silenciar)' : 'Sonido silenciado (clic para activar)'}
              >
                {soundEnabled ? <Volume2 size={15} /> : <VolumeX size={15} />}
              </button>
              <button
                type="button"
                className="notif-icon-action-btn"
                onClick={() => setOpen(false)}
                aria-label="Cerrar notificaciones"
                title="Cerrar"
              >
                <X size={16} />
              </button>
            </div>
          </div>

          {error && (
            <div className="notifications-status" role="alert">
              <span>No se pudieron actualizar los avisos.</span>
              <button type="button" className="notif-retry-btn" onClick={() => void load()}>
                Reintentar
              </button>
            </div>
          )}

          {!inbox && !error && <p className="notifications-status">Cargando avisos...</p>}

          {inbox && inbox.items.length === 0 && !error && (
            <div className="notifications-empty-box">
              <Bell size={22} />
              <span>Todo al día. No tienes notificaciones.</span>
            </div>
          )}

          <div className="notifications-list">
            {inbox?.items.map((item, idx) => {
              const { pastelClass, Icon } = getPastelClassAndIcon(item, idx);
              const isUnread = !item.readAt;

              return (
                <article
                  key={item.id}
                  className={`notification-item ${pastelClass} ${isUnread ? 'unread' : 'is-read'}`}
                >
                  <div className="notif-pastel-icon">
                    <Icon size={15} />
                  </div>

                  <div className="notif-content-col">
                    <div className="notif-top-line">
                      <strong className="notif-title">{item.title}</strong>
                      {isUnread && <span className="notif-unread-dot" title="Sin leer" />}
                    </div>

                    <p className="notif-message">{item.message}</p>

                    <div className="notif-footer-line">
                      <time className="notif-time">
                        {new Date(item.createdAt).toLocaleString('es-CO', {
                          day: '2-digit',
                          month: 'short',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </time>

                      {isUnread && (
                        <button
                          type="button"
                          className="notif-mark-read-btn"
                          onClick={() => void markRead(item.id)}
                          title="Marcar como leída"
                        >
                          <Check size={12} />
                          <span>Leída</span>
                        </button>
                      )}
                    </div>
                  </div>
                </article>
              );
            })}
          </div>
        </section>
      )}
    </div>
  );
}
