FROM quay.io/jupyter/minimal-notebook:latest

USER root

RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
    fd-find \
    fonts-dejavu \
    fonts-noto-cjk \
    htop \
    jq \
    ripgrep \
    rsync \
    texlive-full \
    zsh \
    zstd && \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    apt-get autoremove --purge -qqy && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

RUN PY_VER="$("${CONDA_DIR:?}/bin/python" -c 'import platform; print(platform.python_version())')" && \
    printf 'python==%s\n' "${PY_VER}" > "${CONDA_DIR}/conda-meta/pinned" && \
    mamba update -aqy && \
    mamba install -qy \
    'bash-language-server' \
    'code-server' \
    'conda-pack' \
    'jupyter-archive' \
    'jupyter-resource-usage' \
    'jupyter-vscode-proxy' \
    'jupyterlab-git' \
    'jupyterlab-latex' \
    'jupyterlab-language-pack-zh-cn' \
    'jupyterlab-lsp' \
    'jupyterlab-variableinspector' \
    'jupyterlab_code_formatter' \
    'jupyterlab_execute_time' \
    'jupytext' \
    'nb_conda_kernels' \
    'nbdime' \
    'python-lsp-server' \
    'r-formatR' \
    'r-irkernel' \
    'r-languageserver' \
    'r-styler' \
    'rpy2' \
    'uv' && \
    mamba clean -afqy && \
    printf '%s\n' \
    'import json, pathlib, jupyterlab_language_pack_zh_CN as pkg' \
    'KEYS = ("Notebook", "Console", "Other")' \
    'for path in pathlib.Path(pkg.__path__[0]).rglob("*.json"):' \
    '    data = json.loads(path.read_text(encoding="utf-8"))' \
    '    if not isinstance(data, dict): continue' \
    '    for key in KEYS:' \
    '        value = data.get(key)' \
    '        if isinstance(value, list) and (not value or value[0] != key): data[key] = [key, *value[1:]]' \
    '    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")' \
    | "${CONDA_DIR}/bin/python" - && \
    find "${CONDA_DIR}" -type f,l \
    \( -name '*.a' -o -name '*.pyc' -o -name '*.js.map' \) \
    -delete && \
    mkdir -p "${CONDA_DIR}/envs" "${CONDA_DIR}/etc/jupyter" && \
    printf '%s\n' \
    'c.LatexConfig.latex_command = "lualatex"' \
    >> "${CONDA_DIR}/etc/jupyter/jupyter_server_config.py" && \
    fix-permissions "${CONDA_DIR}" && \
    find "/home/${NB_USER}" -mindepth 1 -maxdepth 1 -name '.*' -exec rm -rf -- {} +

ENV CODE_WORKINGDIR="/home/${NB_USER}/work" \
    CODE_EXTENSIONSDIR="/home/${NB_USER}/work/.code-server/extensions"

COPY --chown="${NB_UID}:${NB_GID}" opt /opt
COPY --chown="${NB_UID}:${NB_GID}" jovyan /home/${NB_USER}
