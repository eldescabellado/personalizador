# Guía Rápida - LicenseTester

## Inicio Rápido (5 minutos)

### 1. Abrir la Aplicación
- Ejecute `LicenseTester.exe`
- La aplicación mostrará automáticamente la información de hardware de su sistema

### 2. Cargar una Licencia
```
1. Click en "Browse..." 
2. Seleccione el archivo .zip de la licencia
3. Click en "Load and Validate License"
```

### 3. Verificar Resultados
✅ **VALID** = Licencia válida y funcional  
❌ **INVALID** = Licencia con problemas (ver mensaje de error)

## Escenarios Comunes

### Escenario 1: Probar Licencia de Cliente
```
Aplicación: Sucursales Premium
Versión: 1.0
Licencia: SUPERMERCADO_REAL_Y_MEDIO,_C.A..zip

Pasos:
1. Configurar Application Name: "Sucursales Premium"
2. Configurar Version: "1"
3. Cargar archivo de licencia
4. Verificar estado = VALID
```

### Escenario 2: Verificar Hardware ID
```
Objetivo: Obtener Hardware ID para generar licencia

Pasos:
1. Abrir LicenseTester
2. Ver sección "Hardware Information"
3. Copiar el "Hardware ID"
4. Usar este ID al generar la licencia en LicenseGuard
```

### Escenario 3: Probar Características
```
Objetivo: Verificar qué características están habilitadas

Pasos:
1. Cargar licencia válida
2. Click en "Test Basic Feature Access"
3. Click en "Test Full Feature Access"
4. Para características personalizadas:
   - Ingresar nombre (ej: "AdvancedReports")
   - Click en "Test Custom Feature"
```

## Tipos de Licencia

| Tipo  | Características | Expiración | Hardware Binding |
|-------|----------------|------------|------------------|
| Full  | Todas          | Opcional   | Opcional         |
| Trial | Limitadas      | Siempre    | No               |
| Demo  | Básicas        | Opcional   | No               |

## Mensajes de Estado

### ✅ VALID
- La licencia es válida
- Todas las verificaciones pasaron
- La aplicación puede usar la licencia

### ❌ INVALID - Motivos Comunes

**"Application name mismatch"**
→ Solución: Verificar que el nombre de aplicación coincida

**"Hardware ID mismatch"**
→ Solución: Esta licencia es para otro equipo

**"License has expired"**
→ Solución: Generar nueva licencia con fecha actualizada

**"Invalid license file format"**
→ Solución: Archivo corrupto, regenerar licencia

## Atajos de Teclado

- `Ctrl+O` - Abrir licencia (Browse)
- `Ctrl+L` - Cargar licencia
- `Ctrl+R` - Refrescar hardware
- `Ctrl+C` - Limpiar todo
- `Alt+F4` - Salir

## Información Mostrada

### License Information
```
License Serial: 6F732109CE6741CAAC84742F2A7E839F
License Type: Full
Client: SUPERMERCADO REAL Y MEDIO, C.A.
Company: SUPERMERCADO REAL Y MEDIO, C.A.
Application: Sucursales Premium
Distributor: IBSEN RAMIRES (DIST-001)
Created: 21/11/2025 10:02:21 p. m.
Expires: Never (Perpetual)
Hardware Binding: None
Status: VALID
```

### Hardware Information
```
Hardware ID: ABC123DEF456...
CPU ID: BFEBFBFF000906E9
Motherboard Serial: 1234567890
MAC Address: 00-11-22-33-44-55
Computer Name: WORKSTATION-01
User Name: SISTEMA
```

## Solución Rápida de Problemas

| Problema | Solución |
|----------|----------|
| No carga la licencia | Verificar que el archivo .zip no esté corrupto |
| Estado INVALID | Revisar nombre y versión de aplicación |
| Hardware mismatch | Usar el Hardware ID correcto al generar |
| No encuentra archivo | Verificar ruta completa del archivo |

## Consejos

💡 **Tip 1:** Copie el Hardware ID antes de generar licencias con binding  
💡 **Tip 2:** Use nombres de aplicación exactos (case-sensitive)  
💡 **Tip 3:** Verifique siempre la fecha de expiración  
💡 **Tip 4:** Pruebe todas las características antes de entregar al cliente  

## Flujo de Trabajo Recomendado

```
1. Generar licencia en LicenseGuard
   ↓
2. Abrir LicenseTester
   ↓
3. Configurar nombre y versión de aplicación
   ↓
4. Cargar y validar licencia
   ↓
5. Verificar estado = VALID
   ↓
6. Probar características requeridas
   ↓
7. Entregar licencia al cliente
```

## Contacto y Soporte

Para más información, consulte el archivo `README.md` completo.

---
**Versión:** 1.0.0  
**Fecha:** Noviembre 2025
