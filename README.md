# Panel admin · Reto 50 Onix

Panel interno de la campaña **Reto 50 Onix**. Usa el **mismo proyecto
Supabase que la landing** (`../landin_onix`), pero solo a través de las
funciones `admin_*` de `landin_onix/docs/esquema_supabase_admin.sql`. No se
conecta a nada de Onix Drive.

Sirve para:

- **Recibir los reclamos de premio** en cuanto un ganador abre su caja: aviso
  dentro del panel, sonido, notificación del navegador y contador en la
  pestaña.
- **Verificar el código de confirmación** del ticket (`PRM-XXXXX-XXXXX`): dice
  si es real, de quién es, qué premio salió y en qué estado está.
- **Revisar a los invitados del ganador**: número de cada invitado, el código
  que el ganador compartió con él y el dispositivo que quedó anclado a ese
  código, con las coincidencias sospechosas marcadas (misma firma de
  navegador que el ganador, entre invitados o misma IP).
- **Confirmar, entregar o rechazar** cada premio.
- **Probar el recorrido**: activar «Ganador de prueba» en cualquier cuenta
  para que pueda reclamar y abrir una caja sin tener 50 tickets, y
  «Reiniciar prueba» para volver a jugar.

## Cómo correrlo

En VS Code, **F5** con la configuración **«Onix · panel admin en Chrome»**
(puerto 5001, para no chocar con la landing en el 5000).

Por consola:

```bash
flutter pub get
flutter run -d chrome --web-port=5001
flutter test
```

El `.env` ya trae la URL y la clave pública del proyecto de la landing (se
copió de `landin_onix/.env`). Si hay que rehacerlo, copiar `.env.ejemplo`.
Nunca poner ahí la `service_role` key.

## Crear la cuenta de administrador

Las cuentas **no se crean desde el panel** (cualquiera con la clave pública
podría hacerlo). Se crean en Supabase → **SQL Editor** con:

```sql
select public.admin_crear_cuenta('tu_usuario', 'Tu Nombre', 'UnaClaveLarga123');
```

Usuario de 3 a 30 caracteres (minúsculas, números, punto o guion bajo) y
contraseña de al menos 10 caracteres con letras y números. Ejecutarla de
nuevo con el mismo usuario cambia la contraseña y cierra sus sesiones.

La sesión del panel dura 12 horas. Tras 5 intentos fallidos el usuario queda
bloqueado 15 minutos.

## Probar las cajas con tu propia cuenta

1. Crea tu cuenta en la landing (con tu celular real, el SMS llega por
   Twilio).
2. En el panel: **Participantes** → busca tu usuario → abre la ficha →
   activa **Ganador de prueba**.
3. En la landing pulsa **Actualizar** en tu panel (o recarga la página):
   aparece «Modo prueba activado» con el botón **Reclamar premio**. Elige una
   caja.
4. El panel suena y muestra el reclamo. En **Verificar código** escribe el
   código del ticket.
5. Para repetir: abre el reclamo y pulsa **Reiniciar prueba**. Los premios
   cambian de lugar en cada nuevo reclamo.

Los tickets de prueba salen marcados como PRUEBA en la landing, en el panel
y al verificar el código, y no cuentan en las cifras de premios.

## Cómo llegan los avisos

Cuando un ganador abre su caja, la base inserta una notificación y emite un
evento por **Supabase Realtime** en el canal `onix-panel-admin`. El evento no
lleva datos: solo despierta al panel, que pide el detalle con su sesión de
administrador. Además, cada 15 segundos (`SEGUNDOS_SONDEO` en el `.env`) el
panel consulta por si Realtime no estuviera disponible.

Para recibir notificaciones con el panel en segundo plano, pulsa **Activar
avisos** en la barra superior y acepta el permiso del navegador.

## Estructura

```
lib/
  main.dart                          Arranque: .env y Supabase
  src/
    app.dart                         ProveedorAdmin y rutas de ingreso/panel
    nucleo/
      entorno.dart                   Lectura del .env
      tema_admin.dart                Paleta Onix y tema
    datos/
      modelos_admin.dart             Reclamo, ficha, invitaciones, dispositivo...
      repositorio_admin.dart         Contrato del panel
      repositorio_admin_supabase.dart  Llamadas a las funciones admin_*
      controlador_admin.dart         Sesión, avisos, sondeo y Realtime
    utiles/
      formato.dart                   Fechas, teléfonos y códigos
      aviso_navegador*.dart          Notificación, sonido y título de pestaña
    ui/
      pantalla_ingreso.dart
      pantalla_principal.dart        Menú, campana y vistas
      vistas/                        Reclamos, verificar, participantes,
                                     detalle de reclamo y ficha
      componentes/                   Tarjetas, carga, tabla de invitados
test/
  panel_admin_test.dart              Recorridos con un repositorio falso
  modelos_desde_json_test.dart       Lectura de respuestas reales de la base
```
