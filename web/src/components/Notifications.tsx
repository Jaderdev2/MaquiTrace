import { useCallback, useEffect, useState } from 'react';
import { Bell } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import '../styles/notifications.css';

type Notice = { id: string; title: string; message: string; createdAt: string; readAt: string | null };
type Inbox = { items: Notice[]; unreadCount: number };
const base = import.meta.env.VITE_API_URL || 'https://maquitrace-backend.onrender.com/api/v1';

export function Notifications() {
  const { token } = useAuth();
  const [open, setOpen] = useState(false);
  const [inbox, setInbox] = useState<Inbox | null>(null);
  const [error, setError] = useState(false);
  const load = useCallback(async () => {
    if (!token) return;
    try {
      const response = await fetch(`${base}/notifications`, { headers: { Authorization: `Bearer ${token}` } });
      if (!response.ok) throw new Error();
      setInbox(await response.json()); setError(false);
    } catch { setError(true); }
  }, [token]);
  useEffect(() => { void load(); const timer = window.setInterval(load, 30000); return () => window.clearInterval(timer); }, [load]);
  async function markRead(id: string) {
    try {
      const response = await fetch(`${base}/notifications/${id}/read`, { method: 'PATCH', headers: { Authorization: `Bearer ${token}` } });
      if (!response.ok) throw new Error();
      await load();
    } catch { setError(true); }
  }
  return <div className="notifications-wrapper">
    <button className="notifications-trigger" type="button" aria-label={`Notificaciones${inbox?.unreadCount ? `, ${inbox.unreadCount} sin leer` : ''}`} aria-expanded={open} onClick={() => { setOpen(!open); if (!open) void load(); }}>
      <Bell size={20}/>{!!inbox?.unreadCount && <span className="notifications-count">{inbox.unreadCount > 99 ? '99+' : inbox.unreadCount}</span>}
    </button>
    {open && <section className="notifications-panel" aria-label="Notificaciones">
      <div className="notifications-heading"><strong>Notificaciones</strong><button type="button" onClick={() => setOpen(false)} aria-label="Cerrar notificaciones">Cerrar</button></div>
      {error && <p className="notifications-status" role="alert">No se pudieron actualizar los avisos. <button type="button" onClick={() => void load()}>Reintentar</button></p>}
      {!inbox && !error && <p className="notifications-status">Cargando avisos...</p>}
      {inbox && inbox.items.length === 0 && !error && <p className="notifications-status">No tienes notificaciones.</p>}
      <div className="notifications-list">{inbox?.items.map(item => <article key={item.id} className={`notification-item ${item.readAt ? '' : 'unread'}`}>
        <strong>{item.title}</strong><p>{item.message}</p><time>{new Date(item.createdAt).toLocaleString('es-CO')}</time>
        {!item.readAt && <button type="button" onClick={() => void markRead(item.id)}>Marcar como leída</button>}
      </article>)}</div>
    </section>}
  </div>;
}
