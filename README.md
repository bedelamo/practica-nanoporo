# 🧬 Práctica: análisis de datos de nanoporo

**Curso de Análisis Bioinformático de Datos Genómicos aplicado al Diagnóstico Genético · Bloque II**
Belén de la Morena Barrio · CIBERER / Longseq Applications

Del FASTQ al diagnóstico: control de calidad → alineamiento (minimap2) → cobertura (samtools) → variantes estructurales (Sniffles2) → visualización (IGV).

## Cómo empezar
1. Necesitas una cuenta gratuita de GitHub (y haber iniciado sesión).
2. Pulsa el botón verde **Code → Codespaces → Create codespace on main**.
3. Espera 3–5 minutos la primera vez: se instalan las herramientas automáticamente.
4. Elige **una** de las dos formas de trabajar:
   - **Cuaderno:** abre `Practica_Nanoporo.ipynb`, pulsa *Select Kernel → Python Environments → Python 3* y ejecuta las celdas en orden (▶ o `Mayús + Intro`).
   - **Terminal:** en la terminal de abajo escribe `bash analisis_nanoporo.sh` y pulsa Intro en cada paso.
5. Descarga la carpeta `resultados` (botón derecho → *Download*) y abre el `.bam` y el `.vcf.gz` en **https://igv.org/app** (genoma hg38).

## Contenido
| Archivo | Qué es |
|---|---|
| `datos/` | FASTQ del paciente (lecturas de nanoporo) |
| `Practica_Nanoporo.ipynb` | Cuaderno guiado con preguntas |
| `analisis_nanoporo.sh` | El mismo análisis en la terminal, paso a paso |
| `.devcontainer/` | Configuración del entorno (no hace falta tocarla) |

> Al terminar, borra tu Codespace en https://github.com/codespaces para no gastar horas gratuitas.
