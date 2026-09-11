# WMA Tank Monitoring System — Architecture Freeze v1

**Date:** 11 September 2026  
**Status:** DRAFT — To Be Frozen  
**Project Type:** Internal Company Monitoring System

---

## 1. Project Goal

WMA Tank Monitoring System is an internal web-based application used to monitor fluid levels and calculated fluid volumes inside tanks.

The physical sensor measures fluid level/distance only. Raw sensor measurements are transmitted by an ESP32 to the server. The backend is responsible for processing the raw measurement into:

- Fluid height
- Fluid volume
- Tank level percentage
- Tank operational status
- Alarm condition

The system provides:

- Real-time tank monitoring
- Historical tank data
- Alarm monitoring
- Sensor online/offline monitoring
- Tank and sensor configuration
- User and role management

### Scope

Version 1 is a **monitoring system only**.

The system does NOT perform:

- Pump control
- Valve control
- Automatic filling/draining
- PLC control
- Other actuator control

The primary objective is reliable monitoring and presentation of tank conditions to authorized company personnel.

---

## 2. Technology Stack

### Frontend

- Next.js
- React
- TypeScript
- Tailwind CSS
- TanStack Query
- Recharts

The frontend will primarily be generated with AI based on the approved UI reference and API contract.
The frontend is responsible for presentation and user interaction only. It must not contain authoritative tank calculation, alarm, or authorization logic.

### Backend

- NestJS
- TypeScript
- Prisma ORM
- Argon2id
- JWT Authentication
- WebSocket

NestJS acts as the main application and business-logic layer.

### Database

- PostgreSQL

PostgreSQL stores:
- Users
- Tank configuration
- Sensor configuration
- Historical telemetry
- Current tank state
- Alarm thresholds
- Alarms
- Audit logs

### IoT

- ESP32
- MQTT
- Eclipse Mosquitto

MQTT is used exclusively for communication between IoT devices and the backend.

### Infrastructure

- Docker
- Docker Compose
- Nginx

The application must support deployment on an internal/on-premise company server. Internet access must not be required for normal local monitoring.

---

## 3. System Architecture

The system uses a **modular monolith** architecture.

```text
                    PHYSICAL SYSTEM
                          │
                          ▼
                    LEVEL SENSOR
                          │
                          ▼
                       ESP32
                          │
                          │ MQTT
                          ▼
                 ┌─────────────────┐
                 │    MOSQUITTO    │
                 │   MQTT BROKER   │
                 └────────┬────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │    NESTJS BACKEND     │
              │                       │
              │  MQTT Consumer        │
              │  Telemetry Service    │
              │  Tank Calculation     │
              │  Alarm Engine         │
              │  Authentication       │
              │  RBAC                 │
              │  REST API             │
              │  WebSocket Gateway    │
              └───────┬───────┬───────┘
                      │       │
                      │       │ WebSocket
                      │       │
                      ▼       ▼
               ┌──────────┐  ┌──────────────┐
               │PostgreSQL│  │   Next.js    │
               │ Database │  │   Frontend   │
               └──────────┘  └──────────────┘
```

### Architecture Pattern

The backend uses a **Modular Monolith**.
The application must NOT be implemented as microservices in Version 1.

**Suggested NestJS modules:**
- `auth`
- `users`
- `tanks`
- `sensors`
- `telemetry`
- `alarms`
- `history`
- `websocket`
- `audit`
- `database`
- `config`

Each module should have clearly separated responsibilities. Business logic should primarily exist inside services rather than controllers.

---

## 4. Responsibility Boundaries

### ESP32 Responsibilities
ESP32 is responsible for:
- Reading the physical sensor
- Performing basic hardware-level validation
- Maintaining MQTT connection
- Publishing telemetry
- Reconnecting when network/MQTT connection is lost

ESP32 should primarily transmit raw measurements. ESP32 is NOT the authoritative source for:
- Final fluid height
- Tank volume
- Tank percentage
- Tank status
- Alarm state

### MQTT Broker Responsibilities
Mosquitto is responsible for:
- Receiving MQTT messages from ESP32 devices
- Authenticating MQTT clients
- Applying topic access control
- Delivering telemetry to subscribed backend services

Mosquitto does NOT perform business calculations.

### Backend Responsibilities
NestJS is the authoritative application/business-logic layer. It is responsible for:
- Authentication & Authorization (RBAC)
- User, Tank, and Sensor management
- MQTT telemetry consumption & validation
- Sensor calibration
- Fluid height, Volume, and Level percentage calculation
- Tank status determination & Alarm evaluation
- Alarm lifecycle
- Sensor offline detection
- Historical data storage & Current state management
- REST API & WebSocket events
- Audit logging

### PostgreSQL Responsibilities
PostgreSQL is the persistent source of application data. It stores both:
- Historical telemetry
- Current application state

Historical telemetry and current tank state must be logically separated to avoid expensive history queries for dashboard requests.

### Frontend Responsibilities
The Next.js frontend is responsible for:
- Rendering UI and User interaction
- REST API requests & WebSocket subscriptions
- Charts & Forms
- Client-side form validation
- Loading and Error states

The frontend must NOT be authoritative for:
- Tank volume calculation
- Alarm decisions
- Sensor validation
- Role authorization

*Frontend RBAC is only for UX. Backend authorization is mandatory.*

---

## 5. Telemetry Data Flow

The normal telemetry flow is:

```text
 Level Sensor
      │
      ▼
 ESP32 reads raw measurement
      │
      ▼
 ESP32 publishes MQTT telemetry
      │
      ▼
 Mosquitto
      │
      ▼
 NestJS MQTT Consumer
      │
      ▼
 Validate MQTT payload
      │
      ▼
 Identify device / sensor / tank
      │
      ▼
 Validate raw sensor measurement
      │
      ▼
 Apply sensor calibration
      │
      ▼
 Calculate fluid height
      │
      ▼
 Calculate tank volume
      │
      ▼
 Calculate tank level percentage
      │
      ▼
 Determine tank status
      │
      ▼
 Evaluate alarm thresholds
      │
      ├───────────────┐
      ▼               ▼
 Store History    Update Alarm State
      │
      ▼
 Update Current Tank State
      │
      ▼
 Emit WebSocket Event
      │
      ▼
 Frontend updates UI
```

---

## 6. Raw Data Principle

Raw sensor measurement must be preserved. The ESP32 should NOT send only calculated volume.

**Bad:**
```json
{
  "volume_liter": 7842,
  "percentage": 78.4
}
```

**Preferred:**
```json
{
  "device_id": "DEV-001",
  "sensor_id": "SNS-001",
  "tank_id": "TANK-001",
  "raw_level_mm": 652,
  "timestamp": "2026-09-11T13:20:00+07:00"
}
```

The backend then performs:
```text
raw sensor measurement
        ↓
   calibration
        ↓
  fluid height
        ↓
     volume
        ↓
   percentage
        ↓
     status
```

This ensures that changes in tank geometry or calibration do not require firmware changes. Raw data can also be used for troubleshooting, calibration, validation, future recalculation, and sensor diagnostics.

---

## 7. Source of Truth

The following responsibility model must be maintained:

- **Physical Sensor:** Physical measurement source
- **ESP32:** Telemetry acquisition and transport
- **NestJS Backend:** Business logic source of truth
- **PostgreSQL:** Persistent application state
- **Next.js Frontend:** Presentation layer

*Business-critical calculations must not exist exclusively on the frontend or ESP32.*

---

## 8. Communication Strategy

Three communication mechanisms are used for different purposes.

1. **ESP32 → Backend (MQTT)**
   Used for telemetry.
2. **Frontend → Backend (REST API)**
   Used for Login, User management, Configuration, Historical queries, Alarm acknowledgement, and Standard CRUD operations.
3. **Backend → Frontend (WebSocket)**
   Used for Realtime tank updates, New alarms, Alarm status changes, and Sensor online/offline changes.

**Flow:**
```text
  ESP32
    │
    │ MQTT
    ▼
 Backend
    ▲ │
    │ │ WebSocket
REST│ │
    │ ▼
 Frontend
```
REST remains the source for initial page loading. WebSocket provides subsequent realtime changes.

---

## 9. Current Architecture Decisions

The following decisions are considered accepted for Version 1:
- Modular monolith backend (NestJS)
- Next.js frontend
- PostgreSQL database with Prisma ORM
- ESP32 as IoT device
- MQTT for IoT telemetry (Eclipse Mosquitto as MQTT broker)
- REST for standard frontend/backend communication
- WebSocket for realtime frontend updates
- Backend performs tank calculations and alarm evaluation
- Raw sensor measurements are retained
- Dashboard uses dedicated current-state data
- Historical readings are stored separately
- Docker Compose is used for deployment (Nginx as reverse proxy)
- Version 1 is monitoring-only

---

## 10. Tank–Sensor Relationship

For Version 1, each tank uses exactly one primary level sensor during normal operation. The database relationship is modeled as:
`Tank 1 ───── 0..1 Sensor`

A tank may temporarily have no sensor assigned during initial configuration, installation, replacement, or maintenance. A sensor can only be assigned to one tank at a time. The `sensors.tank_id` field must therefore have a `UNIQUE` constraint.

Sensor information remains separated from the Tank entity because a sensor has its own lifecycle and configuration (Sensor code, type, installation height, calibration offset, online/offline state, timestamps, and last raw measurement). Replacing a sensor must not require replacing or recreating the Tank record.

---

## 11. Tank Geometry Strategy

The system must support more than five tank geometry variations. Tank geometry must therefore not be represented using rigid geometry columns directly inside the `tanks` table. Each tank stores `shape_type`, `nominal capacity`, and `general metadata`. Geometry-specific parameters are stored separately.

### Tank Geometry Entity
`tank_geometries`
- `id`
- `tank_id`
- `calculation_method`
- `parameters` (JSONB)
- `created_at`
- `updated_at`

### Calculation Methods
- `FORMULA`
- `CALIBRATION_TABLE`

For `FORMULA`-based calculation, the backend selects a geometry strategy based on `shape_type` (e.g., `VERTICAL_CYLINDER`, `RECTANGULAR`, `HORIZONTAL_CYLINDER`, `CONICAL_BOTTOM`, `CUSTOM_GEOMETRY`).

For tanks that cannot be represented accurately using an ideal geometric formula, the system may use a calibration table mapping `fluid height → volume`. Interpolation is performed by the backend. All tank-volume calculations remain authoritative in the backend.

---

## 12. Telemetry Storage Strategy

Telemetry data is separated into historical readings and current state.

### `tank_readings`
The `tank_readings` table is append-only historical telemetry.
- `id`: BIGINT primary key
- `tank_id`: UUID foreign key
- `sensor_id`: UUID foreign key
- `raw_value_mm`: decimal
- `fluid_height_mm`: decimal
- `volume_liter`: decimal
- `level_percentage`: decimal
- `sensor_timestamp`: timestamptz nullable
- `received_at`: timestamptz

Raw measurements and calculated values are both retained. `received_at` is generated by the backend.

### `tank_current_states`
The `tank_current_states` table stores exactly one current runtime state per tank.
- `tank_id`: UUID primary key and foreign key
- `sensor_id`: UUID foreign key
- `raw_value_mm`: decimal
- `fluid_height_mm`: decimal
- `volume_liter`: decimal
- `level_percentage`: decimal
- `tank_status`
- `sensor_status`
- `last_measurement_at`: timestamptz nullable
- `last_received_at`: timestamptz
- `updated_at`: timestamptz

For every valid telemetry message:
1. Insert a historical record into `tank_readings`.
2. Upsert the latest state into `tank_current_states`.
3. Evaluate alarms.
4. Emit realtime updates when required.

The dashboard reads current values primarily from `tank_current_states`, not by repeatedly querying the latest historical reading.

### Runtime State Ownership
The `sensors` table contains sensor identity and configuration. Runtime information (online/offline state, last received timestamp, last raw measurement) belongs to `tank_current_states`. This avoids maintaining duplicate runtime state in multiple tables.

### Tank and Sensor Status
Tank condition and sensor connectivity are separate concepts.

**Tank status:**
- `CRITICAL_HIGH`
- `HIGH_WARNING`
- `NORMAL`
- `LOW_WARNING`
- `CRITICAL_LOW`

**Sensor status:**
- `ONLINE`
- `OFFLINE`

An offline sensor does not imply an empty tank. When a sensor is offline, the last known tank measurement is retained and must be explicitly presented as a **LAST KNOWN VALUE**.

---

## 13. Alarm Architecture

### Alarm Thresholds
Each tank has at most one alarm threshold configuration.

`alarm_thresholds`:
- `id`: UUID primary key
- `tank_id`: UUID unique foreign key
- `critical_high_pct`: decimal
- `high_warning_pct`: decimal
- `low_warning_pct`: decimal
- `critical_low_pct`: decimal
- `hysteresis_pct`: decimal
- `created_at` / `updated_at`: timestamptz

Threshold configuration must satisfy:
`0 <= critical_low < low_warning < high_warning < critical_high <= 100`

### Hysteresis
Alarm evaluation uses hysteresis to prevent alarm chatter caused by sensor noise near a threshold.

### Alarm Entity
`alarms`:
- `id`: UUID primary key
- `tank_id`: UUID foreign key
- `sensor_id`: UUID nullable foreign key
- `type`, `severity`, `status`
- `trigger_value_pct`: decimal nullable
- `triggered_at`: timestamptz
- `acknowledged_by`: UUID nullable foreign key
- `acknowledged_at`: timestamptz nullable
- `resolved_at`: timestamptz nullable
- `created_at` / `updated_at`: timestamptz

**Types:** `CRITICAL_HIGH`, `HIGH_WARNING`, `LOW_WARNING`, `CRITICAL_LOW`, `SENSOR_OFFLINE`
**Severities:** `WARNING`, `CRITICAL`
**Statuses:** `ACTIVE`, `ACKNOWLEDGED`, `RESOLVED`

Acknowledging an alarm does not resolve the physical alarm condition. An alarm is resolved only when its triggering condition has cleared.

### Alarm Deduplication
Only one unresolved alarm of the same applicable condition may exist for a tank at the same time.

### Sensor Offline Alarm
Sensor connectivity is evaluated using the last telemetry receipt time. When no telemetry has been received for longer than the configured offline timeout:
- `sensor_status` becomes `OFFLINE`
- a `SENSOR_OFFLINE` alarm may be created
- the previous tank measurement remains stored as the last known value (Missing telemetry must never be interpreted as a fluid level of zero).

---

## 14. Audit Logging

The system maintains an audit log for important administrative and configuration changes.

`audit_logs`:
- `id`: BIGINT primary key
- `user_id`: UUID nullable foreign key
- `action`: string
- `resource_type`: string
- `resource_id`: string nullable
- `old_value`: JSONB nullable
- `new_value`: JSONB nullable
- `ip_address`: string nullable
- `created_at`: timestamptz

Audit logs should be created for security-sensitive and configuration-changing operations (User management, Tank/Sensor/Alarm configuration changes, Alarm acknowledgement). Audit logs are primarily an internal backend capability in Version 1.

---

## 15. Database Architecture Freeze

The Version 1 conceptual database consists of:
- `users`, `tanks`, `tank_geometries`, `sensors`, `tank_readings`, `tank_current_states`, `alarm_thresholds`, `alarms`, `audit_logs`

**Status:** FROZEN FOR VERSION 1

---

## 16. MQTT Contract

MQTT is used for telemetry transport from ESP32 devices to the NestJS backend. The MQTT broker is Eclipse Mosquitto.

### Topic Structure
Telemetry topic: `company/{site_id}/tanks/{tank_code}/telemetry`
Example: `company/site01/tanks/TANK-001/telemetry`
The backend subscribes using: `company/+/tanks/+/telemetry`

### Telemetry Payload
Because the final physical sensor type may vary, the payload must describe the measurement explicitly.

```json
{
  "device_id": "DEV-001",
  "sensor_id": "SNS-001",
  "measurement_type": "WATER_LEVEL",
  "value": 1850,
  "unit": "mm",
  "timestamp": "2026-09-11T14:00:00+07:00"
}
```

**Possible measurement types for Version 1:**
- `WATER_LEVEL`: value represents fluid height from the defined zero/reference point.
- `DISTANCE_TO_SURFACE`: value represents the distance between the sensor and fluid surface.

The backend converts the measurement into canonical fluid height before performing volume calculations.

### Payload Responsibility
ESP32 is responsible for identifying the device/sensor, publishing the raw physical measurement with type/unit, and optionally providing a device timestamp.

### Tank Identification
The tank is identified primarily from the MQTT topic. The telemetry payload does not need to duplicate `tank_id` or `tank_code`. The backend extracts `TANK-001` from the topic and verifies that the reported sensor is assigned to that tank.

### Timestamp
`timestamp` represents the time reported by the ESP32 (optional). The backend always generates its own `received_at` timestamp. Backend server time is authoritative for telemetry receipt.

### MQTT QoS & Retained Messages
- **QoS:** Telemetry uses QoS 1 (at-least-once delivery).
- **Retained Messages:** Telemetry messages should NOT use MQTT retain. Current application state is stored in PostgreSQL rather than relying on MQTT retained telemetry.

### Invalid & Missing Telemetry
The MQTT consumer must validate incoming messages. Invalid telemetry must not crash the consumer, overwrite state, or generate false values. It should be logged for diagnostics. Missing telemetry is not interpreted as a fluid level of zero.

### Canonical Units
The backend uses canonical internal units:
- distance / height: millimeter (mm)
- volume: liter (L)
- tank level: percent (%)

### Message Identity and Duplicate Handling
Each telemetry message should include a device-generated message identity (`sequence` or `message_id`).

```json
{
  "message_id": "DEV-001-18421",
  "device_id": "DEV-001",
  "sensor_id": "SNS-001",
  "measurement_type": "WATER_LEVEL",
  "value": 1850,
  "unit": "mm",
  "timestamp": "2026-09-11T14:00:00+07:00"
}
```
The backend must detect duplicate telemetry and avoid duplicate historical readings, alarm evaluation, and realtime events.