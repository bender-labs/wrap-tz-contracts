# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.163.1/containers/debian/.devcontainer/base.Dockerfile

# [Choice] Debian version: buster, stretch
ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

RUN wget -q -O ligo.deb https://ligolang.org/deb/ligo.deb
RUN apt install ./ligo.deb
# ** [Optional] Uncomment this section to install additional packages. **
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

