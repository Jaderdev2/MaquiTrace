import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { loginApi } from '../../services/api';
import { Mail, Lock, Eye, EyeOff, ArrowRight, Loader2, AlertCircle } from 'lucide-react';
import heroImg from '../../assets/branding/login_present.png';

export const Login: React.FC = () => {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(true);
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) {
      setError('Por favor, ingresa tu correo electrónico y contraseña.');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const data = await loginApi(email.trim(), password.trim());
      login(data.accessToken, data.user);
      navigate('/dashboard', { replace: true });
    } catch (err: any) {
      setError(err.message || 'Credenciales inválidas o error de conexión.');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickCredentials = (userEmail: string, userPass: string) => {
    setEmail(userEmail);
    setPassword(userPass);
    setError(null);
  };

  return (
    <div className="login-page-bg">
      <div className="login-container-card">
        {/* Panel Izquierdo: Gráfico Hero Exacto de MaquiTrace */}
        <div className="login-hero-side">
          <img
            src={heroImg}
            alt="MaquiTrace Trazabilidad y Seguimiento de Maquinaria"
            className="hero-full-image"
          />
        </div>

        {/* Panel Derecho: Formulario Blanco con Estilo Idéntico a la Maqueta */}
        <div className="login-form-side">
          {/* Decoración curva suave en la esquina superior derecha */}
          <div className="corner-accent-bubble"></div>

          <div className="form-main-content">
            <div className="login-title-group">
              <h1 className="login-main-title">
                Bienvenido a<br />
                Maqui<span className="brand-accent-blue">Trace</span>
              </h1>
              <p className="login-description-text">
                Inicia sesión para acceder a la plataforma y gestionar la trazabilidad de tu maquinaria.
              </p>
            </div>

            {error && (
              <div className="auth-error-alert">
                <AlertCircle size={16} className="error-alert-icon" />
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={handleSubmit} className="login-form-fields">
              {/* Campo Correo electrónico */}
              <div className="field-group">
                <label htmlFor="email" className="field-label">Correo electrónico</label>
                <div className="field-input-box">
                  <Mail className="field-leading-icon" size={18} />
                  <input
                    id="email"
                    type="email"
                    placeholder="usuario@ejemplo.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    disabled={loading}
                    required
                  />
                </div>
              </div>

              {/* Campo Contraseña */}
              <div className="field-group">
                <label htmlFor="password" className="field-label">Contraseña</label>
                <div className="field-input-box">
                  <Lock className="field-leading-icon" size={18} />
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    placeholder="Ingresa tu contraseña"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    disabled={loading}
                    required
                  />
                  <button
                    type="button"
                    className="field-trailing-btn"
                    onClick={() => setShowPassword(!showPassword)}
                    tabIndex={-1}
                    title={showPassword ? 'Ocultar contraseña' : 'Ver contraseña'}
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>

              {/* Fila Recordar sesión y Olvidaste tu contraseña */}
              <div className="remember-forgot-row">
                <label className="checkbox-custom-label">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                  />
                  <span className="checkbox-text">Recordar sesión</span>
                </label>
                <a
                  href="#recuperar"
                  onClick={(e) => {
                    e.preventDefault();
                    alert('Para restablecer tu contraseña, contacta al administrador del sistema.');
                  }}
                  className="forgot-password-link"
                >
                  ¿Olvidaste tu contraseña?
                </a>
              </div>

              {/* Botón Iniciar sesión */}
              <button
                type="submit"
                className="btn-submit-login"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <Loader2 size={18} className="spinner" />
                    <span>Iniciando sesión...</span>
                  </>
                ) : (
                  <>
                    <span>Iniciar sesión</span>
                    <ArrowRight size={18} />
                  </>
                )}
              </button>
            </form>

            {/* Accesos rápidos con credenciales reales de la base de datos (docs/credenciales.md) */}
            <div className="quick-access-strip">
              <span className="quick-label">Cuentas BD:</span>
              <button
                type="button"
                className="quick-chip"
                onClick={() => handleQuickCredentials('admin@maquitrace.com', 'Admin1234!')}
              >
                Admin
              </button>
              <button
                type="button"
                className="quick-chip"
                onClick={() => handleQuickCredentials('itadori@maquitrace.com', 'Operario1234!')}
              >
                Operario (Itadori)
              </button>
              <button
                type="button"
                className="quick-chip"
                onClick={() => handleQuickCredentials('charly@maquitrace.com', 'Operario1234!')}
              >
                Operario (Charly)
              </button>
              <button
                type="button"
                className="quick-chip"
                onClick={() => handleQuickCredentials('transportador@maquitrace.com', 'Transporte1234!')}
              >
                Transporte
              </button>
            </div>
          </div>

          {/* Footer idéntico al diseño */}
          <footer className="login-card-footer">
            <span className="footer-company">MaquiTrace</span>
            <span className="footer-sep">|</span>
            <span className="footer-slogan">Seguridad &nbsp;·&nbsp; Control &nbsp;·&nbsp; Eficiencia</span>
          </footer>
        </div>
      </div>
    </div>
  );
};
