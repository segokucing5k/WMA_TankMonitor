-- CreateEnum
CREATE TYPE "TankShapeType" AS ENUM ('VERTICAL_CYLINDER', 'RECTANGULAR', 'HORIZONTAL_CYLINDER', 'CONICAL_BOTTOM', 'CUSTOM_GEOMETRY');

-- CreateEnum
CREATE TYPE "CalculationMethod" AS ENUM ('FORMULA', 'CALIBRATION_TABLE');

-- CreateEnum
CREATE TYPE "SensorType" AS ENUM ('WATER_LEVEL', 'DISTANCE_TO_SURFACE');

-- CreateTable
CREATE TABLE "tanks" (
    "id" UUID NOT NULL,
    "tank_code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "location" TEXT,
    "shape_type" "TankShapeType" NOT NULL,
    "capacity_liter" DECIMAL(12,3) NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "tanks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tank_geometries" (
    "id" UUID NOT NULL,
    "tank_id" UUID NOT NULL,
    "calculation_method" "CalculationMethod" NOT NULL,
    "parameters" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "tank_geometries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sensors" (
    "id" UUID NOT NULL,
    "sensor_code" TEXT NOT NULL,
    "tank_id" UUID NOT NULL,
    "sensor_type" "SensorType" NOT NULL,
    "installation_height_mm" DECIMAL(10,3),
    "calibration_offset_mm" DECIMAL(10,3) NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "sensors_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "tanks_tank_code_key" ON "tanks"("tank_code");

-- CreateIndex
CREATE UNIQUE INDEX "tank_geometries_tank_id_key" ON "tank_geometries"("tank_id");

-- CreateIndex
CREATE UNIQUE INDEX "sensors_sensor_code_key" ON "sensors"("sensor_code");

-- CreateIndex
CREATE UNIQUE INDEX "sensors_tank_id_key" ON "sensors"("tank_id");

-- AddForeignKey
ALTER TABLE "tank_geometries" ADD CONSTRAINT "tank_geometries_tank_id_fkey" FOREIGN KEY ("tank_id") REFERENCES "tanks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sensors" ADD CONSTRAINT "sensors_tank_id_fkey" FOREIGN KEY ("tank_id") REFERENCES "tanks"("id") ON DELETE CASCADE ON UPDATE CASCADE;
