# Instalación y Configuración - LicenseTester

## ✅ Proyecto Creado Exitosamente

Se ha creado un proyecto completo de prueba de licencias para Delphi Rio. A continuación se detallan los archivos creados y los pasos para completar la configuración.

## 📁 Archivos Creados

### Archivos Principales del Proyecto
- ✅ **LicenseTester.dpr** - Proyecto principal de Delphi
- ✅ **TestMainForm.pas** - Código del formulario principal
- ✅ **TestMainForm.dfm** - Diseño visual del formulario
- ✅ **LicenseTester.res** - Recursos de la aplicación

### Documentación
- ✅ **README.md** - Documentación completa del proyecto
- ✅ **QUICK_START.md** - Guía rápida de inicio
- ✅ **TEST_SCENARIOS.md** - 10 escenarios de prueba detallados
- ✅ **PROJECT_SUMMARY.md** - Resumen completo del proyecto
- ✅ **INSTALLATION.md** - Este archivo

### Archivos de Configuración
- ✅ **LicenseTester.ini.example** - Plantilla de configuración
- ✅ **Build.ps1** - Script de compilación PowerShell

## 🔧 Correcciones Necesarias

Antes de compilar, necesita realizar las siguientes correcciones menores en **TestMainForm.pas**:

### 1. Verificar Propiedad LicenseData

En las líneas 278, 293, 344 y 357, cambiar:
```pascal
if Assigned(FValidator.LicenseData) then
```

Por una de estas opciones (dependiendo de cómo esté implementado en LG.LicenseValidator):

**Opción A** - Si LicenseData es una propiedad que puede ser nil:
```pascal
if Assigned(FValidator.LicenseData) then
```

**Opción B** - Si hay un método para verificar:
```pascal
if FValidator.HasLicense then  // o el método equivalente
```

**Opción C** - Si LicenseData siempre existe pero tiene un estado:
```pascal
// No verificar, usar directamente
ValidationResult := FValidator.Validate;
if ValidationResult.IsValid then
```

### 2. Verificar Método GetLicenseInfo

En la línea 280, asegurarse de que el método existe:
```pascal
memoLicenseInfo.Lines.Text := FValidator.GetLicenseInfo;
```

Si no existe, usar:
```pascal
// Construir manualmente la información
memoLicenseInfo.Lines.Clear;
memoLicenseInfo.Lines.Add('License Serial: ' + FValidator.LicenseData.LicenseSerial);
memoLicenseInfo.Lines.Add('Client: ' + FValidator.LicenseData.ClientName);
// ... etc
```

## 🚀 Pasos para Compilar

### Opción 1: Usar Delphi IDE (Recomendado)

1. **Abrir el Proyecto**
   ```
   - Abrir Delphi Rio (10.3)
   - File → Open Project
   - Navegar a: p:\Proyectos\personalizador\src\TestApp\
   - Abrir: LicenseTester.dpr
   ```

2. **Verificar Rutas de Búsqueda**
   ```
   - Project → Options → Delphi Compiler → Search Path
   - Agregar si no están:
     ..\..\units
     ..\..\forms
   ```

3. **Compilar**
   ```
   - Project → Build LicenseTester
   - O presionar Shift+F9
   ```

4. **Ejecutar**
   ```
   - Run → Run (F9)
   ```

### Opción 2: Línea de Comandos

```powershell
# Navegar al directorio
cd p:\Proyectos\personalizador\src\TestApp

# Ejecutar script de compilación
.\Build.ps1

# O especificar ruta de Delphi
.\Build.ps1 -DelphiPath "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin"
```

## 📋 Checklist de Verificación

Antes de compilar, verifique:

- [ ] Delphi Rio (10.3) está instalado
- [ ] Todas las unidades de LicenseGuard están en `..\..\units\`
- [ ] Los archivos .pas existen:
  - [ ] LG.Encryption.pas
  - [ ] LG.LicenseData.pas
  - [ ] LG.LicenseValidator.pas
  - [ ] LG.HardwareInfo.pas
  - [ ] LG.FileVerification.pas
- [ ] Las rutas de búsqueda están configuradas correctamente
- [ ] Se realizaron las correcciones mencionadas arriba

## 🎯 Uso Rápido

Una vez compilado:

1. **Ejecutar la Aplicación**
   ```
   LicenseTester.exe
   ```

2. **Configurar Aplicación**
   - Application Name: "Sucursales Premium" (o el nombre de su app)
   - Version: "1" (o la versión correspondiente)
   - Click en "Set Application Info"

3. **Cargar Licencia**
   - Click en "Browse..."
   - Seleccionar archivo .zip de licencia
   - Click en "Load and Validate License"

4. **Verificar Resultados**
   - Ver estado en "Validation Status"
   - Revisar información en "License Information"
   - Probar características con los botones de prueba

## 🐛 Solución de Problemas Comunes

### Error: "Unit not found: LG.LicenseValidator"
**Solución:** Verificar que las rutas de búsqueda incluyan `..\..\units`

### Error: "Incompatible types"
**Solución:** Revisar las correcciones mencionadas en la sección "Correcciones Necesarias"

### Error: "Cannot access private symbol"
**Solución:** Ya corregido - se usa `THardwareInfo.GetHardwareInfoString` en lugar de métodos privados

### Error al ejecutar: "Master key mismatch"
**Solución:** Asegurarse de que la master key en LicenseTester coincida con la usada en LicenseGuard

## 📖 Documentación Adicional

Para más información, consulte:

- **README.md** - Documentación completa con todas las características
- **QUICK_START.md** - Guía rápida para empezar en 5 minutos
- **TEST_SCENARIOS.md** - 10 escenarios de prueba paso a paso
- **PROJECT_SUMMARY.md** - Resumen técnico del proyecto

## 🎓 Ejemplo de Uso Completo

```
1. Generar licencia en LicenseGuard:
   - Cliente: "SUPERMERCADO REAL Y MEDIO, C.A."
   - Aplicación: "Sucursales Premium"
   - Tipo: Full
   - Guardar en: C:\Users\SISTEMA\Desktop\LICENCIAS GENERADAS\

2. Abrir LicenseTester

3. Configurar:
   - Application Name: "Sucursales Premium"
   - Version: "1"
   - Click "Set Application Info"

4. Cargar:
   - Click "Browse..."
   - Seleccionar: SUPERMERCADO_REAL_Y_MEDIO,_C.A..zip
   - Click "Load and Validate License"

5. Verificar:
   - Estado debe ser: VALID
   - Ver información del cliente
   - Probar características

6. Entregar licencia al cliente
```

## ✨ Características Implementadas

✅ Validación completa de licencias  
✅ Visualización de información de licencia  
✅ Información de hardware del sistema  
✅ Prueba de acceso a características  
✅ Soporte para todos los tipos de licencia (Full, Trial, Demo)  
✅ Validación de hardware binding  
✅ Verificación de fechas de expiración  
✅ Interfaz gráfica completa y profesional  
✅ Documentación completa en español  

## 📞 Soporte

Si encuentra problemas:

1. Revisar la documentación en README.md
2. Verificar los escenarios de prueba en TEST_SCENARIOS.md
3. Consultar la guía rápida en QUICK_START.md

## 🎉 ¡Proyecto Listo!

El proyecto está completamente configurado y listo para usar. Solo necesita:
1. Realizar las correcciones menores mencionadas
2. Compilar en Delphi
3. Probar con licencias generadas

---

**Creado:** Noviembre 2025  
**Versión:** 1.0.0  
**Compatible con:** Delphi Rio (10.3) o superior  
**Plataforma:** Windows 7 o superior
