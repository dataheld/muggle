# syntax=docker/dockerfile:1.4

# bump this to bust the cache
ARG BUST_CACHE=1

FROM ubuntu:jammy AS base

SHELL ["/bin/bash", "-c"]
RUN set -o pipefail
ARG DEBIAN_FRONTEND=noninteractive

# default place to mount or copy project source
ARG SOURCE_MOUNT_PATH=/root/source/
ENV SOURCE_MOUNT_PATH=$SOURCE_MOUNT_PATH
RUN mkdir --parents $SOURCE_MOUNT_PATH

FROM base AS helper
RUN apt-get update && apt-get install --yes --no-install-recommends \
  ca-certificates=20211016ubuntu0.22.04.1 \
# curl, git and gpg do not have cross-arch versions, so are floated
  curl \
  gpg \
  # needed for makefile, git also does not have cross-arch version
  git \
  make=4.3-4.1build1
# install gh CLI; helpful for authenticating with GitHub
# instructions from https://github.com/cli/cli/blob/trunk/docs/install_linux.md
RUN git config --global --add safe.directory $SOURCE_MOUNT_PATH
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg;
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | tee /etc/apt/sources.list.d/github-cli.list \
  > /dev/null;
RUN apt-get update && apt-get install --yes --no-install-recommends gh

FROM helper AS rstats
ARG TARGETPLATFORM
# install r
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE="arm64-"; else ARCHITECTURE=""; fi \
  && curl -Ls https://github.com/r-lib/rig/releases/download/latest/rig-linux-"${ARCHITECTURE}"latest.tar.gz | \
  tar xz -C /usr/local
ARG R_VERSION=4.2.3
RUN rig add ${R_VERSION}
# no programmatic way to express R
ENV R_HOME=/opt/R/${R_VERSION}/lib/R
# set up RSPM
ENV RSPM_HOST=https://packagemanager.rstudio.com
ENV RSPM_PATH=cran
ENV RSPM_DISTRO_AMD64=__linux__/focal
# TODO add these once available on RSPM
# have to build from source for arm64 for now
ENV RSPM_DISTRO_ARM64=""
ARG RSPM_SNAPSHOT_DATE="2023-05-02"
ARG RSPM_SNAPSHOT_QUERY="bc1p44Vo"
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
    RSPM_SNAPSHOT_URL="${RSPM_HOST}"/"${RSPM_PATH}"/"${RSPM_DISTRO_AMD64}"/"${RSPM_SNAPSHOT_DATE}"+"${RSPM_SNAPSHOT_QUERY}"; \
  else \
    RSPM_SNAPSHOT_URL="${RSPM_HOST}"/"${RSPM_PATH}"/"${RSPM_SNAPSHOT_DATE}"; \
  fi \
  && echo "options(repos = c(CRAN = '${RSPM_SNAPSHOT_URL}'))" >> $R_HOME/etc/Rprofile.site

# set up git
WORKDIR ${SOURCE_MOUNT_PATH}
# auth into gh
RUN --mount=type=secret,required=true,id=GH_TOKEN \
  gh auth login --git-protocol "https" --with-token < /run/secrets/GH_TOKEN
RUN gh auth setup-git

FROM rstats AS builder
RUN Rscript -e "pak::pkg_install(pkg = 'roxygen2')"
COPY Makefile .
COPY DESCRIPTION .
RUN make rdeps
COPY . .
# TODO create a tarball here and copy that below
RUN make install
RUN rm -rf ${SOURCE_MOUNT_PATH}/*

FROM builder AS runner
# TODO copy from above tarball

FROM rstats AS extras
ARG R_DEPS_BUILDTIME="devtools, pkgdown, rcmdcheck, roxygen2, lintr"
SHELL ["Rscript", "-e"]
RUN pak::pkg_install(pkg = strsplit(Sys.getenv("R_DEPS_BUILDTIME"), ", ")[[1]])
SHELL ["/bin/sh", "-c"]

FROM extras AS developer
RUN apt-get update && apt-get install --yes --no-install-recommends \
  python3 \
  python3-pip \
  python3-dev
RUN pip3 install --no-cache-dir --upgrade \
  radian
RUN Rscript -e 'pak::pkg_install(pkg = "usethis")'
COPY Makefile .
COPY DESCRIPTION .
RUN make rdeps
RUN rm -rf ${SOURCE_MOUNT_PATH}/*
