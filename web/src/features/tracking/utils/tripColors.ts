import type { TransportTrip } from '../../../types';

export interface TripColorTheme {
  id: string;
  name: string;
  primary: string;
  light: string;
  border: string;
  text: string;
  badgeBg: string;
  badgeText: string;
  glow: string;
}

export const TRIP_PALETTE: TripColorTheme[] = [
  {
    id: 'blue',
    name: 'Azul Real',
    primary: '#0066FF',
    light: '#EFF6FF',
    border: '#BFDBFE',
    text: '#1D4ED8',
    badgeBg: '#DBEAFE',
    badgeText: '#1E40AF',
    glow: 'rgba(0, 102, 255, 0.28)',
  },
  {
    id: 'purple',
    name: 'Morado Vía',
    primary: '#7C3AED',
    light: '#F5F3FF',
    border: '#DDD6FE',
    text: '#6D28D9',
    badgeBg: '#EDE9FE',
    badgeText: '#5B21B6',
    glow: 'rgba(124, 58, 237, 0.28)',
  },
  {
    id: 'emerald',
    name: 'Verde Esmeralda',
    primary: '#059669',
    light: '#ECFDF5',
    border: '#A7F3D0',
    text: '#047857',
    badgeBg: '#D1FAE5',
    badgeText: '#065F46',
    glow: 'rgba(5, 150, 105, 0.28)',
  },
  {
    id: 'amber',
    name: 'Ámbar Transporte',
    primary: '#D97706',
    light: '#FFFBEB',
    border: '#FDE68A',
    text: '#B45309',
    badgeBg: '#FEF3C7',
    badgeText: '#92400E',
    glow: 'rgba(217, 119, 6, 0.28)',
  },
  {
    id: 'rose',
    name: 'Rojo Carmesí',
    primary: '#E11D48',
    light: '#FFF1F2',
    border: '#FECDD3',
    text: '#BE123C',
    badgeBg: '#FFE4E6',
    badgeText: '#9F1239',
    glow: 'rgba(225, 29, 72, 0.28)',
  },
  {
    id: 'teal',
    name: 'Turquesa Andino',
    primary: '#0D9488',
    light: '#F0FDFA',
    border: '#99F6E4',
    text: '#0F766E',
    badgeBg: '#CCFBF1',
    badgeText: '#115E59',
    glow: 'rgba(13, 148, 136, 0.28)',
  },
  {
    id: 'indigo',
    name: 'Índigo Central',
    primary: '#4F46E5',
    light: '#EEF2FF',
    border: '#C7D2FE',
    text: '#4338CA',
    badgeBg: '#E0E7FF',
    badgeText: '#3730A3',
    glow: 'rgba(79, 70, 229, 0.28)',
  },
  {
    id: 'orange',
    name: 'Naranja Despacho',
    primary: '#EA580C',
    light: '#FFF7ED',
    border: '#FED7AA',
    text: '#C2410C',
    badgeBg: '#FFEDD5',
    badgeText: '#9A3412',
    glow: 'rgba(234, 88, 12, 0.28)',
  },
];

export function getTripColorTheme(trip: TransportTrip, index?: number): TripColorTheme {
  if (trip.color) {
    const found = TRIP_PALETTE.find((c) => c.primary.toLowerCase() === trip.color?.toLowerCase());
    if (found) return found;
  }
  let idx = index;
  if (idx === undefined) {
    let hash = 0;
    const str = trip.id || trip.vehicle || 'trip';
    for (let i = 0; i < str.length; i++) {
      hash = (hash << 5) - hash + str.charCodeAt(i);
      hash |= 0;
    }
    idx = Math.abs(hash) % TRIP_PALETTE.length;
  }
  return TRIP_PALETTE[idx % TRIP_PALETTE.length];
}
