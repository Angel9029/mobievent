# Guía de Prueba: HU-E2 y HU-C4

## HU-E2: Logística - Asignar Rutas y Vehículos (Admin)

### Descripción
Los administradores pueden asignar vehículos de flota a reservas de clientes para gestionar la logística de entrega.

### Características Implementadas
- ✅ **Vehicle Model** (`lib/models/vehicle.dart`):
  - Fields: `id`, `plate`, `model`, `driver`, `status`, `capacity`, `createdAt`
  - Serialización Firestore completa (fromJson, toJson)

- ✅ **InventoryService Extensions** (`lib/services/inventory_service.dart`):
  - `vehicles` getter → lista de vehículos en tiempo real
  - `_listenVehicles()` → suscripción a cambios en `/vehicles` collection
  - `findVehicleById(id)` → buscar vehículo por ID
  - `seedDefaultVehicles()` → crear 3 vehículos de ejemplo al iniciar
  - `assignVehicleToReservation(reservationId, vehicleId)` → escribir en Firestore

- ✅ **Seed Data**: 3 vehículos de ejemplo
  - Ford Transit (ABC-1234) - Capacidad 100 - Chofer: Juan Pérez
  - Hino 300 (XYZ-5678) - Capacidad 200 - Chofer: Carlos López
  - Renault Master (DEF-9101) - Capacidad 80 - Chofer: Miguel Rodríguez

- ✅ **Admin UI** (`lib/pages/admin_reservations_page.dart`):
  - Cada reserva muestra campo "Vehículo: [Placa] ([Modelo])" o "Sin vehículo asignado"
  - Botón "Asignar vehículo" en PopupMenu de cada reserva
  - BottomSheet modal con lista de vehículos disponibles (status='available')
  - Al seleccionar vehículo → se guarda en Firestore y se actualiza la UI
  - Confirmación con SnackBar: "Vehículo ABC-1234 asignado"

### Flujo de Prueba (Admin)
1. Login como administrador
2. Navegar a **Reservas (Admin)** en bottom navigation
3. Ver lista de reservas con campo "Sin vehículo asignado"
4. Tap en **PopupMenu** (⋮) de una reserva
5. Seleccionar **"Asignar vehículo"**
6. En BottomSheet, ver lista de vehículos disponibles
7. Tap en un vehículo (ej: "ABC-1234 • Ford Transit • Capacidad: 100 • Chofer: Juan Pérez")
8. ✅ Confirmación: SnackBar "Vehículo ABC-1234 asignado"
9. ✅ La reserva ahora muestra "Vehículo: ABC-1234 (Furgón Ford Transit)"
10. ✅ En Firestore (`/reservations/{id}`): campo `assignedVehicleId` = "ABC-1234" guardado

---

## HU-C4: Reprogramar Entrega con Antelación (Cliente)

### Descripción
Los clientes pueden cambiar la fecha de entrega de sus reservas activas con anticipación (plazo mínimo 7 días antes).

### Características Implementadas
- ✅ **Reservation Model Updates** (`lib/models/reservation.dart`):
  - Nuevo campo: `lastRescheduleDate?` para rastrear cambios
  - Métodos de serialización actualizados (fromJson, toJson)

- ✅ **InventoryService Method** (`lib/services/inventory_service.dart`):
  - `rescheduleReservation(reservationId, newEnd)` → actualiza fecha de fin en Firestore

- ✅ **Client UI** (`lib/pages/reservation_history_page.dart`):
  - **Reservas Activas**: muestra dos botones en cada card
    - "Reprogramar" (azul) - solo si faltan ≥ 7 días para entrega
    - "Cancelar" (rojo) - siempre disponible
  - **Lógica de Validación**:
    - Calcula días hasta final de reserva: `res.end.difference(now).inDays`
    - Solo muestra "Reprogramar" si `daysUntilEnd >= 7`
    - Rango de fechas permitido: `minDate = hoy + 7 días`, `maxDate = fechaActual + 30 días`

- ✅ **Reschedule Modal**:
  - Título: "Reprogramar Entrega"
  - Muestra fecha actual: "Fecha actual: 2024-12-25"
  - Selector de fecha: "Nueva fecha: [SelectButton]"
  - DatePicker con restricciones de rango
  - Nota informativa: "Debe ser al menos 7 días antes de la entrega"
  - Botones: "Cancelar" | "Confirmar"

### Flujo de Prueba (Cliente)

#### Caso 1: Reserva con > 7 días para entrega
1. Login como cliente
2. Navegar a **Historial de Reservas** (tab Perfil o botón en Carrito)
3. Ver tab **"Activas"** seleccionado
4. Verificar que las reservas con > 7 días muestren botón **"Reprogramar"** (azul)
5. Tap en **"Reprogramar"**
6. Modal abierto: ve fecha actual y selector
7. Tap en **"Seleccionar fecha"**
8. DatePicker permite fechas desde [hoy+7d] hasta [fechaEntrega+30d]
9. Selecciona nueva fecha (ej: 7 días después de ahora)
10. ✅ Modal muestra "Nueva fecha: 2024-12-31"
11. Tap **"Confirmar"**
12. ✅ SnackBar: "Entrega reprogramada para 2024-12-31"
13. ✅ En Firestore (`/reservations/{id}`): campo `end` actualizado

#### Caso 2: Reserva con < 7 días para entrega
1. Ver reserva con < 7 días hasta fin
2. ✅ NO muestra botón "Reprogramar", solo "Cancelar"
3. Nota en card: "Reprogramación no disponible (< 7 días)"

#### Caso 3: Reservas Pasadas
1. Ver tab **"Pasadas"**
2. ✅ Reservas con end date en pasado no muestran "Reprogramar"
3. Solo información de lectura

---

## Datos en Firestore

### Colección `/vehicles`
```
{
  "id": "auto-generated",
  "plate": "ABC-1234",
  "model": "Furgón Ford Transit",
  "driver": "Juan Pérez",
  "status": "available" | "in_transit" | "maintenance",
  "capacity": 100,
  "createdAt": Timestamp
}
```

### Actualización en `/reservations/{id}`
```
{
  "assignedVehicleId": "vehicle-id-xxx",  // NEW (HU-E2)
  "lastRescheduleDate": Timestamp,          // NEW (HU-C4) - opcional
  "end": Timestamp                          // MODIFIED (HU-C4) - nueva fecha
}
```

---

## Casos de Prueba Adicionales

### Validación de Plazo (HU-C4)
- ✅ No permite seleccionar fecha < 7 días desde ahora
- ✅ DatePicker restringe a `minDate` automáticamente
- ✅ Botón "Confirmar" deshabilitado si no se selecciona fecha

### Múltiples Asignaciones (HU-E2)
- ✅ Reasignar vehículo a misma reserva (button tap → seleccionar otro)
- ✅ Verificar que solo vehículos con `status='available'` aparecen

### Sincronización en Tiempo Real
- ✅ Si admin asigna vehículo mientras cliente ve historial → debe reflejarse (Provider listener)
- ✅ Si cliente reprograma mientras admin ve reservas → debe actualizarse (Provider listener)

---

## Notas de Desarrollo

1. **Seed Data**: Se ejecuta automáticamente en `main.dart` al iniciar la app
   - Crea vehículos solo si no existen (`vehicles` collection vacía)
   
2. **Estado de Vehículos**: Actualmente todos comienzan en `status='available'`
   - Admin puede cambiar status en futuro (no implementado aún)

3. **Transporte Costo**: No se recalcula al reprogramar (mismo costo antes/después)

4. **Cancelación**: Cliente aún puede cancelar reserva aunque tenga vehículo asignado

---

## URLs Relevantes
- AdminReservationsPage: `/lib/pages/admin_reservations_page.dart` (línea ~15-75)
- ReservationHistoryPage: `/lib/pages/reservation_history_page.dart` (línea ~100-160)
- Vehicle Model: `/lib/models/vehicle.dart`
- InventoryService: `/lib/services/inventory_service.dart` (línea ~320-365)
