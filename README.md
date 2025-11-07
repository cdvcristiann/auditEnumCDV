````markdown
# 🧠 auditorcdv.sh — Auditoría de Seguridad Automática

Script de **auditoría ofensiva y reconocimiento automatizado** desarrollado por **Cristian Villordo**.  
Permite realizar escaneos, enumeraciones y ataques de fuerza bruta controlados sobre un objetivo, centralizando las herramientas más comunes en un solo flujo de trabajo bash.

> ⚠️ **Uso exclusivo para entornos autorizados.**  
> Este script fue diseñado con fines educativos, de pentesting ético y análisis de seguridad en laboratorios o entornos con consentimiento expreso.

---

## 📋 Funcionalidades principales

| Opción | Descripción | Herramienta(s) usada(s) |
|--------|--------------|--------------------------|
| 1 | Escaneo SYN rápido de puertos abiertos | `nmap -sS` |
| 2 | Escaneo de versiones de servicios | `nmap -sV` |
| 3 | Detección de TTL / estimación de sistema operativo | `ping` |
| 4 | Conversión de resultados XML a HTML | `xsltproc` |
| 5 | Fuzzing de directorios web (modo limpio sin verbose) | `gobuster` |
| 6 | Fuerza bruta SSH | `hydra` |
| 7 | Enumeración SMB / NetBIOS | `enum4linux` |
| 8 | Conexión SSH y subida de `linpeas.sh` | `sshpass`, `scp`, `curl/wget` |
| 9 | Búsqueda de exploits relacionados | `searchsploit` |

Todos los resultados se almacenan automáticamente en subcarpetas dentro del directorio `audits/`.

---

## ⚙️ Requisitos previos

Debés ejecutar el script como **root o con sudo**, ya que algunas herramientas requieren privilegios elevados (por ejemplo, `nmap -sS`).

### 🔧 Dependencias principales
El script verificará y ofrecerá instalar automáticamente si faltan:
- `nmap`
- `xsltproc`
- `gobuster`
- `hydra`
- `enum4linux`
- `sshpass`
- `searchsploit`
- `curl` o `wget`



---

## 🚀 Uso

Ejecutá el script desde terminal:

```bash
sudo ./auditorcdv.sh
```

### 🧩 Flujo inicial:

1. **IP/Host objetivo:** ingresá la IP o dominio del sistema a auditar.
2. **Timing Nmap (0–5):** elige el nivel de velocidad/agresividad (por defecto `4`).
3. **Nombre de carpeta de salida:** opcional, si no se define se autogenera.

El script creará una carpeta en `audits/` para guardar todos los resultados, por ejemplo:

```
audits/prueba-20251107-211200/
```

---

## 📊 Ejemplo de ejecución

```bash
$ sudo ./auditorcdv.sh
IP/Host objetivo: 10.10.11.5
Timing template nmap (0-5) [4]: 4
Guardar resultados en subcarpeta (nombre) [auto]: test
Resultados se guardarán en: audits/test-20251107-210959

=== MENU ===
1) Escaneo SYN rápido (nmap -sS -T)
2) Escaneo de versiones (-sV)
3) Obtener TTL / estimar OS (ping)
4) Convertir xml nmap -> html
5) Fuzz directorios con gobuster
6) Fuerza bruta SSH con hydra
7) Enumeración SMB/NetBIOS
8) Intentar SSH y subir linpeas
9) Buscar exploits con searchsploit
0) Salir
```

Ejemplo:

```
Elegí opción: 1
[*] Ejecutando SYN scan (-sS) con -T4 en 10.10.11.5
Puertos abiertos detectados: 22,80
```

---

## 🧰 Resultados generados

Cada módulo genera salidas organizadas dentro del directorio de auditoría:

```
audits/prueba-20251107-211200/
├── nmap_syn.nmap
├── nmap_syn.xml
├── puertos_abiertos.csv
├── gobuster-20251107-211500.txt
├── hydra-ssh-20251107-212000.txt
├── enum4linux-20251107-212300.txt
├── searchsploit-20251107-212500.txt
└── ping_ttl.txt
```

---

## 🔍 Detalles técnicos

* **Estructura modular:** cada tarea es una función independiente, fácilmente ampliable.
* **Gestión de dependencias:** `which_or_install()` detecta y ofrece instalar binarios faltantes.
* **Registro completo:** todas las ejecuciones guardan salida (`stdout` + `stderr`) para posterior análisis forense.
* **Modo background:** el fuzzing con Gobuster se ejecuta en segundo plano, permitiendo seguir usando el menú.
* **Compatibilidad:** probado en Kali Linux, Parrot y Ubuntu con herramientas de pentesting.

---

## ⚖️ Consideraciones éticas

* No utilices este script contra sistemas o redes sin autorización formal.
* El propósito es **educativo y profesional** dentro del ámbito del *Ethical Hacking* y *Red Team legal*.
* Cualquier uso indebido puede violar leyes locales y tratados internacionales de ciberseguridad.

---

## 🧩 Autor

**Cristian Villordo**
Analista de Seguridad & Full Stack Developer
🔹 Pentester / Forense / Backend Python-Django
🔹 Poder Judicial de Corrientes – Área Regional de Informática

📧 Contacto: *[Agregar email profesional o GitHub]*
💻 GitHub: [github.com/cdvcristiann](https://github.com/cdvcristiann)

---

## 📜 Licencia

Este proyecto se distribuye bajo la licencia **MIT**, promoviendo el uso libre, la modificación y el aprendizaje ético.

```
MIT License © 2025 Cristian Villordo
```

---
Instalación manual en Kali / Debian aunque no es necesario ya que kaly trae:
```bash
sudo apt update
sudo apt install -y nmap gobuster hydra enum4linux xsltproc sshpass exploitdb curl wget
````