# LicenseGuard - Ejemplos de Integración

Este directorio contiene ejemplos completos de cómo integrar LicenseGuard en sus aplicaciones Delphi.

## Contenido

- `IntegrationExample.pas` / `IntegrationExample.dfm` - Ejemplo completo con interfaz VCL

## Cómo Usar los Ejemplos

### Paso 1: Crear un Nuevo Proyecto de Prueba

1. Abra Delphi
2. Cree un nuevo proyecto VCL: File → New → VCL Forms Application
3. Guarde el proyecto en una carpeta de prueba

### Paso 2: Copiar Archivos Necesarios

Copie los siguientes archivos a la carpeta de su proyecto de prueba:

**Unidades Core (desde `../units/`):**
```
LG.Encryption.pas
LG.LicenseData.pas
LG.LicenseValidator.pas
LG.HardwareInfo.pas
```

**Ejemplo (desde este directorio):**
```
IntegrationExample.pas
IntegrationExample.dfm
```

### Paso 3: Agregar Unidades al Proyecto

1. Project → Add to Project
2. Seleccione todas las unidades `.pas` que copió
3. Compile el proyecto (Project → Build)

### Paso 4: Generar una Licencia de Prueba

1. Ejecute la aplicación LicenseGuard principal
2. Vaya a Settings → Configure la clave maestra (use la misma en el ejemplo)
3. Genere el archivo de control: Settings → Generate Control File
4. Agregue una aplicación de prueba: Applications → Add
5. Agregue un distribuidor: Distributors → Add
6. Genere una licencia: Generate License
   - Nombre del cliente: "Test Client"
   - Empresa: "TestCompany"
   - Seleccione la aplicación y distribuidor
   - Genere la licencia

### Paso 5: Configurar el Ejemplo

Edite `IntegrationExample.pas`:

```pascal
const
  // Use la MISMA clave maestra que usó en LicenseGuard
  MASTER_KEY = 'YourSecureMasterKey';

  // Información de su aplicación
  APP_NAME = 'MyTestApp';
  APP_VERSION = '1.0.0';
```

### Paso 6: Ejecutar el Ejemplo

1. Compile y ejecute el proyecto de ejemplo
2. Copie `premium.sis` a la carpeta del ejecutable
3. En el ejemplo, haga clic en "Load License File..."
4. Seleccione el archivo `.zip` generado por LicenseGuard
5. La licencia se validará y mostrará la información

## Características del Ejemplo

### 1. Validación al Inicio
El ejemplo valida automáticamente la licencia al iniciar la aplicación.

### 2. Carga Manual de Licencia
Permite al usuario seleccionar manualmente un archivo de licencia.

### 3. Visualización de Hardware ID
Muestra la información de hardware del sistema para generar licencias vinculadas.

### 4. Control de Acceso a Características
Demuestra cómo habilitar/deshabilitar funcionalidades según el tipo de licencia.

### 5. Información Detallada
Muestra todos los detalles de la licencia cargada.

## Integración en su Aplicación Real

### Patrón Básico

```pascal
// 1. Al inicio de la aplicación
procedure TMainForm.FormCreate(Sender: TObject);
begin
  if not ValidateAndLoadLicense then
  begin
    ShowMessage('No valid license found.');
    Application.Terminate;
  end;
end;

// 2. Validar licencia
function TMainForm.ValidateAndLoadLicense: Boolean;
var
  Validator: TLicenseValidator;
  Result: TValidationResult;
begin
  Validator := TLicenseValidator.Create(MASTER_KEY);
  try
    Validator.ApplicationVersion := APP_VERSION;

    Result := Validator.LoadLicenseFromZip(
      GetLicensePath,
      GetControlFilePath
    );

    Result := Result.IsValid;
  finally
    Validator.Free;
  end;
end;

// 3. Antes de operaciones críticas
procedure TMainForm.SaveDocumentClick(Sender: TObject);
begin
  if not IsLicenseValid then
  begin
    ShowMessage('License expired. Please renew.');
    Exit;
  end;

  // Continuar con la operación
  DoSaveDocument;
end;
```

### Patrón con Manager Global

```pascal
// Crear un manager global en el proyecto
var
  GlobalLicenseManager: TLicenseManager;

// Inicializar al inicio
GlobalLicenseManager := TLicenseManager.Create(MASTER_KEY);

// Usar en toda la aplicación
if GlobalLicenseManager.IsValid then
begin
  // Ejecutar funcionalidad
end;
```

## Casos de Uso Comunes

### 1. Aplicación que Requiere Licencia Siempre

```pascal
procedure TMainForm.FormCreate(Sender: TObject);
begin
  if not LoadLicense then
  begin
    ShowLicenseRequiredDialog;
    Application.Terminate;
  end;
end;
```

### 2. Aplicación con Modo Demo

```pascal
procedure TMainForm.FormCreate(Sender: TObject);
var
  HasLicense: Boolean;
begin
  HasLicense := LoadLicense;

  if HasLicense then
    EnableFullMode
  else
    EnableDemoMode;
end;
```

### 3. Aplicación con Características Opcionales

```pascal
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Cargar licencia si existe
  LoadLicense;

  // Habilitar características según licencia
  btnExport.Enabled := CheckFeature('Export');
  btnAdvancedReports.Enabled := CheckFeature('AdvancedReports');
end;
```

## Solución de Problemas

### Error: "Unit not found"
**Solución**: Verifique que copió todas las unidades y agregó la ruta en Project → Options → Delphi Compiler → Search Path

### Error: "Control file not found"
**Solución**: Copie `premium.sis` a la misma carpeta que el ejecutable

### Error: "Invalid encrypted data"
**Solución**: Verifique que está usando la misma MASTER_KEY que usó para generar la licencia

### La licencia no se valida
**Solución**:
1. Verifique que el nombre de la aplicación coincide
2. Verifique que la versión es compatible
3. Revise si tiene vinculación de hardware habilitada

## Recursos Adicionales

- Documentación completa: `../docs/INTEGRATION_GUIDE.md`
- Información de seguridad: `../docs/SECURITY.md`
- README principal: `../README.md`

## Soporte

Para más ayuda:
1. Revise la documentación en `../docs/`
2. Consulte el código fuente de las unidades
3. Revise los comentarios en el código de ejemplo

---

**Versión**: 1.0
**Autor**: LicenseGuard System
