


> Script de **pentesting** y reconocimiento automatizado diseñado por **Cristian Villordo**.  
> Centraliza `nmap`, `gobuster`, `hydra`, `enum4linux`, `searchsploit`, `linpeas` y utilidades comunes en un solo flujo de trabajo.

> ⚠️ **Advertencia legal:** Usar únicamente contra sistemas con autorización explícita. El autor no se responsabiliza por usos indebidos.

---

## 🧭 Resumen / Objetivo

`auditorcdv.sh` automatiza tareas comunes de reconocimiento activo y post-explotación inicial en entornos controlados:

- **Detección de puertos** (`nmap -sS`)
- **Detección de versiones** (`nmap -sV`)
- **Estimación OS por TTL** (`ping`)
- **Fuzzing de directorios web** (`gobuster` — modo *limpio* `-q`)
- **Fuerza bruta SSH** (`hydra`)
- **Enumeración SMB/NetBIOS** (`enum4linux`)
- **Subida/ejecución de linpeas** (opcional) vía `scp`/`sshpass`
- **Búsqueda de exploits** (`searchsploit`)

Todos los resultados se guardan en `audits/<tag>/` organizados por herramienta y timestamp.

---

## ✅ Requisitos

Ejecutar con `sudo` / root.

Dependencias (puede ofrecer instalar algunas automáticamente):

- `nmap`
- `gobuster`
- `hydra`
- `enum4linux`
- `xsltproc` (para convertir XML -> HTML)
- `sshpass` (opcional para scp/ssh automático)
- `searchsploit` (exploitdb)
- `curl` o `wget`

Instalación rápida (Debian / Kali):
```bash
sudo apt update
sudo apt install -y nmap gobuster hydra enum4linux xsltproc sshpass exploitdb curl wget
````

---

## 📦 Instalación del script

1. Clonar/descargar el repo.
2. Pegar `auditorcdv.sh` en la carpeta deseada.
3. Dar permisos y ejecutar:

```bash
chmod +x auditorcdv.sh
sudo ./auditorcdv.sh
```

---

## ⚙️ Uso (flujo rápido)

1. Ejecutar: `sudo ./auditorcdv.sh`
2. Ingresar **IP/Host objetivo** (no se acepta vacío).
3. Seleccionar **Timing nmap (0-5)** (por defecto `4`).
4. Elegir nombre de subcarpeta (opcional) — si se deja vacío se genera `target-YYYYMMDD-HHMMSS`.
5. Escoger la opción del menú:

```
1) Escaneo SYN rápido (nmap -sS -T)
2) Escaneo de versiones (-sV)
3) Obtener TTL / estimar OS (ping)
4) Convertir xml nmap -> html (xsltproc)
5) Fuzz directorios con gobuster (modo limpio -q)
6) Fuerza bruta SSH con hydra
7) Enumeración SMB/NetBIOS (enum4linux)
8) Intentar SSH y subir linpeas (scp)
9) Buscar exploits con searchsploit
0) Salir
```

---

## 🛠 Ejemplos prácticos

### Escaneo SYN + extracción de puertos

Ejecuta opción `1`:

```text
[*] Ejecutando SYN scan (-sS) con -T4 en 10.201.120.215
Puertos abiertos detectados: 22,80,139,445,8009,8080
```

Resultado: `audits/<tag>/nmap_syn.*` y `puertos_abiertos.csv`.

### Escaneo de versiones sobre puertos detectados

Elegir opción `2` y presionar Enter para usar puertos detectados:

```bash
nmap -sV -T4 -v -p22,80,139,445,8009,8080 10.201.120.215 -oA audits/<tag>/puertosVersion
```

### Estimar OS por TTL

Opción `3`:

```text
10.201.59.245 → TTL=61 → Unix/Linux (TTL base 64)
```

### Gobuster *limpio* (solo resultados)

Opción `5` ejecuta Gobuster en background con `-q` (quiet):

```bash
gobuster dir -u http://10.201.120.215/ -w /ruta/wordlist.txt -t 40 -q -o audits/<tag>/gobuster-YYYYMMDD-HHMMSS.txt
```

* Archivo limpio con solo rutas encontradas: `gobuster-*.txt`
* Log técnico completo: `gobuster-log-*.log`

Si querés ver resultados en vivo:

```bash
tail -f audits/<tag>/gobuster-*.txt
```

### Fuerza bruta SSH (hydra)

Opción `6`:

```bash
hydra -l jan -P /usr/share/wordlists/rockyou.txt -t 64 -f -V ssh://10.201.120.215
```

Salida guardada en `audits/<tag>/hydra-ssh-*.txt`.

### Subir linpeas y probar

Opción `8` permite:

* Descargar `linpeas.sh` automáticamente al folder de auditoría.
* Subirlo con `scp` a `/dev/shm/` o ruta que especifiques (usa `sshpass` si proporcionás contraseña).
* Archivo local: `audits/<tag>/linpeas.sh`.

---

## 🗂 Estructura de salida (ejemplo)

```
audits/<tag>/
├─ nmap_syn.nmap
├─ nmap_syn.xml
├─ puertos_abiertos.csv
├─ puertosVersion.nmap
├─ gobuster-YYYYMMDD-HHMMSS.txt
├─ gobuster-log-YYYYMMDD-HHMMSS.log
├─ hydra-ssh-YYYYMMDD-HHMMSS.txt
├─ enum4linux-YYYYMMDD-HHMMSS.txt
├─ searchsploit-YYYYMMDD-HHMMSS.txt
└─ ping_ttl.txt
```

---

## 🔁 Integraciones sugeridas (mejoras)

* Ejecutar cada herramienta en **tmux** para monitoreo en vivo.
* Generar `index.html` automático que liste y enlace todos los archivos en la carpeta `audits/<tag>`.
* Reescribir el parser XML → JSON en **Python** para generar informes PDF/HTML.
* Integrar `ffuf` como alternativa a `gobuster` (mayor flexibilidad y rendimiento).

---

## 🧾 Licencia

MIT License © 2025 **Cristian Villordo**

---

## 📬 Contacto / Autor

**Cristian Villordo** 
GitHub: [https://github.com/cdvcristiann](https://github.com/cdvcristiann)
cristianndvillordo11@gmail.com)

---
