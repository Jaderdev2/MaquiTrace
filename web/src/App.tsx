import React from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Login } from './features/auth/Login';
import { Dashboard } from './features/dashboard/Dashboard';
import { Loader2 } from 'lucide-react';
import './App.css';

const MainApp: React.FC = () => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <div className="full-screen-loading">
        <Loader2 size={40} className="spinner text-primary" />
        <p>Cargando sesión de MaquiTrace...</p>
      </div>
    );
  }

  return isAuthenticated ? <Dashboard /> : <Login />;
};

export default function App() {
  return (
    <AuthProvider>
      <MainApp />
    </AuthProvider>
  );
}
