# Documentación simple del esquema SQL de inventario

> Esta guía explica **en palabras sencillas** qué hace cada parte del archivo `esquema_inventario_mysql.sql`.

## 1) ¿Qué crea este script?

Este script construye una base de datos para un sistema de inventario con:

- sucursales,
- usuarios y roles,
- catálogo de productos,
- existencias por sucursal,
- ventas y detalle de ventas,
- un procedimiento almacenado para vender y descontar inventario de forma segura.

---

## 2) Bloque inicial: base de datos y limpieza

### `CREATE DATABASE ...`
Crea la base de datos `inventario_db` si no existe.

- `CHARACTER SET utf8mb4`: permite guardar texto moderno (acentos, emojis, etc.).
- `COLLATE utf8mb4_0900_ai_ci`: define reglas de comparación (por ejemplo, mayúsculas/minúsculas y acentos).

### `USE inventario_db;`
Le dice a MySQL: “todo lo siguiente va en esta base”.

### Limpieza opcional

- `SET FOREIGN_KEY_CHECKS = 0;`
- `DROP TABLE IF EXISTS ...`
- `SET FOREIGN_KEY_CHECKS = 1;`

Sirve para **re-ejecutar** el script sin errores por tablas ya existentes.

---

## 3) Tablas y para qué sirve cada una

## `roles`
Guarda tipos de rol del sistema (ejemplo: ADMIN, CAJERO).

Campos clave:
- `id_rol`: identificador único.
- `nombre`: nombre del rol, no se puede repetir (`UNIQUE`).
- `activo`: 1 activo / 0 inactivo.
- `creado_en`, `actualizado_en`: fechas automáticas.

## `sucursales`
Guarda las tiendas/sedes físicas.

Campos clave:
- `id_sucursal`: identificador único.
- `codigo`: código único de sucursal.
- `activa`: estado de la sucursal.

## `usuarios`
Guarda personas que usan el sistema.

Campos clave:
- `id_sucursal`: indica en qué sucursal trabaja.
- `email`: único.
- `password_hash`: contraseña **hasheada** (no texto plano).
- `fk_usuarios_sucursal`: llave foránea hacia `sucursales`.

## `usuario_roles`
Tabla puente para relación **muchos a muchos** entre usuarios y roles.

¿Por qué existe?
- Un usuario puede tener varios roles.
- Un rol puede estar en varios usuarios.

Campos clave:
- `PRIMARY KEY (id_usuario, id_rol)`: evita duplicar la misma asignación.
- `ON DELETE CASCADE` en usuario: si borras usuario, se borran sus asignaciones.
- `ON DELETE RESTRICT` en rol: impide borrar un rol en uso.

## `categorias`
Clasificación de productos (ejemplo: bebidas, limpieza).

Campos clave:
- `nombre`: único.
- `activa`: categoría disponible o no.

## `productos`
Catálogo maestro de artículos vendibles.

Campos clave:
- `id_categoria`: categoría opcional (`NULL` permitido).
- `sku`: identificador único interno.
- `codigo_barras`: único si se usa.
- `costo` y `precio_venta`: valores monetarios.
- `fk_productos_categoria`: relación con `categorias`.

## `inventario`
Existencia de cada producto por sucursal.

Campos clave:
- `id_sucursal` + `id_producto`: combinación única (`UNIQUE`) para que no haya dos filas del mismo producto en la misma sucursal.
- `stock_actual`, `stock_minimo`, `stock_maximo`.
- `fk_inventario_sucursal`: si se elimina sucursal, se elimina su inventario (`CASCADE`).
- `fk_inventario_producto`: no permite borrar producto si tiene inventario (`RESTRICT`).

## `ventas`
Encabezado de una venta (ticket/factura principal).

Campos clave:
- `folio`: número único de venta.
- `fecha_venta`.
- `subtotal`, `impuesto`, `descuento`, `total`.
- `metodo_pago`: lista cerrada con `ENUM`.
- `estado`: `PAGADA` o `CANCELADA`.

## `detalle_venta`
Líneas o partidas de una venta.

Campos clave:
- `id_venta`: a qué venta pertenece.
- `id_producto`: qué producto se vendió.
- `cantidad`, `precio_unitario`, `descuento_linea`, `impuesto_linea`, `total_linea`.
- Si se elimina una venta, su detalle se elimina (`ON DELETE CASCADE`).

---

## 4) ¿Qué hacen los índices (`CREATE INDEX`)?

Los índices aceleran búsquedas y joins. Aquí se crean en campos comunes de consulta:

- sucursal del usuario,
- categoría del producto,
- producto en inventario,
- fecha y sucursal de ventas,
- venta/producto del detalle.

En lenguaje simple: ayudan a que la base responda más rápido en reportes y pantallas comunes.

---

## 5) Datos de ejemplo

El script inserta datos mínimos para arrancar:

- roles: ADMIN, CAJERO, ALMACEN,
- una sucursal,
- un usuario admin,
- asignación del rol ADMIN a ese usuario.

> Importante: `CAMBIAR_POR_HASH_SEGURO` es solo placeholder. Debe reemplazarse por un hash real.

---

## 6) Procedimiento almacenado `sp_registrar_detalle_venta`

Este procedimiento sirve para **agregar una línea de venta y descontar inventario** de forma segura.

### Parámetros de entrada
- id de venta,
- id de producto,
- cantidad,
- precio unitario,
- descuento e impuesto de la línea.

### Validaciones que realiza
1. La cantidad debe ser mayor que cero.
2. La venta debe existir.
3. La venta debe estar en estado `PAGADA`.
4. Debe existir inventario para ese producto en esa sucursal.
5. Debe haber stock suficiente.

### Flujo interno (simplificado)
1. Inicia transacción.
2. Bloquea filas relevantes con `FOR UPDATE` para evitar choques en concurrencia.
3. Inserta la fila en `detalle_venta`.
4. Resta stock en `inventario`.
5. Actualiza acumulados de `ventas` (subtotal, descuento, impuesto, total).
6. Hace `COMMIT`.

Si ocurre un error SQL, ejecuta `ROLLBACK` y relanza el error.

---

## 7) Conceptos SQL básicos usados (mini glosario)

- **PK (Primary Key):** identificador único de la fila.
- **FK (Foreign Key):** relación entre tablas para mantener integridad.
- **UNIQUE:** evita valores repetidos.
- **NOT NULL:** obliga a tener valor.
- **DEFAULT:** valor automático si no se envía uno.
- **CASCADE:** propaga ciertos cambios/borrados.
- **RESTRICT:** bloquea borrado/cambio si rompe relaciones.
- **INDEX:** mejora velocidad de consulta.
- **TRANSACTION:** grupo de cambios que se aplican todos o ninguno.

---

## 8) Relación general del modelo (resumen mental)

- `sucursales` 1—N `usuarios`
- `usuarios` N—M `roles` (vía `usuario_roles`)
- `categorias` 1—N `productos`
- `sucursales` 1—N `inventario`
- `productos` 1—N `inventario`
- `ventas` 1—N `detalle_venta`
- `productos` 1—N `detalle_venta`

---

## 9) Buenas prácticas rápidas para alguien que empieza

1. Nunca guardes contraseñas en texto plano.
2. Usa transacciones cuando actualizas varias tablas relacionadas.
3. Valida stock antes de vender.
4. No borres catálogos “a lo loco” si están relacionados.
5. Empieza probando en ambiente de desarrollo antes de producción.

---

## 10) Ejecución recomendada

1. Abre MySQL Workbench.
2. Carga `esquema_inventario_mysql.sql`.
3. Ejecuta todo el script.
4. Verifica tablas creadas.
5. Prueba ventas usando primero inserción en `ventas` y luego llamadas al procedimiento almacenado.

Si quieres, en un siguiente paso te puedo preparar una guía aún más básica con ejemplos de consultas tipo:

- “ver stock por sucursal”,
- “top productos vendidos”,
- “ventas por fecha”.
