-- CreateEnum
CREATE TYPE "AlarmType" AS ENUM ('CRITICAL_HIGH', 'HIGH_WARNING', 'LOW_WARNING', 'CRITICAL_LOW', 'SENSOR_OFFLINE');

-- CreateEnum
CREATE TYPE "AlarmSeverity" AS ENUM ('WARNING', 'CRITICAL');

-- CreateEnum
CREATE TYPE "AlarmStatus" AS ENUM ('ACTIVE', 'ACKNOWLEDGED', 'RESOLVED');

-- CreateTable
CREATE TABLE "alarm_thresholds" (
    "id" UUID NOT NULL,
    "tank_id" UUID NOT NULL,
    "critical_high_pct" DECIMAL(6,3) NOT NULL,
    "high_warning_pct" DECIMAL(6,3) NOT NULL,
    "low_warning_pct" DECIMAL(6,3) NOT NULL,
    "critical_low_pct" DECIMAL(6,3) NOT NULL,
    "hysteresis_pct" DECIMAL(6,3) NOT NULL DEFAULT 2,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "alarm_thresholds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alarms" (
    "id" UUID NOT NULL,
    "tank_id" UUID NOT NULL,
    "sensor_id" UUID,
    "type" "AlarmType" NOT NULL,
    "severity" "AlarmSeverity" NOT NULL,
    "status" "AlarmStatus" NOT NULL DEFAULT 'ACTIVE',
    "trigger_value_pct" DECIMAL(6,3),
    "triggered_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "acknowledged_by" UUID,
    "acknowledged_at" TIMESTAMPTZ(6),
    "resolved_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "alarms_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" BIGSERIAL NOT NULL,
    "user_id" UUID,
    "action" TEXT NOT NULL,
    "resource_type" TEXT NOT NULL,
    "resource_id" TEXT,
    "old_value" JSONB,
    "new_value" JSONB,
    "ip_address" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "alarm_thresholds_tank_id_key" ON "alarm_thresholds"("tank_id");

-- CreateIndex
CREATE INDEX "alarms_tank_id_status_idx" ON "alarms"("tank_id", "status");

-- CreateIndex
CREATE INDEX "alarms_status_severity_idx" ON "alarms"("status", "severity");

-- CreateIndex
CREATE INDEX "alarms_triggered_at_idx" ON "alarms"("triggered_at");

-- CreateIndex
CREATE INDEX "audit_logs_user_id_created_at_idx" ON "audit_logs"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_resource_type_resource_id_idx" ON "audit_logs"("resource_type", "resource_id");

-- AddForeignKey
ALTER TABLE "alarm_thresholds" ADD CONSTRAINT "alarm_thresholds_tank_id_fkey" FOREIGN KEY ("tank_id") REFERENCES "tanks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alarms" ADD CONSTRAINT "alarms_tank_id_fkey" FOREIGN KEY ("tank_id") REFERENCES "tanks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alarms" ADD CONSTRAINT "alarms_sensor_id_fkey" FOREIGN KEY ("sensor_id") REFERENCES "sensors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alarms" ADD CONSTRAINT "alarms_acknowledged_by_fkey" FOREIGN KEY ("acknowledged_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
