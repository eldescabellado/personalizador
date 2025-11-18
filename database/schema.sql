-- LicenseGuard Database Schema
-- Compatible con SQLite y PostgreSQL

-- Tabla de aplicaciones
CREATE TABLE IF NOT EXISTS applications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    current_version TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Tabla de distribuidores
CREATE TABLE IF NOT EXISTS distributors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    serial_number TEXT NOT NULL UNIQUE,
    contact_info TEXT,
    active INTEGER NOT NULL DEFAULT 1, -- 0 = false, 1 = true
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Tabla de licencias generadas
CREATE TABLE IF NOT EXISTS licenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    company_name TEXT NOT NULL,
    contact_name TEXT,
    contact_email TEXT,
    application_name TEXT NOT NULL,
    application_version TEXT NOT NULL,
    license_type TEXT NOT NULL, -- 'Full', 'Demo', 'Trial'
    distributor_serial TEXT,
    expiration_date TEXT,
    hardware_binding_type TEXT, -- 'None', 'MAC', 'CPU', 'Disk', 'Combined'
    hardware_id TEXT,
    demo_expires_date TEXT,
    control_file_hash TEXT,
    zip_file_path TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (distributor_serial) REFERENCES distributors(serial_number)
);

-- Tabla de log de actividades
CREATE TABLE IF NOT EXISTS activity_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    log_level TEXT NOT NULL, -- 'INFO', 'WARNING', 'ERROR', 'DEBUG'
    category TEXT NOT NULL, -- 'LICENSE', 'APPLICATION', 'DISTRIBUTOR', 'VALIDATION', 'SYSTEM'
    message TEXT NOT NULL,
    details TEXT, -- JSON con información adicional
    user_action TEXT, -- Descripción de la acción del usuario
    error_code TEXT,
    stack_trace TEXT
);

-- Índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_licenses_company ON licenses(company_name);
CREATE INDEX IF NOT EXISTS idx_licenses_app ON licenses(application_name);
CREATE INDEX IF NOT EXISTS idx_licenses_created ON licenses(created_at);
CREATE INDEX IF NOT EXISTS idx_activity_log_timestamp ON activity_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_activity_log_level ON activity_log(log_level);
CREATE INDEX IF NOT EXISTS idx_activity_log_category ON activity_log(category);
