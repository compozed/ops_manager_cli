FROM ruby:2.3.0

ENV OVFTOOL_VERSION 4.1.0-2459827

RUN OVFTOOL_INSTALLER=vmware-ovftool-${OVFTOOL_VERSION}-lin.x86_64.bundle \
  && wget --no-check-certificate -q https://storage.googleapis.com/mortarchive/pub/ovftool/${OVFTOOL_INSTALLER} \
  && wget --no-check-certificate -q https://storage.googleapis.com/mortarchive/pub/ovftool/${OVFTOOL_INSTALLER}.sha256 \
  && sha256sum -c ${OVFTOOL_INSTALLER}.sha256 \
  && sh ${OVFTOOL_INSTALLER} -p /usr/local --eulas-agreed --required \
  && rm -f ${OVFTOOL_INSTALLER}*

RUN wget --no-check-certificate -q https://github.com/geofffranks/spruce/releases/download/v1.0.1/spruce_1.0.1_linux_amd64.tar.gz \
    && tar -xvf spruce_1.0.1_linux_amd64.tar.gz \
    && chmod +x /spruce_1.0.1_linux_amd64/spruce \
    && ln -s /spruce_1.0.1_linux_amd64/spruce /usr/bin/.

# Installs ops_manager_cli
COPY pkg/ops_manager_cli-0.1.0.gem /tmp/

RUN gem install /tmp/ops_manager_cli-0.1.0.gem


