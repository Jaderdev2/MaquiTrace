import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Login } from './features/auth/Login';
import { Dashboard } from './features/dashboard/Dashboard';
import { MachinesPage } from './features/machines';
import { Loader2 } from 'lucide-react';
import './App.css';

/**
 * Componente para proteger rutas privadas (Dashboard, etc.)
 * Si no está autenticado, redirige a /login.
 */
const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <div className="full-screen-loading">
        <Loader2 size={40} className="spinner text-primary" />
        <p>Cargando sesión de MaquiTrace...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
};

/**
 * Componente para rutas públicas (Login)
 * Si ya está autenticado, redirige directamente a /dashboard.
 */
const PublicRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <div className="full-screen-loading">
        <Loader2 size={40} className="spinner text-primary" />
        <p>Cargando sesión de MaquiTrace...</p>
      </div>
    );
  }

  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />;
  }

  return <>{children}</>;
};

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
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

          {/* Rutas por defecto y comodín redirigen a /dashboard */}
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

