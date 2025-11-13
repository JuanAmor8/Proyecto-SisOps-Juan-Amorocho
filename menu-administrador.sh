#!/bin/bash

################################################################################
# HERRAMIENTA DE ADMINISTRACION DE DATA CENTER - BASH
# Sistema Operativo: Linux
# Autor: Juan Camilo Amorocho Murillo
# Descripcion: Menu interactivo con 5 opciones para administracion de servidores
################################################################################

# Colores para mejor visualizacion
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

################################################################################
# FUNCION: MOSTRAR MENU PRINCIPAL
################################################################################
mostrar_menu() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}     HERRAMIENTA DE ADMINISTRACION DE DATA CENTER - v1.0       ${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    echo -e "${YELLOW}  [1] Usuarios del sistema y ultimo login${NC}"
    echo -e "${YELLOW}  [2] Informacion de discos y filesystems${NC}"
    echo -e "${YELLOW}  [3] Top 10 archivos mas grandes${NC}"
    echo -e "${YELLOW}  [4] Memoria RAM y Swap en uso${NC}"
    echo -e "${YELLOW}  [5] Backup de directorio a USB${NC}"
    echo -e "${RED}  [0] Salir${NC}"
    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo ""
}

################################################################################
# FUNCION: PAUSAR Y ESPERAR TECLA
################################################################################
pausar() {
    echo ""
    echo -e "${GRAY}Presione cualquier tecla para continuar...${NC}"
    read -n 1 -s
}

################################################################################
# OPCION 1: USUARIOS Y ULTIMO LOGIN
################################################################################
opcion1_usuarios() {
    clear
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}  OPCION 1: USUARIOS DEL SISTEMA Y ULTIMO LOGIN${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Obteniendo informacion de usuarios...${NC}"
    echo ""
    
    # Encabezado de la tabla
    printf "%-20s %-30s %-20s\n" "USUARIO" "NOMBRE COMPLETO" "ULTIMO LOGIN"
    echo "--------------------------------------------------------------------------------"
    
    # Obtener usuarios del sistema (UID >= 1000 son usuarios normales, 0 es root)
    while IFS=: read -r username _ uid _ _ fullname _; do
        # Filtrar usuarios del sistema (normalmente UID >= 1000 o UID = 0 para root)
        if [ "$uid" -ge 1000 ] || [ "$uid" -eq 0 ]; then
            # Obtener ultimo login
            ultimo_login=$(last -1 "$username" 2>/dev/null | head -1 | awk '{
                if ($1 != "") {
                    # Formato: usuario tty fecha hora
                    print $4" "$5" "$6" "$7
                }
            }')
            
            # Si no hay informacion de last, intentar con lastlog
            if [ -z "$ultimo_login" ] || [ "$ultimo_login" = "   " ]; then
                ultimo_login=$(lastlog -u "$username" 2>/dev/null | tail -1 | awk '{
                    if (NF > 3 && $2 != "**Never") {
                        print $4" "$5" "$6" "$7" "$8" "$9
                    } else {
                        print "Nunca"
                    }
                }')
            fi
            
            # Si aun no hay informacion
            if [ -z "$ultimo_login" ] || [ "$ultimo_login" = "   " ]; then
                ultimo_login="Nunca"
            fi
            
            # Limpiar nombre completo (remover comentarios)
            fullname=$(echo "$fullname" | cut -d',' -f1)
            if [ -z "$fullname" ]; then
                fullname="N/A"
            fi
            
            printf "%-20s %-30s %-20s\n" "$username" "$fullname" "$ultimo_login"
        fi
    done < /etc/passwd
    
    echo ""
    total_usuarios=$(awk -F: '{if ($3 >= 1000 || $3 == 0) print $1}' /etc/passwd | wc -l)
    echo -e "${CYAN}Total de usuarios encontrados: $total_usuarios${NC}"
    
    pausar
}

################################################################################
# OPCION 2: INFORMACION DE DISCOS Y FILESYSTEMS
################################################################################
opcion2_discos() {
    clear
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}  OPCION 2: INFORMACION DE DISCOS Y FILESYSTEMS${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Obteniendo informacion de discos...${NC}"
    echo ""
    
    # Mostrar informacion resumida
    echo -e "${CYAN}RESUMEN DE FILESYSTEMS:${NC}"
    echo ""
    printf "%-20s %-15s %-15s %-15s %-10s\n" "FILESYSTEM" "TIPO" "TAMANO (GB)" "LIBRE (GB)" "% USO"
    echo "--------------------------------------------------------------------------------"
    
    df -T | grep -v "tmpfs\|devtmpfs\|squashfs\|loop" | tail -n +2 | while read -r filesystem tipo tamano usado libre porcentaje montaje; do
        # Convertir a GB para visualizacion
        tamano_gb=$(echo "scale=2; $tamano / 1024 / 1024" | bc 2>/dev/null || echo "0")
        libre_gb=$(echo "scale=2; $libre / 1024 / 1024" | bc 2>/dev/null || echo "0")
        
        printf "%-20s %-15s %-15s %-15s %-10s\n" "$filesystem" "$tipo" "$tamano_gb" "$libre_gb" "$porcentaje"
    done
    
    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}INFORMACION DETALLADA EN BYTES:${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    # Informacion detallada en bytes
    df -B1 -T | grep -v "tmpfs\|devtmpfs\|squashfs\|loop" | tail -n +2 | while read -r filesystem tipo tamano usado libre porcentaje montaje; do
        echo -e "${YELLOW}Filesystem: $filesystem${NC}"
        echo -e "  Tipo: ${WHITE}$tipo${NC}"
        echo -e "  Punto de montaje: ${WHITE}$montaje${NC}"
        echo -e "  Tamano Total: ${WHITE}$tamano bytes${NC}"
        echo -e "  Espacio Usado: ${WHITE}$usado bytes${NC}"
        echo -e "  Espacio Libre: ${GREEN}$libre bytes${NC}"
        echo -e "  Porcentaje usado: ${WHITE}$porcentaje${NC}"
        echo ""
    done
    
    total_discos=$(df -T | grep -v "tmpfs\|devtmpfs\|squashfs\|loop" | tail -n +2 | wc -l)
    echo -e "${CYAN}Total de filesystems encontrados: $total_discos${NC}"
    
    pausar
}

################################################################################
# OPCION 3: TOP 10 ARCHIVOS MAS GRANDES
################################################################################
opcion3_archivos_grandes() {
    clear
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}  OPCION 3: TOP 10 ARCHIVOS MAS GRANDES${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    
    # Mostrar filesystems disponibles
    echo -e "${YELLOW}Filesystems disponibles:${NC}"
    echo ""
    df -h | grep -v "tmpfs\|devtmpfs\|squashfs\|loop" | tail -n +2 | while read -r filesystem tamano usado libre porcentaje montaje; do
        echo -e "  ${CYAN}[$montaje]${NC} - $filesystem - $tamano"
    done
    
    echo ""
    echo -e "${YELLOW}Ingrese el punto de montaje a analizar (ej: / o /home):${NC} "
    read -r punto_montaje
    
    # Validar que el directorio existe
    if [ ! -d "$punto_montaje" ]; then
        echo ""
        echo -e "${RED}ERROR: El directorio $punto_montaje no existe o no es accesible.${NC}"
        pausar
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Buscando archivos mas grandes en $punto_montaje...${NC}"
    echo -e "${GRAY}Este proceso puede tardar varios minutos dependiendo del tamano...${NC}"
    echo ""
    
    # Buscar los 10 archivos mas grandes
    # Usamos find con -type f para solo archivos regulares
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}TOP 10 ARCHIVOS MAS GRANDES EN $punto_montaje${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    contador=1
    find "$punto_montaje" -type f -exec du -b {} + 2>/dev/null | sort -rn | head -10 | while read -r tamano_bytes ruta; do
        # Calcular tamanos en diferentes unidades
        tamano_mb=$(echo "scale=2; $tamano_bytes / 1024 / 1024" | bc 2>/dev/null || echo "0")
        tamano_gb=$(echo "scale=2; $tamano_bytes / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
        
        echo -e "${YELLOW}[$contador]${NC} ${WHITE}$ruta${NC}"
        echo -e "    ${CYAN}Tamano: $tamano_bytes bytes${NC}"
        echo -e "            ${GREEN}$tamano_mb MB${NC}"
        echo -e "            ${GREEN}$tamano_gb GB${NC}"
        echo ""
        
        contador=$((contador + 1))
    done
    
    # Verificar si se encontraron archivos
    archivos_encontrados=$(find "$punto_montaje" -type f 2>/dev/null | head -1)
    if [ -z "$archivos_encontrados" ]; then
        echo -e "${YELLOW}No se encontraron archivos en el directorio especificado.${NC}"
    fi
    
    pausar
}

################################################################################
# OPCION 4: MEMORIA RAM Y SWAP
################################################################################
opcion4_memoria() {
    clear
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}  OPCION 4: MEMORIA RAM Y SWAP${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Obteniendo informacion de memoria...${NC}"
    echo ""
    
    # ============== MEMORIA RAM ==============
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}                    MEMORIA RAM                                 ${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    # Obtener informacion de /proc/meminfo (valores en KB)
    mem_total_kb=$(grep "MemTotal:" /proc/meminfo | awk '{print $2}')
    mem_available_kb=$(grep "MemAvailable:" /proc/meminfo | awk '{print $2}')
    mem_free_kb=$(grep "MemFree:" /proc/meminfo | awk '{print $2}')
    
    # Convertir a bytes (KB * 1024)
    mem_total_bytes=$((mem_total_kb * 1024))
    mem_libre_bytes=$((mem_available_kb * 1024))
    mem_usada_bytes=$((mem_total_bytes - mem_libre_bytes))
    
    # Calcular porcentajes
    porcentaje_usada=$(echo "scale=2; ($mem_usada_bytes * 100) / $mem_total_bytes" | bc)
    porcentaje_libre=$(echo "scale=2; ($mem_libre_bytes * 100) / $mem_total_bytes" | bc)
    
    # Convertir a GB para visualizacion
    mem_total_gb=$(echo "scale=2; $mem_total_bytes / 1024 / 1024 / 1024" | bc)
    mem_usada_gb=$(echo "scale=2; $mem_usada_bytes / 1024 / 1024 / 1024" | bc)
    mem_libre_gb=$(echo "scale=2; $mem_libre_bytes / 1024 / 1024 / 1024" | bc)
    
    echo -e "${WHITE}Memoria Total:  ${YELLOW}$mem_total_bytes bytes${NC}"
    echo -e "                ${GREEN}$mem_total_gb GB${NC}"
    echo ""
    echo -e "${WHITE}Memoria Usada:  ${YELLOW}$mem_usada_bytes bytes${NC}"
    echo -e "                ${RED}$mem_usada_gb GB${NC}"
    echo -e "                ${RED}$porcentaje_usada%${NC}"
    echo ""
    echo -e "${WHITE}Memoria Libre:  ${YELLOW}$mem_libre_bytes bytes${NC}"
    echo -e "                ${GREEN}$mem_libre_gb GB${NC}"
    echo -e "                ${GREEN}$porcentaje_libre%${NC}"
    echo ""
    
    # ============== SWAP ==============
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}                 SWAP (MEMORIA DE INTERCAMBIO)                  ${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    swap_total_kb=$(grep "SwapTotal:" /proc/meminfo | awk '{print $2}')
    swap_free_kb=$(grep "SwapFree:" /proc/meminfo | awk '{print $2}')
    
    if [ "$swap_total_kb" -gt 0 ]; then
        # Convertir a bytes
        swap_total_bytes=$((swap_total_kb * 1024))
        swap_libre_bytes=$((swap_free_kb * 1024))
        swap_usado_bytes=$((swap_total_bytes - swap_libre_bytes))
        
        # Calcular porcentajes
        porcentaje_swap_usado=$(echo "scale=2; ($swap_usado_bytes * 100) / $swap_total_bytes" | bc)
        porcentaje_swap_libre=$(echo "scale=2; ($swap_libre_bytes * 100) / $swap_total_bytes" | bc)
        
        # Convertir a GB
        swap_total_gb=$(echo "scale=2; $swap_total_bytes / 1024 / 1024 / 1024" | bc)
        swap_usado_gb=$(echo "scale=2; $swap_usado_bytes / 1024 / 1024 / 1024" | bc)
        swap_libre_gb=$(echo "scale=2; $swap_libre_bytes / 1024 / 1024 / 1024" | bc)
        
        # Mostrar dispositivo de swap
        swap_device=$(swapon --show=NAME --noheadings 2>/dev/null | head -1)
        if [ -n "$swap_device" ]; then
            echo -e "${WHITE}Ubicacion:      ${CYAN}$swap_device${NC}"
            echo ""
        fi
        
        echo -e "${WHITE}Swap Total:     ${YELLOW}$swap_total_bytes bytes${NC}"
        echo -e "                ${GREEN}$swap_total_gb GB${NC}"
        echo ""
        echo -e "${WHITE}Swap en Uso:    ${YELLOW}$swap_usado_bytes bytes${NC}"
        echo -e "                ${RED}$swap_usado_gb GB${NC}"
        echo -e "                ${RED}$porcentaje_swap_usado%${NC}"
        echo ""
        echo -e "${WHITE}Swap Libre:     ${YELLOW}$swap_libre_bytes bytes${NC}"
        echo -e "                ${GREEN}$swap_libre_gb GB${NC}"
        echo -e "                ${GREEN}$porcentaje_swap_libre%${NC}"
    else
        echo -e "${YELLOW}No se detecto swap configurado en el sistema.${NC}"
    fi
    
    pausar
}

################################################################################
# OPCION 5: BACKUP A USB CON CATALOGO
################################################################################
opcion5_backup() {
    clear
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}  OPCION 5: BACKUP DE DIRECTORIO A USB${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    
    # Mostrar dispositivos montados (posibles USB)
    echo -e "${YELLOW}Buscando dispositivos removibles disponibles...${NC}"
    echo ""
    
    # Buscar dispositivos USB montados
    echo -e "${CYAN}Dispositivos montados:${NC}"
    echo ""
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE | grep -E "disk|part" | head -20
    echo ""
    
    # Solicitar directorio origen
    echo -e "${YELLOW}Ingrese la ruta completa del directorio a respaldar:${NC}"
    echo -e "${GRAY}(Ejemplo: /home/usuario/documentos)${NC}"
    echo -n "Ruta origen: "
    read -r directorio_origen
    
    # Validar directorio origen
    if [ ! -d "$directorio_origen" ]; then
        echo ""
        echo -e "${RED}ERROR: El directorio origen no existe: $directorio_origen${NC}"
        pausar
        return
    fi
    
    # Solicitar directorio destino
    echo ""
    echo -e "${YELLOW}Ingrese la ruta completa del destino (USB):${NC}"
    echo -e "${GRAY}(Ejemplo: /media/usb/backup)${NC}"
    echo -n "Ruta destino: "
    read -r directorio_destino
    
    # Crear directorio destino si no existe
    if [ ! -d "$directorio_destino" ]; then
        echo ""
        echo -e "${YELLOW}El directorio destino no existe. Creando...${NC}"
        mkdir -p "$directorio_destino" 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}ERROR: No se pudo crear el directorio destino.${NC}"
            echo -e "${RED}Verifique que tiene permisos o que el dispositivo USB esta montado.${NC}"
            pausar
            return
        fi
    fi
    
    # Confirmar operacion
    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}                   CONFIRMACION DE BACKUP                       ${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    echo -e "${WHITE}Origen:  ${CYAN}$directorio_origen${NC}"
    echo -e "${WHITE}Destino: ${CYAN}$directorio_destino${NC}"
    echo ""
    echo -n "Desea continuar con el backup? (s/n): "
    read -r confirmar
    
    if [ "$confirmar" != "s" ] && [ "$confirmar" != "S" ]; then
        echo ""
        echo -e "${YELLOW}Operacion cancelada por el usuario.${NC}"
        pausar
        return
    fi
    
    # Realizar backup
    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}              INICIANDO PROCESO DE BACKUP...                    ${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    
    inicio_backup=$(date +%s)
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] Copiando archivos...${NC}"
    
    # Copiar archivos con rsync (si esta disponible) o cp
    if command -v rsync &> /dev/null; then
        rsync -av --progress "$directorio_origen/" "$directorio_destino/" 2>/dev/null
    else
        cp -r "$directorio_origen/"* "$directorio_destino/" 2>/dev/null
    fi
    
    fin_backup=$(date +%s)
    duracion=$((fin_backup - inicio_backup))
    
    echo -e "${GREEN}[$(date '+%H:%M:%S')] Copia completada en $duracion segundos.${NC}"
    echo ""
    
    # Generar catalogo
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] Generando catalogo de archivos...${NC}"
    
    catalogo_txt="$directorio_destino/catalogo_backup.txt"
    catalogo_csv="$directorio_destino/catalogo_backup.csv"
    
    # Crear catalogo en formato texto
    {
        echo "================================================================"
        echo "        CATALOGO DE BACKUP - $(date '+%d/%m/%Y %H:%M:%S')"
        echo "================================================================"
        echo ""
        echo "Directorio origen:  $directorio_origen"
        echo "Directorio destino: $directorio_destino"
        echo "Fecha de backup:    $(date '+%d/%m/%Y %H:%M:%S')"
        echo ""
        echo "================================================================"
        echo "LISTA DE ARCHIVOS:"
        echo "================================================================"
        echo ""
    } > "$catalogo_txt"
    
    # Crear catalogo CSV
    echo "Nombre,Ruta_Relativa,Tamano_Bytes,Tamano_MB,Fecha_Modificacion" > "$catalogo_csv"
    
    # Contador de archivos
    total_archivos=0
    tamano_total=0
    
    # Recorrer archivos y agregar al catalogo
    find "$directorio_destino" -type f ! -name "catalogo_backup.txt" ! -name "catalogo_backup.csv" | while read -r archivo; do
        # Obtener informacion del archivo
        nombre_archivo=$(basename "$archivo")
        ruta_relativa="${archivo#$directorio_destino/}"
        tamano_bytes=$(stat -c%s "$archivo" 2>/dev/null || stat -f%z "$archivo" 2>/dev/null)
        if [ -z "$tamano_bytes" ]; then
            tamano_bytes=0
        fi
        tamano_mb=$(echo "scale=2; $tamano_bytes / 1024 / 1024" | bc 2>/dev/null || echo "0")
        fecha_mod=$(stat -c%y "$archivo" 2>/dev/null | cut -d'.' -f1 || stat -f%Sm "$archivo" 2>/dev/null)
        
        # Agregar a catalogo TXT
        {
            echo "Archivo: $ruta_relativa"
            echo "  Tamano: $tamano_bytes bytes"
            echo "  Tamano: $tamano_mb MB"
            echo "  Ultima modificacion: $fecha_mod"
            echo ""
        } >> "$catalogo_txt"
        
        # Agregar a catalogo CSV
        echo "\"$nombre_archivo\",\"$ruta_relativa\",$tamano_bytes,$tamano_mb,\"$fecha_mod\"" >> "$catalogo_csv"
        
        total_archivos=$((total_archivos + 1))
        tamano_total=$((tamano_total + tamano_bytes))
    done
    
    # Contar archivos y calcular tamano total
    total_archivos=$(find "$directorio_destino" -type f ! -name "catalogo_backup.txt" ! -name "catalogo_backup.csv" 2>/dev/null | wc -l)
    
    # Calcular tamano total (compatible con Linux y BSD/macOS)
    if stat -c%s "$directorio_destino" &>/dev/null; then
        # Sistema GNU (Linux)
        tamano_total=$(find "$directorio_destino" -type f ! -name "catalogo_backup.txt" ! -name "catalogo_backup.csv" -exec stat -c%s {} + 2>/dev/null | awk '{sum+=$1} END {print sum}')
    else
        # Sistema BSD (macOS y otros)
        tamano_total=$(find "$directorio_destino" -type f ! -name "catalogo_backup.txt" ! -name "catalogo_backup.csv" -exec stat -f%z {} + 2>/dev/null | awk '{sum+=$1} END {print sum}')
    fi
    
    if [ -z "$tamano_total" ] || [ "$tamano_total" = "" ]; then
        tamano_total=0
    fi
    
    tamano_total_mb=$(echo "scale=2; $tamano_total / 1024 / 1024" | bc 2>/dev/null || echo "0")
    tamano_total_gb=$(echo "scale=2; $tamano_total / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
    
    # Agregar resumen al catalogo TXT
    {
        echo "================================================================"
        echo "RESUMEN:"
        echo "================================================================"
        echo "Total de archivos: $total_archivos"
        echo "Tamano total: $tamano_total bytes"
        echo "Tamano total: $tamano_total_mb MB"
        echo "Tamano total: $tamano_total_gb GB"
        echo "Duracion del backup: $duracion segundos"
        echo ""
    } >> "$catalogo_txt"
    
    echo -e "${GREEN}[$(date '+%H:%M:%S')] Catalogo generado exitosamente.${NC}"
    echo ""
    
    # Mostrar resumen
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}                  BACKUP COMPLETADO                             ${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    echo -e "${WHITE}Archivos copiados:  ${GREEN}$total_archivos${NC}"
    echo -e "${WHITE}Tamano total:       ${GREEN}$tamano_total bytes${NC}"
    echo -e "${WHITE}Tamano total:       ${GREEN}$tamano_total_mb MB${NC}"
    echo -e "${WHITE}Duracion:           ${GREEN}$duracion segundos${NC}"
    echo ""
    echo -e "${WHITE}Catalogos generados:${NC}"
    echo -e "  ${CYAN}- $catalogo_txt${NC}"
    echo -e "  ${CYAN}- $catalogo_csv${NC}"
    
    pausar
}

################################################################################
# PROGRAMA PRINCIPAL
################################################################################

# Verificar si se ejecuta como root (recomendado)
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${YELLOW}  ADVERTENCIA: No se esta ejecutando como root/sudo            ${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo ""
    echo -e "${YELLOW}Algunas funciones pueden no estar disponibles.${NC}"
    echo -e "${YELLOW}Para mejor funcionalidad, ejecute: sudo $0${NC}"
    echo ""
    echo -e "${GRAY}Presione cualquier tecla para continuar...${NC}"
    read -n 1 -s
fi

# Bucle principal del menu
while true; do
    mostrar_menu
    echo -n "Seleccione una opcion [0-5]: "
    read -r opcion
    
    case $opcion in
        1)
            opcion1_usuarios
            ;;
        2)
            opcion2_discos
            ;;
        3)
            opcion3_archivos_grandes
            ;;
        4)
            opcion4_memoria
            ;;
        5)
            opcion5_backup
            ;;
        0)
            clear
            echo ""
            echo -e "${CYAN}================================================================${NC}"
            echo -e "${CYAN}     Gracias por usar la Herramienta de Administracion         ${NC}"
            echo -e "${CYAN}                   Hasta pronto!                                ${NC}"
            echo -e "${CYAN}================================================================${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo -e "${RED}Opcion invalida. Seleccione una opcion entre 0 y 5.${NC}"
            sleep 2
            ;;
    esac
done

