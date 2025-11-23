# LicenseGuard - Aplicación de Prueba de Licencias

## Descripción

Esta aplicación de prueba permite validar y probar las licencias generadas por el sistema LicenseGuard. Es una herramienta completa para verificar que las licencias funcionan correctamente antes de distribuirlas a los clientes.

## Características

### 1. Carga y Validación de Licencias
- Cargar archivos de licencia (.zip) generados por LicenseGuard
- Validar automáticamente la licencia contra:
  - Nombre de aplicación
  - Versión de aplicación
  - Vinculación de hardware (si está habilitada)
  - Fecha de expiración
  - Integridad de archivos

### 2. Visualización de Información de Licencia
- Serial de licencia
- Tipo de licencia (Full, Trial, Demo)
- Información del cliente
- Información del distribuidor
- Fechas de creación y expiración
- Estado de vinculación de hardware
- Campos personalizados

### 3. Información de Hardware
- Hardware ID del sistema actual
- CPU ID
- Serial de placa madre
- Dirección MAC
- Nombre de computadora
- Nombre de usuario

### 4. Prueba de Acceso a Características
- Probar acceso a características básicas
- Probar acceso a características completas
- Probar características personalizadas por nombre

### 5. Estado de Validación
- Indicador visual de estado (VÁLIDO/INVÁLIDO)
- Días restantes hasta expiración
- Mensajes de error y advertencia detallados

## Cómo Usar

### Paso 1: Configurar Información de Aplicación
1. Ingrese el nombre de la aplicación en el campo "Application Name"
2. Ingrese la versión de la aplicación en el campo "Version"
3. Haga clic en "Set Application Info"

**Nota:** Estos valores deben coincidir con los usados al generar la licencia.

### Paso 2: Cargar una Licencia
1. Haga clic en el botón "Browse..." para seleccionar un archivo de licencia (.zip)
2. Navegue hasta la ubicación del archivo de licencia generado
3. Seleccione el archivo y haga clic en "Abrir"
4. Haga clic en "Load and Validate License"

### Paso 3: Revisar Resultados
La aplicación mostrará:
- **License Information:** Detalles completos de la licencia
- **Validation Status:** Estado actual (VALID/INVALID) y días restantes
- **Hardware Information:** Información del hardware del sistema

### Paso 4: Probar Acceso a Características
Puede probar diferentes niveles de acceso:

#### Características Básicas
- Haga clic en "Test Basic Feature Access"
- Disponible para licencias Full, Trial y Demo

#### Características Completas
- Haga clic en "Test Full Feature Access"
- Solo disponible para licencias Full

#### Características Personalizadas
1. Ingrese el nombre de la característica en el campo "Custom Feature Name"
2. Haga clic en "Test Custom Feature"
3. La aplicación verificará si la licencia tiene acceso a esa característica

## Tipos de Licencia

### Full (Completa)
- Acceso a todas las características
- Puede ser perpetua o con fecha de expiración
- Puede tener vinculación de hardware

### Trial (Prueba)
- Acceso limitado a características
- Siempre tiene fecha de expiración
- Generalmente sin vinculación de hardware

### Demo (Demostración)
- Acceso solo a características básicas
- Puede tener fecha de expiración
- Sin vinculación de hardware

## Vinculación de Hardware

Si la licencia tiene vinculación de hardware habilitada:
- La licencia solo funcionará en el equipo específico para el cual fue generada
- El Hardware ID del sistema debe coincidir con el registrado en la licencia
- Puede usar diferentes tipos de vinculación:
  - **Strict:** Todos los componentes deben coincidir
  - **Flexible:** Permite algunos cambios de hardware
  - **Loose:** Solo verifica componentes principales

## Mensajes de Error Comunes

### "License file not found"
- Verifique que la ruta del archivo sea correcta
- Asegúrese de que el archivo existe en la ubicación especificada

### "Invalid license file format"
- El archivo puede estar corrupto
- Asegúrese de que es un archivo .zip válido generado por LicenseGuard

### "Application name mismatch"
- El nombre de aplicación no coincide con el de la licencia
- Verifique que ingresó el nombre correcto en "Application Name"

### "Application version not allowed"
- La versión de la aplicación no está permitida por la licencia
- Verifique la configuración de tolerancia de versión en la licencia

### "Hardware ID mismatch"
- La licencia está vinculada a otro equipo
- Esta licencia no funcionará en este sistema

### "License has expired"
- La fecha de expiración de la licencia ha pasado
- Genere una nueva licencia o extienda la fecha de expiración

## Estructura de Archivos

```
TestApp/
├── LicenseTester.dpr          # Proyecto principal
├── LicenseTester.dproj        # Archivo de proyecto Delphi
├── LicenseTester.res          # Recursos de la aplicación
├── TestMainForm.pas           # Código del formulario principal
├── TestMainForm.dfm           # Diseño del formulario
└── README.md                  # Este archivo
```

## Dependencias

La aplicación utiliza las siguientes unidades de LicenseGuard:
- `LG.Encryption` - Encriptación/desencriptación
- `LG.LicenseData` - Estructuras de datos de licencia
- `LG.LicenseValidator` - Validación de licencias
- `LG.HardwareInfo` - Información de hardware
- `LG.FileVerification` - Verificación de integridad de archivos

## Compilación

### Requisitos
- Delphi Rio (10.3) o superior
- Windows 7 o superior

### Pasos para Compilar
1. Abra `LicenseTester.dproj` en Delphi
2. Asegúrese de que todas las rutas de búsqueda estén configuradas correctamente
3. Compile el proyecto (Project → Compile)
4. Ejecute la aplicación (Run → Run)

### Rutas de Búsqueda
El proyecto debe tener acceso a:
- `..\..\units\` - Unidades de LicenseGuard
- `..\..\forms\` - Formularios (si es necesario)

## Solución de Problemas

### Error al compilar: "Unit not found"
- Verifique que las rutas en el archivo .dpr sean correctas
- Asegúrese de que todos los archivos .pas estén presentes en las carpetas correspondientes

### La aplicación no se ejecuta
- Verifique que todas las DLLs necesarias estén presentes
- Ejecute como administrador si hay problemas de permisos

### No se puede cargar la licencia
- Verifique que el archivo .zip no esté corrupto
- Asegúrese de que el archivo fue generado correctamente por LicenseGuard

## Casos de Uso

### Caso 1: Verificar Licencia de Cliente
1. Configure el nombre y versión de la aplicación del cliente
2. Cargue el archivo de licencia generado para ese cliente
3. Verifique que el estado sea VALID
4. Confirme que la información del cliente es correcta
5. Pruebe el acceso a las características requeridas

### Caso 2: Probar Vinculación de Hardware
1. Genere una licencia con vinculación de hardware para este equipo
2. Cargue la licencia en la aplicación de prueba
3. Verifique que el Hardware ID coincida
4. Confirme que la validación sea exitosa

### Caso 3: Verificar Expiración
1. Genere una licencia con fecha de expiración específica
2. Cargue la licencia
3. Verifique que los días restantes sean correctos
4. Confirme que el período de gracia funcione correctamente

### Caso 4: Probar Características Personalizadas
1. Genere una licencia con campos personalizados
2. Cargue la licencia
3. Use "Test Custom Feature" para verificar cada característica
4. Confirme que el control de acceso funcione correctamente

## Notas Importantes

- **Seguridad:** Esta aplicación es solo para pruebas. No distribuya esta aplicación a clientes finales.
- **Licencias de Prueba:** Use esta aplicación para verificar licencias antes de entregarlas a clientes.
- **Hardware ID:** El Hardware ID mostrado es el que debe usar al generar licencias con vinculación de hardware.
- **Versiones:** Asegúrese de que la versión de la aplicación de prueba coincida con la versión para la cual se generó la licencia.

## Soporte

Para problemas o preguntas sobre LicenseGuard, consulte la documentación principal del proyecto.

## Versión

- **Versión:** 1.0.0
- **Fecha:** Noviembre 2025
- **Compatible con:** LicenseGuard 1.0+
