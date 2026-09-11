# WMA Tank Monitoring System — Architecture Freeze v1

**Date:** 11 September 2026  
**Status:** DRAFT — To Be Frozen  
**Project Type:** Internal Company Monitoring System

---

## 1. Project Goal

WMA Tank Monitoring System is an internal web-based application used to
monitor fluid levels and calculated fluid volumes inside tanks.

The physical sensor measures fluid level/distance only.

Raw sensor measurements are transmitted by an ESP32 to the server.
The backend is responsible for processing the raw measurement into:

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

The primary objective is reliable monitoring and presentation of tank
conditions to authorized company personnel.

---

## 2. Technology Stack

### Frontend

- Next.js
- React
- TypeScript
- Tailwind CSS
- TanStack Query
- Recharts

The frontend will primarily be generated with AI based on the approved
UI reference and API contract.

The frontend is responsible for presentation and user interaction only.
It must not contain authoritative tank calculation, alarm, or
authorization logic.

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

MQTT is used exclusively for communication between IoT devices and the
backend.

### Infrastructure

- Docker
- Docker Compose
- Nginx

The application must support deployment on an internal/on-premise
company server.

Internet access must not be required for normal local monitoring.

---

## 3. System Architecture

The system uses a modular monolith architecture.

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