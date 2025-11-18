# LicenseGuard - Documentación de Seguridad

## Visión General del Sistema de Seguridad

LicenseGuard implementa un sistema de protección multicapa que combina encriptación fuerte, validación de integridad y opciones de vinculación de hardware.

## Tabla de Contenidos

1. [Arquitectura de Seguridad](#arquitectura-de-seguridad)
2. [Encriptación](#encriptación)
3. [Sistema de Control](#sistema-de-control)
4. [Vinculación de Hardware](#vinculación-de-hardware)
5. [Mejoras para Producción](#mejoras-para-producción)
6. [Vectores de Ataque y Mitigaciones](#vectores-de-ataque-y-mitigaciones)
7. [Recomendaciones](#recomendaciones)

## Arquitectura de Seguridad

### Capas de Protección

```
┌─────────────────────────────────────────────┐
│  1. Archivo ZIP Comprimido                  │
│     - Dificulta inspección casual           │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│  2. Archivo .sis Encriptado                 │
│     - AES-256 con PBKDF2                    │
│     - Salt e IV únicos                      │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│  3. Verificación de Archivo de Control      │
│     - Hash SHA-256 de premium.sis           │
│     - Previene licencias falsificadas       │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│  4. Validación de Datos de Licencia         │
│     - Versión de aplicación                 │
│     - Fecha de expiración                   │
│     - Hardware ID (opcional)                │
│     - Serial de distribuidor                │
└─────────────────────────────────────────────┘
```

## Encriptación

### Algoritmo: AES-256

**Especificaciones**:
- **Tamaño de clave**: 256 bits (32 bytes)
- **Modo de operación**: CBC (Cipher Block Chaining)
- **Tamaño de bloque**: 128 bits (16 bytes)
- **Padding**: PKCS#7

### Derivación de Clave: PBKDF2

**Parámetros**:
```pascal
Salt Size: 256 bits (32 bytes)
Iterations: 100,000
Hash Function: HMAC-SHA256
Output Length: 256 bits (32 bytes)
```

**Por qué PBKDF2**:
- Resistente a ataques de fuerza bruta
- Derivación determinística de clave desde password
- Salt único por licencia previene rainbow tables
- Alto número de iteraciones aumenta el costo computacional de ataques

### Flujo de Encriptación

```
Input: License Data (JSON)
  ↓
Generate Random Salt (32 bytes)
  ↓
Derive Key = PBKDF2(MasterPassword, Salt, 100k iterations)
  ↓
Generate Random IV (16 bytes)
  ↓
Encrypt Data = AES-256-CBC(LicenseData, Key, IV)
  ↓
Output: [Salt][IV][Encrypted Data]
  ↓
Encode as Base64
```

### Implementación Actual vs. Producción

#### Implementación Actual (Demostración)
```pascal
// NOTA: Implementación simplificada usando XOR
// Para demostración y pruebas solamente
EncBlock := XORBytes(Block, Key);
```

#### Implementación Recomendada para Producción

**Opción 1: DCPcrypt**
```pascal
uses DCPcrypt2, DCPrijndael, DCPsha256;

function EncryptAES256(const Data, Password: string): string;
var
  Cipher: TDCP_rijndael;
  Key: array[0..31] of Byte;
  IV: array[0..15] of Byte;
begin
  Cipher := TDCP_rijndael.Create(nil);
  try
    // Derive key
    DeriveKey(Password, @Key[0], SizeOf(Key));

    // Initialize
    Cipher.Init(Key, SizeOf(Key) * 8, @IV[0]);

    // Encrypt
    Result := Cipher.EncryptString(Data);
  finally
    Cipher.Free;
  end;
end;
```

**Opción 2: System.Crypto (Delphi 11+)**
```pascal
uses System.Crypto;

function EncryptAES256(const Data, Password: TBytes): TBytes;
var
  Cipher: ISymmetricCipher;
  Salt, Key: TBytes;
begin
  Salt := RandomBytes(32);
  Key := PBKDF2(Password, Salt, 100000, 32);

  Cipher := TCipherFactory.CreateCipher(
    TAlgorithm.AES,
    TMode.CBC,
    TPadding.PKCS7,
    Key
  );

  Result := Cipher.Encrypt(Data);
end;
```

**Opción 3: LockBox3**
```pascal
uses TPLB3.Codec, TPLB3.CryptographicLibrary;

function EncryptAES256(const PlainText: string): string;
var
  Codec: TCodec;
  Lib: TCryptographicLibrary;
begin
  Lib := TCryptographicLibrary.Create(nil);
  Codec := TCodec.Create(nil);
  try
    Codec.CryptoLibrary := Lib;
    Codec.StreamCipherId := 'native.AES-256';
    Codec.BlockCipherId := 'native.AES-256';
    Codec.ChainModeId := 'native.CBC';
    Codec.Password := 'YourPassword';

    Result := Codec.EncryptString(PlainText);
  finally
    Codec.Free;
    Lib.Free;
  end;
end;
```

## Sistema de Control

### Archivo de Control (premium.sis)

**Propósito**: Vincular licencias a una "instalación maestra" específica.

**Contenido**:
```
[Magic String] | [Unique ID] | [Timestamp]
```

**Generación**:
```pascal
ControlData := 'LICENSEGUARD-CONTROL-FILE-V1.0|' +
               GenerateUniqueID() + '|' +
               DateTimeToStr(Now);

EncryptedControl := Encrypt(ControlData, MasterKey);
Save(EncryptedControl, 'premium.sis');

ControlHash := SHA256(EncryptedControl);
```

**Validación**:
```pascal
// En la aplicación cliente
LocalHash := SHA256(ReadFile('premium.sis'));
LicenseHash := DecryptedLicense.ControlFileHash;

if LocalHash <> LicenseHash then
  RaiseError('Invalid license - control file mismatch');
```

**Resistencia a Ataques**:
1. **Copia de licencia**: Una licencia no funcionará con otro premium.sis
2. **Modificación**: Cualquier cambio en premium.sis invalida el hash
3. **Regeneración**: Sin la clave maestra, no se puede crear un premium.sis válido

## Vinculación de Hardware

### Tipos de Vinculación

#### 1. MAC Address
```pascal
function GetMACAddress: string;
// Obtiene dirección MAC de la primera interfaz de red activa
// Pros: Relativamente estable
// Contras: Puede cambiar si se cambia NIC
```

#### 2. CPU ID
```pascal
function GetCPUId: string;
// Lee identificación del procesador del registro de Windows
// Pros: No cambia a menos que se cambie CPU
// Contras: Información puede ser difícil de obtener en algunos sistemas
```

#### 3. Disk Serial
```pascal
function GetDiskSerial: string;
// Obtiene serial del volumen C:\
// Pros: Único por instalación de Windows
// Contras: Cambia si se reinstala Windows o HDD
```

#### 4. Combined (Recomendado)
```pascal
function GetCombinedHardwareID: string;
var
  Combined: string;
begin
  Combined := MAC + '|' + CPU + '|' + DISK + '|' + ComputerName;
  Result := SHA256(Combined);
end;
```

**Ventajas del ID Combinado**:
- Más robusto: tolera cambio de un componente
- Más único: combinación de múltiples factores
- Hash final protege privacidad del usuario

### Consideraciones de Hardware Binding

**Flexibilidad vs. Seguridad**:
- Vinculación estricta = Mayor seguridad, menor flexibilidad
- Sin vinculación = Mayor flexibilidad, menor seguridad

**Recomendación**:
- Licencias Demo/Trial: Sin vinculación (fácil de probar)
- Licencias Personales: Vinculación combinada
- Licencias Enterprise: Vinculación opcional (cambios frecuentes de hardware)

## Mejoras para Producción

### 1. Implementación AES Real

**Crítico**: Reemplace la implementación XOR por AES real.

```pascal
// Archivo: LG.Encryption.pas
// Línea: ~150-180

// REEMPLAZAR esta sección con implementación real de AES-256
class function TLGEncryption.EncryptBytes(const Data: TBytes;
  const Key: TBytes): TBytes;
begin
  // TODO: Implementar AES-256 real usando DCPcrypt, LockBox3 o System.Crypto
  // La implementación actual usa XOR como placeholder
end;
```

### 2. Ofuscación de Código

**Herramientas Recomendadas**:
- **Enigma Protector**: Protección integral, VM, anti-debug
- **Themida**: Protección avanzada con virtualización
- **VMProtect**: Virtualización de código
- **Delphi Code Obfuscator**: Específico para Delphi

**Técnicas**:
```pascal
// Ofuscar strings críticos
const
  {$IFDEF RELEASE}
  MASTER_KEY = <ofuscado>;
  {$ELSE}
  MASTER_KEY = 'PlainTextForDebug';
  {$ENDIF}

// Ofuscar lógica de validación
procedure ValidateLicense; inline;
asm
  // Código assembly para dificultar reversing
end;
```

### 3. Anti-Debugging

```pascal
function IsDebuggerPresent: Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := Winapi.Windows.IsDebuggerPresent;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function DetectVM: Boolean;
begin
  // Detectar VMware, VirtualBox, etc.
  Result := CheckVMwarePresence or
            CheckVirtualBoxPresence or
            CheckQEMUPresence;
end;

procedure CheckEnvironment;
begin
  if IsDebuggerPresent then
  begin
    // No mostrar mensaje obvio
    ExitProcess(0);
  end;

  if DetectVM then
  begin
    // Decidir política para VMs
    ShowWarning('Running in virtual environment');
  end;
end;
```

### 4. Code Signing

```pascal
// Verificar firma digital del ejecutable
function VerifyExecutableSignature: Boolean;
var
  FileInfo: WINTRUST_FILE_INFO;
  TrustData: WINTRUST_DATA;
begin
  // Usar WinVerifyTrust API
  Result := WinVerifyTrust(...) = ERROR_SUCCESS;
end;
```

### 5. Checksum del Ejecutable

```pascal
function VerifyExecutableIntegrity: Boolean;
var
  ExpectedHash: string;
  ActualHash: string;
begin
  // Hash embebido en recurso o servidor
  ExpectedHash := GetExpectedHash;

  // Calcular hash del ejecutable
  ActualHash := SHA256File(ParamStr(0));

  Result := ExpectedHash = ActualHash;
end;
```

### 6. Activación Online

```pascal
function ValidateLicenseOnline(const LicenseSerial: string): Boolean;
var
  HTTP: THTTPClient;
  Response: IHTTPResponse;
  JSONResponse: TJSONObject;
begin
  HTTP := THTTPClient.Create;
  try
    Response := HTTP.Post(
      'https://your-server.com/api/validate',
      TJSONObject.Create.AddPair('serial', LicenseSerial)
    );

    if Response.StatusCode = 200 then
    begin
      JSONResponse := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      try
        Result := JSONResponse.GetValue<Boolean>('valid');
      finally
        JSONResponse.Free;
      end;
    end
    else
      Result := False;
  finally
    HTTP.Free;
  end;
end;
```

## Vectores de Ataque y Mitigaciones

### Ataque 1: Ingeniería Inversa del Ejecutable

**Vector**: Usar herramientas como IDA Pro, Ghidra para analizar el código.

**Mitigaciones**:
1. **Ofuscación de código**: Dificulta lectura del código desensamblado
2. **Virtualización**: Ejecutar código en VM propia
3. **Anti-debugging**: Detectar y prevenir debugging
4. **String encryption**: Ofuscar strings críticos
5. **Code signing**: Detectar modificaciones

### Ataque 2: Generación de Licencias Falsas

**Vector**: Intentar crear archivos .sis válidos sin la clave maestra.

**Mitigaciones**:
1. **Clave maestra secreta**: Nunca distribuir ni exponer
2. **Encriptación fuerte**: AES-256 es computacionalmente seguro
3. **Control file hash**: Requiere premium.sis específico
4. **Activación online**: Validar seriales contra servidor

**Efectividad**: Sin la clave maestra, es prácticamente imposible generar licencias válidas (asumiendo AES-256 real).

### Ataque 3: Patch del Ejecutable

**Vector**: Modificar el ejecutable para saltar verificación de licencia.

**Mitigaciones**:
1. **Code signing**: Detectar modificaciones
2. **Checksum verification**: Verificar integridad
3. **Multiple validation points**: Validar en varios puntos del código
4. **Validation obfuscation**: Ofuscar lógica de validación
5. **Online verification**: Requiere servidor para funciones críticas

```pascal
// Validar en múltiples puntos
procedure TMainForm.FormCreate(Sender: TObject);
begin
  ValidateLicense1;
end;

procedure TMainForm.CriticalOperationClick(Sender: TObject);
begin
  ValidateLicense2;  // Verificar nuevamente
end;

procedure TMainForm.TimerCheck(Sender: TObject);
begin
  ValidateLicense3;  // Verificación periódica
end;
```

### Ataque 4: Uso de Licencia en Múltiples Equipos

**Vector**: Compartir archivo de licencia.

**Mitigaciones**:
1. **Hardware binding**: Vincular a hardware específico
2. **Activación online**: Registrar hardware ID en servidor
3. **Límite de activaciones**: Permitir N activaciones
4. **Telemetría**: Monitorear uso sospechoso

### Ataque 5: Manipulación de Fecha del Sistema

**Vector**: Cambiar fecha para evitar expiración.

**Mitigaciones**:
```pascal
function GetTrustedTime: TDateTime;
var
  NTPTime: TDateTime;
  LastKnownTime: TDateTime;
begin
  // Intentar obtener hora de servidor NTP
  NTPTime := GetNTPTime;
  if NTPTime > 0 then
    Exit(NTPTime);

  // Usar última hora conocida guardada
  LastKnownTime := LoadLastKnownTime;

  // Si hora del sistema es anterior, usar última conocida
  if Now < LastKnownTime then
    Result := LastKnownTime
  else
  begin
    Result := Now;
    SaveLastKnownTime(Result);
  end;
end;
```

### Ataque 6: Depuración en Tiempo de Ejecución

**Vector**: Usar debugger para modificar valores en memoria.

**Mitigaciones**:
```pascal
procedure AntiDebugCheck;
begin
  // Verificar IsDebuggerPresent
  if IsDebuggerPresent then
    TerminateProcess(GetCurrentProcess, 0);

  // Verificar timing attacks
  var Start := GetTickCount;
  Sleep(100);
  if GetTickCount - Start > 200 then
    TerminateProcess(GetCurrentProcess, 0);

  // Verificar debug flags
  if DebugHook <> 0 then
    TerminateProcess(GetCurrentProcess, 0);
end;
```

## Recomendaciones

### Nivel Básico (Mínimo Requerido)

1. Implementar AES-256 real (DCPcrypt/LockBox3/System.Crypto)
2. Usar clave maestra fuerte (32+ caracteres)
3. Distribuir premium.sis con la aplicación
4. Validar licencia al inicio

### Nivel Intermedio (Recomendado)

Todo lo anterior, más:

5. Habilitar hardware binding para licencias no-demo
6. Implementar validación periódica (cada hora)
7. Ofuscar la clave maestra en el código
8. Agregar anti-debugging básico
9. Firmar digitalmente el ejecutable

### Nivel Avanzado (Máxima Seguridad)

Todo lo anterior, más:

10. Usar herramienta de protección (Enigma/Themida)
11. Implementar activación online
12. Telemetría de uso
13. Límites de activación por licencia
14. Validación NTP para tiempo confiable
15. Checksum del ejecutable
16. Múltiples puntos de validación en código crítico
17. Ofuscación completa del código

## Conclusión

LicenseGuard proporciona una base sólida para protección de software. La seguridad real dependerá de:

1. **Implementación correcta de AES-256** (crítico)
2. **Protección de la clave maestra** (crítico)
3. **Capas adicionales de protección** (recomendado)
4. **Mantenimiento y actualizaciones** (continuo)

Ningún sistema es 100% seguro, pero con las mejoras recomendadas, LicenseGuard puede proporcionar protección efectiva contra la mayoría de los ataques.

---

**Versión**: 1.0
**Última Actualización**: 2025
