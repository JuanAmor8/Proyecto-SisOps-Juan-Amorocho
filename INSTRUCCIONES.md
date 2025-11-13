# Instrucciones de Uso Detalladas

## Tabla de Contenidos
1. [Configuración Inicial en Windows](#configuración-inicial-en-windows)
2. [Configuración Inicial en Linux](#configuración-inicial-en-linux)
3. [Guía de Uso por Opción](#guía-de-uso-por-opción)
4. [Solución de Problemas](#solución-de-problemas)

---

## Configuración Inicial en Windows

### Paso 1: Verificar PowerShell
Abrir PowerShell y ejecutar:
```powershell
$PSVersionTable.PSVersion
```
Debe ser versión 5.1 o superior.

### Paso 2: Habilitar Ejecución de Scripts
Como administrador, ejecutar:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

### Paso 3: Ubicar el Script
Colocar `menu-administrador.ps1` en una carpeta accesible, por ejemplo:
```
C:\Scripts\menu-administrador.ps1
```

### Paso 4: Ejecutar
Clic derecho en PowerShell > Ejecutar como Administrador
```powershell
cd C:\Scripts
.\menu-administrador.ps1
```

---

## Configuración Inicial en Linux

### Paso 1: Verificar BASH
```bash
bash --version
```

### Paso 2: Transferir el Script
Opciones para transferir el script a Linux:

**Opción A - SCP desde Windows:**
```bash
scp menu-administrador.sh usuario@ip-servidor:/home/usuario/
```

**Opción B - Crear manualmente:**
```bash
nano menu-administrador.sh
# Copiar y pegar el contenido
# Ctrl+O para guardar, Ctrl+X para salir
```

### Paso 3: Dar Permisos
```bash
chmod +x menu-administrador.sh
```

### Paso 4: Ejecutar
```bash
sudo ./menu-administrador.sh
```

---

## Guía de Uso por Opción

### Opción 1: Usuarios y Último Login

**Propósito:** Ver todos los usuarios del sistema y cuándo fue su último acceso.

**Uso:**
1. Seleccionar opción 1
2. El sistema mostrará una tabla automáticamente
3. Presionar cualquier tecla para volver al menú

**Salida esperada:**
```
USUARIO              NOMBRE COMPLETO              ULTIMO LOGIN
juan                 Juan Amorocho                Nov 13 10:30
admin                Administrator                Nov 12 15:20
```

**Notas:**
- "Nunca" indica que el usuario no ha iniciado sesión
- En Windows requiere permisos de administrador para acceder a Security Log

---

### Opción 2: Información de Discos

**Propósito:** Ver el espacio disponible en todos los discos del sistema.

**Uso:**
1. Seleccionar opción 2
2. El sistema mostrará información resumida y detallada
3. Presionar cualquier tecla para continuar

**Salida esperada (Windows):**
```
Disco: C: - Windows
  Tamaño Total: 256060514304 bytes
  Espacio Libre: 102424801280 bytes
  Espacio Usado: 153635713024 bytes
```

**Salida esperada (Linux):**
```
Filesystem: /dev/sda1
  Tipo: ext4
  Punto de montaje: /
  Tamano Total: 107374182400 bytes
  Espacio Libre: 53687091200 bytes
```

---

### Opción 3: Top 10 Archivos Más Grandes

**Propósito:** Identificar qué archivos ocupan más espacio en un disco específico.

**Uso:**
1. Seleccionar opción 3
2. Ver lista de discos disponibles
3. Ingresar letra de disco (Windows: C) o punto de montaje (Linux: /)
4. Esperar mientras el sistema busca (puede tardar varios minutos)
5. Ver resultados
6. Presionar cualquier tecla para continuar

**Ejemplo de entrada:**
- Windows: `C`
- Linux: `/` o `/home`

**Salida esperada:**
```
[1] C:\pagefile.sys
    Tamaño: 8589934592 bytes
            8192.00 MB
            8.00 GB
```

**Advertencias:**
- El proceso puede tardar en discos grandes
- En Linux, buscar en / puede tomar mucho tiempo
- Considerar buscar en subdirectorios específicos (/home, /var)

---

### Opción 4: Memoria RAM y Swap

**Propósito:** Monitorear el uso de memoria del sistema.

**Uso:**
1. Seleccionar opción 4
2. Ver información automáticamente
3. Presionar cualquier tecla para continuar

**Salida esperada:**
```
Memoria Total:  17179869184 bytes
                16.00 GB

Memoria Usada:  8589934592 bytes
                8.00 GB
                50.00%

Swap Total:     4294967296 bytes
                4.00 GB

Swap en Uso:    0 bytes
                0.00 GB
                0.00%
```

**Interpretación:**
- Porcentaje alto de RAM usada (>80%): Normal en sistemas activos
- Swap en uso alto: Puede indicar falta de RAM
- Sin swap configurado: Común en algunas instalaciones modernas

---

### Opción 5: Backup de Directorio

**Propósito:** Crear copia de seguridad de un directorio con catálogo de archivos.

**Uso:**
1. Seleccionar opción 5
2. Ver dispositivos disponibles (USB recomendado)
3. Ingresar ruta del directorio a respaldar
4. Ingresar ruta de destino
5. Confirmar operación (s/n)
6. Esperar a que termine la copia
7. Verificar catálogos generados
8. Presionar cualquier tecla para continuar

**Ejemplo Windows:**
```
Ruta origen: C:\Users\Juan\Documentos
Ruta destino: E:\Backup_Documentos
```

**Ejemplo Linux:**
```
Ruta origen: /home/juan/documentos
Ruta destino: /media/usb/backup
```

**Archivos generados:**
- `catalogo_backup.txt` - Catálogo en formato texto legible
- `catalogo_backup.csv` - Catálogo en formato CSV para Excel

**Contenido de los catálogos:**
- Lista completa de archivos respaldados
- Tamaño de cada archivo en bytes y MB
- Fecha de última modificación
- Resumen con total de archivos y tamaño

---

## Solución de Problemas

### Windows

**Error: "No se puede ejecutar scripts"**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

**Error: "Acceso denegado al Security Log"**
- Ejecutar PowerShell como Administrador
- Clic derecho > Ejecutar como Administrador

**Error: "No se detectaron unidades USB"**
- Conectar USB y esperar a que Windows la reconozca
- Verificar que la unidad tenga letra asignada
- Puede continuar sin USB si especifica otra ruta

---

### Linux

**Error: "Permission denied"**
```bash
chmod +x menu-administrador.sh
sudo ./menu-administrador.sh
```

**Error: "command not found: bc"**
```bash
# Ubuntu/Debian
sudo apt-get install bc

# CentOS/RHEL
sudo yum install bc
```

**Error: "No se pudo crear directorio destino"**
- Verificar que el USB esté montado
- Montar manualmente si es necesario:
```bash
sudo mount /dev/sdb1 /media/usb
```

**El script no muestra colores**
- Terminal no soporta colores ANSI
- Funcionalidad no afectada, solo visualización

---

## Recomendaciones de Uso

### Para Opción 3 (Archivos Grandes)
- En discos grandes (>500GB), considerar subdirectorios específicos
- Cancelar con Ctrl+C si tarda demasiado
- Primera ejecución siempre es más lenta

### Para Opción 5 (Backup)
- Verificar espacio disponible en destino antes de iniciar
- No interrumpir el proceso de copia
- Guardar los catálogos junto con el backup
- Considerar crear backups incrementales periódicamente

### General
- Ejecutar con permisos elevados para funcionalidad completa
- Revisar logs del sistema si hay errores persistentes
- En entornos de producción, probar primero en ambiente de prueba

---

## Preguntas Frecuentes

**¿Puedo ejecutar el script sin permisos de administrador/root?**
Sí, pero algunas funciones tendrán limitaciones. El script mostrará una advertencia.

**¿Los catálogos de backup incluyen subdirectorios?**
Sí, el backup es recursivo e incluye toda la estructura de directorios.

**¿Puedo cancelar una operación en progreso?**
Sí, presionar Ctrl+C cancelará la operación actual y volverá al menú.

**¿El script modifica archivos del sistema?**
No, el script es de solo lectura excepto por la opción 5 que copia archivos al destino especificado.

**¿Funciona en PowerShell 7?**
Sí, el script es compatible con PowerShell 5.1 y superiores, incluyendo PowerShell 7.

**¿Funciona en macOS?**
El script BASH puede funcionar en macOS con algunas limitaciones, ya que algunos comandos tienen diferente sintaxis.

