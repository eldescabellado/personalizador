# LicenseGuard - Integración de Base de Datos

## Descripción General

LicenseGuard ahora utiliza una base de datos para almacenar aplicaciones, distribuidores, licencias generadas y logs de actividad. El sistema soporta tanto SQLite como PostgreSQL, permitiendo iniciar con SQLite y migrar a PostgreSQL cuando sea necesario.

## Características

### 1. Soporte Multi-Base de Datos
- **SQLite**: Base de datos por defecto, ideal para instalaciones locales y desarrollo
- **PostgreSQL**: Para entornos de producción con múltiples usuarios

### 2. Sistema de Logging
Todos los eventos del sistema se registran en la tabla `activity_log`:
- Generación de licencias
- Adición/modificación de aplicaciones y distribuidores
- Errores y warnings
- Acciones del usuario

### 3. Esquema de Base de Datos

#### Tabla: applications
Almacena las aplicaciones registradas en el sistema.
```sql
- id: INTEGER PRIMARY KEY (autoincremental)
- name: TEXT NOT NULL UNIQUE
- current_version: TEXT NOT NULL
- created_at: TEXT NOT NULL (formato: yyyy-mm-dd hh:nn:ss)
- updated_at: TEXT NOT NULL
```

#### Tabla: distributors
Almacena los distribuidores autorizados.
```sql
- id: INTEGER PRIMARY KEY
- name: TEXT NOT NULL
- serial_number: TEXT NOT NULL UNIQUE (formato: XXXX-XXXX-XXXX-XXXX)
- contact_info: TEXT (Email, teléfono, dirección)
- active: INTEGER (0 = inactivo, 1 = activo)
- created_at: TEXT NOT NULL
- updated_at: TEXT NOT NULL
```

#### Tabla: licenses
Historial de todas las licencias generadas.
```sql
- id: INTEGER PRIMARY KEY
- company_name: TEXT NOT NULL (nombre de la empresa cliente)
- contact_name: TEXT (nombre del contacto)
- contact_email: TEXT
- application_name: TEXT NOT NULL
- application_version: TEXT NOT NULL
- license_type: TEXT NOT NULL (Full, Demo, Trial)
- distributor_serial: TEXT (FK a distributors)
- expiration_date: TEXT (fecha de expiración)
- hardware_binding_type: TEXT (None, MAC, CPU, Disk, Combined)
- hardware_id: TEXT (ID del hardware vinculado)
- demo_expires_date: TEXT (fecha de expiración para demos)
- control_file_hash: TEXT (hash SHA-256 del archivo de control)
- zip_file_path: TEXT (ruta al archivo ZIP generado)
- created_at: TEXT NOT NULL
```

#### Tabla: activity_log
Log de todas las actividades del sistema.
```sql
- id: INTEGER PRIMARY KEY
- timestamp: TEXT NOT NULL
- log_level: TEXT NOT NULL (INFO, WARNING, ERROR, DEBUG)
- category: TEXT NOT NULL (LICENSE, APPLICATION, DISTRIBUTOR, VALIDATION, SYSTEM)
- message: TEXT NOT NULL (mensaje descriptivo)
- details: TEXT (JSON con información adicional)
- user_action: TEXT (descripción de la acción del usuario)
- error_code: TEXT (código de error si aplica)
- stack_trace: TEXT (stack trace para errores)
```

## Configuración

### SQLite (Por Defecto)

Al iniciar por primera vez, LicenseGuard crea automáticamente:
1. Archivo `licenseguard.db` en el directorio de la aplicación
2. Archivo `licenseguard.ini` con la configuración de la base de datos

No se requiere configuración adicional.

### PostgreSQL

Para usar PostgreSQL, edita el archivo `licenseguard.ini`:

```ini
[Database]
Type=PostgreSQL

[PostgreSQL]
Host=localhost
Port=5432
Database=licenseguard
Username=postgres
Password=tu_contraseña_aqui
```

#### Preparar PostgreSQL:

1. Crear la base de datos:
```sql
CREATE DATABASE licenseguard;
```

2. Ejecutar el script de inicialización:
```bash
psql -U postgres -d licenseguard -f database/schema_postgresql.sql
```

## Migración de JSON a Base de Datos

Si tienes datos existentes en archivos JSON (`data/applications.json`, etc.), puedes migrarlos manualmente:

### Opción 1: Migración Manual
1. Abre los archivos JSON
2. Usa la interfaz de LicenseGuard para agregar cada registro

### Opción 2: Script de Migración (Próximamente)
Se incluirá un script de migración automática en futuras versiones.

## Uso en el Código

### Inicializar Conexión
```delphi
var
  Database: TLGDatabase;
  Logger: TLGDatabaseLogger;
  Config: TDatabaseConfig;
begin
  Database := TLGDatabase.Create;

  // Usar configuración guardada o default (SQLite)
  Config := Database.LoadConfig;
  Database.Connect(Config);

  // Crear logger
  Logger := TLGDatabaseLogger.Create(Database);

  // Usar...
  Logger.LogInfo(lcSystem, 'Sistema iniciado');
end;
```

### Operaciones con DataManager
```delphi
var
  DataManager: TDataManager;
begin
  // Opción 1: Usar base de datos existente
  DataManager := TDataManager.Create(Database, Logger);

  // Opción 2: Crear su propia base de datos (SQLite por defecto)
  DataManager := TDataManager.Create;

  // Agregar aplicación
  DataManager.AddApplication('MiApp', 'Descripción', '1.0.0');

  // Las operaciones se registran automáticamente en el log
end;
```

### Logging Manual
```delphi
// Logs simples
Logger.LogInfo(lcLicense, 'Licencia generada exitosamente');
Logger.LogWarning(lcValidation, 'Advertencia de validación');

// Log con acción del usuario
Logger.LogInfo(lcApplication, 'Aplicación agregada', 'Usuario agregó nueva aplicación');

// Log de errores
try
  // operación...
except
  on E: Exception do
    Logger.LogError(lcSystem, 'Error en operación', E, 'Usuario intentó...');
end;
```

## Consultas Personalizadas

### Ejemplos de Queries SQL

```delphi
// Obtener estadísticas de licencias por tipo
var
  Query: TFDQuery;
begin
  Query := Database.ExecuteQuery(
    'SELECT license_type, COUNT(*) as total ' +
    'FROM licenses GROUP BY license_type'
  );

  while not Query.Eof do
  begin
    WriteLn(Query.FieldByName('license_type').AsString, ': ',
            Query.FieldByName('total').AsInteger);
    Query.Next;
  end;

  Query.Free;
end;

// Ver logs del último día
Query := Database.ExecuteQuery(
  'SELECT * FROM activity_log ' +
  'WHERE timestamp >= datetime("now", "-1 day") ' +
  'ORDER BY timestamp DESC'
);
```

## Backup y Mantenimiento

### SQLite
```bash
# Backup
sqlite3 licenseguard.db ".backup licenseguard_backup.db"

# Restaurar
sqlite3 licenseguard.db ".restore licenseguard_backup.db"

# Vacuuming (optimizar)
sqlite3 licenseguard.db "VACUUM;"
```

### PostgreSQL
```bash
# Backup
pg_dump -U postgres licenseguard > licenseguard_backup.sql

# Restaurar
psql -U postgres licenseguard < licenseguard_backup.sql
```

## Consideraciones de Seguridad

1. **Contraseñas**: En producción, NO guardes contraseñas de PostgreSQL en texto plano en el archivo INI. Considera usar:
   - Variables de entorno
   - Cifrado de configuración
   - Autenticación integrada de Windows

2. **Permisos**:
   - SQLite: Asegurar que el archivo .db tenga permisos apropiados
   - PostgreSQL: Usar usuarios con privilegios mínimos necesarios

3. **Conexiones**:
   - PostgreSQL: Usar SSL para conexiones remotas
   - Limitar conexiones concurrentes según necesidad

## Troubleshooting

### Error: "Could not load SQLite library"
- Asegúrate de que `sqlite3.dll` esté en el PATH o en el directorio de la aplicación
- FireDAC incluye estas DLLs, revisa la configuración de deployment

### Error: "Cannot connect to PostgreSQL server"
- Verifica que PostgreSQL esté corriendo
- Revisa host, puerto y credenciales en licenseguard.ini
- Verifica firewall y pg_hba.conf

### Base de datos corrupta (SQLite)
```bash
# Intentar reparación
sqlite3 licenseguard.db ".recover" | sqlite3 licenseguard_recovered.db
```

## Próximas Mejoras

- [ ] Script de migración automática desde JSON
- [ ] Interfaz gráfica para configuración de base de datos
- [ ] Visor de logs integrado en la aplicación
- [ ] Backup automático programado
- [ ] Soporte para MySQL/MariaDB
- [ ] Reportes estadísticos basados en datos históricos
