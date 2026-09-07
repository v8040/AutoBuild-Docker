#!/usr/bin/env bash
set -eu

IMAGE="${IMAGE:?set IMAGE env}"
CNAME="bentopdf-verify"
PORT="18080"
FAIL=0

docker pull -q "${IMAGE}"
docker run -d --name "${CNAME}" -p "${PORT}:8080" "${IMAGE}"
trap 'docker rm -f "${CNAME}" &>/dev/null' EXIT

for I in $(seq 1 30); do
  curl -fsS -o /dev/null "http://localhost:${PORT}/" && break
  sleep 2
done
curl -fsS -o /dev/null "http://localhost:${PORT}/"
BASE="http://localhost:${PORT}"

check() {
  CODE=$(curl -s -o /dev/null -w '%{http_code}' "$1") || CODE=000
  if [ "${CODE}" != "200" ]; then
    echo "FAIL [${CODE}] $1"
    FAIL=$((FAIL + 1))
  else
    echo "ok   [${CODE}] $1"
  fi
}

echo '=== 0. extracted manifests + mirrored fonts intact ==='
docker exec "${CNAME}" sh -c 'for V in pymupdf gs cpdf pdfium tj; do test -s "/ver/$V" || { echo "empty manifest: $V"; exit 1; }; done; test -s /ver/fonts; test -s /ver/notofonts; N=$(find /usr/share/nginx/html/wasm/fonts-host -type f | wc -l); M=$(wc -l < /ver/notofonts); if [ "$N" -ne "$M" ]; then echo "fonts-host=$N manifest=$M"; exit 1; fi; echo "manifests OK, fonts-host=$N"'

echo '=== 1. tesseract.js mirrored version (dir listing) ==='
TJ=$(docker exec "${CNAME}" sh -c 'ls -d /usr/share/nginx/html/wasm/npm/tesseract.js@v*' | sed 's|.*@v||')
echo "tj=${TJ}"
check "${BASE}/wasm/npm/tesseract.js@v${TJ}/dist/worker.min.js"

echo '=== 1b. ocr runtime rewrite (direct worker + tessdata path) ==='
RTSRC=$(docker exec "${CNAME}" sh -c 'cat /usr/share/nginx/html/assets/tesseract-runtime-*.js')
echo "${RTSRC}" | grep -qF 'workerBlobURL:!1'
if echo "${RTSRC}" | grep -qF 'workerBlobURL:!0'; then
  echo '::error::workerBlobURL:!0 residual found'
  exit 1
fi
echo 'ok   direct worker enabled'
WMSRC=$(docker exec "${CNAME}" sh -c 'cat /usr/share/nginx/html/wasm/npm/tesseract.js@v*/dist/worker.min.js')
echo "${WMSRC}" | grep -qF '"/wasm/tessdata/"'
if echo "${WMSRC}" | grep -qF 'tesseract.js-data'; then
  echo '::error::langPath residual (tesseract.js-data) in worker.min.js'
  exit 1
fi
if echo "${WMSRC}" | grep -qF '4.0.0_best_int'; then
  echo '::error::variant residual (4.0.0_best_int) in worker.min.js'
  exit 1
fi
echo 'ok   worker langPath rewritten to /wasm/tessdata/'

echo '=== 2. every /wasm/ reference found in served text (docs site exempt) ==='
REFS=$(docker exec "${CNAME}" sh -c 'cd /usr/share/nginx/html && find . -type f \( -name "*.js" -o -name "*.html" -o -name "*.json" -o -name "*.css" \) ! -path "./docs/*" -exec cat {} + | grep -ohE "/wasm/[a-zA-Z0-9@/._-]*" | sort -u')
echo "${REFS}"
while read -r P; do
  [ -n "${P}" ] || continue
  case "${P}" in */) continue ;; esac
  case "${P##*/}" in *@v) continue ;; esac
  case "${P##*/}" in *.*) : ;; *) continue ;; esac
  check "${BASE}${P}"
done < <(printf '%s\n' "${REFS}")

echo '=== 3. runtime font file references (concat-built URLs) ==='
FONTFILES=$(docker exec "${CNAME}" sh -c 'cd /usr/share/nginx/html && find . -type f -name "*.js" ! -path "./docs/*" -exec cat {} + | grep -ohE "fonts-[a-z]*@[0-9][0-9.]*[a-zA-Z0-9/._-]*" | grep "/" | sort -u')
echo "${FONTFILES}"
while read -r FF; do
  [ -n "${FF}" ] || continue
  check "${BASE}/wasm/npm/@embedpdf/${FF}"
done < <(printf '%s\n' "${FONTFILES}")

echo '=== 4. tesseract traineddata concat chain (for review) ==='
docker exec "${CNAME}" sh -c 'grep -ohE "@tesseract\.js-data[^;]{0,140}" /usr/share/nginx/html/wasm/npm/tesseract.js@v*/dist/worker.min.js | head -3' || true

echo '=== 5. tesseract language data (tessdata_fast bundle) ==='
N=$(docker exec "${CNAME}" sh -c 'ls /usr/share/nginx/html/wasm/tessdata | wc -l')
echo "languages=${N}"
if [ "${N}" -lt 100 ]; then
  echo '::error::tessdata language count too low'
  exit 1
fi
for LNG in eng deu chi_sim chi_tra jpn kor ara heb; do
  check "${BASE}/wasm/tessdata/${LNG}/${LNG}.traineddata.gz"
done

echo '=== 5b. pyodide runtime served from pymupdf local assets ==='
PMU=$(docker exec "${CNAME}" sh -c 'ls -d /usr/share/nginx/html/wasm/npm/@bentopdf/pymupdf-wasm@*' | sed 's|.*wasm@||')
echo "pymupdf=${PMU}"
check "${BASE}/wasm/npm/@bentopdf/pymupdf-wasm@${PMU}/assets/pyodide.asm.wasm"
check "${BASE}/wasm/npm/@bentopdf/pymupdf-wasm@${PMU}/assets/pyodide-lock.json"
check "${BASE}/wasm/npm/@bentopdf/pymupdf-wasm@${PMU}/assets/python_stdlib.zip"
docker exec "${CNAME}" sh -c 'grep -ohE "setCdnUrl\([^)]{0,120}" /usr/share/nginx/html/wasm/npm/@bentopdf/pymupdf-wasm@*/assets/pyodide.js | head -2' || true

echo '=== 6. tesseract core loader variants ==='
COREDIR=$(docker exec "${CNAME}" sh -c 'ls -d /usr/share/nginx/html/wasm/npm/tesseract.js-core@v*')
for CORE in $(docker exec "${CNAME}" sh -c "ls ${COREDIR} | grep 'wasm.js$'"); do
  check "${BASE}/wasm/npm/$(basename "${COREDIR}")/${CORE}"
done

echo '=== 7. open-sans woff2 sample (index.css relative refs) ==='
for W in $(docker exec "${CNAME}" sh -c "grep -ohE 'files/[a-zA-Z0-9._-]*' /usr/share/nginx/html/wasm/fonts/open-sans/index.css | sort -u | head -4"); do
  check "${BASE}/wasm/fonts/open-sans/${W}"
done

echo '=== 7b. libreoffice cjk font injection ==='
docker exec "${CNAME}" sh -c 'cd /usr/share/nginx/html && for FN in jp kr sc tc; do grep -qF "},{filename:\"/instdir/share/fonts/truetype/NotoSansCJK${FN}-Regular.otf\"" libreoffice-wasm/soffice.js || { echo "missing closed entry: ${FN}"; exit 1; }; done'
echo 'ok   4 closed metadata entries'
SZ=$(docker exec "${CNAME}" sh -c 'wc -c < /usr/share/nginx/html/libreoffice-wasm/soffice.data.gz')
echo "soffice.data.gz=${SZ}"
if [ "${SZ}" -lt 30000000 ]; then
  echo '::error::soffice.data.gz smaller than injected size'
  exit 1
fi
ST=$(docker exec "${CNAME}" sh -c 'grep -oE "NotoSansCJKjp-Regular.otf\",start:[0-9]+" /usr/share/nginx/html/libreoffice-wasm/soffice.js | grep -oE "[0-9]+"')
MAGIC=$(docker exec "${CNAME}" sh -c "gunzip -c /usr/share/nginx/html/libreoffice-wasm/soffice.data.gz | tail -c +$((ST+1)) | head -c 4")
if [ "${MAGIC}" != "OTTO" ]; then
  echo "::error::data payload at offset ${ST} is not OTTO: ${MAGIC}"
  exit 1
fi
echo 'ok   jp font payload verified (OTTO magic)'

echo '=== 8. host audit (served text, docs site exempt) ==='
HOSTS=$(docker exec "${CNAME}" sh -c 'cd /usr/share/nginx/html && find . -type f \( -name "*.js" -o -name "*.html" -o -name "*.json" -o -name "*.css" \) ! -path "./docs/*" -exec cat {} + | grep -ohE "https?://[a-zA-Z0-9._-]*" | sort -u')
echo "${HOSTS}"
if echo "${HOSTS}" | grep -qE 'cdn\.jsdelivr|fonts\.googleapis|fonts\.gstatic|projectnaptha|githack'; then
  echo '::error::residual CDN host found'
  exit 1
fi
if [ "${FAIL}" -gt 0 ]; then
  echo "::error::${FAIL} path check(s) failed"
  exit 1
fi
echo 'VERIFY OK'
