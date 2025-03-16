FROM sharelatex/sharelatex:latest

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-dejavu \
    fonts-noto-cjk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLO https://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh && \
    sh update-tlmgr-latest.sh -- --upgrade && \
    tlmgr option autobackup 0 && \
    tlmgr option docfiles 0 && \
    tlmgr option srcfiles 0 && \
    tlmgr update --self --all && \
    tlmgr install scheme-full

COPY custom /usr/share/fonts/custom