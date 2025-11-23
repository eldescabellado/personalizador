# LicenseGuard - Guía Rápida

## Sistema Simplificado

Esta versión genera archivos `.lic` directamente (sin ZIP, sin archivo de control separado).

## Generación de Licencias

1. Abrir LicenseGuard
2. Llenar datos del cliente
3. Seleccionar aplicación y distribuidor
4. Click en "Generar Licencia"
5. Se crea un archivo `.lic` en la carpeta de salida

El archivo generado (ejemplo: `MiEmpresa.lic`) contiene toda la información encriptada.

## Validación en Aplicaciones Cliente

### Archivos Necesarios

Copiar estas unidades a tu proyecto:
- `LG.LicenseValidator.pas`
- `LG.LicenseData.pas`
- `LG.Encryption.pas`
- `LG.HardwareInfo.pas` (solo si usas vinculación de hardware)

### Código Mínimo

```pascal
uses
  LG.LicenseValidator;

procedure TFormMain.FormCreate(Sender: TObject);
const
  MASTER_KEY = 'TU-MASTER-KEY-AQUI';  // Misma que usaste para generar
  APP_NAME = 'NombreDetuApp';
var
  Validator: TLicenseValidator;
  LicensePath: string;
begin
  LicensePath := ExtractFilePath(Application.ExeName) + 'license.lic';

  Validator := TLicenseValidator.Create(MASTER_KEY);
  try
    if Validator.LoadLicense(LicensePath) then
    begin
      if Validator.IsValidFor(APP_NAME) then
      begin
        // Licencia válida - continuar
        Caption := 'Registrado a: ' + Validator.ClientCompany;
      end
      else
      begin
        ShowMessage('Licencia inválida: ' + Validator.ErrorMessage);
        Application.Terminate;
      end;
    end
    else
    begin
      ShowMessage('No se encontró licencia');
      Application.Terminate;
    end;
  finally
    Validator.Free;
  end;
end;
```

### Propiedades Útiles del Validador

```pascal
// Después de LoadLicense:
Validator.IsValid           // Boolean - si la licencia es válida
Validator.IsLoaded          // Boolean - si se cargó correctamente
Validator.ErrorMessage      // String - mensaje de error
Validator.WarningMessage    // String - advertencias (ej: expira pronto)

Validator.ClientName        // Nombre del cliente
Validator.ClientCompany     // Empresa
Validator.LicenseType       // ltFull, ltDemo, ltTrial
Validator.ExpirationDate    // Fecha de expiración
Validator.GetDaysRemaining  // Días restantes

Validator.GetLicenseInfo    // Texto con toda la info de la licencia
```

## Distribución al Cliente

1. Generar la licencia con LicenseGuard
2. Enviar el archivo `.lic` al cliente
3. El cliente coloca el archivo en la carpeta de la aplicación
4. Renombrar a `license.lic` (o la ruta que uses en tu código)

## Ejemplo Completo

Ver archivo `examples/ClientIntegration.pas` para ejemplos detallados incluyendo:
- Verificación simple
- Uso con TLicenseManager
- Verificación periódica
- Búsqueda en múltiples ubicaciones
- Manejo de diferentes tipos de licencia (Full/Demo/Trial)

## Notas Importantes

- **MasterKey**: Usa la misma clave en generación y validación
- **Seguridad**: No guardes la MasterKey en texto plano en el ejecutable final
- **Extensión**: Por defecto es `.lic`, pero puedes cambiarla
- **Sin ZIP**: El archivo es directamente el contenido encriptado
