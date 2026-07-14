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
    zsh \
    zstd && \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    apt-get autoremove --purge -qqy && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

RUN mamba update -aqy && \
    mamba install -qy \
    'bash-language-server' \
    'code-server' \
    'conda-pack' \
    'jupyter-archive' \
    'jupyter-resource-usage' \
    'jupyter-vscode-proxy' \
    'jupyterlab-git' \
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
    find $(python3 -c 'import os, jupyterlab_language_pack_zh_CN as p; print(os.path.dirname(p.__file__))') \
    -name '*.json' -exec sh -c ' \
    for FILE; do \
    jq "if has(\"Notebook\") then .Notebook[0] = \"Notebook\" else . end | if has(\"Console\") then .Console[0] = \"Console\" else . end | if has(\"Other\") then .Other[0] = \"Other\" else . end" "${FILE}" > "${FILE}.tmp" && mv "${FILE}.tmp" "${FILE}"; \
    done \
    ' _ {} + && \
    find -L "${CONDA_DIR}" -type f \
    \( -name '*.a' -o -name '*.pyc' -o -name '*.js.map' \) \
    -delete && \
    mkdir -p "${CONDA_DIR}/envs" && \
    fix-permissions "${CONDA_DIR}" && \
    rm -rf "/home/${NB_USER}"/.[!.]*

ENV CODE_WORKINGDIR="/home/${NB_USER}/work" \
    CODE_EXTENSIONSDIR="/home/${NB_USER}/work/.code-server/extensions"

COPY --chown="${NB_UID}:${NB_GID}" opt /opt
COPY --chown="${NB_UID}:${NB_GID}" jovyan /home/${NB_USER}
