-- CreateEnum
CREATE TYPE "TankStatus" AS ENUM ('CRITICAL_HIGH', 'HIGH_WARNING', 'NORMAL', 'LOW_WARNING', 'CRITICAL_LOW');

-- CreateEnum
CREATE TYPE "SensorStatus" AS ENUM ('ONLINE', 'OFFLINE');

-- CreateTable
CREATE TABLE "tank_readings" (
    "id" BIGSERIAL NOT NULL,
    "tank_id" UUID NOT NULL,
    "sensor_id" UUID NOT NULL,
    "raw_value_mm" DECIMAL(12,3) NOT NULL,
    "fluid_height_mm" DECIMAL(12,3) NOT NULL,
    "volume_liter" DECIMAL(14,3) NOT NULL,
    "level_percentage" DECIMAL(6,3) NOT NULL,
    "sensor_timestamp" TIMESTAMPTZ(6),
    "received_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tank_readings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tank_current_states" (
    "tank_id" UUID NOT NULL,
    "sensor_id" UUID NOT NULL,
    "raw_value_mm" DECIMAL(12,3) NOT NULL,
    "fluid_height_mm" DECIMAL(12,3) NOT NULL,
    "volume_liter" DECIMAL(14,3) NOT NULL,
    "level_percentage" DECIMAL(6,3) NOT NULL,
    "tank_status" "TankStatus" NOT NULL,
    "sensor_status" "SensorStatus" NOT NULL,
    "last_measurement_at" TIMESTAMPTZ(6),
    "last_received_at" TIMESTAMPTZ(6) NOT NULL,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "tank_current_states_pkey" PRIMARY KEY ("tank_id")
);

-- CreateIndex
CREATE INDEX "tank_readings_tank_id_received_at_idx" ON "tank_readings"("tank_id", "received_at");

-- CreateIndex
CREATE INDEX "tank_readings_sensor_id_received_at_idx" ON "tank_readings"("sensor_id", "received_at");

-- CreateIndex
CREATE INDEX "tank_current_states_sensor_status_idx" ON "tank_current_states"("sensor_status");

-- AddForeignKey
ALTER TABLE "tank_readings" ADD CONSTRAINT "tank_readings_tank_id_fkey" FOREIGN KEY ("tank_id") REFERENCES "tanks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tank_readings" ADD CONSTRAINT "tank_readings_sensor_id_fkey" FOREIGN KEY ("sensor_id") REFERENCES "sensors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tank_current_states" ADD CONSTRAINT "tank_current_states_tank_id_fkey" FOREIGN KEY ("tank_id") REFERENCES "tanks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tank_current_states" ADD CONSTRAINT "tank_current_states_sensor_id_fkey" FOREIGN KEY ("sensor_id") REFERENCES "sensors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
