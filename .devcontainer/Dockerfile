# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.163.1/containers/debian/.devcontainer/base.Dockerfile


ARG VARIANT="3"
FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT}

RUN apt update && apt install -y libsodium-dev libsecp256k1-dev libgmp-dev
COPY requirements.txt /tmp/pip-tmp/
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
    && rm -rf /tmp/pip-tmp
RUN wget -q -O ligo.deb https://ligolang.org/deb/ligo.deb
RUN apt install ./ligo.deb

# ** [Optional] Uncomment this section to install additional packages. **
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

