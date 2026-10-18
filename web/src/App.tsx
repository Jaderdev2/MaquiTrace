import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Login } from './features/auth/Login';
import { Dashboard } from './features/dashboard/Dashboard';
import { MachinesPage } from './features/machines';
import { PreparationPage } from './features/preparation/PreparationPage';
import { TrackingPage } from './features/tracking/TrackingPage';
import { UsersPage } from './features/users/UsersPage';
import { Loader2 } from 'lucide-react';
import { RouteProgressBar } from './components/RouteProgressBar';
import { isAdminUser } from './utils/auth';
import './App.css';

/**
 * Componente para proteger rutas privadas (Dashboard, Maquinarias, etc.)
 * Si no está autenticado o no es Administrador, limpia la sesión y redirige a /login.
 */
const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, user, loading, logout } = useAuth();

  useEffect(() => {
    // Si hay una sesión pero no pertenece a un administrador, cerrarla de inmediato
    if (!loading && isAuthenticated && user && !isAdminUser(user)) {
      logout();
    }
  }, [loading, isAuthenticated, user, logout]);

  if (loading) {
    return (
      <div className="full-screen-loading">
        <Loader2 size={40} className="spinner text-primary" />
        <p>Cargando sesión de MaquiTrace...</p>
      </div>
    );
  }

  if (!isAuthenticated || !user || !isAdminUser(user)) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
};

/**
 * Componente para rutas públicas (Login)
 * Si ya está autenticado como Administrador, redirige directamente a /dashboard.
 */
const PublicRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, user, loading } = useAuth();

  if (loading) {
    return (
      <div className="full-screen-loading">
        <Loader2 size={40} className="spinner text-primary" />
        <p>Cargando sesión de MaquiTrace...</p>
      </div>
    );
  }

  if (isAuthenticated && isAdminUser(user)) {
    return <Navigate to="/dashboard" replace />;
  }

  return <>{children}</>;
};

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <RouteProgressBar />
        <Routes>
          {/* Ruta pública: Inicio de sesión */}
          <Route
            path="/login"
            element={
              <PublicRoute>
                <Login />
              </PublicRoute>
            }
          />

          {/* Ruta protegida: Panel de control */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />

          {/* Ruta protegida: Parque y Gestión de Maquinaria */}
          <Route
            path="/maquinas"
            element={
              <ProtectedRoute>
                <MachinesPage />
              </ProtectedRoute>
            }
          />

          {/* Ruta protegida: Fases de Alistamiento */}
          <Route
            path="/alistamientos"
            element={
              <ProtectedRoute>
                <PreparationPage />
              </ProtectedRoute>
            }
          />

          {/* Ruta protegida: Seguimiento y Rutas de Transporte */}
          <Route
            path="/seguimiento"
            element={
              <ProtectedRoute>
                <TrackingPage />
              </ProtectedRoute>
            }
          />

          {/* Ruta protegida: Gestión de Usuarios y Roles */}
          <Route
            path="/usuarios"
            element={
              <ProtectedRoute>
                <UsersPage />
              </ProtectedRoute>
            }
          />

          {/* Rutas por defecto y comodín redirigen a /dashboard */}
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

