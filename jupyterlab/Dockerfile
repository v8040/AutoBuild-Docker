FROM quay.io/jupyter/minimal-notebook:latest

USER root

RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
    fonts-dejavu \
    fonts-noto-cjk \
    unixodbc \
    unixodbc-dev \
    gfortran \
    gcc \
    zsh && \
    apt-get autoremove --purge -qqy && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

RUN mamba install -qy \
    'black' \
    'code-server' \
    'conda-pack' \
    'jupyter-lsp' \
    'jupyter-vscode-proxy' \
    'jupyterlab-git' \
    'jupyterlab-language-pack-zh-cn' \
    'jupyterlab-variableinspector' \
    'jupyterlab_code_formatter' \
    'jupyterlab_execute_time' \
    'nb_conda_kernels' \
    'python-lsp-server' \
    'r-devtools' \
    'r-formatR' \
    'r-irkernel' \
    'r-languageserver' \
    'r-odbc' \
    'r-styler' \
    'rpy2' && \
    mamba clean -afqy && \
    find "${CONDA_DIR}" -follow -type f \
    \( -name '*.a' -o -name '*.pyc' -o -name '*.js.map' \) \
    -delete && \
    mkdir "${CONDA_DIR}/envs" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "$HOME" && \
    rm -rf "$HOME"/.*

ENV CODE_WORKINGDIR="$HOME/work" \
    CODE_EXTENSIONSDIR="$HOME/work/.code-server/extensions"

COPY --chown="${NB_UID}:${NB_GID}" opt /opt
COPY --chown="${NB_UID}:${NB_GID}" jovyan "$HOME"