#!/usr/bin/env bash
# =====================================================================
#  Análisis básico de datos de nanoporo - paso a paso
#  Curso de Bioinformática aplicada al Diagnóstico Genético · Bloque II
#  Belén de la Morena Barrio
#
#  Uso (desde la carpeta del repositorio):
#     bash analisis_nanoporo.sh
#  o indicando fichero, cromosoma y región:
#     bash analisis_nanoporo.sh datos/P1_subset_bioinfo.fastq chr1 chr1:173900000-173950000
# =====================================================================
set -u   # (sin pipefail: "| head" cortaría el script)

# Por defecto: el primer FASTQ que haya en la carpeta datos/
FASTQ=${1:-$(ls datos/*.fastq datos/*.fastq.gz datos/*.fq datos/*.fq.gz 2>/dev/null | head -1)}
CROM=${2:-chr1}
REGION=${3:-chr1:173900000-173950000}
if [ -z "$FASTQ" ] || [ ! -f "$FASTQ" ]; then
  echo "❌ No encuentro el FASTQ. Ponlo en la carpeta 'datos/' o indícalo: bash analisis_nanoporo.sh datos/mi_fichero.fastq"
  exit 1
fi
MUESTRA=$(basename "$FASTQ" | sed -E 's/\.(fastq|fq)(\.gz)?$//')
mkdir -p resultados
REF="resultados/$CROM.fa"
echo "FASTQ: $FASTQ   ·   Referencia: $CROM (hg38)   ·   Región: $REGION"

AZUL='\033[1;34m'; VERDE='\033[1;32m'; NEGRITA='\033[1m'; NADA='\033[0m'

paso () {   # paso "título" "explicación" "comando"
  echo -e "\n${AZUL}══════════════════════════════════════════════════════════════${NADA}"
  echo -e "${AZUL}  $1${NADA}"
  echo -e "${AZUL}══════════════════════════════════════════════════════════════${NADA}"
  echo -e "$2\n"
  echo -e "Voy a ejecutar:\n  ${VERDE}\$ $3${NADA}\n"
  read -rp "Pulsa INTRO para ejecutarlo (o Ctrl+C para salir)... "
  eval "$3"
  echo -e "\n${NEGRITA}✅ Hecho.${NADA}"
}

paso "0. Descargar la referencia ($CROM, hg38)" \
"Solo descargamos el cromosoma de interés para ir más rápido (UCSC).
samtools faidx crea un índice (.fai) para acceder a cualquier posición." \
"[ -f $REF ] || (wget -q -O $REF.gz https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/$CROM.fa.gz && gunzip -f $REF.gz); samtools faidx $REF; ls -lh $REF"

paso "1. Mirar el FASTQ" \
"Cada lectura ocupa 4 líneas:
  1) @nombre   2) secuencia   3) +   4) calidad de cada base (código Phred)" \
"(zcat -f $FASTQ 2>/dev/null || true) | head -4 | cut -c1-120"

paso "2. Contar lecturas y bases" \
"Un FASTQ tiene 4 líneas por lectura: contamos líneas y dividimos entre 4." \
"zcat -f $FASTQ | awk 'NR%4==2 {n++; b+=length(\$0)} END {print \"Lecturas:\", n; print \"Bases (Mb):\", b/1e6; print \"Longitud media (pb):\", int(b/n)}'"

paso "3. Alinear contra la referencia (minimap2) y ordenar (samtools)" \
"  minimap2 -ax map-ont  → alinea con parámetros para nanoporo y escribe SAM
  | samtools sort        → ordena por posición y guarda en BAM (binario)
  samtools index         → crea el índice .bai que necesita IGV" \
"minimap2 -t 2 -ax map-ont $REF $FASTQ | samtools sort -@2 -o resultados/$MUESTRA.bam - && samtools index resultados/$MUESTRA.bam"

paso "4. ¿Cuántas lecturas han alineado?" \
"samtools flagstat resume el BAM. Fíjate en 'mapped' y en 'supplementary'
(lecturas partidas en dos trozos: ¡pista de variante estructural!)." \
"samtools flagstat resultados/$MUESTRA.bam | head -7"

paso "5. Mirar dentro del BAM" \
"Columnas: nombre · FLAG · cromosoma · posición · MAPQ · CIGAR (M, I, D, S) · ... · secuencia" \
"samtools view resultados/$MUESTRA.bam $REGION | head -3 | cut -f1-6 | cut -c1-200"

paso "6. Cobertura en la región de interés" \
"Profundidad media en $REGION (con adaptive sampling debería ser mucho mayor que en el resto)." \
"samtools coverage -r $REGION resultados/$MUESTRA.bam"

paso "7. Llamar variantes estructurales (Sniffles2)" \
"Sniffles2 busca lecturas con inserciones, deleciones, inversiones... de más de 50 pb." \
"sniffles --input resultados/$MUESTRA.bam --vcf resultados/$MUESTRA.sv.vcf --reference $REF --threads 2 2>&1 | tail -2 && bgzip -kf resultados/$MUESTRA.sv.vcf && tabix -f -p vcf resultados/$MUESTRA.sv.vcf.gz"

paso "8. Variantes en tu región" \
"Columnas: cromosoma · posición · ID · filtro · INFO (SVTYPE = tipo, SVLEN = tamaño, SUPPORT = lecturas que la apoyan)." \
"tabix resultados/$MUESTRA.sv.vcf.gz $REGION | cut -f1-3,7,8 | cut -c1-200"

echo -e "\n${VERDE}🎉 ¡Análisis terminado!${NADA}"
echo "Descarga la carpeta 'resultados' (botón derecho → Download) y abre en https://igv.org/app :"
echo "   resultados/$MUESTRA.bam  (+ .bai)   y   resultados/$MUESTRA.sv.vcf.gz (+ .tbi)"
