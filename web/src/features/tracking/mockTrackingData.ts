import type { TransportTrip } from '../../types';

/**
 * Datos genéricos de ejemplo realistas para el módulo de Seguimiento Satelital y Trazabilidad.
 * Todas las rutas inician en el Puerto de Buenaventura (puerto de llegada de maquinaria a Colombia)
 * y siguen trazados reales por carreteras nacionales (Ruta 40, Ruta 25, Vía al Mar, Autopistas Pacífico y del Café):
 * 1. Buenaventura -> Bogotá D.C. (por Buga, Tuluá, La Línea, Ibagué)
 * 2. Buenaventura -> Medellín, Antioquia (por Buga, Cartago, Pereira, La Pintada)
 * 3. Buenaventura -> Cali, Valle (por Dagua, Km 18, Portada al Mar)
 * 4. Buenaventura -> Tuluá, Valle (por Loboguerrero, Media Canoa, Buga)
 * 5. Buenaventura -> Antioquia (Consorcio Vial Pacífico 2, Bolombolo)
 */
export const MOCK_TRIPS: TransportTrip[] = [
  {
    id: 'trip-demo-01',
    machineId: 'mach-demo-01',
    color: '#0066FF', // Azul Eléctrico
    vehicle: 'Camión Cama Baja Kenworth T800 (Placa: WKK-482)',
    destination: 'Parque Industrial Fontibón - Bogotá D.C.',
    status: 'en_transito',
    departureAt: new Date(Date.now() - 7.5 * 3600 * 1000).toISOString(),
    transporterId: 'user-demo-transporter-1',
    transporter: {
      id: 'user-demo-transporter-1',
      name: 'Carlos Alberto Mendoza',
      email: 'carlos.mendoza@transporte-maquitrace.com',
      phone: '+57 312 458 9921',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      cedula: 'CC 1.094.882.310',
      experienceTime: '4 años y 6 meses',
      licenseType: 'Licencia C3 (Tractocamiones y Carga Pesada)',
    },
    machine: {
      id: 'mach-demo-01',
      category: 'Excavadora Hidráulica',
      model: 'Caterpillar 320D L',
      serial: 'CAT-320D-8942',
      status: 'en_transito',
      imageUrl: 'https://images.unsplash.com/photo-1579829366248-204fe8413f31?auto=format&fit=crop&w=600&q=80',
      evidence: [
        {
          id: 'ev-1',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1579829366248-204fe8413f31?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 8 * 3600 * 1000).toISOString(),
          observations: 'Inspección de salida en patio de descargue portuario TCBUEN - Buenaventura.',
        },
        {
          id: 'ev-2',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 7.6 * 3600 * 1000).toISOString(),
          observations: 'Inspección lateral y amarre de orugas con cadenas tensoras certificadas.',
        },
        {
          id: 'ev-3',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 7.5 * 3600 * 1000).toISOString(),
          observations: 'Cabina cerrada y sellos de seguridad verificados antes de iniciar marcha.',
        },
      ],
    },
    // Carretera real: Buenaventura -> Cisneros -> Loboguerrero -> Buga -> Tuluá -> Calarcá -> La Línea -> Ibagué (punto actual en vivo)
    gpsRecords: [
      { id: 'gps-1-01', tripId: 'trip-demo-01', latitude: 3.8826, longitude: -77.0311, recordedAt: new Date(Date.now() - 7.5 * 3600 * 1000).toISOString() }, // Puerto Buenaventura
      { id: 'gps-1-02', tripId: 'trip-demo-01', latitude: 3.8872, longitude: -76.9921, recordedAt: new Date(Date.now() - 7.2 * 3600 * 1000).toISOString() }, // Vía Alterna Interna
      { id: 'gps-1-03', tripId: 'trip-demo-01', latitude: 3.8741, longitude: -76.9423, recordedAt: new Date(Date.now() - 6.8 * 3600 * 1000).toISOString() }, // Córdoba
      { id: 'gps-1-04', tripId: 'trip-demo-01', latitude: 3.8341, longitude: -76.8521, recordedAt: new Date(Date.now() - 6.3 * 3600 * 1000).toISOString() }, // Triana
      { id: 'gps-1-05', tripId: 'trip-demo-01', latitude: 3.7842, longitude: -76.7645, recordedAt: new Date(Date.now() - 5.8 * 3600 * 1000).toISOString() }, // Cisneros
      { id: 'gps-1-06', tripId: 'trip-demo-01', latitude: 3.7663, longitude: -76.6610, recordedAt: new Date(Date.now() - 5.2 * 3600 * 1000).toISOString() }, // Loboguerrero
      { id: 'gps-1-07', tripId: 'trip-demo-01', latitude: 3.8214, longitude: -76.5182, recordedAt: new Date(Date.now() - 4.6 * 3600 * 1000).toISOString() }, // Restrepo
      { id: 'gps-1-08', tripId: 'trip-demo-01', latitude: 3.8569, longitude: -76.4021, recordedAt: new Date(Date.now() - 4.1 * 3600 * 1000).toISOString() }, // Media Canoa
      { id: 'gps-1-09', tripId: 'trip-demo-01', latitude: 3.9009, longitude: -76.2978, recordedAt: new Date(Date.now() - 3.6 * 3600 * 1000).toISOString() }, // Guadalajara de Buga
      { id: 'gps-1-10', tripId: 'trip-demo-01', latitude: 4.0847, longitude: -76.1954, recordedAt: new Date(Date.now() - 3.0 * 3600 * 1000).toISOString() }, // Tuluá
      { id: 'gps-1-11', tripId: 'trip-demo-01', latitude: 4.3215, longitude: -75.9521, recordedAt: new Date(Date.now() - 2.3 * 3600 * 1000).toISOString() }, // La Paila
      { id: 'gps-1-12', tripId: 'trip-demo-01', latitude: 4.5298, longitude: -75.6421, recordedAt: new Date(Date.now() - 1.6 * 3600 * 1000).toISOString() }, // Calarcá
      { id: 'gps-1-13', tripId: 'trip-demo-01', latitude: 4.4851, longitude: -75.5214, recordedAt: new Date(Date.now() - 1.1 * 3600 * 1000).toISOString() }, // Túnel de La Línea
      { id: 'gps-1-14', tripId: 'trip-demo-01', latitude: 4.4421, longitude: -75.4285, recordedAt: new Date(Date.now() - 0.6 * 3600 * 1000).toISOString() }, // Cajamarca
      { id: 'gps-1-15', tripId: 'trip-demo-01', latitude: 4.4389, longitude: -75.2322, recordedAt: new Date(Date.now() - 0.1 * 3600 * 1000).toISOString() }, // Ibagué (Posición en vivo en carretera a Bogotá)
    ],
    incidents: [
      {
        id: 'inc-demo-1',
        tripId: 'trip-demo-01',
        description: 'Parada técnica de 25 min en estación de servicio de Buga para verificación de tensión de cadenas.',
        reportedAt: new Date(Date.now() - 3.5 * 3600 * 1000).toISOString(),
      },
    ],
  },
  {
    id: 'trip-demo-02',
    machineId: 'mach-demo-02',
    color: '#7C3AED', // Morado Real
    vehicle: 'Remolque Doble Troque Freightliner Cascadia (Placa: TZN-901)',
    destination: 'Proyecto Vial Autopista al Mar 1 - Medellín, Antioquia',
    status: 'en_transito',
    departureAt: new Date(Date.now() - 6.5 * 3600 * 1000).toISOString(),
    transporterId: 'user-demo-transporter-2',
    transporter: {
      id: 'user-demo-transporter-2',
      name: 'Mauricio Gómez Quintero',
      email: 'mauricio.gomez@transporte-maquitrace.com',
      phone: '+57 320 871 3344',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      cedula: 'CC 79.451.902',
      experienceTime: '6 años y 2 meses',
      licenseType: 'Licencia C3 Especializada Carga Extradimensionada',
    },
    machine: {
      id: 'mach-demo-02',
      category: 'Retroexcavadora',
      model: 'Komatsu PC200-8',
      serial: 'KOM-PC200-5510',
      status: 'en_transito',
      imageUrl: 'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&w=600&q=80',
      evidence: [
        {
          id: 'ev-2-1',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 7 * 3600 * 1000).toISOString(),
          observations: 'Inspección técnica de balde y pluma completada en muelle portuario de Buenaventura.',
        },
        {
          id: 'ev-2-2',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 6.6 * 3600 * 1000).toISOString(),
          observations: 'Verificación de luces reglamentarias de escolta y señalización de carga ancha.',
        },
      ],
    },
    // Carretera real: Buenaventura -> Buga -> Tuluá -> Cartago -> Pereira -> Chinchiná -> La Pintada (Antioquia, en vivo)
    gpsRecords: [
      { id: 'gps-2-01', tripId: 'trip-demo-02', latitude: 3.8826, longitude: -77.0311, recordedAt: new Date(Date.now() - 6.5 * 3600 * 1000).toISOString() }, // Buenaventura
      { id: 'gps-2-02', tripId: 'trip-demo-02', latitude: 3.7842, longitude: -76.7645, recordedAt: new Date(Date.now() - 5.7 * 3600 * 1000).toISOString() }, // Cisneros
      { id: 'gps-2-03', tripId: 'trip-demo-02', latitude: 3.7663, longitude: -76.6610, recordedAt: new Date(Date.now() - 5.1 * 3600 * 1000).toISOString() }, // Loboguerrero
      { id: 'gps-2-04', tripId: 'trip-demo-02', latitude: 3.8569, longitude: -76.4021, recordedAt: new Date(Date.now() - 4.4 * 3600 * 1000).toISOString() }, // Media Canoa
      { id: 'gps-2-05', tripId: 'trip-demo-02', latitude: 3.9009, longitude: -76.2978, recordedAt: new Date(Date.now() - 3.8 * 3600 * 1000).toISOString() }, // Buga
      { id: 'gps-2-06', tripId: 'trip-demo-02', latitude: 4.0847, longitude: -76.1954, recordedAt: new Date(Date.now() - 3.2 * 3600 * 1000).toISOString() }, // Tuluá
      { id: 'gps-2-07', tripId: 'trip-demo-02', latitude: 4.3981, longitude: -76.0712, recordedAt: new Date(Date.now() - 2.5 * 3600 * 1000).toISOString() }, // Zarzal
      { id: 'gps-2-08', tripId: 'trip-demo-02', latitude: 4.7464, longitude: -75.9117, recordedAt: new Date(Date.now() - 1.8 * 3600 * 1000).toISOString() }, // Cartago
      { id: 'gps-2-09', tripId: 'trip-demo-02', latitude: 4.8133, longitude: -75.6961, recordedAt: new Date(Date.now() - 1.2 * 3600 * 1000).toISOString() }, // Pereira
      { id: 'gps-2-10', tripId: 'trip-demo-02', latitude: 5.0142, longitude: -75.6021, recordedAt: new Date(Date.now() - 0.7 * 3600 * 1000).toISOString() }, // Chinchiná
      { id: 'gps-2-11', tripId: 'trip-demo-02', latitude: 5.4742, longitude: -75.6712, recordedAt: new Date(Date.now() - 0.4 * 3600 * 1000).toISOString() }, // Irra / Supía (Pacífico 3)
      { id: 'gps-2-12', tripId: 'trip-demo-02', latitude: 5.7481, longitude: -75.6052, recordedAt: new Date(Date.now() - 0.1 * 3600 * 1000).toISOString() }, // La Pintada, Antioquia (Posición en vivo hacia Medellín)
    ],
    incidents: [
      {
        id: 'inc-demo-2',
        tripId: 'trip-demo-02',
        description: 'Paso alternado por mantenimiento de calzada en el tramo Chinchiná - Irra (demora de 20 min).',
        reportedAt: new Date(Date.now() - 0.8 * 3600 * 1000).toISOString(),
      },
    ],
  },
  {
    id: 'trip-demo-03',
    machineId: 'mach-demo-03',
    color: '#D97706', // Ámbar Cálido
    vehicle: 'Camión Plataforma Internacional 7600 (Placa: SQP-314)',
    destination: 'Zona Industrial Acopi Yumbo - Cali, Valle del Cauca',
    status: 'pendiente',
    departureAt: undefined,
    transporterId: 'user-demo-transporter-3',
    transporter: {
      id: 'user-demo-transporter-3',
      name: 'Andrés Felipe Ramos',
      email: 'andres.ramos@transporte-maquitrace.com',
      phone: '+57 310 994 1205',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
      cedula: 'CC 1.018.423.881',
      experienceTime: '2 años y 10 meses',
      licenseType: 'Licencia C2 (Camiones rígidos y maquinaria pesada)',
    },
    machine: {
      id: 'mach-demo-03',
      category: 'Rodillo Compactador',
      model: 'Dynapac CA250D',
      serial: 'DYN-CA250-1099',
      status: 'en_proceso',
      imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=600&q=80',
      phases: [
        { id: 'ph-3-1', name: 'ensamblaje', status: 'completada', observations: 'Ensamble de rodillo y motor diesel certificado.' },
        { id: 'ph-3-2', name: 'pintura', status: 'en_proceso', observations: 'En cabina de pintura: aplicación de esmalte de protección.' },
        { id: 'ph-3-3', name: 'lavado', status: 'pendiente' },
      ],
      evidence: [
        {
          id: 'ev-3-1',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 1.5 * 3600 * 1000).toISOString(),
          observations: 'Inspección de tambor vibratorio y niveles hidráulicos completada en patio portuario.',
        },
      ],
    },
    // Punto de origen listo para salir por la Vía al Mar hacia Cali (por Dagua y Km 18)
    gpsRecords: [
      { id: 'gps-3-01', tripId: 'trip-demo-03', latitude: 3.8826, longitude: -77.0311, recordedAt: new Date().toISOString() }, // Puerto Buenaventura (En muelle listo para despacho)
    ],
    incidents: [],
  },
  {
    id: 'trip-demo-04',
    machineId: 'mach-demo-04',
    color: '#059669', // Verde Esmeralda
    vehicle: 'Tractomula Mack Anthem (Placa: XVB-772)',
    destination: 'Parque Logístico e Industrial del Valle - Tuluá, Valle',
    status: 'entregado',
    departureAt: new Date(Date.now() - 14 * 3600 * 1000).toISOString(),
    arrivalAt: new Date(Date.now() - 2.5 * 3600 * 1000).toISOString(),
    transporterId: 'user-demo-transporter-1',
    transporter: {
      id: 'user-demo-transporter-1',
      name: 'Carlos Alberto Mendoza',
      email: 'carlos.mendoza@transporte-maquitrace.com',
      phone: '+57 312 458 9921',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      cedula: 'CC 1.094.882.310',
      experienceTime: '4 años y 6 meses',
      licenseType: 'Licencia C3 (Tractocamiones y Carga Pesada)',
    },
    machine: {
      id: 'mach-demo-04',
      category: 'Motoniveladora',
      model: 'John Deere 670G',
      serial: 'JD-670G-3381',
      status: 'entregada',
      imageUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb18615f8?auto=format&fit=crop&w=600&q=80',
      evidence: [
        {
          id: 'ev-4-1',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1541888946425-d0fbb18615f8?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 15 * 3600 * 1000).toISOString(),
          observations: 'Inspección de vertedera central y escarificador trasero previa a salida en Buenaventura.',
        },
        {
          id: 'ev-4-2',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 2.5 * 3600 * 1000).toISOString(),
          observations: 'Acta de entrega firmada a satisfacción por el jefe de patio en Tuluá.',
        },
      ],
    },
    // Carretera real completa: Buenaventura -> Córdoba -> Cisneros -> Loboguerrero -> Restrepo -> Media Canoa -> Yotoco -> Buga -> San Pedro -> Tuluá
    gpsRecords: [
      { id: 'gps-4-01', tripId: 'trip-demo-04', latitude: 3.8826, longitude: -77.0311, recordedAt: new Date(Date.now() - 14 * 3600 * 1000).toISOString() }, // Buenaventura
      { id: 'gps-4-02', tripId: 'trip-demo-04', latitude: 3.8741, longitude: -76.9423, recordedAt: new Date(Date.now() - 13.2 * 3600 * 1000).toISOString() }, // Córdoba
      { id: 'gps-4-03', tripId: 'trip-demo-04', latitude: 3.7842, longitude: -76.7645, recordedAt: new Date(Date.now() - 12.1 * 3600 * 1000).toISOString() }, // Cisneros
      { id: 'gps-4-04', tripId: 'trip-demo-04', latitude: 3.7663, longitude: -76.6610, recordedAt: new Date(Date.now() - 10.8 * 3600 * 1000).toISOString() }, // Loboguerrero
      { id: 'gps-4-05', tripId: 'trip-demo-04', latitude: 3.8214, longitude: -76.5182, recordedAt: new Date(Date.now() - 9.4 * 3600 * 1000).toISOString() }, // Restrepo
      { id: 'gps-4-06', tripId: 'trip-demo-04', latitude: 3.8569, longitude: -76.4021, recordedAt: new Date(Date.now() - 7.9 * 3600 * 1000).toISOString() }, // Media Canoa
      { id: 'gps-4-07', tripId: 'trip-demo-04', latitude: 3.8612, longitude: -76.3815, recordedAt: new Date(Date.now() - 6.5 * 3600 * 1000).toISOString() }, // Yotoco
      { id: 'gps-4-08', tripId: 'trip-demo-04', latitude: 3.9009, longitude: -76.2978, recordedAt: new Date(Date.now() - 5.0 * 3600 * 1000).toISOString() }, // Buga
      { id: 'gps-4-09', tripId: 'trip-demo-04', latitude: 3.9982, longitude: -76.2314, recordedAt: new Date(Date.now() - 3.7 * 3600 * 1000).toISOString() }, // San Pedro
      { id: 'gps-4-10', tripId: 'trip-demo-04', latitude: 4.0847, longitude: -76.1954, recordedAt: new Date(Date.now() - 2.5 * 3600 * 1000).toISOString() }, // Tuluá Destino Entregado
    ],
    incidents: [],
  },
  {
    id: 'trip-demo-05',
    machineId: 'mach-demo-05',
    color: '#E11D48', // Carmesí / Rojo
    vehicle: 'Tractocamión Kenworth W900 (Placa: SKL-119)',
    destination: 'Consorcio Vial Pacífico 2, Sector Bolombolo - Antioquia',
    status: 'en_transito',
    departureAt: new Date(Date.now() - 5.0 * 3600 * 1000).toISOString(),
    transporterId: 'user-demo-transporter-2',
    transporter: {
      id: 'user-demo-transporter-2',
      name: 'Mauricio Gómez Quintero',
      email: 'mauricio.gomez@transporte-maquitrace.com',
      phone: '+57 320 871 3344',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      cedula: 'CC 79.451.902',
      experienceTime: '6 años y 2 meses',
      licenseType: 'Licencia C3 Especializada Carga Extradimensionada',
    },
    machine: {
      id: 'mach-demo-05',
      category: 'Cargador Frontal',
      model: 'Caterpillar 950M',
      serial: 'CAT-950M-7714',
      status: 'en_transito',
      imageUrl: 'https://images.unsplash.com/photo-1579829366248-204fe8413f31?auto=format&fit=crop&w=600&q=80',
      evidence: [
        {
          id: 'ev-5-1',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1579829366248-204fe8413f31?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 5.2 * 3600 * 1000).toISOString(),
          observations: 'Revisión técnica de balde frontal de 3.5m³ en patio Buenaventura.',
        },
      ],
    },
    // Carretera real: Buenaventura -> Loboguerrero -> Buga -> Tuluá -> Cartago -> Pereira -> La Pintada -> Bolombolo (Antioquia)
    gpsRecords: [
      { id: 'gps-5-01', tripId: 'trip-demo-05', latitude: 3.8826, longitude: -77.0311, recordedAt: new Date(Date.now() - 5.0 * 3600 * 1000).toISOString() }, // Buenaventura
      { id: 'gps-5-02', tripId: 'trip-demo-05', latitude: 3.7663, longitude: -76.6610, recordedAt: new Date(Date.now() - 4.1 * 3600 * 1000).toISOString() }, // Loboguerrero
      { id: 'gps-5-03', tripId: 'trip-demo-05', latitude: 3.9009, longitude: -76.2978, recordedAt: new Date(Date.now() - 3.2 * 3600 * 1000).toISOString() }, // Buga
      { id: 'gps-5-04', tripId: 'trip-demo-05', latitude: 4.0847, longitude: -76.1954, recordedAt: new Date(Date.now() - 2.5 * 3600 * 1000).toISOString() }, // Tuluá
      { id: 'gps-5-05', tripId: 'trip-demo-05', latitude: 4.7464, longitude: -75.9117, recordedAt: new Date(Date.now() - 1.7 * 3600 * 1000).toISOString() }, // Cartago
      { id: 'gps-5-06', tripId: 'trip-demo-05', latitude: 4.8133, longitude: -75.6961, recordedAt: new Date(Date.now() - 1.1 * 3600 * 1000).toISOString() }, // Pereira
      { id: 'gps-5-07', tripId: 'trip-demo-05', latitude: 5.7481, longitude: -75.6052, recordedAt: new Date(Date.now() - 0.4 * 3600 * 1000).toISOString() }, // La Pintada
      { id: 'gps-5-08', tripId: 'trip-demo-05', latitude: 5.9723, longitude: -75.8341, recordedAt: new Date(Date.now() - 0.1 * 3600 * 1000).toISOString() }, // Bolombolo, Antioquia (En vivo)
    ],
    incidents: [],
  },
  {
    id: 'trip-demo-06',
    machineId: 'mach-demo-06',
    color: '#0D9488', // Turquesa Andino
    vehicle: 'Camión Cama Baja Internacional WorkStar (Placa: KLO-428)',
    destination: 'Proyecto Infraestructura Troncal del Magdalena - Santander',
    status: 'pendiente',
    departureAt: undefined,
    transporterId: 'user-demo-transporter-1',
    transporter: {
      id: 'user-demo-transporter-1',
      name: 'Carlos Alberto Mendoza',
      email: 'carlos.mendoza@transporte-maquitrace.com',
      phone: '+57 312 458 9921',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      cedula: 'CC 1.094.882.310',
      experienceTime: '5 años',
      licenseType: 'Licencia C3 (Carga Pesada)',
    },
    machine: {
      id: 'mach-demo-06',
      category: 'Bulldozer sobre Orugas',
      model: 'Caterpillar D6T XL',
      serial: 'CAT-D6T-7721',
      status: 'completada',
      imageUrl: 'https://images.unsplash.com/photo-1579829366248-204fe8413f31?auto=format&fit=crop&w=600&q=80',
      phases: [
        { id: 'ph-6-1', name: 'ensamblaje', status: 'completada', observations: 'Ensamble de hoja topadora y orugas certificado.' },
        { id: 'ph-6-2', name: 'pintura', status: 'completada', observations: 'Pintura y rotulado institucional MaquiTrace aprobado.' },
        { id: 'ph-6-3', name: 'lavado', status: 'completada', observations: 'Lavado a presión e inspección de entrega 100% aprobado.' },
      ],
      evidence: [
        {
          id: 'ev-6-1',
          type: 'foto',
          url: 'https://images.unsplash.com/photo-1579829366248-204fe8413f31?auto=format&fit=crop&w=600&q=80',
          createdAt: new Date(Date.now() - 2 * 3600 * 1000).toISOString(),
          observations: 'Control de calidad final en patio: listo para despacho.',
        },
      ],
    },
    gpsRecords: [
      { id: 'gps-6-01', tripId: 'trip-demo-06', latitude: 3.8826, longitude: -77.0311, recordedAt: new Date().toISOString() }, // Puerto Buenaventura
    ],
    incidents: [],
  },
];
