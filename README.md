# Herramientas de Administración de Data Center

**Autor:** Juan Camilo Amorocho Murillo  
**Curso:** Sistemas Operativos  
**Fecha:** 13 De Noviembre De 2025

## Descripción del Proyecto

Este proyecto consiste en la implementación de dos herramientas de línea de comandos para la administración de servidores en un data center. Una herramienta está desarrollada en PowerShell para entornos Windows, y la otra en BASH para entornos Linux/Unix.

Ambas herramientas proporcionan un menú interactivo con cinco opciones principales para facilitar las labores administrativas del sistema.

## Contenido del Repositorio

```
.
├── menu-administrador.ps1    # Script para Windows (PowerShell)
├── menu-administrador.sh     # Script para Linux (BASH)
└── README.md                 # Este archivo
```

## Funcionalidades Implementadas

### Opción 1: Usuarios del Sistema y Último Login
Despliega una lista de todos los usuarios creados en el sistema, mostrando:
- Nombre de usuario
- Nombre completo
- Fecha y hora del último inicio de sesión

### Opción 2: Información de Discos y Filesystems
Muestra información detallada de los discos conectados al sistema:
- Nombre del filesystem o disco
- Tipo de sistema de archivos
- Tamaño total en bytes
- Espacio libre en bytes
- Porcentaje de uso

### Opción 3: Top 10 Archivos Más Grandes
Permite al usuario especificar un disco o filesystem y despliega:
- Los 10 archivos de mayor tamaño
- Ruta completa de cada archivo
- Tamaño en bytes, megabytes y gigabytes

### Opción 4: Información de Memoria
Muestra el estado actual de la memoria del sistema:
- Memoria RAM total, usada y libre (en bytes y porcentaje)
- Memoria Swap total, en uso y libre (en bytes y porcentaje)

### Opción 5: Backup de Directorio
Realiza una copia de seguridad de un directorio especificado:
- Copia todos los archivos del directorio origen al destino
- Genera un catálogo en formato texto (.txt)
- Genera un catálogo en formato CSV (.csv)
- Los catálogos incluyen: nombre, tamaño y fecha de última modificación de cada archivo

## Requisitos del Sistema

### Para Windows (PowerShell)
- Windows 10 o superior
- PowerShell 5.1 o superior
- Permisos de administrador (recomendado)

### Para Linux (BASH)
- Cualquier distribución Linux moderna
- BASH 4.0 o superior
- Comandos del sistema: df, find, du, grep, awk, stat
- Permisos root/sudo (recomendado)

## Instalación y Uso

### Windows (PowerShell)

1. Descargar el archivo `menu-administrador.ps1`

2. Abrir PowerShell como administrador

3. Configurar política de ejecución si es necesario:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

4. Navegar al directorio del script:
```powershell
cd ruta\del\directorio
```

5. Ejecutar el script:
```powershell
.\menu-administrador.ps1
```

### Linux (BASH)

1. Descargar el archivo `menu-administrador.sh`

2. Dar permisos de ejecución:
```bash
chmod +x menu-administrador.sh
```

3. Ejecutar el script con sudo:
```bash
sudo ./menu-administrador.sh
```

## Comandos y Tecnologías Utilizadas

### PowerShell (Windows)

| Funcionalidad | Comandos/Cmdlets |
|---------------|------------------|
| Usuarios | `Get-LocalUser`, `Get-WinEvent` |
| Discos | `Get-Volume`, `Get-PSDrive` |
| Archivos | `Get-ChildItem`, `Sort-Object` |
| Memoria | `Get-CimInstance Win32_OperatingSystem`, `Get-CimInstance Win32_PageFileUsage` |
| Backup | `Copy-Item`, `Get-ChildItem`, `Out-File`, `Export-Csv` |

### BASH (Linux)

| Funcionalidad | Comandos |
|---------------|----------|
| Usuarios | `/etc/passwd`, `last`, `lastlog` |
| Discos | `df`, `lsblk` |
| Archivos | `find`, `du`, `sort` |
| Memoria | `/proc/meminfo`, `free`, `swapon` |
| Backup | `cp`, `rsync`, `stat` |

## Estructura del Código

Ambos scripts siguen una estructura modular similar:

1. **Declaración de variables y configuración inicial**
2. **Función de menú principal**
3. **Cinco funciones para cada opción del menú**
4. **Función de pausa para mejor experiencia de usuario**
5. **Bucle principal del programa**

Cada función está documentada con comentarios que explican su propósito y funcionamiento.

## Características Técnicas

### Validación de Datos
- Verificación de rutas de directorios
- Validación de entrada del usuario
- Manejo de errores con try-catch (PowerShell) o condicionales (BASH)

### Formato de Salida
- Información presentada en bytes para precisión técnica
- Conversiones adicionales a GB/MB para legibilidad
- Uso de colores para mejorar la visualización
- Formato tabular para datos estructurados

### Generación de Catálogos
Los catálogos de backup incluyen:
- Formato TXT: Legible para humanos con toda la información
- Formato CSV: Compatible con hojas de cálculo para análisis
- Metadatos: Fecha de backup, número de archivos, tamaño total

## Notas de Implementación

### Diferencias entre Versiones

Aunque ambos scripts realizan las mismas funciones, existen diferencias inherentes a cada sistema operativo:

**Windows:**
- Usa Event Log para obtener historial de login
- Identifica discos por letras (C:, D:, etc.)
- El archivo de paginación (pagefile.sys) actúa como swap

**Linux:**
- Usa archivos de log del sistema (/var/log/auth.log)
- Identifica discos por puntos de montaje (/, /home, etc.)
- Usa particiones swap dedicadas

### Permisos y Seguridad

Para funcionalidad completa, ambos scripts requieren permisos elevados:
- **Windows:** Ejecutar PowerShell como Administrador
- **Linux:** Ejecutar con sudo o como root

Sin permisos elevados, algunas funciones pueden tener limitaciones en el acceso a logs del sistema o ciertos directorios.

## Limitaciones Conocidas

1. La búsqueda de archivos grandes puede tardar varios minutos en discos de gran tamaño
2. Los logs de usuario pueden estar vacíos si el usuario nunca ha iniciado sesión
3. En sistemas sin swap configurado, la opción 4 indicará que no hay swap disponible
4. El backup no incluye compresión de archivos

## Conclusiones

Este proyecto demuestra el uso práctico de scripting en dos shells diferentes para realizar tareas comunes de administración de sistemas. Ambas herramientas proporcionan información crítica del sistema de manera rápida y accesible, facilitando el trabajo del administrador de sistemas en un entorno de data center.

Las implementaciones muestran cómo diferentes sistemas operativos abordan las mismas tareas administrativas utilizando sus herramientas nativas, destacando tanto las similitudes conceptuales como las diferencias técnicas entre Windows y Linux.

## Autor

**Juan Camilo Amorocho Murillo**

Proyecto desarrollado como parte del curso de Sistemas Operativos.

---

**Repositorio:** https://github.com/JuanAmor8/Proyecto-SisOps-Juan-Amorocho  


