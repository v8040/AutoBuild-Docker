ARG BASE_IMAGE=ghcr.io/alam00000/bentopdf-simple:latest

FROM ${BASE_IMAGE} AS base
USER root
RUN mkdir -p /ver && cd /usr/share/nginx/html && \
    find . -type f \( -name '*.js' -o -name '*.html' -o -name '*.json' -o -name '*.webmanifest' \) -exec cat {} + > /tmp/tree.txt && \
    grep -oh 'npm/@bentopdf/pymupdf-wasm@[0-9][0-9.]*' /tmp/tree.txt | sed 's/.*@//' | sort -u | head -1 > /ver/pymupdf && \
    grep -oh 'npm/@bentopdf/gs-wasm@[0-9][0-9.]*' /tmp/tree.txt | sed 's/.*@//' | sort -u | head -1 > /ver/gs && \
    grep -oh 'npm/coherentpdf@[0-9][0-9.]*' /tmp/tree.txt | sed 's/.*@//' | sort -u | head -1 > /ver/cpdf && \
    grep -oh '@embedpdf/pdfium@[0-9][0-9.]*' /tmp/tree.txt | sed 's/.*@//' | sort -u | head -1 > /ver/pdfium && \
    grep -oh 'tesseract\.js@[0-9][0-9.]*' /tmp/tree.txt | sed 's/.*@//' | sort -u | head -1 > /ver/tj && \
    grep -oh 'fonts-[a-z]*@[0-9][0-9.]*[a-zA-Z0-9/._-]*' /tmp/tree.txt | grep '/' | sort -u > /ver/fontfiles && \
    cut -d/ -f1 /ver/fontfiles | sort -u | sed 's|^|@embedpdf/|' > /ver/fonts && \
    grep -ohE 'https://rawcdn\.githack\.com/[^`"]*' /tmp/tree.txt | sort -u > /ver/notofonts

FROM --platform=${BUILDPLATFORM} node:22-alpine AS wasm
RUN apk add --no-cache curl
WORKDIR /dl
COPY --from=base /ver/ ./ver/
RUN set -eu; \
    pack_to() { \
      F=$(npm pack --pack-destination /tmp "$1" | tail -1); \
      mkdir -p "$2"; \
      tar -xzf "/tmp/${F}" -C "$2" --strip-components=1; \
      rm -f "/tmp/${F}"; \
    }; \
    pack_to "@bentopdf/pymupdf-wasm@$(cat ver/pymupdf)" "/out/wasm/npm/@bentopdf/pymupdf-wasm@$(cat ver/pymupdf)"; \
    rm -rf "/out/wasm/npm/@bentopdf/pymupdf-wasm@$(cat ver/pymupdf)/build_scripts" "/out/wasm/npm/@bentopdf/pymupdf-wasm@$(cat ver/pymupdf)/types"; \
    pack_to "@bentopdf/gs-wasm@$(cat ver/gs)" "/out/wasm/npm/@bentopdf/gs-wasm@$(cat ver/gs)"; \
    pack_to "coherentpdf@$(cat ver/cpdf)" "/out/wasm/npm/coherentpdf@$(cat ver/cpdf)"; \
    pack_to "@embedpdf/pdfium@$(cat ver/pdfium)" "/out/wasm/npm/@embedpdf/pdfium@$(cat ver/pdfium)"; \
    pack_to "tesseract.js@$(cat ver/tj)" "/out/wasm/npm/tesseract.js@v$(cat ver/tj)"; \
    pack_to "tesseract.js-core@$(cat ver/tj)" "/out/wasm/npm/tesseract.js-core@v$(cat ver/tj)"; \
    while read -r FP; do pack_to "${FP}" "/out/wasm/npm/${FP}"; done < ver/fonts; \
    pack_to "@fontsource/open-sans" "/out/wasm/fonts/open-sans"; \
    while read -r U; do \
      P="/out/wasm/fonts-host${U#https://rawcdn.githack.com}"; \
      mkdir -p "$(dirname "${P}")"; \
      curl -fsSL --retry 3 --retry-delay 2 -o "${P}" "${U}"; \
    done < ver/notofonts; \
    mkdir -p /out/wasm/tessdata && \
    curl -fsSL --retry 3 -o /tmp/tf.tar.gz https://codeload.github.com/tesseract-ocr/tessdata_fast/tar.gz/refs/heads/main && \
    tar -xzf /tmp/tf.tar.gz -C /tmp && \
    find /tmp/tessdata_fast-main -maxdepth 1 -name '*.traineddata' | while read -r P; do \
      L=$(basename "${P}" .traineddata); \
      mkdir -p "/out/wasm/tessdata/${L}" && \
      gzip -c "${P}" > "/out/wasm/tessdata/${L}/${L}.traineddata.gz"; \
    done && \
    rm -rf /tmp/tf.tar.gz /tmp/tessdata_fast-main

FROM ${BASE_IMAGE} AS final
USER root
COPY --from=base /ver/ /ver/
COPY --from=wasm /out/wasm/ /usr/share/nginx/html/wasm/
RUN set -eu; cd /usr/share/nginx/html; \
    find . -type f \( -name '*.js' -o -name '*.html' -o -name '*.json' -o -name '*.css' -o -name '*.webmanifest' \) -exec grep -lF 'https://cdn.jsdelivr.net/npm' {} + | while read -r F; do \
      sed -i 's|https://cdn.jsdelivr.net/npm|/wasm/npm|g' "${F}"; \
      rm -f "${F}.br" "${F}.gz"; \
    done; \
    find . -type f -name '*.js' -exec grep -lF 'https://cdn.jsdelivr.net/pyodide/' {} + | while read -r F; do \
      sed -i 's|https://cdn\.jsdelivr\.net/pyodide/v[^"]\{0,80\}full/|/wasm/npm/@bentopdf/pymupdf-wasm@'"$(cat /ver/pymupdf)"'/assets/|g' "${F}"; \
      rm -f "${F}.br" "${F}.gz"; \
    done; \
    find . -type f -name '*.js' -exec grep -lF 'https://cdn.jsdelivr.net' {} + | while read -r F; do \
      sed -i 's|new Set(\[.https://cdn\.jsdelivr\.net.\])|new Set([])|g' "${F}"; \
      rm -f "${F}.br" "${F}.gz"; \
    done; \
    find . -type f \( -name '*.js' -o -name '*.html' -o -name '*.json' \) -exec grep -lF 'https://rawcdn.githack.com' {} + | while read -r F; do \
      sed -i 's|https://rawcdn\.githack\.com|/wasm/fonts-host|g' "${F}"; \
      rm -f "${F}.br" "${F}.gz"; \
    done; \
    find . -type f \( -name '*.css' -o -name '*.html' -o -name '*.js' \) -exec grep -lF 'fonts.googleapis.com' {} + | while read -r F; do \
      sed -i 's|https://fonts.googleapis.com/css2?family=Open+Sans:[^)]*|/wasm/fonts/open-sans/index.css|g' "${F}"; \
      rm -f "${F}.br" "${F}.gz"; \
    done; \
    find . -type f -name '*.js' -exec grep -lF 'workerBlobURL:!0' {} + | while read -r F; do \
      sed -i 's|workerBlobURL:!0|workerBlobURL:!1|g' "${F}"; \
      rm -f "${F}.br" "${F}.gz"; \
    done; \
    find . -type f -name '*.js' -exec grep -lF '"/wasm/npm/@tesseract.js-data/"' {} + | while read -r F; do \
      sed -i 's|"/wasm/npm/@tesseract\.js-data/"|"/wasm/tessdata/"|g' "${F}"; \
      sed -i 's|m?"/4\.0\.0_best_int":"/4\.0\.0"|""|g' "${F}"; \
      rm -f "${F}.br" "${F}.gz"; \
    done; \
    LO=/usr/share/nginx/html/libreoffice-wasm; \
    gunzip -c "${LO}/soffice.data.gz" > /tmp/soffice.data && \
    TOTAL=$(wc -c < /tmp/soffice.data) && \
    CUR=${TOTAL} && \
    INS="" && \
    for FN in jp kr sc tc; do \
      SRC=$(find /usr/share/nginx/html/wasm/fonts-host -name "NotoSansCJK${FN}-Regular.otf" | head -1) && \
      SZ=$(wc -c < "${SRC}") && \
      END=$((CUR + SZ)) && \
      INS="${INS}{filename:\"/instdir/share/fonts/truetype/NotoSansCJK${FN}-Regular.otf\",start:${CUR},end:${END}}," && \
      CUR=${END} && \
      cat "${SRC}" >> /tmp/soffice.data; \
    done && \
    INS=${INS%,} && \
    sed -i "s|end:${TOTAL}\}]|end:${TOTAL}},${INS}]|" "${LO}/soffice.js" && \
    gzip -c /tmp/soffice.data > "${LO}/soffice.data.gz" && \
    rm -f "${LO}/soffice.js.br" "${LO}/soffice.js.gz"
USER nginx
