FROM quay.io/jupyter/minimal-notebook:latest

USER root

RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
    build-essential \
    fonts-dejavu \
    fonts-noto-cjk \
    gfortran \
    htop \
    zsh && \
    apt-get autoremove --purge -qqy && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

RUN mamba update -aqy && \
    mamba install -qy \
    'bash-language-server' \
    'code-server' \
    'conda-pack' \
    'jupyter-resource-usage' \
    'jupyter-vscode-proxy' \
    'jupyterlab-git' \
    'jupyterlab-language-pack-zh-cn' \
    'jupyterlab-lsp' \
    'jupyterlab-variableinspector' \
    'jupyterlab_code_formatter' \
    'jupyterlab_execute_time' \
    'nb_conda_kernels' \
    'pipx' \
    'python-lsp-server' \
    'r-formatR' \
    'r-irkernel' \
    'r-languageserver' \
    'r-styler' \
    'rpy2' && \
    mamba clean -afqy && \
    find $(python3 -c "import os, jupyterlab_language_pack_zh_CN as p; print(os.path.dirname(p.__file__))") \
    -name '*.json' -exec sed -i \
    -e '/^[[:space:]]*"Notebook": \[/{n;s/".*"/"Notebook"/;}' \
    -e '/^[[:space:]]*"Console": \[/{n;s/".*"/"Console"/;}' \
    -e '/^[[:space:]]*"Other": \[/{n;s/".*"/"Other"/;}' \
    {} + && \
    find "${CONDA_DIR}" -follow -type f \
    \( -name '*.a' -o -name '*.pyc' -o -name '*.js.map' \) \
    -delete && \
    mkdir -p "${CONDA_DIR}/envs" && \
    fix-permissions "${CONDA_DIR}" && \
    rm -rf "/home/${NB_USER}"/.[!.]*

ENV CODE_WORKINGDIR="/home/${NB_USER}/work" \
    CODE_EXTENSIONSDIR="/home/${NB_USER}/work/.code-server/extensions"

COPY --chown="${NB_UID}:${NB_GID}" opt /opt
COPY --chown="${NB_UID}:${NB_GID}" jovyan /home/${NB_USER}