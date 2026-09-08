# SMS Gateway (servidor privado)

Servidor privado de [SMSGate](https://docs.sms-gate.app/) desplegado en EasyPanel. Un teléfono Android con la app oficial envía los SMS; el panel web y la API mandan los mensajes a ese dispositivo.

Repo: https://github.com/sistemasclinicamaicao/sms-gateway

## URLs en producción

| Uso | URL |
|---|---|
| API (salud) | https://chat-sms-gateway.rhfh8t.easypanel.host/api/3rdparty/v1/health |
| API 3rd party | https://chat-sms-gateway.rhfh8t.easypanel.host/api/3rdparty/v1 |
| API móvil (solo la app) | https://chat-sms-gateway.rhfh8t.easypanel.host/api/mobile/v1 |
| Panel web (login) | https://chat-sms-dashboard.rhfh8t.easypanel.host/ |

`/api/mobile/v1` en el navegador responde `Unauthorized`. Eso es normal: no es una página de login.

## EasyPanel

Proyecto `chat`, servicio Compose `sms-gateway`.

### Dominios

| Host | Servicio Compose | Puerto |
|---|---|---|
| `chat-sms-gateway.rhfh8t.easypanel.host` | `backend` | `8080` |
| `chat-sms-dashboard.rhfh8t.easypanel.host` | `dashboard` | `8081` |

HTTPS encendido, destino HTTP, ruta `/`. No cambies el dominio de la API para apuntarlo al dashboard.

### Variables de entorno

Copiar desde [`.env.example`](.env.example) al Environment del servicio Compose. No subir `.env` ni claves reales a Git.

Si `GATEWAY_PRIVATE_TOKEN` tiene `#`, `$` o comillas, déjalo entre comillas simples.

### Puertos internos

| Contenedor | Escucha | Variable |
|---|---|---|
| `backend` | `0.0.0.0:8080` | `HTTP__LISTEN` |
| `dashboard` | `0.0.0.0:8081` | `HTTP__LISTEN` y `HTTP__ADDRESS` |
| `mariadb` | `3306` | — |

El dashboard oficial usa `HTTP__LISTEN`. Sin eso queda en `127.0.0.1:3000` y EasyPanel muestra *Service is not reachable*.

MariaDB no reaplica `MYSQL_PASSWORD` si el volumen ya existe. Si hay error `1045 Access denied`, hay que recrear el volumen (`mariadb-data-v3`) o el servicio `mariadb` y volver a desplegar. En logs debe verse `Initializing database files`, no solo `upgrade not required`.

## App Android

1. Instalar el APK oficial (no está en Play Store):
   - Releases: https://github.com/capcom6/android-sms-gateway/releases
   - Copia local (no va a Git): `apk/SMSGate-v1.75.0.apk`
2. Aceptar permisos: enviar SMS, estado del teléfono, recibir SMS.
3. **Settings → Cloud Server**:
   - API URL: `https://chat-sms-gateway.rhfh8t.easypanel.host/api/mobile/v1`
   - Private Token: el mismo `GATEWAY_PRIVATE_TOKEN` de EasyPanel, **sin comillas**.
4. **Home**: activar Cloud server y tocar Offline hasta que quede **Online**.
5. En Cloud Server aparecen **Username** y **Password** (los genera la app). Con esos datos se entra al panel web.

El teléfono debe quedar encendido, con chip, señal, internet y la app en Online. Si se cambia el token o el servidor, hay que registrar de nuevo.

## Panel web

1. Abrir https://chat-sms-dashboard.rhfh8t.easypanel.host/login
2. Login y contraseña = Username y Password de la app (no el token ni las claves de MariaDB).
3. Enviar SMS con número en formato internacional, por ejemplo `+573001234567`.

### Estados del mensaje

| Estado | Significado |
|---|---|
| Pending | En cola en el servidor |
| Processed | El teléfono ya recibió el trabajo |
| Sent | El chip envió el SMS |
| Delivered | El operador confirmó entrega (si lo reporta) |
| Failed | Falló (primeros intentos o el teléfono Offline) |

En la lista el texto puede verse como hash: el servidor oculta el contenido después de un tiempo. En **View** a veces aún se ve el mensaje.

## Prueba de salud

Desde la raíz del repo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-deploy.ps1
```

Debe devolver HTTP 200 en `/health` y en `/api/3rdparty/v1/health` (incluye `db:ping`).

## Contenido del repo

| Ruta | Rol |
|---|---|
| `docker-compose.yml` | Stack para EasyPanel (imágenes oficiales) |
| `.env.example` | Plantilla de variables (sin secretos) |
| `server/` | Código del backend Go |
| `web-dashboard/` | Panel web |
| `client-php/` | Cliente PHP |
| `android/` | Código de la app (no se despliega en el VPS) |
| `apk/` | APK descargado en local (ignorado por Git) |
| `test-deploy.ps1` | Smoke test contra el host de EasyPanel |

Documentación oficial: https://docs.sms-gate.app/getting-started/private-server/
