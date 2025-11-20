FROM --platform=linux/amd64 sharelatex/sharelatex:latest

USER root

RUN apt update -qq && \
    apt install -y -qq --no-install-recommends \
    fonts-dejavu \
    fonts-noto-cjk && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet && \
    tlmgr update --self --all && \
    tlmgr install scheme-full

COPY custom /usr/share/fonts/custom