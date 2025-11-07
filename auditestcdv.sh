#!/usr/bin/env bash
# auditorcdv.sh
# AuditorÃ­a rÃ¡pida (nmap, parseo puertos, ttl/os, gobuster, hydra, enum4linux, scp linpeas, searchsploit)
# Uso: sudo ./auditorcdv.sh
# WARNING: Ejecutar Ãºnicamente en objetivos con autorizaciÃ³n.

set -euo pipefail
IFS=$'\n\t'

# -------------------------
# Config global
# -------------------------
declare TARGET=""
declare TIMING="4"
declare OUTDIR_BASE="audits"
declare OUTDIR=""
declare DEBUG_ON=1   # 1=on, 0=off
mkdir -p "$OUTDIR_BASE"

TIMESTAMP(){ date +"%Y%m%d-%H%M%S"; }
dbg(){ if [ "${DEBUG_ON:-0}" -eq 1 ]; then echo "[DEBUG] $*"; fi }

# -------------------------
# Helpers
# -------------------------
check_root(){
  if [ "$(id -u)" -ne 0 ]; then
    echo "Este script requiere privilegios root. Ejecutalo con sudo."
    exit 1
  fi
}

which_or_install(){
  # Uso interactivo: $1 binario, $2 paquete apt (opcional)
  local bin="$1" pkg="${2:-$1}"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "No se encontrÃ³ '$bin'. Â¿Instalar ahora? [Y/n]"
    read -r ans
    if [[ "$ans" =~ ^([yY]|)$ ]]; then
      if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y "$pkg"
      elif command -v yum >/dev/null 2>&1; then
        yum install -y "$pkg"
      else
        echo "No se detectÃ³ gestor de paquetes soportado. InstalÃ¡ $bin manualmente."
        return 1
      fi
    else
      echo "Omitiendo instalaciÃ³n de $bin."
      return 2
    fi
  fi
  return 0
}

# -------------------------
# Inputs / PreparaciÃ³n
# -------------------------
prompt_ip_and_timing(){
  while [ -z "$TARGET" ]; do
    read -rp "IP/Host objetivo: " TARGET
    TARGET="${TARGET:-}"
    if [ -z "$TARGET" ]; then
      echo "IngresÃ¡ una IP/Host vÃ¡lida. (No puede quedar vacÃ­o)"
    fi
  done

  read -rp "Timing template nmap (0-5) [4]: " TIMING_IN
  TIMING="${TIMING_IN:-4}"

  read -rp "Guardar resultados en subcarpeta (nombre) [auto]: " TAG
  if [ -z "$TAG" ]; then
    TAG="$(echo "$TARGET" | tr '/:' '_' )-$(TIMESTAMP)"
  else
    TAG="$TAG-$(TIMESTAMP)"
  fi

  OUTDIR="$OUTDIR_BASE/$TAG"
  mkdir -p "$OUTDIR"
  echo "Resultados se guardarÃ¡n en: $OUTDIR"
  dbg "TARGET=$TARGET TIMING=$TIMING OUTDIR=$OUTDIR"
}

# -------------------------
# Funciones principales
# -------------------------
nmap_syn_scan(){
  dbg "nmap_syn_scan -> TARGET=${TARGET}"
  echo "[*] Ejecutando SYN scan (-sS) con -T${TIMING} en ${TARGET}"
  OUT_PREFIX="$OUTDIR/nmap_syn"
  # -Pn para evitar fallos si ICMP bloqueado; podÃ©s quitar si no querÃ©s
  nmap -sS -T"${TIMING}" -Pn "${TARGET:?No se definiÃ³ TARGET}" -oA "$OUT_PREFIX" | tee "$OUTDIR/nmap_syn_stdout.txt"
  parse_ports_from_nmap "$OUT_PREFIX.nmap"
}

nmap_version_scan(){
  dbg "nmap_version_scan -> entrada: $1"
  local ports="${1:-}"
  if [ -z "$ports" ]; then
    echo "[*] No se indicaron puertos. Ejecutando SYN scan para detectarlos..."
    nmap_syn_scan
    ports="$(get_ports_csv)"
    if [ -z "$ports" ]; then
      echo "No se detectaron puertos abiertos. Abortando -sV."
      return 1
    fi
  fi
  echo "[*] Ejecutando nmap -sV en puertos: $ports"
  OUT_PREFIX="$OUTDIR/puertosVersion"
  nmap -sV -T"${TIMING}" -v -p"$ports" "${TARGET:?No se definiÃ³ TARGET}" -oA "$OUT_PREFIX" | tee "$OUTDIR/nmap_sV_stdout.txt"
  echo "[*] Resultados guardados en $OUTDIR (basename $OUT_PREFIX)"
}

parse_ports_from_nmap(){
  local file="$1"
  dbg "parse_ports_from_nmap file=$file"
  if [ ! -f "$file" ]; then
    echo "Archivo nmap no encontrado: $file"
    return 1
  fi
  # Extrae lÃ­neas con 'open' y forma CSV: 22,80,...
  grep -E '^[0-9]+/tcp[[:space:]]+open' "$file" | awk '{print $1}' | cut -d'/' -f1 | paste -sd, - > "$OUTDIR/puertos_abiertos.csv" || true
  if [ -s "$OUTDIR/puertos_abiertos.csv" ]; then
    echo "Puertos abiertos detectados: $(cat "$OUTDIR/puertos_abiertos.csv")"
  else
    echo "No se detectaron puertos abiertos en $file"
  fi
}

get_ports_csv(){
  if [ -f "$OUTDIR/puertos_abiertos.csv" ]; then
    cat "$OUTDIR/puertos_abiertos.csv"
  else
    echo ""
  fi
}

ping_ttl_os(){
  echo "[*] Ejecutando ping (1) para TTL/estimaciÃ³n OS de $TARGET"
  t=$(ping -c1 -W1 "$TARGET" 2>/dev/null | grep -oE "ttl=[0-9]+" | cut -d= -f2 || true)
  if [ -z "$t" ]; then
    echo "Sin respuesta ICMP de $TARGET" | tee "$OUTDIR/ping_ttl.txt"
    return 1
  fi
  if [ "$t" -le 64 ]; then os="Unix/Linux (TTL base 64)"
  elif [ "$t" -le 128 ]; then os="Windows (TTL base 128)"
  else os="Router/Dispositivo de red (TTL base 255 o mayor)"
  fi
  echo "$TARGET â†’ TTL=$t â†’ $os" | tee "$OUTDIR/ping_ttl.txt"
}

convert_xml_to_html(){
  if ! command -v xsltproc >/dev/null 2>&1; then
    echo "xsltproc no instalado."
    which_or_install xsltproc xsltproc || return 1
  fi
  xmlfile=$(ls "$OUTDIR"/*.xml 2>/dev/null | head -n1 || true)
  if [ -z "$xmlfile" ]; then
    echo "No se encontrÃ³ XML en $OUTDIR"
    return 1
  fi
  htmlout="${xmlfile%.xml}.html"
  echo "[*] Generando HTML desde $xmlfile -> $htmlout"
  xsltproc "$xmlfile" -o "$htmlout" && echo "Generado $htmlout"
}

gobuster_dir_fuzz(){
  which_or_install gobuster gobuster || return 1
  read -rp "Wordlist (ruta) [/usr/share/dirbuster/wordlists/directory-list-2.3-small.txt]: " WORDLIST
  WORDLIST="${WORDLIST:-/usr/share/dirbuster/wordlists/directory-list-2.3-small.txt}"
  read -rp "Threads (ej 40) [40]: " GBT
  GBT="${GBT:-40}"
  read -rp "Protocolo (http/https) [http]: " PROT
  PROT="${PROT:-http}"
  url="$PROT://$TARGET/"
  out="$OUTDIR/gobuster-$(TIMESTAMP).txt"
  log="$OUTDIR/gobuster-log-$(TIMESTAMP).log"

  echo "[*] Ejecutando Gobuster limpio (solo resultados) en $url"
  
  # EjecuciÃ³n en background, sin verbose ni progreso
  nohup gobuster dir -u "$url" -w "$WORDLIST" -t "$GBT" -q -o "$out" >"$log" 2>&1 &

  echo "Gobuster ejecutÃ¡ndose en background (PID $!)"
  echo "Resultados limpios: $out"
  echo "Log completo: $log"
}


ssh_bruteforce_hydra(){
  which_or_install hydra hydra || return 1
  read -rp "Usuario (o archivo de usuarios) [root]: " H_USER
  H_USER="${H_USER:-root}"
  read -rp "Passwordlist (ruta) [/usr/share/wordlists/rockyou.txt]: " PWL
  PWL="${PWL:-/usr/share/wordlists/rockyou.txt}"
  read -rp "Threads (ej 64) [16]: " HT
  HT="${HT:-16}"
  echo "[*] Iniciando hydra SSH contra $TARGET"
  OUT="$OUTDIR/hydra-ssh-$(TIMESTAMP).txt"
  if [ -f "$H_USER" ]; then
    hydra -L "$H_USER" -P "$PWL" -t "$HT" -f -V "ssh://${TARGET}" 2>&1 | tee "$OUT"
  else
    hydra -l "$H_USER" -P "$PWL" -t "$HT" -f -V "ssh://${TARGET}" 2>&1 | tee "$OUT"
  fi
  echo "Hydra finalizÃ³. RevisÃ¡ $OUT para credenciales encontradas."
}

enum4linux_run(){
  which_or_install enum4linux enum4linux || return 1
  OUT="$OUTDIR/enum4linux-$(TIMESTAMP).txt"
  echo "[*] Ejecutando enum4linux -a $TARGET"
  enum4linux -a "$TARGET" | tee "$OUT"
  echo "Resultados: $OUT"
  # extracciÃ³n simple de usuarios (intentos)
  grep -Ei "user|username|users|accounts" "$OUT" || true
}

attempt_ssh_and_scp_linpeas(){
  which_or_install sshpass sshpass || true
  read -rp "Usuario para SSH (ej: jan): " SUSER
  read -rsp "Password: " SPASS; echo
  echo "[*] Intentando SSH con $SUSER@$TARGET (revisÃ¡ $OUTDIR/ssh_test_*.txt)"
  OUT_SSH="$OUTDIR/ssh_test_$(TIMESTAMP).txt"
  if command -v sshpass >/dev/null 2>&1; then
    sshpass -p "$SPASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 "$SUSER@$TARGET" 'echo "Conexion OK"; uname -a' | tee "$OUT_SSH" || echo "No se pudo conectar con esas credenciales."
  else
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 "$SUSER@$TARGET" 'echo "Conexion OK"; uname -a' | tee "$OUT_SSH" || echo "No se pudo conectar con esas credenciales."
  fi

  read -rp "Â¿QuerÃ©s descargar linpeas automÃ¡ticamente desde GitHub y luego subirla? [y/N]: " DL
  if [[ "$DL" =~ ^([yY])$ ]]; then
    LINPEAS_URL="https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh"
    LINPEAS_LOCAL="$OUTDIR/linpeas.sh"
    echo "[*] Descargando linpeas a $LINPEAS_LOCAL"
    curl -L --insecure -s -o "$LINPEAS_LOCAL" "$LINPEAS_URL" || wget -q -O "$LINPEAS_LOCAL" "$LINPEAS_URL"
    chmod +x "$LINPEAS_LOCAL" || true
  else
    read -rp "Ruta local de linpeas.sh (si querÃ©s subir): " LINPEAS_LOCAL
  fi

  if [ -n "${LINPEAS_LOCAL:-}" ] && [ -f "$LINPEAS_LOCAL" ]; then
    read -rp "Ruta remota destino (ej: /dev/shm/) [/dev/shm/]: " REMDEST
    REMDEST="${REMDEST:-/dev/shm/}"
    if command -v sshpass >/dev/null 2>&1; then
      sshpass -p "$SPASS" scp -o StrictHostKeyChecking=no "$LINPEAS_LOCAL" "$SUSER@$TARGET:$REMDEST" && echo "linpeas subido a $SUSER@$TARGET:$REMDEST"
    else
      scp -o StrictHostKeyChecking=no "$LINPEAS_LOCAL" "$SUSER@$TARGET:$REMDEST" && echo "linpeas subido a $SUSER@$TARGET:$REMDEST"
    fi
  else
    echo "No hay linpeas local para subir."
  fi
}

searchsploit_lookup(){
  which_or_install searchsploit exploitdb || return 1
  read -rp "Buscar exploit para (p.ej. tomcat 9): " QUERY
  searchsploit "$QUERY" | tee "$OUTDIR/searchsploit-$(TIMESTAMP).txt"
}

# -------------------------
# UI menu
# -------------------------
show_menu(){
  cat <<'EOF'
=== MENU ===
1) Escaneo SYN rÃ¡pido (nmap -sS -T)
2) Escaneo de versiones (-sV) sobre puertos detectados o ingresados
3) Obtener TTL / estimar OS (ping)
4) Convertir xml nmap -> html (xsltproc)
5) Fuzz directorios con gobuster (background + verbose log)
6) Fuerza bruta SSH con hydra
7) EnumeraciÃ³n SMB/NetBIOS (enum4linux)
8) Intentar SSH y subir linpeas (scp, con opciÃ³n de descargar linpeas)
9) Buscar exploits con searchsploit
0) Salir
EOF
}

# -------------------------
# Flow principal
# -------------------------
check_root
prompt_ip_and_timing

while true; do
  show_menu
  read -rp "ElegÃ­ opciÃ³n: " opt
  case "$opt" in
    1) nmap_syn_scan ;;
    2)
       read -rp "Ingresar puertos CSV (ej 22,80,445) o ENTER para usar los detectados: " PCSV
       if [ -n "$PCSV" ]; then nmap_version_scan "$PCSV"; else nmap_version_scan ""; fi
       ;;
    3) ping_ttl_os ;;
    4) convert_xml_to_html ;;
    5) gobuster_dir_fuzz ;;
    6) ssh_bruteforce_hydra ;;
    7) enum4linux_run ;;
    8) attempt_ssh_and_scp_linpeas ;;
    9) searchsploit_lookup ;;
    0) echo "Saliendo..."; exit 0 ;;
    *) echo "OpciÃ³n invÃ¡lida";;
  esac
  echo "------ OperaciÃ³n finalizada. Volviendo al menÃº. ------"
done