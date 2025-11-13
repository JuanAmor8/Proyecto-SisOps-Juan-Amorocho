#==============================================================================
# HERRAMIENTA DE ADMINISTRACIÓN DE DATA CENTER - PowerShell
# Sistema Operativo: Windows
# Autor: Administrador de Sistemas
# Descripción: Menú interactivo con 5 opciones para administración de servidores
#==============================================================================

# Configuración de colores y formato
$host.UI.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.ForegroundColor = "White"
Clear-Host

#==============================================================================
# FUNCIÓN: MOSTRAR MENÚ PRINCIPAL
#==============================================================================
function Mostrar-Menu {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     HERRAMIENTA DE ADMINISTRACIÓN DE DATA CENTER - v1.0       ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Usuarios del sistema y último login" -ForegroundColor Yellow
    Write-Host "  [2] Información de discos y filesystems" -ForegroundColor Yellow
    Write-Host "  [3] Top 10 archivos más grandes" -ForegroundColor Yellow
    Write-Host "  [4] Memoria RAM y Swap en uso" -ForegroundColor Yellow
    Write-Host "  [5] Backup de directorio a USB" -ForegroundColor Yellow
    Write-Host "  [0] Salir" -ForegroundColor Red
    Write-Host ""
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

#==============================================================================
# OPCIÓN 1: USUARIOS Y ÚLTIMO LOGIN
#==============================================================================
function Opcion1-Usuarios {
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  OPCIÓN 1: USUARIOS DEL SISTEMA Y ÚLTIMO LOGIN" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    
    try {
        Write-Host "Obteniendo información de usuarios..." -ForegroundColor Yellow
        Write-Host ""
        
        # Obtener todos los usuarios locales
        $usuarios = Get-LocalUser
        
        # Crear array para almacenar resultados
        $resultados = @()
        
        foreach ($usuario in $usuarios) {
            $ultimoLogin = "Nunca"
            
            # Intentar obtener el último login desde el registro de eventos
            # EventID 4624 = Login exitoso
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
                # Si no se puede acceder al log de seguridad, usar información del usuario
                if ($usuario.LastLogon) {
                    $ultimoLogin = $usuario.LastLogon.ToString("dd/MM/yyyy HH:mm:ss")
                }
            }
            
            $resultados += [PSCustomObject]@{
                'Usuario' = $usuario.Name
                'Nombre Completo' = if ($usuario.FullName) { $usuario.FullName } else { "N/A" }
                'Habilitado' = if ($usuario.Enabled) { "Sí" } else { "No" }
                'Último Login' = $ultimoLogin
            }
        }
        
        # Mostrar resultados en formato tabla
        $resultados | Format-Table -AutoSize
        
        Write-Host ""
        Write-Host "Total de usuarios encontrados: $($resultados.Count)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "ERROR: No se pudo obtener información de usuarios." -ForegroundColor Red
        Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#==============================================================================
# OPCIÓN 2: INFORMACIÓN DE DISCOS Y FILESYSTEMS
#==============================================================================
function Opcion2-Discos {
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  OPCIÓN 2: INFORMACIÓN DE DISCOS Y FILESYSTEMS" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    
    try {
        Write-Host "Obteniendo información de discos..." -ForegroundColor Yellow
        Write-Host ""
        
        # Obtener información de volúmenes
        $volumenes = Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.Size -gt 0 }
        
        # Crear array para resultados
        $resultados = @()
        
        foreach ($vol in $volumenes) {
            $tamañoBytes = $vol.Size
            $libreBytes = $vol.SizeRemaining
            $usadoBytes = $tamañoBytes - $libreBytes
            $porcentajeLibre = [math]::Round(($libreBytes / $tamañoBytes) * 100, 2)
            
            $resultados += [PSCustomObject]@{
                'Disco' = "$($vol.DriveLetter):"
                'Etiqueta' = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "Sin etiqueta" }
                'Sistema de Archivos' = $vol.FileSystem
                'Tamaño Total (Bytes)' = "{0:N0}" -f $tamañoBytes
                'Tamaño Total (GB)' = [math]::Round($tamañoBytes / 1GB, 2)
                'Espacio Usado (Bytes)' = "{0:N0}" -f $usadoBytes
                'Espacio Libre (Bytes)' = "{0:N0}" -f $libreBytes
                'Espacio Libre (GB)' = [math]::Round($libreBytes / 1GB, 2)
                '% Libre' = "$porcentajeLibre%"
            }
        }
        
        # Mostrar resultados
        $resultados | Format-Table -Property 'Disco', 'Etiqueta', 'Sistema de Archivos', 'Tamaño Total (GB)', 'Espacio Libre (GB)', '% Libre' -AutoSize
        
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "INFORMACIÓN DETALLADA EN BYTES:" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        
        foreach ($res in $resultados) {
            Write-Host ""
            Write-Host "Disco: $($res.Disco) - $($res.Etiqueta)" -ForegroundColor Yellow
            Write-Host "  Tamaño Total: $($res.'Tamaño Total (Bytes)') bytes" -ForegroundColor White
            Write-Host "  Espacio Libre: $($res.'Espacio Libre (Bytes)') bytes" -ForegroundColor Green
            Write-Host "  Espacio Usado: $($res.'Espacio Usado (Bytes)') bytes" -ForegroundColor Magenta
        }
        
        Write-Host ""
        Write-Host "Total de discos encontrados: $($resultados.Count)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "ERROR: No se pudo obtener información de discos." -ForegroundColor Red
        Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#==============================================================================
# OPCIÓN 3: TOP 10 ARCHIVOS MÁS GRANDES
#==============================================================================
function Opcion3-ArchivosGrandes {
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  OPCIÓN 3: TOP 10 ARCHIVOS MÁS GRANDES" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    
    try {
        # Mostrar discos disponibles
        $discos = Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.Size -gt 0 }
        
        Write-Host "Discos disponibles:" -ForegroundColor Yellow
        foreach ($disco in $discos) {
            $etiqueta = if ($disco.FileSystemLabel) { $disco.FileSystemLabel } else { "Sin etiqueta" }
            Write-Host "  [$($disco.DriveLetter):] - $etiqueta - $([math]::Round($disco.Size / 1GB, 2)) GB" -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "Ingrese la letra del disco a analizar (ej: C): " -ForegroundColor Yellow -NoNewline
        $letraDisco = Read-Host
        
        # Validar entrada
        if ($letraDisco -match '^[A-Za-z]$') {
            $letraDisco = $letraDisco.ToUpper()
            $rutaDisco = "$letraDisco`:\"
            
            if (Test-Path $rutaDisco) {
                Write-Host ""
                Write-Host "Buscando archivos más grandes en $rutaDisco..." -ForegroundColor Yellow
                Write-Host "Este proceso puede tardar varios minutos dependiendo del tamaño del disco..." -ForegroundColor Gray
                Write-Host ""
                
                # Buscar archivos y ordenar por tamaño
                $archivosGrandes = Get-ChildItem -Path $rutaDisco -Recurse -File -ErrorAction SilentlyContinue | 
                    Sort-Object Length -Descending | 
                    Select-Object -First 10
                
                if ($archivosGrandes.Count -gt 0) {
                    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                    Write-Host "TOP 10 ARCHIVOS MÁS GRANDES EN $rutaDisco" -ForegroundColor Cyan
                    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                    Write-Host ""
                    
                    $contador = 1
                    foreach ($archivo in $archivosGrandes) {
                        $tamañoBytes = $archivo.Length
                        $tamañoMB = [math]::Round($tamañoBytes / 1MB, 2)
                        $tamañoGB = [math]::Round($tamañoBytes / 1GB, 2)
                        
                        Write-Host "[$contador] " -ForegroundColor Yellow -NoNewline
                        Write-Host "$($archivo.FullName)" -ForegroundColor White
                        Write-Host "    Tamaño: " -ForegroundColor Gray -NoNewline
                        Write-Host "{0:N0} bytes" -f $tamañoBytes -ForegroundColor Cyan -NoNewline
                        Write-Host " ($tamañoMB MB / $tamañoGB GB)" -ForegroundColor Green
                        Write-Host ""
                        
                        $contador++
                    }
                } else {
                    Write-Host "No se encontraron archivos en el disco especificado." -ForegroundColor Yellow
                }
                
            } else {
                Write-Host ""
                Write-Host "ERROR: El disco $rutaDisco no existe o no está accesible." -ForegroundColor Red
            }
        } else {
            Write-Host ""
            Write-Host "ERROR: Entrada inválida. Debe ingresar una letra de disco (A-Z)." -ForegroundColor Red
        }
        
    } catch {
        Write-Host "ERROR: No se pudo completar la búsqueda." -ForegroundColor Red
        Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#==============================================================================
# OPCIÓN 4: MEMORIA RAM Y SWAP
#==============================================================================
function Opcion4-Memoria {
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  OPCIÓN 4: MEMORIA RAM Y SWAP (PAGEFILE)" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    
    try {
        Write-Host "Obteniendo información de memoria..." -ForegroundColor Yellow
        Write-Host ""
        
        # ============== MEMORIA RAM ==============
        $os = Get-CimInstance Win32_OperatingSystem
        
        # Convertir de KB a Bytes
        $memoriaLibreBytes = $os.FreePhysicalMemory * 1KB
        $memoriaTotalBytes = $os.TotalVisibleMemorySize * 1KB
        $memoriaUsadaBytes = $memoriaTotalBytes - $memoriaLibreBytes
        
        $porcentajeLibreRAM = [math]::Round(($memoriaLibreBytes / $memoriaTotalBytes) * 100, 2)
        $porcentajeUsadoRAM = [math]::Round(($memoriaUsadaBytes / $memoriaTotalBytes) * 100, 2)
        
        Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                    MEMORIA RAM                            ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Memoria Total:      " -NoNewline -ForegroundColor White
        Write-Host "{0:N0} bytes" -f $memoriaTotalBytes -ForegroundColor Yellow -NoNewline
        Write-Host " ($([math]::Round($memoriaTotalBytes / 1GB, 2)) GB)" -ForegroundColor Green
        
        Write-Host "Memoria Usada:      " -NoNewline -ForegroundColor White
        Write-Host "{0:N0} bytes" -f $memoriaUsadaBytes -ForegroundColor Yellow -NoNewline
        Write-Host " ($([math]::Round($memoriaUsadaBytes / 1GB, 2)) GB) - $porcentajeUsadoRAM%" -ForegroundColor Red
        
        Write-Host "Memoria Libre:      " -NoNewline -ForegroundColor White
        Write-Host "{0:N0} bytes" -f $memoriaLibreBytes -ForegroundColor Yellow -NoNewline
        Write-Host " ($([math]::Round($memoriaLibreBytes / 1GB, 2)) GB) - $porcentajeLibreRAM%" -ForegroundColor Green
        
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
            
            Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║                 SWAP (ARCHIVO DE PAGINACIÓN)              ║" -ForegroundColor Cyan
            Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Ubicación:          " -NoNewline -ForegroundColor White
            Write-Host "$($pageFile.Name)" -ForegroundColor Cyan
            
            Write-Host "Swap Total:         " -NoNewline -ForegroundColor White
            Write-Host "{0:N0} bytes" -f $swapTotalBytes -ForegroundColor Yellow -NoNewline
            Write-Host " ($([math]::Round($swapTotalBytes / 1GB, 2)) GB)" -ForegroundColor Green
            
            Write-Host "Swap en Uso:        " -NoNewline -ForegroundColor White
            Write-Host "{0:N0} bytes" -f $swapUsadoBytes -ForegroundColor Yellow -NoNewline
            Write-Host " ($([math]::Round($swapUsadoBytes / 1GB, 2)) GB) - $porcentajeUsadoSwap%" -ForegroundColor Red
            
            Write-Host "Swap Libre:         " -NoNewline -ForegroundColor White
            Write-Host "{0:N0} bytes" -f $swapLibreBytes -ForegroundColor Yellow -NoNewline
            Write-Host " ($([math]::Round($swapLibreBytes / 1GB, 2)) GB) - $porcentajeLibreSwap%" -ForegroundColor Green
            
        } else {
            Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║                 SWAP (ARCHIVO DE PAGINACIÓN)              ║" -ForegroundColor Cyan
            Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "No se detectó archivo de paginación (swap) configurado." -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "ERROR: No se pudo obtener información de memoria." -ForegroundColor Red
        Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#==============================================================================
# OPCIÓN 5: BACKUP A USB CON CATÁLOGO
#==============================================================================
function Opcion5-Backup {
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  OPCIÓN 5: BACKUP DE DIRECTORIO A USB" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
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
            Write-Host "¿Desea continuar de todas formas? (S/N): " -ForegroundColor Yellow -NoNewline
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
        
        # Confirmar operación
        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║                   CONFIRMACIÓN DE BACKUP                  ║" -ForegroundColor Yellow
        Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Origen:  " -NoNewline -ForegroundColor White
        Write-Host "$directorioOrigen" -ForegroundColor Cyan
        Write-Host "Destino: " -NoNewline -ForegroundColor White
        Write-Host "$directorioDestino" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "¿Desea continuar con el backup? (S/N): " -ForegroundColor Yellow -NoNewline
        $confirmar = Read-Host
        
        if ($confirmar -ne 'S' -and $confirmar -ne 's') {
            Write-Host ""
            Write-Host "Operación cancelada por el usuario." -ForegroundColor Yellow
            return
        }
        
        # Realizar backup
        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║              INICIANDO PROCESO DE BACKUP...               ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        
        $inicioBackup = Get-Date
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Copiando archivos..." -ForegroundColor Yellow
        
        # Copiar archivos
        Copy-Item -Path "$directorioOrigen\*" -Destination $directorioDestino -Recurse -Force -ErrorAction SilentlyContinue
        
        $finBackup = Get-Date
        $duracion = ($finBackup - $inicioBackup).TotalSeconds
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Copia completada en $([math]::Round($duracion, 2)) segundos." -ForegroundColor Green
        Write-Host ""
        
        # Generar catálogo
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Generando catálogo de archivos..." -ForegroundColor Yellow
        
        $catalogoPath = Join-Path $directorioDestino "catalogo_backup.txt"
        $catalogoCSVPath = Join-Path $directorioDestino "catalogo_backup.csv"
        
        # Obtener todos los archivos del backup
        $archivosBackup = Get-ChildItem -Path $directorioDestino -Recurse -File | Where-Object { 
            $_.Name -ne "catalogo_backup.txt" -and $_.Name -ne "catalogo_backup.csv" 
        }
        
        # Crear catálogo en formato texto
        $catalogoContenido = @()
        $catalogoContenido += "═══════════════════════════════════════════════════════════════"
        $catalogoContenido += "        CATÁLOGO DE BACKUP - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        $catalogoContenido += "═══════════════════════════════════════════════════════════════"
        $catalogoContenido += ""
        $catalogoContenido += "Directorio origen:  $directorioOrigen"
        $catalogoContenido += "Directorio destino: $directorioDestino"
        $catalogoContenido += "Fecha de backup:    $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        $catalogoContenido += "Total de archivos:  $($archivosBackup.Count)"
        $catalogoContenido += ""
        $catalogoContenido += "═══════════════════════════════════════════════════════════════"
        $catalogoContenido += "LISTA DE ARCHIVOS:"
        $catalogoContenido += "═══════════════════════════════════════════════════════════════"
        $catalogoContenido += ""
        
        # Crear catálogo CSV
        $catalogoCSV = @()
        
        foreach ($archivo in $archivosBackup) {
            # Obtener ruta relativa
            $rutaRelativa = $archivo.FullName.Replace($directorioDestino, "").TrimStart('\')
            
            # Agregar a catálogo de texto
            $catalogoContenido += "Archivo: $rutaRelativa"
            $catalogoContenido += "  Tamaño: {0:N0} bytes ({1} MB)" -f $archivo.Length, ([math]::Round($archivo.Length / 1MB, 2))
            $catalogoContenido += "  Última modificación: $($archivo.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss'))"
            $catalogoContenido += ""
            
            # Agregar a catálogo CSV
            $catalogoCSV += [PSCustomObject]@{
                'Nombre' = $archivo.Name
                'Ruta Relativa' = $rutaRelativa
                'Tamaño (Bytes)' = $archivo.Length
                'Tamaño (MB)' = [math]::Round($archivo.Length / 1MB, 2)
                'Fecha Modificación' = $archivo.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')
                'Fecha Creación' = $archivo.CreationTime.ToString('dd/MM/yyyy HH:mm:ss')
            }
        }
        
        # Agregar resumen al final
        $tamañoTotal = ($archivosBackup | Measure-Object -Property Length -Sum).Sum
        $catalogoContenido += "═══════════════════════════════════════════════════════════════"
        $catalogoContenido += "RESUMEN:"
        $catalogoContenido += "═══════════════════════════════════════════════════════════════"
        $catalogoContenido += "Total de archivos: $($archivosBackup.Count)"
        $catalogoContenido += "Tamaño total: {0:N0} bytes ({1} MB / {2} GB)" -f $tamañoTotal, ([math]::Round($tamañoTotal / 1MB, 2)), ([math]::Round($tamañoTotal / 1GB, 2))
        $catalogoContenido += "Duración del backup: $([math]::Round($duracion, 2)) segundos"
        $catalogoContenido += ""
        
        # Guardar catálogos
        $catalogoContenido | Out-File -FilePath $catalogoPath -Encoding UTF8
        $catalogoCSV | Export-Csv -Path $catalogoCSVPath -NoTypeInformation -Encoding UTF8
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Catálogo generado exitosamente." -ForegroundColor Green
        Write-Host ""
        
        # Mostrar resumen
        Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                  BACKUP COMPLETADO                        ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Archivos copiados:  " -NoNewline -ForegroundColor White
        Write-Host "$($archivosBackup.Count)" -ForegroundColor Green
        Write-Host "Tamaño total:       " -NoNewline -ForegroundColor White
        Write-Host "{0:N0} bytes ({1} MB)" -f $tamañoTotal, ([math]::Round($tamañoTotal / 1MB, 2)) -ForegroundColor Green
        Write-Host "Duración:           " -NoNewline -ForegroundColor White
        Write-Host "$([math]::Round($duracion, 2)) segundos" -ForegroundColor Green
        Write-Host ""
        Write-Host "Catálogos generados:" -ForegroundColor White
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

#==============================================================================
# PROGRAMA PRINCIPAL
#==============================================================================

# Verificar permisos de administrador (recomendado para algunas operaciones)
$esAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $esAdmin) {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  ADVERTENCIA: No se está ejecutando como administrador" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Algunas funciones pueden no estar disponibles o mostrar información limitada." -ForegroundColor Yellow
    Write-Host "Para mejor funcionalidad, ejecute PowerShell como administrador." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar de todas formas..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Bucle principal del menú
do {
    Mostrar-Menu
    Write-Host "Seleccione una opción [0-5]: " -ForegroundColor White -NoNewline
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
            Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║     Gracias por usar la Herramienta de Administración         ║" -ForegroundColor Cyan
            Write-Host "║                   ¡Hasta pronto!                               ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            exit 
        }
        default { 
            Write-Host ""
            Write-Host "Opción inválida. Por favor seleccione una opción entre 0 y 5." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
    
} while ($true)

