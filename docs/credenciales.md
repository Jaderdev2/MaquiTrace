# Credenciales de Acceso y Datos de Prueba · MaquiTrace

Este documento contiene los usuarios, roles y contraseñas de prueba activos en la base de datos PostgreSQL (Neon) para el desarrollo, validación y sustentación del proyecto.

---

## 1. Tabla de Usuarios y Credenciales

| Rol | Nombre | Correo Electrónico | Contraseña | Destino en App Móvil |
| :--- | :--- | :--- | :--- | :--- |
| **Operario** | Yuji Itadori | `itadori@maquitrace.com` | `Operario1234!` | Dashboard Operario (`HomeScreen`) |
| **Operario** | Charly Murillo | `charly@maquitrace.com` | `Operario1234!` | Dashboard Operario (`HomeScreen`) |
| **Transportador** | Carlos Transporte | `transportador@maquitrace.com` | `Transporte1234!` | Módulo de Transporte (`TransportHomeScreen`) |
| **Administrador** | Supervisor General | `admin@maquitrace.com` | `Admin1234!` | Acceso completo / Swagger API |

> **Nota de seguridad:** Todas las contraseñas están almacenadas en la base de datos protegidas con **hashing `bcrypt`** (10 salt rounds).

---

## 2. Máquinas Registradas para Pruebas (Seriales)

| Serial | Modelo | Categoría | Estado Inicial | Fases Asociadas |
| :--- | :--- | :--- | :--- | :--- |
| **`ABC123`** | CAT 320D | Excavadoras | `en_proceso` | Lavado (completada), Ensamblaje (en proceso), Pintura (pendiente) |
| **`DEF789`** | CAT 950M | Cargadores frontales | `pendiente` | Pendiente de inicio |
| **`GHI456`** | CAT 420F2 | Retroexcavadoras | `completada` | Lista para despacho |

---

## 3. Acceso a Documentación Interactiva (Swagger UI)

Para probar los endpoints y autenticación con Bearer Token:
* **URL:** [http://localhost:3000/api/docs](http://localhost:3000/api/docs)
* **Paso 1:** Ejecutar `POST /api/v1/auth/login` con cualquiera de las credenciales de arriba.
* **Paso 2:** Copiar el `accessToken` devuelto.
* **Paso 3:** Pulsar el botón verde **Authorize** en la parte superior derecha de Swagger y pegar el token.
