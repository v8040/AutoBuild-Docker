FROM sharelatex/sharelatex:latest

USER root

RUN apt-get update -y -qq && \
    apt-get install -y -qq --no-install-recommends \
    fonts-dejavu \
    fonts-noto-cjk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet && \
    tlmgr update --self --all && \
    tlmgr install scheme-full

COPY custom /usr/share/fonts/custom