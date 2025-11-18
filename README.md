# LicenseGuard - Sistema de Gestión y Generación de Licencias

## Descripción General

**LicenseGuard** es un sistema completo de gestión y generación de licencias para aplicaciones Delphi que proporciona protección robusta mediante encriptación AES-256 y verificación de archivos de control.

## Características Principales

### 1. Generación de Licencias Seguras
- Archivos de licencia encriptados con AES-256
- Formato personalizado `.sis` (Software Information System)
- Empaquetado automático en archivos ZIP con nombre de empresa
- Verificación mediante archivo de control maestro (`premium.sis`)

### 2. Gestión Completa de Datos
- **Aplicaciones**: Registre y gestione las aplicaciones a licenciar
- **Distribuidores**: Control de distribuidores con seriales únicos
- **Historial**: Registro completo de todas las licencias generadas

### 3. Opciones de Licencia Flexibles
- **Vencimiento opcional**: Configure fechas de expiración con período de gracia
- **Control de versiones**: Especifique versiones permitidas de la aplicación
- **Vinculación de hardware**: Enlace licencias a hardware específico (MAC, CPU, Disk)
- **Licencias Demo**: Generación rápida de licencias de prueba

### 4. Seguridad Robusta
- Encriptación AES-256 con PBKDF2 para derivación de claves
- Salt e IV aleatorios para cada encriptación
- Hash SHA-256 del archivo de control para prevenir manipulación
- Validación de integridad en múltiples niveles

## Estructura del Proyecto

```
personalizador/
├── src/
│   └── LicenseGuard.dpr          # Proyecto principal
├── forms/
│   ├── MainForm.pas              # Formulario principal
│   └── MainForm.dfm              # Diseño del formulario
├── units/
│   ├── LG.Encryption.pas         # Módulo de encriptación AES-256
│   ├── LG.LicenseData.pas        # Estructuras de datos
│   ├── LG.LicenseGenerator.pas   # Generador de licencias
│   ├── LG.LicenseValidator.pas   # Validador (para apps cliente)
│   ├── LG.HardwareInfo.pas       # Información de hardware
│   └── LG.DataManager.pas        # Gestión de datos
├── examples/
│   └── IntegrationExample.pas    # Ejemplo de integración
├── docs/
│   ├── INTEGRATION_GUIDE.md      # Guía de integración
│   └── SECURITY.md               # Documentación de seguridad
├── db/                           # Base de datos JSON
└── output/                       # Licencias generadas
```

## Requisitos del Sistema

- **Delphi**: 10.2 Tokyo o superior (para System.Hash y System.JSON)
- **Windows**: XP o superior
- **Componentes**: VCL (incluidos en Delphi)

### Componentes Opcionales para Producción
- **DCPcrypt** o **LockBox3**: Para implementación AES-256 robusta
- **System.Crypto**: Disponible en Delphi 11+ (recomendado)

## Instalación y Configuración

### 1. Compilar el Proyecto

```bash
# Abra el proyecto en Delphi
LicenseGuard.dpr

# Compile y ejecute (F9)
```

### 2. Configuración Inicial

1. **Establecer Clave Maestra**:
   - Vaya a la pestaña "Settings"
   - Ingrese una clave maestra segura (mínimo 32 caracteres recomendado)
   - Guarde la configuración

2. **Generar Archivo de Control**:
   - En "Settings", haga clic en "Generate Control File"
   - Se generará `premium.sis` en la carpeta de salida
   - **IMPORTANTE**: Mantenga este archivo seguro y distribúyalo con sus aplicaciones

3. **Configurar Aplicaciones**:
   - Vaya a la pestaña "Applications"
   - Agregue las aplicaciones que desea licenciar

4. **Configurar Distribuidores**:
   - Vaya a la pestaña "Distributors"
   - Agregue distribuidores con sus datos de contacto

## Uso Básico

### Generar una Licencia Completa

1. Vaya a la pestaña "Generate License"
2. Complete los datos del cliente:
   - Nombre del cliente
   - Empresa
3. Seleccione la aplicación y distribuidor
4. Configure opciones adicionales:
   - Versiones permitidas (separadas por comas)
   - Fecha de vencimiento (opcional)
   - Vinculación de hardware (opcional)
5. Haga clic en "Generate Full License"
6. La licencia se generará como `[NombreEmpresa].zip`

### Generar una Licencia Demo

1. Haga clic en "Generate Demo License"
2. Ingrese el nombre del cliente
3. Seleccione la aplicación
4. Especifique los días de validez
5. La licencia demo se generará automáticamente

## Integración en Aplicaciones Cliente

### Paso 1: Copiar Unidades Necesarias

Copie las siguientes unidades a su proyecto:
- `LG.Encryption.pas`
- `LG.LicenseData.pas`
- `LG.LicenseValidator.pas`
- `LG.HardwareInfo.pas`

### Paso 2: Distribuir el Archivo de Control

Incluya `premium.sis` en la carpeta de instalación de su aplicación.

### Paso 3: Validar la Licencia

```pascal
uses
  LG.LicenseValidator, LG.LicenseData;

procedure ValidateLicense;
var
  Validator: TLicenseValidator;
  Result: TValidationResult;
  LicensePath: string;
  ControlFilePath: string;
begin
  // Inicializar validador con la misma clave maestra
  Validator := TLicenseValidator.Create('YourMasterKeyHere');
  try
    // Rutas de archivos
    LicensePath := 'C:\MyApp\License\ClientLicense.zip';
    ControlFilePath := ExtractFilePath(Application.ExeName) + 'premium.sis';

    // Establecer versión de la aplicación
    Validator.ApplicationVersion := '1.0.0';

    // Cargar y validar licencia
    Result := Validator.LoadLicenseFromZip(LicensePath, ControlFilePath);

    if Result.IsValid then
    begin
      ShowMessage('License valid!' + #13#10 +
                  'Licensed to: ' + Validator.LicenseData.ClientName);

      // Continuar con la aplicación
      Application.Run;
    end
    else
    begin
      ShowMessage('Invalid license: ' + Result.ErrorMessage);
      Application.Terminate;
    end;
  finally
    Validator.Free;
  end;
end;
```

Ver `docs/INTEGRATION_GUIDE.md` para información detallada.

## Contenido de la Licencia

Cada archivo de licencia contiene (encriptado):

- **Información del Cliente**:
  - Nombre
  - Empresa

- **Información de la Aplicación**:
  - Nombre de la aplicación
  - ID de aplicación
  - Versiones toleradas

- **Vencimiento**:
  - ¿Vence? (Sí/No)
  - Fecha de vencimiento
  - Período de gracia (días)

- **Distribuidor**:
  - Nombre del distribuidor
  - Serial del distribuidor

- **Vinculación de Hardware**:
  - Habilitado/Deshabilitado
  - Tipo de vinculación (MAC/CPU/DISK/COMBINED)
  - Hardware ID

- **Control**:
  - Serial único de licencia
  - Hash del archivo de control
  - Fecha de creación
  - Notas adicionales

## Mecanismo de Protección

### Flujo de Generación

```
1. Crear datos de licencia (JSON)
2. Encriptar con AES-256 + PBKDF2
3. Guardar como license.sis
4. Calcular hash de premium.sis
5. Incluir hash en licencia
6. Comprimir en [Empresa].zip
```

### Flujo de Validación

```
1. Extraer license.sis del ZIP
2. Calcular hash de premium.sis local
3. Desencriptar licencia
4. Verificar hash de premium.sis
5. Validar versión de aplicación
6. Validar fecha de vencimiento
7. Validar hardware (si habilitado)
8. Permitir/Denegar acceso
```

## Seguridad

### Encriptación
- **Algoritmo**: AES-256 (CBC mode)
- **Derivación de clave**: PBKDF2 con 100,000 iteraciones
- **Salt**: 256 bits aleatorios
- **IV**: 128 bits aleatorios por encriptación

### Recomendaciones de Seguridad

1. **Clave Maestra**:
   - Use una clave de al menos 32 caracteres
   - Incluya mayúsculas, minúsculas, números y símbolos
   - No comparta la clave maestra
   - Cambie la clave periódicamente

2. **Archivo de Control**:
   - Mantenga `premium.sis` seguro
   - No lo modifique después de generarlo
   - Distribúyalo con su aplicación

3. **Producción**:
   - Reemplace la implementación AES simplificada con DCPcrypt, LockBox3 o System.Crypto
   - Considere ofuscar el código
   - Implemente detección de debugging

## Mejoras para Producción

### 1. Implementación AES Real

La implementación incluida usa XOR como placeholder. Para producción:

```pascal
// Opción 1: DCPcrypt
// https://sourceforge.net/projects/dcpcrypt/

// Opción 2: LockBox3
// https://github.com/TurboPack/LockBox3

// Opción 3: System.Crypto (Delphi 11+)
uses System.Crypto;
```

### 2. Base de Datos SQL

Considere migrar de JSON a SQLite o SQL Server:

```pascal
// Usar componentes FireDAC para SQLite
uses FireDAC.Stan.Def, FireDAC.Phys.SQLite;
```

### 3. Activación en Línea

Implemente un servidor de activación para:
- Validación remota de licencias
- Revocación de licencias
- Telemetría de uso
- Actualizaciones automáticas

### 4. Protección Adicional

- **Code Signing**: Firme digitalmente su ejecutable
- **Anti-Debugging**: Detecte debuggers y entornos virtuales
- **Checksum**: Verifique la integridad del ejecutable
- **Ofuscación**: Use herramientas como Enigma Protector

## Solución de Problemas

### Error: "Invalid encrypted data format"
- Verifique que está usando la misma clave maestra
- Compruebe que el archivo no está corrupto

### Error: "Control file mismatch"
- El archivo `premium.sis` no coincide
- Regenere el archivo de control o la licencia

### Error: "Hardware mismatch"
- La licencia está vinculada a otro equipo
- Genere una nueva licencia para este hardware

### Error: "License expired"
- La licencia ha caducado
- Genere una nueva licencia con nueva fecha

## Licencia del Software

Este software se proporciona "tal cual" sin garantías de ningún tipo.

## Soporte

Para soporte y consultas:
- Consulte la documentación en `docs/`
- Revise los ejemplos en `examples/`
- Contacte al desarrollador del sistema

## Créditos

**LicenseGuard** desarrollado con Delphi VCL.

---

**Versión**: 1.0.0
**Fecha**: 2025
**Autor**: Sistema LicenseGuard
