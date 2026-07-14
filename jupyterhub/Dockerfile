FROM quay.io/jupyterhub/jupyterhub:latest

RUN python3 -m pip -qq install --progress-bar off --no-compile --no-cache-dir --break-system-packages \
    dockerspawner \
    jupyterhub-idle-culler \
    jupyterhub-nativeauthenticator