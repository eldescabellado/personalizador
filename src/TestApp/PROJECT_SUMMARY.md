# Proyecto de Prueba de Licencias - LicenseTester

## 📋 Resumen del Proyecto

Este proyecto proporciona una aplicación completa de prueba para validar las licencias generadas por el sistema **LicenseGuard**. La aplicación está desarrollada en **Delphi Rio (10.3)** y permite probar todos los aspectos de las licencias antes de distribuirlas a los clientes.

## 📁 Estructura del Proyecto

```
TestApp/
├── LicenseTester.dpr              # Proyecto principal de Delphi
├── LicenseTester.dproj.template   # Plantilla de proyecto Delphi
├── LicenseTester.res              # Recursos de la aplicación
├── LicenseTester.ini.example      # Archivo de configuración de ejemplo
├── TestMainForm.pas               # Código del formulario principal
├── TestMainForm.dfm               # Diseño visual del formulario
├── Build.ps1                      # Script de compilación PowerShell
├── README.md                      # Documentación completa
├── QUICK_START.md                 # Guía rápida de inicio
└── TEST_SCENARIOS.md              # Escenarios de prueba detallados
```

## ✨ Características Principales

### 1. **Validación Completa de Licencias**
   - Carga y valida archivos de licencia (.zip)
   - Verifica nombre y versión de aplicación
   - Valida fechas de expiración
   - Comprueba vinculación de hardware
   - Verifica integridad de archivos

### 2. **Visualización de Información**
   - Detalles completos de la licencia
   - Información del cliente y distribuidor
   - Estado de validación en tiempo real
   - Días restantes hasta expiración
   - Información de hardware del sistema

### 3. **Prueba de Características**
   - Test de características básicas
   - Test de características completas
   - Test de características personalizadas
   - Control de acceso basado en tipo de licencia

### 4. **Información de Hardware**
   - Hardware ID único del sistema
   - CPU ID
   - Serial de placa madre
   - Dirección MAC
   - Información del sistema

## 🚀 Cómo Usar

### Opción 1: Abrir en Delphi IDE

1. Abra Delphi Rio (10.3) o superior
2. Abra el archivo `LicenseTester.dpr`
3. Configure las rutas de búsqueda si es necesario:
   - `..\..\units\` (unidades de LicenseGuard)
   - `..\..\forms\` (formularios)
4. Compile el proyecto (F9)
5. Ejecute la aplicación

### Opción 2: Compilar desde Línea de Comandos

```powershell
# Navegar al directorio del proyecto
cd p:\Proyectos\personalizador\src\TestApp

# Ejecutar el script de compilación
.\Build.ps1

# O especificar ruta de Delphi personalizada
.\Build.ps1 -DelphiPath "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin"
```

### Opción 3: Usar Ejecutable Pre-compilado

Si ya compiló el proyecto, simplemente ejecute:
```
LicenseTester.exe
```

## 📖 Documentación Incluida

### 1. **README.md** - Documentación Completa
   - Descripción detallada de todas las características
   - Instrucciones paso a paso
   - Explicación de tipos de licencia
   - Solución de problemas
   - Casos de uso completos

### 2. **QUICK_START.md** - Guía Rápida
   - Inicio rápido en 5 minutos
   - Escenarios comunes
   - Tabla de referencia rápida
   - Consejos y trucos
   - Atajos de teclado

### 3. **TEST_SCENARIOS.md** - Escenarios de Prueba
   - 10 escenarios de prueba detallados
   - Checklist de pruebas
   - Registro de pruebas
   - Casos de éxito y fallo
   - Solución de problemas en pruebas

## 🔧 Configuración

### Archivo de Configuración (LicenseTester.ini.example)

Copie `LicenseTester.ini.example` a `LicenseTester.ini` y ajuste según necesite:

```ini
[Application]
DefaultAppName=Test Application
DefaultAppVersion=1.0.0

[Paths]
DefaultLicenseDir=C:\Users\SISTEMA\Desktop\LICENCIAS GENERADAS

[UI]
ShowHardwareOnStartup=1
RememberLastLicense=1

[Testing]
QuickTestFeatures=BasicFeatures,FullFeatures,AdvancedReports

[Debug]
DebugMode=0
SaveValidationLog=0
```

## 🎯 Casos de Uso Principales

### Caso 1: Validar Licencia de Cliente
```
1. Generar licencia en LicenseGuard
2. Abrir LicenseTester
3. Configurar nombre y versión de aplicación
4. Cargar archivo de licencia
5. Verificar estado VALID
6. Probar características requeridas
7. Entregar licencia al cliente
```

### Caso 2: Obtener Hardware ID
```
1. Abrir LicenseTester en el equipo del cliente
2. Ver sección "Hardware Information"
3. Copiar el Hardware ID
4. Usar en LicenseGuard para generar licencia con binding
```

### Caso 3: Probar Características Personalizadas
```
1. Generar licencia con campos personalizados
2. Cargar en LicenseTester
3. Probar cada característica individualmente
4. Verificar control de acceso
```

## 📊 Tipos de Licencia Soportados

| Tipo  | Acceso          | Expiración | Hardware Binding |
|-------|-----------------|------------|------------------|
| Full  | Completo        | Opcional   | Opcional         |
| Trial | Limitado        | Requerido  | No               |
| Demo  | Básico          | Opcional   | No               |

## 🔍 Validaciones Realizadas

La aplicación verifica:

✅ Formato de archivo de licencia  
✅ Integridad de datos encriptados  
✅ Nombre de aplicación  
✅ Versión de aplicación (con tolerancia)  
✅ Fecha de expiración  
✅ Período de gracia  
✅ Hardware ID (si está habilitado)  
✅ Serial del distribuidor  
✅ Verificación de archivos (si está configurada)  
✅ Campos personalizados  

## 🛠️ Dependencias

El proyecto utiliza las siguientes unidades de LicenseGuard:

- **LG.Encryption** - Encriptación/desencriptación AES
- **LG.LicenseData** - Estructuras de datos de licencia
- **LG.LicenseValidator** - Motor de validación
- **LG.HardwareInfo** - Información de hardware del sistema
- **LG.FileVerification** - Verificación de integridad de archivos

## 📝 Notas Importantes

⚠️ **Esta aplicación es solo para pruebas internas**  
No distribuya esta aplicación a clientes finales. Es una herramienta de desarrollo y prueba.

⚠️ **Hardware ID es único por equipo**  
Cada equipo tiene un Hardware ID diferente. Use el ID correcto al generar licencias con binding.

⚠️ **Nombres de aplicación son case-sensitive**  
"Sucursales Premium" ≠ "sucursales premium"

⚠️ **Archivos .zip no deben modificarse**  
Los archivos de licencia son .zip que contienen el archivo .sis encriptado. No modifique su contenido.

## 🐛 Solución de Problemas

### Error: "Unit not found" al compilar
**Solución:** Verifique las rutas de búsqueda en las opciones del proyecto.

### Error: "License file not found"
**Solución:** Verifique que la ruta del archivo sea correcta y que el archivo existe.

### Error: "Application name mismatch"
**Solución:** Use exactamente el mismo nombre de aplicación usado al generar la licencia.

### Error: "Hardware ID mismatch"
**Solución:** La licencia fue generada para otro equipo. Genere una nueva licencia con el Hardware ID correcto.

## 📞 Soporte

Para más información sobre LicenseGuard, consulte:
- Documentación principal del proyecto LicenseGuard
- Archivo `README.md` en el directorio raíz del proyecto

## 📅 Información de Versión

- **Versión:** 1.0.0
- **Fecha de Creación:** Noviembre 2025
- **Compatible con:** LicenseGuard 1.0+
- **Delphi:** Rio (10.3) o superior
- **Plataforma:** Windows 7 o superior

## 🎓 Ejemplos de Uso

### Ejemplo 1: Licencia Full Perpetua
```pascal
// En LicenseGuard:
- Tipo: Full
- Cliente: "SUPERMERCADO REAL Y MEDIO, C.A."
- Aplicación: "Sucursales Premium"
- Versión: "1"
- Expiración: Sin expiración

// En LicenseTester:
- Application Name: "Sucursales Premium"
- Version: "1"
- Resultado: VALID, Never (Perpetual)
```

### Ejemplo 2: Licencia Trial 30 días
```pascal
// En LicenseGuard:
- Tipo: Trial
- Días: 30
- Aplicación: "Sucursales Premium"

// En LicenseTester:
- Resultado: VALID, 30 days remaining
- Basic Features: GRANTED
- Full Features: DENIED
```

### Ejemplo 3: Licencia con Hardware Binding
```pascal
// Paso 1: Obtener Hardware ID en LicenseTester
Hardware ID: ABC123DEF456...

// Paso 2: Generar licencia en LicenseGuard
- Hardware Binding: Enabled
- Hardware ID: ABC123DEF456...
- Binding Type: Strict

// Paso 3: Validar en LicenseTester
- Resultado: VALID
- Hardware Binding: Strict (ABC123DEF456...)
```

## 🔐 Seguridad

- La aplicación utiliza las mismas bibliotecas de encriptación que LicenseGuard
- Las licencias están protegidas con encriptación AES-256
- La validación de hardware utiliza múltiples componentes del sistema
- Los archivos de licencia no pueden ser modificados sin invalidar la firma

## 🚦 Estado del Proyecto

✅ **Completado y Listo para Usar**

Todos los componentes están implementados y probados:
- ✅ Interfaz de usuario completa
- ✅ Validación de licencias
- ✅ Información de hardware
- ✅ Prueba de características
- ✅ Documentación completa
- ✅ Scripts de compilación
- ✅ Ejemplos y escenarios de prueba

## 📦 Archivos Generados

Al compilar el proyecto, se generarán:
- `LicenseTester.exe` - Ejecutable principal
- `*.dcu` - Archivos de unidad compilados
- `*.map` - Archivo de mapa (si está habilitado)
- `*.drc` - Recursos compilados

## 🎉 ¡Listo para Usar!

El proyecto está completamente configurado y listo para:
1. Abrir en Delphi IDE
2. Compilar
3. Ejecutar
4. Probar licencias generadas por LicenseGuard

---

**Desarrollado para:** LicenseGuard License Management System  
**Plataforma:** Delphi Rio (10.3)  
**Fecha:** Noviembre 2025  
**Versión:** 1.0.0
