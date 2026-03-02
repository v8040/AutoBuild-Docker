FROM --platform=linux/amd64 sharelatex/sharelatex:latest

USER root

RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
    fonts-dejavu \
    fonts-noto-cjk \
    fontconfig && \
    apt-get autoremove --purge -qqy && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet && \
    tlmgr update -q --self --all --reinstall-forcibly-removed && \
    tlmgr install -q scheme-full && \
    tlmgr path add && \
    tlmgr backup -q --clean --all

COPY custom /usr/share/fonts/custom