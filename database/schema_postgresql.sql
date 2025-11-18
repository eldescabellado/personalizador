-- LicenseGuard Database Schema para PostgreSQL

-- Tabla de aplicaciones
CREATE TABLE IF NOT EXISTS applications (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    current_version VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de distribuidores
CREATE TABLE IF NOT EXISTS distributors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    serial_number VARCHAR(100) NOT NULL UNIQUE,
    contact_info TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de licencias generadas
CREATE TABLE IF NOT EXISTS licenses (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    application_name VARCHAR(255) NOT NULL,
    application_version VARCHAR(50) NOT NULL,
    license_type VARCHAR(20) NOT NULL, -- 'Full', 'Demo', 'Trial'
    distributor_serial VARCHAR(100),
    expiration_date TIMESTAMP,
    hardware_binding_type VARCHAR(20), -- 'None', 'MAC', 'CPU', 'Disk', 'Combined'
    hardware_id VARCHAR(255),
    demo_expires_date TIMESTAMP,
    control_file_hash VARCHAR(64),
    zip_file_path TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (distributor_serial) REFERENCES distributors(serial_number)
);

-- Tabla de log de actividades
CREATE TABLE IF NOT EXISTS activity_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    log_level VARCHAR(20) NOT NULL, -- 'INFO', 'WARNING', 'ERROR', 'DEBUG'
    category VARCHAR(50) NOT NULL, -- 'LICENSE', 'APPLICATION', 'DISTRIBUTOR', 'VALIDATION', 'SYSTEM'
    message TEXT NOT NULL,
    details JSONB, -- JSON con información adicional
    user_action TEXT, -- Descripción de la acción del usuario
    error_code VARCHAR(50),
    stack_trace TEXT
);

-- Índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_licenses_company ON licenses(company_name);
CREATE INDEX IF NOT EXISTS idx_licenses_app ON licenses(application_name);
CREATE INDEX IF NOT EXISTS idx_licenses_created ON licenses(created_at);
CREATE INDEX IF NOT EXISTS idx_activity_log_timestamp ON activity_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_activity_log_level ON activity_log(log_level);
CREATE INDEX IF NOT EXISTS idx_activity_log_category ON activity_log(category);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_distributors_updated_at BEFORE UPDATE ON distributors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
