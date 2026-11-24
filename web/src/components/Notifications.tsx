import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Bell,
  Check,
  CheckCheck,
  Volume2,
  VolumeX,
  X,
  Truck,
  CheckCircle2,
  AlertTriangle,
  Sparkles,
  Wrench,
  Camera,
  Navigation,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { fetchMachinesApi, fetchTripsApi, fetchActiveTripsApi } from '../services/api';
import type { Machine, TransportTrip } from '../types';
import '../styles/notifications.css';

type NoticeRole = 'operario' | 'transportador' | 'sistema';

type Notice = {
  id: string;
  type?: string;
  roleSource?: NoticeRole;
  actorName?: string;
  title: string;
  message: string;
  createdAt: string;
  readAt: string | null;
  persisted?: boolean;
};

const base = import.meta.env.VITE_API_URL || 'https://maquitrace-backend.onrender.com/api/v1';
const LOCAL_READ_KEY = 'maquitrace_read_notices_v1';

const PASTEL_VARIANTS = [
  'pastel-sky',
  'pastel-mint',
  'pastel-rose',
  'pastel-lavender',
  'pastel-peach',
] as const;

function getLocalReadSet(): Set<string> {
  try {
    const raw = localStorage.getItem(LOCAL_READ_KEY);
    if (!raw) return new Set();
    return new Set(JSON.parse(raw));
  } catch {
    return new Set();
  }
}

function saveLocalReadSet(set: Set<string>) {
  try {
    const arr = Array.from(set).slice(-300);
    localStorage.setItem(LOCAL_READ_KEY, JSON.stringify(arr));
  } catch {
    // ignore storage errors
  }
}

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

function inferRoleSource(item: Notice): NoticeRole {
  if (item.roleSource) return item.roleSource;
  const text = `${item.type || ''} ${item.title} ${item.message}`.toLowerCase();
  if (
    text.includes('operario') ||
    text.includes('taller') ||
    text.includes('ensamblaje') ||
    text.includes('lavado') ||
    text.includes('pintura') ||
    text.includes('alistamiento') ||
    text.includes('phase') ||
    text.includes('evidencia')
  ) {
    return 'operario';
  }
  if (
    text.includes('transportador') ||
    text.includes('conductor') ||
    text.includes('viaje') ||
    text.includes('ruta') ||
    text.includes('traslado') ||
    text.includes('novedad') ||
    text.includes('incidencia') ||
    text.includes('entreg') ||
    text.includes('gps') ||
    text.includes('trip') ||
    text.includes('incident')
  ) {
    return 'transportador';
  }
  return 'sistema';
}

function getPastelClassAndIcon(item: Notice, index: number) {
  const text = `${item.type || ''} ${item.title} ${item.message}`.toLowerCase();

  if (text.includes('novedad') || text.includes('incidencia') || text.includes('incident') || text.includes('derrumbe')) {
    return { pastelClass: 'pastel-rose', Icon: AlertTriangle };
  }
  if (text.includes('entregad') || text.includes('delivered') || text.includes('completad') || text.includes('aprobado')) {
    return { pastelClass: 'pastel-mint', Icon: CheckCircle2 };
  }
  if (text.includes('evidencia') || text.includes('foto')) {
    return { pastelClass: 'pastel-lavender', Icon: Camera };
  }
  if (text.includes('taller') || text.includes('fase') || text.includes('ensamblaje') || text.includes('lavado') || text.includes('pintura') || text.includes('alistamiento')) {
    return { pastelClass: 'pastel-peach', Icon: Wrench };
  }
  if (text.includes('gps') || text.includes('ubicación') || text.includes('coordenada')) {
    return { pastelClass: 'pastel-sky', Icon: Navigation };
  }
  if (text.includes('viaje') || text.includes('ruta') || text.includes('traslado') || text.includes('trip') || text.includes('salida')) {
    return { pastelClass: 'pastel-sky', Icon: Truck };
  }
  if (text.includes('reasignad') || text.includes('usuario')) {
    return { pastelClass: 'pastel-lavender', Icon: Sparkles };
  }

  const fallbackClass = PASTEL_VARIANTS[index % PASTEL_VARIANTS.length];
  return { pastelClass: fallbackClass, Icon: Bell };
}

/**
 * Construye eventos de notificación a partir de todos los cambios reales hechos
 * por Operarios (fases de taller y evidencias fotográficas) y Transportadores
 * (salidas, entregas, reportes/incidencias con foto y transmisiones GPS).
 */
function buildActivityNotices(
  machines: Machine[],
  trips: TransportTrip[],
  readSet: Set<string>
): Notice[] {
  const events: Notice[] = [];

  // 1. Cambios de Operarios en Fases de Alistamiento y Evidencias Fotográficas
  for (const machine of machines) {
    const machineLabel = `${machine.model} (${machine.serial})`;

    if (Array.isArray(machine.phases)) {
      for (const phase of machine.phases) {
        if (phase.status === 'en_proceso' || phase.status === 'completada') {
          const timestamp =
            phase.completedAt ||
            phase.startedAt ||
            machine.createdAt ||
            new Date().toISOString();
          const operatorName = phase.operator?.name || 'Operario de Taller';
          const phaseTitle = phase.name.charAt(0).toUpperCase() + phase.name.slice(1);
          const isDone = phase.status === 'completada';
          const noticeId = `act-phase-${phase.id}-${phase.status}-${phase.observations || ''}`;

          events.push({
            id: noticeId,
            type: isDone ? 'phase_completada' : 'phase_en_proceso',
            roleSource: 'operario',
            actorName: operatorName,
            title: isDone
              ? `Fase de ${phaseTitle} completada`
              : `Fase de ${phaseTitle} en proceso`,
            message: `${operatorName} marcó ${phaseTitle} como "${isDone ? 'Completada' : 'En proceso'}" en ${machineLabel}${phase.observations ? `: "${phase.observations}"` : '.'}`,
            createdAt: timestamp,
            readAt: readSet.has(noticeId) ? timestamp : null,
            persisted: false,
          });
        }
      }
    }

    if (Array.isArray(machine.evidence)) {
      for (const ev of machine.evidence) {
        const uploaderName = ev.uploader?.name || 'Operario de Taller';
        const noticeId = `act-ev-${ev.id}`;
        events.push({
          id: noticeId,
          type: 'evidence_uploaded',
          roleSource: 'operario',
          actorName: uploaderName,
          title: `Evidencia fotográfica en ${machine.serial}`,
          message: `${uploaderName} registró fotografía de inspección para ${machineLabel}${ev.observations ? `: "${ev.observations}"` : '.'}`,
          createdAt: ev.createdAt || machine.createdAt || new Date().toISOString(),
          readAt: readSet.has(noticeId) ? ev.createdAt : null,
          persisted: false,
        });
      }
    }
  }

  // 2. Cambios del Transportador (Inicio de ruta, Entrega, Novedades/Evidencias en ruta y GPS)
  for (const trip of trips) {
    const driverName = trip.transporter?.name || 'Transportador Asignado';
    const machineLabel = trip.machine
      ? `${trip.machine.model} (${trip.machine.serial})`
      : 'Maquinaria';

    if (trip.status === 'en_transito' && trip.departureAt) {
      const noticeId = `act-trip-depart-${trip.id}-${trip.status}`;
      events.push({
        id: noticeId,
        type: 'trip_departed',
        roleSource: 'transportador',
        actorName: driverName,
        title: `Salida a ruta: ${trip.vehicle}`,
        message: `${driverName} inició el traslado de ${machineLabel} hacia ${trip.destination}.`,
        createdAt: trip.departureAt,
        readAt: readSet.has(noticeId) ? trip.departureAt : null,
        persisted: false,
      });
    }

    if (trip.status === 'entregado') {
      const arrivalTime = trip.arrivalAt || trip.departureAt || new Date().toISOString();
      const noticeId = `act-trip-deliver-${trip.id}-entregado`;
      events.push({
        id: noticeId,
        type: 'trip_delivered',
        roleSource: 'transportador',
        actorName: driverName,
        title: `Entrega confirmada en destino`,
        message: `${driverName} entregó a conformidad ${machineLabel} en ${trip.destination}.`,
        createdAt: arrivalTime,
        readAt: readSet.has(noticeId) ? arrivalTime : null,
        persisted: false,
      });
    }

    if (Array.isArray(trip.incidents)) {
      for (const inc of trip.incidents) {
        const noticeId = `act-inc-${inc.id}`;
        const hasPhoto = Boolean(inc.photoUrl);
        events.push({
          id: noticeId,
          type: 'incident_reported',
          roleSource: 'transportador',
          actorName: driverName,
          title: hasPhoto
            ? `Evidencia / Reporte del conductor`
            : `Novedad en ruta reportada`,
          message: `${driverName} (${trip.vehicle}) reportó en ${machineLabel}: "${inc.description}"`,
          createdAt: inc.reportedAt || trip.departureAt || new Date().toISOString(),
          readAt: readSet.has(noticeId) ? inc.reportedAt : null,
          persisted: false,
        });
      }
    }

    if (Array.isArray(trip.gpsRecords) && trip.gpsRecords.length > 0) {
      const latestGps = trip.gpsRecords[trip.gpsRecords.length - 1];
      const noticeId = `act-gps-${trip.id}-${latestGps.id || latestGps.recordedAt}`;
      events.push({
        id: noticeId,
        type: 'gps_updated',
        roleSource: 'transportador',
        actorName: driverName,
        title: `Ubicación GPS actualizada`,
        message: `${driverName} transmitió coordenada (${latestGps.latitude.toFixed(4)}, ${latestGps.longitude.toFixed(4)}) rumbo a ${trip.destination}.`,
        createdAt: latestGps.recordedAt || new Date().toISOString(),
        readAt: readSet.has(noticeId) ? latestGps.recordedAt : null,
        persisted: false,
      });
    }
  }

  return events;
}

export function Notifications() {
  const { token } = useAuth();
  const [open, setOpen] = useState(false);
  const [items, setItems] = useState<Notice[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [roleFilter, setRoleFilter] = useState<'todos' | 'operario' | 'transportador'>('todos');

  const seenUnreadIdsRef = useRef<Set<string>>(new Set());
  const isInitialLoadRef = useRef<boolean>(true);
  const wrapperRef = useRef<HTMLDivElement>(null);

  const load = useCallback(async () => {
    if (!token) return;
    try {
      const localRead = getLocalReadSet();

      const [notifRes, machinesData, tripsData] = await Promise.all([
        fetch(`${base}/notifications`, {
          headers: { Authorization: `Bearer ${token}` },
        })
          .then((r) => (r.ok ? r.json() : { items: [], unreadCount: 0 }))
          .catch(() => ({ items: [], unreadCount: 0 })),
        fetchMachinesApi(token).catch(() => [] as Machine[]),
        fetchTripsApi(token)
          .catch(() => fetchActiveTripsApi(token))
          .catch(() => [] as TransportTrip[]),
      ]);

      const persistedNotices: Notice[] = Array.isArray(notifRes?.items)
        ? notifRes.items.map((n: Notice) => ({
            ...n,
            roleSource: inferRoleSource(n),
            readAt: n.readAt || (localRead.has(n.id) ? n.createdAt : null),
            persisted: true,
          }))
        : [];

      const synthesizedNotices = buildActivityNotices(machinesData, tripsData, localRead);

      // Combinar evitando duplicados semánticos (mismo mensaje y fecha cercana)
      const combined: Notice[] = [...persistedNotices];
      for (const syn of synthesizedNotices) {
        const isDuplicate = persistedNotices.some(
          (p) =>
            p.message.toLowerCase() === syn.message.toLowerCase() ||
            (p.title.toLowerCase() === syn.title.toLowerCase() &&
              Math.abs(new Date(p.createdAt).getTime() - new Date(syn.createdAt).getTime()) < 60000)
        );
        if (!isDuplicate) {
          combined.push(syn);
        }
      }

      // Ordenar de más reciente a más antigua
      combined.sort(
        (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      );

      const finalItems = combined.slice(0, 60);

      // Detectar si llegó algún cambio nuevo sin leer de operario o transportador
      const currentUnread = finalItems.filter((n) => !n.readAt);
      let hasNewUnread = false;

      for (const item of currentUnread) {
        if (!seenUnreadIdsRef.current.has(item.id)) {
          seenUnreadIdsRef.current.add(item.id);
          hasNewUnread = true;
        }
      }

      if (!isInitialLoadRef.current && hasNewUnread && soundEnabled) {
        playShortNotificationSound();
      }
      isInitialLoadRef.current = false;

      setItems(finalItems);
      setError(false);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, [token, soundEnabled]);

  useEffect(() => {
    void load();
    const timer = window.setInterval(load, 12000);
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

  async function markRead(notice: Notice) {
    const localRead = getLocalReadSet();
    localRead.add(notice.id);
    saveLocalReadSet(localRead);

    setItems((prev) =>
      prev.map((item) =>
        item.id === notice.id ? { ...item, readAt: new Date().toISOString() } : item
      )
    );

    if (notice.persisted) {
      await fetch(`${base}/notifications/${notice.id}/read`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` },
      }).catch(() => {});
    }
  }

  async function markAllRead() {
    const localRead = getLocalReadSet();
    items.forEach((n) => localRead.add(n.id));
    saveLocalReadSet(localRead);

    const nowIso = new Date().toISOString();
    setItems((prev) => prev.map((item) => ({ ...item, readAt: item.readAt || nowIso })));

    await fetch(`${base}/notifications/read-all`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${token}` },
    }).catch(() => {});
  }

  const unreadCount = useMemo(
    () => items.filter((n) => !n.readAt).length,
    [items]
  );

  const filteredItems = useMemo(() => {
    if (roleFilter === 'todos') return items;
    return items.filter((n) => inferRoleSource(n) === roleFilter);
  }, [items, roleFilter]);

  return (
    <div className="notifications-wrapper" ref={wrapperRef}>
      <button
        className={`notifications-trigger ${open ? 'is-open' : ''}`}
        type="button"
        aria-label={`Notificaciones${unreadCount ? `, ${unreadCount} sin leer` : ''}`}
        aria-expanded={open}
        onClick={() => {
          setOpen(!open);
          if (!open) void load();
        }}
      >
        <Bell size={19} />
        {unreadCount > 0 && (
          <span className="notifications-count">
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {open && (
        <section className="notifications-panel" aria-label="Notificaciones">
          <div className="notifications-heading">
            <div className="notifications-heading-left">
              <strong>Actividad y Avisos</strong>
              {unreadCount > 0 && (
                <span className="notifications-unread-pill">{unreadCount} nuevas</span>
              )}
            </div>

            <div className="notifications-heading-actions">
              {unreadCount > 0 && (
                <button
                  type="button"
                  className="notif-icon-action-btn"
                  onClick={() => void markAllRead()}
                  title="Marcar todas como leídas"
                >
                  <CheckCheck size={15} />
                </button>
              )}
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

          {/* Filtros rápidos minimalistas por origen: Todos, Operarios, Transportador */}
          <div className="notifications-filter-bar">
            <button
              type="button"
              className={`notif-filter-chip ${roleFilter === 'todos' ? 'active' : ''}`}
              onClick={() => setRoleFilter('todos')}
            >
              Todos ({items.length})
            </button>
            <button
              type="button"
              className={`notif-filter-chip ${roleFilter === 'operario' ? 'active' : ''}`}
              onClick={() => setRoleFilter('operario')}
            >
              <Wrench size={11} /> Operarios
            </button>
            <button
              type="button"
              className={`notif-filter-chip ${roleFilter === 'transportador' ? 'active' : ''}`}
              onClick={() => setRoleFilter('transportador')}
            >
              <Truck size={11} /> Transportador
            </button>
          </div>

          {error && (
            <div className="notifications-status" role="alert">
              <span>No se pudieron actualizar los avisos.</span>
              <button type="button" className="notif-retry-btn" onClick={() => void load()}>
                Reintentar
              </button>
            </div>
          )}

          {loading && items.length === 0 && !error && (
            <p className="notifications-status">Sincronizando actividad de operarios y transporte...</p>
          )}

          {!loading && filteredItems.length === 0 && !error && (
            <div className="notifications-empty-box">
              <Bell size={22} />
              <span>No hay notificaciones en esta categoría.</span>
            </div>
          )}

          <div className="notifications-list">
            {filteredItems.map((item, idx) => {
              const { pastelClass, Icon } = getPastelClassAndIcon(item, idx);
              const isUnread = !item.readAt;
              const roleSource = inferRoleSource(item);
              const roleBadgeText =
                roleSource === 'operario'
                  ? 'Operario'
                  : roleSource === 'transportador'
                  ? 'Transportador'
                  : 'Sistema';

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
                      <div style={{ display: 'flex', alignItems: 'center', gap: '5px', flexShrink: 0 }}>
                        <span className={`notif-role-tag role-${roleSource}`}>
                          {roleBadgeText}
                        </span>
                        {isUnread && <span className="notif-unread-dot" title="Sin leer" />}
                      </div>
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
                          onClick={() => void markRead(item)}
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
