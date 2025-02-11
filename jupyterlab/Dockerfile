FROM quay.io/jupyter/minimal-notebook:latest

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-dejavu \
    fonts-noto-cjk \
    unixodbc \
    unixodbc-dev \
    r-cran-rodbc \
    gfortran \
    gcc \
    zsh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

RUN mamba install --yes \
    'black' \
    'conda-pack' \
    'jupyter-lsp' \
    'jupyterlab-git' \
    'jupyterlab-language-pack-zh-cn' \
    'jupyterlab-variableinspector' \
    'jupyterlab_autoversion' \
    'jupyterlab_code_formatter' \
    'jupyterlab_execute_time' \
    'nb_conda_kernels' \
    'python-lsp-server' \
    'r-devtools' \
    'r-formatR' \
    'r-irkernel' \
    'r-languageserver' \
    'r-styler' \
    'rpy2' && \
    mamba clean --all -f -y && \
    mkdir "${CONDA_DIR}/envs" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "${HOME}"

ENV ZSH='/opt/oh-my-zsh'
ENV OSH='/opt/oh-my-bash'

COPY --chown="${NB_UID}:${NB_GID}" opt /opt
COPY --chown="${NB_UID}:${NB_GID}" jovyan "${HOME}"