# ==============================================================================
# HERRAMIENTA DE ADMINISTRACION DE DATA CENTER - PowerShell
# Sistema Operativo: Windows
# Autor: Juan Amorocho
# Descripcion: Menu interactivo con 5 opciones para administracion de servidores
# ==============================================================================

# Configuracion inicial
Clear-Host

# ==============================================================================
# FUNCION: MOSTRAR MENU PRINCIPAL
# ==============================================================================
function Mostrar-Menu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "     HERRAMIENTA DE ADMINISTRACION DE DATA CENTER - v1.0       " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Usuarios del sistema y ultimo login" -ForegroundColor Yellow
    Write-Host "  [2] Informacion de discos y filesystems" -ForegroundColor Yellow
    Write-Host "  [3] Top 10 archivos mas grandes" -ForegroundColor Yellow
    Write-Host "  [4] Memoria RAM y Swap en uso" -ForegroundColor Yellow
    Write-Host "  [5] Backup de directorio a USB" -ForegroundColor Yellow
    Write-Host "  [0] Salir" -ForegroundColor Red
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ==============================================================================
# OPCION 1: USUARIOS Y ULTIMO LOGIN
# ==============================================================================
function Opcion1-Usuarios {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  OPCION 1: USUARIOS DEL SISTEMA Y ULTIMO LOGIN" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    
    try {
        Write-Host "Obteniendo informacion de usuarios..." -ForegroundColor Yellow
        Write-Host ""
        
        # Obtener todos los usuarios locales
        $usuarios = Get-LocalUser
        
        # Crear array para almacenar resultados
        $resultados = @()
        
        foreach ($usuario in $usuarios) {
            $ultimoLogin = "Nunca"
            
            # Intentar obtener el ultimo login desde el registro de eventos
            try {
                $loginEvent = Get-WinEvent -FilterHashtable @{
                    LogName = 'Security'
                    ID = 4624
                } -MaxEvents 10000 -ErrorAction SilentlyContinue | Where-Object {
                    $_.Properties[5].Value -eq $usuario.Name
                } | Select-Object -First 1
                
                if ($loginEvent) {
                    $ultimoLogin = $loginEvent.TimeCreated.ToString("dd/MM/yyyy HH:mm:ss")
                }
            } catch {
                # Si no se puede acceder al log de seguridad, usar informacion del usuario
                if ($usuario.LastLogon) {
                    $ultimoLogin = $usuario.LastLogon.ToString("dd/MM/yyyy HH:mm:ss")
                }
            }
            
            $resultados += [PSCustomObject]@{
                'Usuario' = $usuario.Name
                'Nombre Completo' = if ($usuario.FullName) { $usuario.FullName } else { "N/A" }
                'Habilitado' = if ($usuario.Enabled) { "Si" } else { "No" }
                'Ultimo Login' = $ultimoLogin
            }
        }
        
        # Mostrar resultados en formato tabla
        $resultados | Format-Table -AutoSize
        
        Write-Host ""
        Write-Host "Total de usuarios encontrados: $($resultados.Count)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "ERROR: No se pudo obtener informacion de usuarios." -ForegroundColor Red
        Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# OPCION 2: INFORMACION DE DISCOS Y FILESYSTEMS
# ==============================================================================
function Opcion2-Discos {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  OPCION 2: INFORMACION DE DISCOS Y FILESYSTEMS" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    
    try {
        Write-Host "Obteniendo informacion de discos..." -ForegroundColor Yellow
        Write-Host ""
        
        # Obtener informacion de volumenes
        $volumenes = Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.Size -gt 0 }
        
        # Crear array para resultados
        $resultados = @()
        
        foreach ($vol in $volumenes) {
            $tamanoBytes = $vol.Size
            $libreBytes = $vol.SizeRemaining
            $usadoBytes = $tamanoBytes - $libreBytes
            $porcentajeLibre = [math]::Round(($libreBytes / $tamanoBytes) * 100, 2)
            
            $resultados += [PSCustomObject]@{
                'Disco' = "$($vol.DriveLetter):"
                'Etiqueta' = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "Sin etiqueta" }
                'FileSystem' = $vol.FileSystem
                'Total_Bytes' = $tamanoBytes
                'Total_GB' = [math]::Round($tamanoBytes / 1GB, 2)
                'Usado_Bytes' = $usadoBytes
                'Libre_Bytes' = $libreBytes
                'Libre_GB' = [math]::Round($libreBytes / 1GB, 2)
                'Porcentaje_Libre' = "$porcentajeLibre%"
            }
        }
        
        # Mostrar resultados en tabla resumida
        Write-Host "RESUMEN DE DISCOS:" -ForegroundColor Cyan
        Write-Host ""
        $resultados | Format-Table -Property Disco, Etiqueta, FileSystem, Total_GB, Libre_GB, Porcentaje_Libre -AutoSize
        
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "INFORMACION DETALLADA EN BYTES:" -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        
        foreach ($res in $resultados) {
            Write-Host ""
            Write-Host "Disco: $($res.Disco) - $($res.Etiqueta)" -ForegroundColor Yellow
            Write-Host "  Tamano Total: $($res.Total_Bytes) bytes" -ForegroundColor White
            Write-Host "  Espacio Libre: $($res.Libre_Bytes) bytes" -ForegroundColor Green
            Write-Host "  Espacio Usado: $($res.Usado_Bytes) bytes" -ForegroundColor Magenta
        }
        
        Write-Host ""
        Write-Host "Total de discos encontrados: $($resultados.Count)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "ERROR: No se pudo obtener informacion de discos." -ForegroundColor Red
        Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# OPCION 3: TOP 10 ARCHIVOS MAS GRANDES
# ==============================================================================
function Opcion3-ArchivosGrandes {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  OPCION 3: TOP 10 ARCHIVOS MAS GRANDES" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    
    try {
        # Mostrar discos disponibles
        $discos = Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.Size -gt 0 }
        
        Write-Host "Discos disponibles:" -ForegroundColor Yellow
        foreach ($disco in $discos) {
            $etiqueta = if ($disco.FileSystemLabel) { $disco.FileSystemLabel } else { "Sin etiqueta" }
            $tamanoGB = [math]::Round($disco.Size / 1GB, 2)
            Write-Host "  [$($disco.DriveLetter):] - $etiqueta - $tamanoGB GB" -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "Ingrese la letra del disco a analizar (ej: C): " -ForegroundColor Yellow -NoNewline
        $letraDisco = Read-Host
        
        # Validar entrada
        if ($letraDisco -match '^[A-Za-z]$') {
            $letraDisco = $letraDisco.ToUpper()
            $rutaDisco = $letraDisco + ":\"
            
            if (Test-Path $rutaDisco) {
                Write-Host ""
                Write-Host "Buscando archivos mas grandes en $rutaDisco..." -ForegroundColor Yellow
                Write-Host "Este proceso puede tardar varios minutos..." -ForegroundColor Gray
                Write-Host ""
                
                # Buscar archivos y ordenar por tamano
                $archivosGrandes = Get-ChildItem -Path $rutaDisco -Recurse -File -ErrorAction SilentlyContinue | 
                    Sort-Object Length -Descending | 
                    Select-Object -First 10
                
                if ($archivosGrandes.Count -gt 0) {
                    Write-Host "================================================================" -ForegroundColor Cyan
                    Write-Host "TOP 10 ARCHIVOS MAS GRANDES EN $rutaDisco" -ForegroundColor Cyan
                    Write-Host "================================================================" -ForegroundColor Cyan
                    Write-Host ""
                    
                    $contador = 1
                    foreach ($archivo in $archivosGrandes) {
                        $tamanoBytes = $archivo.Length
                        $tamanoMB = [math]::Round($tamanoBytes / 1MB, 2)
                        $tamanoGB = [math]::Round($tamanoBytes / 1GB, 2)
                        
                        Write-Host "[$contador] $($archivo.FullName)" -ForegroundColor White
                        Write-Host "    Tamano: $tamanoBytes bytes" -ForegroundColor Cyan
                        Write-Host "            $tamanoMB MB" -ForegroundColor Green
                        Write-Host "            $tamanoGB GB" -ForegroundColor Green
                        Write-Host ""
                        
                        $contador++
                    }
                } else {
                    Write-Host "No se encontraron archivos en el disco especificado." -ForegroundColor Yellow
                }
                
            } else {
                Write-Host ""
                Write-Host "ERROR: El disco $rutaDisco no existe o no esta accesible." -ForegroundColor Red
            }
        } else {
            Write-Host ""
            Write-Host "ERROR: Entrada invalida. Debe ingresar una letra de disco (A-Z)." -ForegroundColor Red
        }
        
    } catch {
        Write-Host "ERROR: No se pudo completar la busqueda." -ForegroundColor Red
        Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# OPCION 4: MEMORIA RAM Y SWAP
# ==============================================================================
function Opcion4-Memoria {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  OPCION 4: MEMORIA RAM Y SWAP (PAGEFILE)" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    
    try {
        Write-Host "Obteniendo informacion de memoria..." -ForegroundColor Yellow
        Write-Host ""
        
        # ============== MEMORIA RAM ==============
        $os = Get-CimInstance Win32_OperatingSystem
        
        # Convertir de KB a Bytes
        $memoriaLibreBytes = $os.FreePhysicalMemory * 1KB
        $memoriaTotalBytes = $os.TotalVisibleMemorySize * 1KB
        $memoriaUsadaBytes = $memoriaTotalBytes - $memoriaLibreBytes
        
        $porcentajeLibreRAM = [math]::Round(($memoriaLibreBytes / $memoriaTotalBytes) * 100, 2)
        $porcentajeUsadoRAM = [math]::Round(($memoriaUsadaBytes / $memoriaTotalBytes) * 100, 2)
        
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "                    MEMORIA RAM                                 " -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Memoria Total:  $memoriaTotalBytes bytes" -ForegroundColor White
        Write-Host "                $([math]::Round($memoriaTotalBytes / 1GB, 2)) GB" -ForegroundColor Green
        Write-Host ""
        Write-Host "Memoria Usada:  $memoriaUsadaBytes bytes" -ForegroundColor White
        Write-Host "                $([math]::Round($memoriaUsadaBytes / 1GB, 2)) GB" -ForegroundColor Red
        Write-Host "                $porcentajeUsadoRAM%" -ForegroundColor Red
        Write-Host ""
        Write-Host "Memoria Libre:  $memoriaLibreBytes bytes" -ForegroundColor White
        Write-Host "                $([math]::Round($memoriaLibreBytes / 1GB, 2)) GB" -ForegroundColor Green
        Write-Host "                $porcentajeLibreRAM%" -ForegroundColor Green
        Write-Host ""
        
        # ============== SWAP / PAGEFILE ==============
        $pageFile = Get-CimInstance Win32_PageFileUsage
        
        if ($pageFile) {
            $swapTotalBytes = $pageFile.AllocatedBaseSize * 1MB
            $swapUsadoBytes = $pageFile.CurrentUsage * 1MB
            $swapLibreBytes = $swapTotalBytes - $swapUsadoBytes
            
            $porcentajeUsadoSwap = if ($swapTotalBytes -gt 0) { 
                [math]::Round(($swapUsadoBytes / $swapTotalBytes) * 100, 2) 
            } else { 
                0 
            }
            $porcentajeLibreSwap = if ($swapTotalBytes -gt 0) { 
                [math]::Round(($swapLibreBytes / $swapTotalBytes) * 100, 2) 
            } else { 
                0 
            }
            
            Write-Host "================================================================" -ForegroundColor Cyan
            Write-Host "                 SWAP (ARCHIVO DE PAGINACION)                   " -ForegroundColor Cyan
            Write-Host "================================================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Ubicacion:      $($pageFile.Name)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Swap Total:     $swapTotalBytes bytes" -ForegroundColor White
            Write-Host "                $([math]::Round($swapTotalBytes / 1GB, 2)) GB" -ForegroundColor Green
            Write-Host ""
            Write-Host "Swap en Uso:    $swapUsadoBytes bytes" -ForegroundColor White
            Write-Host "                $([math]::Round($swapUsadoBytes / 1GB, 2)) GB" -ForegroundColor Red
            Write-Host "                $porcentajeUsadoSwap%" -ForegroundColor Red
            Write-Host ""
            Write-Host "Swap Libre:     $swapLibreBytes bytes" -ForegroundColor White
            Write-Host "                $([math]::Round($swapLibreBytes / 1GB, 2)) GB" -ForegroundColor Green
            Write-Host "                $porcentajeLibreSwap%" -ForegroundColor Green
            
        } else {
            Write-Host "================================================================" -ForegroundColor Cyan
            Write-Host "                 SWAP (ARCHIVO DE PAGINACION)                   " -ForegroundColor Cyan
            Write-Host "================================================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "No se detecto archivo de paginacion (swap) configurado." -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "ERROR: No se pudo obtener informacion de memoria." -ForegroundColor Red
        Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# OPCION 5: BACKUP A USB CON CATALOGO
# ==============================================================================
function Opcion5-Backup {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  OPCION 5: BACKUP DE DIRECTORIO A USB" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    
    try {
        # Mostrar unidades removibles disponibles
        Write-Host "Buscando unidades USB disponibles..." -ForegroundColor Yellow
        Write-Host ""
        
        $unidadesUSB = Get-Volume | Where-Object { 
            $_.DriveType -eq 'Removable' -and $_.DriveLetter -ne $null 
        }
        
        if ($unidadesUSB.Count -eq 0) {
            Write-Host "ADVERTENCIA: No se detectaron unidades USB conectadas." -ForegroundColor Yellow
            Write-Host "Por favor, conecte una unidad USB e intente nuevamente." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Desea continuar de todas formas? (S/N): " -ForegroundColor Yellow -NoNewline
            $continuar = Read-Host
            if ($continuar -ne 'S' -and $continuar -ne 's') {
                return
            }
        } else {
            Write-Host "Unidades USB detectadas:" -ForegroundColor Cyan
            foreach ($usb in $unidadesUSB) {
                $etiqueta = if ($usb.FileSystemLabel) { $usb.FileSystemLabel } else { "Sin etiqueta" }
                $espacio = [math]::Round($usb.SizeRemaining / 1GB, 2)
                Write-Host "  [$($usb.DriveLetter):] - $etiqueta - $espacio GB disponibles" -ForegroundColor Green
            }
            Write-Host ""
        }
        
        # Solicitar directorio origen
        Write-Host "Ingrese la ruta completa del directorio a respaldar:" -ForegroundColor Yellow
        Write-Host "(Ejemplo: C:\Users\Usuario\Documentos)" -ForegroundColor Gray
        Write-Host "Ruta origen: " -ForegroundColor Yellow -NoNewline
        $directorioOrigen = Read-Host
        
        # Validar directorio origen
        if (-not (Test-Path $directorioOrigen)) {
            Write-Host ""
            Write-Host "ERROR: El directorio origen no existe: $directorioOrigen" -ForegroundColor Red
            return
        }
        
        if (-not (Get-Item $directorioOrigen).PSIsContainer) {
            Write-Host ""
            Write-Host "ERROR: La ruta especificada no es un directorio." -ForegroundColor Red
            return
        }
        
        # Solicitar directorio destino
        Write-Host ""
        Write-Host "Ingrese la ruta completa del destino en la USB:" -ForegroundColor Yellow
        Write-Host "(Ejemplo: E:\Backup_Documentos)" -ForegroundColor Gray
        Write-Host "Ruta destino: " -ForegroundColor Yellow -NoNewline
        $directorioDestino = Read-Host
        
        # Crear directorio destino si no existe
        if (-not (Test-Path $directorioDestino)) {
            Write-Host ""
            Write-Host "El directorio destino no existe. Creando..." -ForegroundColor Yellow
            New-Item -Path $directorioDestino -ItemType Directory -Force | Out-Null
        }
        
        # Confirmar operacion
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host "                   CONFIRMACION DE BACKUP                       " -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Origen:  $directorioOrigen" -ForegroundColor Cyan
        Write-Host "Destino: $directorioDestino" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Desea continuar con el backup? (S/N): " -ForegroundColor Yellow -NoNewline
        $confirmar = Read-Host
        
        if ($confirmar -ne 'S' -and $confirmar -ne 's') {
            Write-Host ""
            Write-Host "Operacion cancelada por el usuario." -ForegroundColor Yellow
            return
        }
        
        # Realizar backup
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "              INICIANDO PROCESO DE BACKUP...                    " -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host ""
        
        $inicioBackup = Get-Date
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Copiando archivos..." -ForegroundColor Yellow
        
        # Copiar archivos
        $origenPath = Join-Path $directorioOrigen "*"
        Copy-Item -Path $origenPath -Destination $directorioDestino -Recurse -Force -ErrorAction SilentlyContinue
        
        $finBackup = Get-Date
        $duracion = ($finBackup - $inicioBackup).TotalSeconds
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Copia completada en $([math]::Round($duracion, 2)) segundos." -ForegroundColor Green
        Write-Host ""
        
        # Generar catalogo
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Generando catalogo de archivos..." -ForegroundColor Yellow
        
        $catalogoPath = Join-Path $directorioDestino "catalogo_backup.txt"
        $catalogoCSVPath = Join-Path $directorioDestino "catalogo_backup.csv"
        
        # Obtener todos los archivos del backup
        $archivosBackup = Get-ChildItem -Path $directorioDestino -Recurse -File | Where-Object { 
            $_.Name -ne "catalogo_backup.txt" -and $_.Name -ne "catalogo_backup.csv" 
        }
        
        # Crear catalogo en formato texto
        $catalogoContenido = @()
        $catalogoContenido += "================================================================"
        $catalogoContenido += "        CATALOGO DE BACKUP - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        $catalogoContenido += "================================================================"
        $catalogoContenido += ""
        $catalogoContenido += "Directorio origen:  $directorioOrigen"
        $catalogoContenido += "Directorio destino: $directorioDestino"
        $catalogoContenido += "Fecha de backup:    $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        $catalogoContenido += "Total de archivos:  $($archivosBackup.Count)"
        $catalogoContenido += ""
        $catalogoContenido += "================================================================"
        $catalogoContenido += "LISTA DE ARCHIVOS:"
        $catalogoContenido += "================================================================"
        $catalogoContenido += ""
        
        # Crear catalogo CSV
        $catalogoCSV = @()
        
        foreach ($archivo in $archivosBackup) {
            # Obtener ruta relativa
            $rutaRelativa = $archivo.FullName.Replace($directorioDestino, "").TrimStart('\')
            
            # Agregar a catalogo de texto
            $catalogoContenido += "Archivo: $rutaRelativa"
            $catalogoContenido += "  Tamano: $($archivo.Length) bytes"
            $catalogoContenido += "  Tamano: $([math]::Round($archivo.Length / 1MB, 2)) MB"
            $catalogoContenido += "  Ultima modificacion: $($archivo.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss'))"
            $catalogoContenido += ""
            
            # Agregar a catalogo CSV
            $catalogoCSV += [PSCustomObject]@{
                'Nombre' = $archivo.Name
                'Ruta_Relativa' = $rutaRelativa
                'Tamano_Bytes' = $archivo.Length
                'Tamano_MB' = [math]::Round($archivo.Length / 1MB, 2)
                'Fecha_Modificacion' = $archivo.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')
                'Fecha_Creacion' = $archivo.CreationTime.ToString('dd/MM/yyyy HH:mm:ss')
            }
        }
        
        # Agregar resumen al final
        $tamanoTotal = ($archivosBackup | Measure-Object -Property Length -Sum).Sum
        $catalogoContenido += "================================================================"
        $catalogoContenido += "RESUMEN:"
        $catalogoContenido += "================================================================"
        $catalogoContenido += "Total de archivos: $($archivosBackup.Count)"
        $catalogoContenido += "Tamano total: $tamanoTotal bytes"
        $catalogoContenido += "Tamano total: $([math]::Round($tamanoTotal / 1MB, 2)) MB"
        $catalogoContenido += "Tamano total: $([math]::Round($tamanoTotal / 1GB, 2)) GB"
        $catalogoContenido += "Duracion del backup: $([math]::Round($duracion, 2)) segundos"
        $catalogoContenido += ""
        
        # Guardar catalogos
        $catalogoContenido | Out-File -FilePath $catalogoPath -Encoding UTF8
        $catalogoCSV | Export-Csv -Path $catalogoCSVPath -NoTypeInformation -Encoding UTF8
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Catalogo generado exitosamente." -ForegroundColor Green
        Write-Host ""
        
        # Mostrar resumen
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "                  BACKUP COMPLETADO                             " -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Archivos copiados:  $($archivosBackup.Count)" -ForegroundColor Green
        Write-Host "Tamano total:       $tamanoTotal bytes" -ForegroundColor Green
        Write-Host "Tamano total:       $([math]::Round($tamanoTotal / 1MB, 2)) MB" -ForegroundColor Green
        Write-Host "Duracion:           $([math]::Round($duracion, 2)) segundos" -ForegroundColor Green
        Write-Host ""
        Write-Host "Catalogos generados:" -ForegroundColor White
        Write-Host "  - $catalogoPath" -ForegroundColor Cyan
        Write-Host "  - $catalogoCSVPath" -ForegroundColor Cyan
        
    } catch {
        Write-Host ""
        Write-Host "ERROR: No se pudo completar el backup." -ForegroundColor Red
        Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# PROGRAMA PRINCIPAL
# ==============================================================================

# Verificar permisos de administrador
$esAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $esAdmin) {
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "  ADVERTENCIA: No se esta ejecutando como administrador        " -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Algunas funciones pueden no estar disponibles." -ForegroundColor Yellow
    Write-Host "Para mejor funcionalidad, ejecute PowerShell como administrador." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Bucle principal del menu
do {
    Mostrar-Menu
    Write-Host "Seleccione una opcion [0-5]: " -ForegroundColor White -NoNewline
    $opcion = Read-Host
    
    switch ($opcion) {
        '1' { Opcion1-Usuarios }
        '2' { Opcion2-Discos }
        '3' { Opcion3-ArchivosGrandes }
        '4' { Opcion4-Memoria }
        '5' { Opcion5-Backup }
        '0' { 
            Clear-Host
            Write-Host ""
            Write-Host "================================================================" -ForegroundColor Cyan
            Write-Host "     Gracias por usar la Herramienta de Administracion         " -ForegroundColor Cyan
            Write-Host "                   Hasta pronto!                                " -ForegroundColor Cyan
            Write-Host "================================================================" -ForegroundColor Cyan
            Write-Host ""
            exit 
        }
        default { 
            Write-Host ""
            Write-Host "Opcion invalida. Seleccione una opcion entre 0 y 5." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
    
} while ($true)
