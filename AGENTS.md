# AGENTS.md

## Repo purpose
Docker image building repo. Each subdirectory (`derper`, `jupyterhub`, `jupyterlab`, `sharelatex`, `bentopdf`) holds a `Dockerfile`. Compose files are examples only. `derper` is a standalone binary and has none. `images.txt` also lists external images (smartdns, sing-box, home-assistant) for mirroring only. Images are built via a manual GitHub Actions workflow and pushed to Docker Hub + GHCR

## Build and CI

- **All builds are manual** — triggered via `workflow_dispatch` in `.github/workflows/build.yml`. There are no push or PR triggers
- Only the repo owner can trigger builds (enforced by owner-only guard in the workflow)
- Build workflow selects a single project or `all` from the dropdown (bentopdf, derper, jupyterhub, jupyterlab, sharelatex, all). Default is `all`

## Platform support

- `sharelatex` is **linux/amd64 only** (TeX Live `scheme-full` doesn't install cleanly on arm64)
- All other images build for `linux/amd64,linux/arm64`

## Build-time dependencies (not in repo)

The following are fetched at build time and are **not** committed:

- **jupyterlab**: Clones oh-my-bash, oh-my-zsh, zsh-syntax-highlighting, zsh-autosuggestions; downloads a jovyantarball from a secret URL (`URL_JOVYAN`). COPY instructions in the Dockerfile reference `opt/` and `jovyan/` directories created by the "Fetch Resources" step
- **sharelatex**: Downloads a fonts tarball from a secret URL (`URL_FONTS`). COPY references `custom/` directory created by that step
- **derper**: No external dependencies
- **bentopdf**: All downloads happen inside the Dockerfile (no workflow fetch step, no secrets): npm packages mirrored from the versions extracted out of the official `ghcr.io/alam00000/bentopdf-simple` image, tesseract traineddata for all languages from `tesseract-ocr/tessdata_fast` (bundled under `/wasm/tessdata/<lang>/<lang>.traineddata.gz`), Noto fonts from rawcdn.githack.com, and @fontsource/open-sans. Derived image rewrites all CDN references to same-origin paths under `/wasm/`, switches tesseract.js to a direct same-origin worker (`workerBlobURL:!1`, required because a blob worker cannot resolve root-relative URLs), and injects Noto CJK fonts into the embedded LibreOffice wasm data blob (`soffice.data.gz` + metadata in `soffice.js`) for CJK Word-to-PDF rendering; embedded docs site (`docs/`) is inert content exempt from the residual-external-reference assertions

## Image registries

Images are pushed to both Docker Hub (`docker.io/v8040/<project>`) and GHCR (`ghcr.io/v8040/<project>`)

## Code conventions

- Use `jq` for JSON manipulation — never `sed`/`grep` for structured data
- The GitHub Actions runner has `jq`, `curl` pre-installed

## Mirroring (sync.yml)

`images.txt` lists all images to sync to Tencent Cloud TCR (`ccr.ccs.tencentyun.com`). Each line is `<source_image> [target_name]` (target_name is optional; if omitted, the image name is used). Lines starting with `#` are ignored. The sync workflow uses `skopeo copy` and prefers the GHCR mirror when available.

The workflow resolves Docker auth credentials from `$DOCKER_CONFIG` or `~/.docker/config.json` in a dedicated "Set Auth" step (shared between Resolve and Sync stages). Image deduplication is based on target image name. `Resolve Images` outputs input lines, duplicates skipped, GHCR redirects, and final image count. `Sync` outputs total, synced, failed counts, and duration.

## Workflow cleanup

Both workflows delete old workflow runs, keeping only the last 2 days of history

## Secrets required

**Build**: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `URL_JOVYAN`, `URL_FONTS`
**Sync**: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `TCR_USERNAME`, `TCR_TOKEN`, `TCR_NAMESPACE`, `IMAGE_LIST_URL`
