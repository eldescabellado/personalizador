# Ejemplos de Pruebas de Licencias

Este documento describe diferentes escenarios de prueba para validar el funcionamiento del sistema de licencias.

## Preparación

Antes de comenzar las pruebas, asegúrese de tener:
1. LicenseGuard ejecutándose para generar licencias
2. LicenseTester compilado y listo para usar
3. Acceso a las licencias generadas

## Escenarios de Prueba

### Test 1: Licencia Full Perpetua

**Objetivo:** Verificar que una licencia completa sin expiración funciona correctamente.

**Pasos:**
1. En LicenseGuard, generar una licencia:
   - Tipo: Full
   - Cliente: "Empresa de Prueba S.A."
   - Aplicación: "Sucursales Premium"
   - Versión: "1.0"
   - Expiración: Sin expiración (perpetua)
   - Hardware Binding: Deshabilitado

2. En LicenseTester:
   - Application Name: "Sucursales Premium"
   - Version: "1.0"
   - Cargar la licencia generada

**Resultado Esperado:**
- ✅ Estado: VALID
- ✅ Días restantes: Never (Perpetual)
- ✅ Test Basic Feature: GRANTED
- ✅ Test Full Feature: GRANTED

---

### Test 2: Licencia Trial con Expiración

**Objetivo:** Verificar que una licencia de prueba con fecha de expiración funciona.

**Pasos:**
1. En LicenseGuard, generar una licencia:
   - Tipo: Trial
   - Cliente: "Cliente Trial"
   - Aplicación: "Sucursales Premium"
   - Versión: "1.0"
   - Expiración: 30 días desde hoy
   - Hardware Binding: Deshabilitado

2. En LicenseTester:
   - Application Name: "Sucursales Premium"
   - Version: "1.0"
   - Cargar la licencia generada

**Resultado Esperado:**
- ✅ Estado: VALID
- ✅ Días restantes: 30 days (aproximadamente)
- ✅ Test Basic Feature: GRANTED
- ❌ Test Full Feature: DENIED

---

### Test 3: Licencia con Hardware Binding

**Objetivo:** Verificar que la vinculación de hardware funciona correctamente.

**Pasos:**
1. En LicenseTester:
   - Copiar el "Hardware ID" mostrado

2. En LicenseGuard, generar una licencia:
   - Tipo: Full
   - Cliente: "Cliente con Binding"
   - Aplicación: "Sucursales Premium"
   - Versión: "1.0"
   - Hardware Binding: Habilitado
   - Hardware ID: [pegar el ID copiado]
   - Binding Type: Strict

3. En LicenseTester:
   - Application Name: "Sucursales Premium"
   - Version: "1.0"
   - Cargar la licencia generada

**Resultado Esperado:**
- ✅ Estado: VALID
- ✅ Hardware Binding: Strict (Hardware ID: [su ID])
- ✅ Test Basic Feature: GRANTED
- ✅ Test Full Feature: GRANTED

**Prueba Adicional:**
- Copiar la licencia a otro equipo
- Intentar cargarla en LicenseTester
- ❌ Resultado esperado: INVALID - Hardware ID mismatch

---

### Test 4: Licencia Demo

**Objetivo:** Verificar que una licencia demo tiene acceso limitado.

**Pasos:**
1. En LicenseGuard, generar una licencia:
   - Tipo: Demo
   - Cliente: "Cliente Demo"
   - Aplicación: "Sucursales Premium"
   - Versión: "1.0"
   - Días de demostración: 15
   - Hardware Binding: Deshabilitado

2. En LicenseTester:
   - Application Name: "Sucursales Premium"
   - Version: "1.0"
   - Cargar la licencia generada

**Resultado Esperado:**
- ✅ Estado: VALID
- ✅ Días restantes: 15 days (aproximadamente)
- ✅ Test Basic Feature: GRANTED
- ❌ Test Full Feature: DENIED

---

### Test 5: Validación de Versión de Aplicación

**Objetivo:** Verificar que la tolerancia de versión funciona correctamente.

**Pasos:**
1. En LicenseGuard, generar una licencia:
   - Tipo: Full
   - Aplicación: "Sucursales Premium"
   - Versión: "1.0"
   - Tolerancia de versión: Patch (permite 1.0.x)

2. En LicenseTester - Prueba 1:
   - Application Name: "Sucursales Premium"
   - Version: "1.0.0"
   - Cargar la licencia
   - ✅ Resultado esperado: VALID

3. En LicenseTester - Prueba 2:
   - Application Name: "Sucursales Premium"
   - Version: "1.0.5"
   - Cargar la licencia
   - ✅ Resultado esperado: VALID

4. En LicenseTester - Prueba 3:
   - Application Name: "Sucursales Premium"
   - Version: "1.1.0"
   - Cargar la licencia
   - ❌ Resultado esperado: INVALID - Version not allowed

---

### Test 6: Características Personalizadas

**Objetivo:** Verificar que las características personalizadas funcionan.

**Pasos:**
1. En LicenseGuard, generar una licencia:
   - Tipo: Full
   - Aplicación: "Sucursales Premium"
   - Campos personalizados:
     - AdvancedReports: true
     - ExportData: true
     - APIAccess: false

2. En LicenseTester:
   - Application Name: "Sucursales Premium"
   - Version: "1.0"
   - Cargar la licencia

3. Probar características:
   - Custom Feature: "AdvancedReports" → ✅ GRANTED
   - Custom Feature: "ExportData" → ✅ GRANTED
   - Custom Feature: "APIAccess" → ❌ DENIED
   - Custom Feature: "UnknownFeature" → ❌ DENIED

---

### Test 7: Licencia Expirada

**Objetivo:** Verificar que las licencias expiradas son rechazadas.

**Pasos:**
1. En LicenseGuard, generar una licencia:
   - Tipo: Trial
   - Fecha de expiración: Fecha pasada (ej: hace 1 día)

2. En LicenseTester:
   - Cargar la licencia generada

**Resultado Esperado:**
- ❌ Estado: INVALID
- ❌ Error: "License has expired"
- ❌ Días restantes: Expired

---

### Test 8: Archivo de Licencia Corrupto

**Objetivo:** Verificar el manejo de archivos corruptos.

**Pasos:**
1. Tomar un archivo de licencia válido (.zip)
2. Modificar el archivo con un editor hexadecimal o renombrar un archivo .txt a .zip
3. En LicenseTester:
   - Intentar cargar el archivo corrupto

**Resultado Esperado:**
- ❌ Error: "Invalid license file format" o similar
- ❌ Estado: INVALID

---

### Test 9: Nombre de Aplicación Incorrecto

**Objetivo:** Verificar que se valida el nombre de aplicación.

**Pasos:**
1. Generar una licencia para "Sucursales Premium"
2. En LicenseTester:
   - Application Name: "Aplicación Incorrecta"
   - Cargar la licencia

**Resultado Esperado:**
- ❌ Estado: INVALID
- ❌ Error: "Application name mismatch"

---

### Test 10: Verificación de Integridad de Archivos

**Objetivo:** Verificar que la verificación de integridad funciona.

**Pasos:**
1. En LicenseGuard, generar una licencia:
   - Habilitar verificación de archivos
   - Agregar archivos para verificar (ej: ejecutable de la aplicación)

2. En LicenseTester:
   - Cargar la licencia
   - Verificar que la información de archivos se muestra

**Resultado Esperado:**
- ✅ Estado: VALID
- ✅ Información de archivos verificados mostrada en License Information

---

## Checklist de Pruebas

Use este checklist para asegurarse de que todas las funcionalidades están probadas:

- [ ] Test 1: Licencia Full Perpetua
- [ ] Test 2: Licencia Trial con Expiración
- [ ] Test 3: Licencia con Hardware Binding
- [ ] Test 4: Licencia Demo
- [ ] Test 5: Validación de Versión de Aplicación
- [ ] Test 6: Características Personalizadas
- [ ] Test 7: Licencia Expirada
- [ ] Test 8: Archivo de Licencia Corrupto
- [ ] Test 9: Nombre de Aplicación Incorrecto
- [ ] Test 10: Verificación de Integridad de Archivos

## Registro de Pruebas

| Test | Fecha | Resultado | Notas |
|------|-------|-----------|-------|
| 1    |       |           |       |
| 2    |       |           |       |
| 3    |       |           |       |
| 4    |       |           |       |
| 5    |       |           |       |
| 6    |       |           |       |
| 7    |       |           |       |
| 8    |       |           |       |
| 9    |       |           |       |
| 10   |       |           |       |

## Notas Importantes

1. **Fechas de Expiración:** Al probar licencias con expiración, tenga en cuenta que los días restantes cambiarán con el tiempo.

2. **Hardware ID:** El Hardware ID es único para cada equipo. Asegúrese de usar el ID correcto al generar licencias con binding.

3. **Nombres de Aplicación:** Los nombres de aplicación son case-sensitive. "Sucursales Premium" ≠ "sucursales premium".

4. **Archivos de Licencia:** Los archivos .zip generados contienen el archivo .sis encriptado. No modifique el contenido del .zip.

5. **Versiones:** La tolerancia de versión determina qué versiones son compatibles con la licencia.

## Solución de Problemas en Pruebas

### Problema: Todas las licencias fallan con "Application name mismatch"
**Solución:** Verifique que está usando exactamente el mismo nombre de aplicación usado al generar la licencia.

### Problema: Hardware binding siempre falla
**Solución:** Asegúrese de copiar el Hardware ID completo sin espacios adicionales.

### Problema: No se puede cargar ninguna licencia
**Solución:** Verifique que los archivos .zip no están corruptos y que LicenseGuard generó las licencias correctamente.

---

**Última actualización:** Noviembre 2025  
**Versión del documento:** 1.0
