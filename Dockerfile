FROM ruby:2.3.0

ENV OVFTOOL_VERSION 4.1.0-2459827
RUN echo $HTTP_PROXY
RUN OVFTOOL_INSTALLER=vmware-ovftool-${OVFTOOL_VERSION}-lin.x86_64.bundle \
  && wget --no-check-certificate -q https://storage.googleapis.com/mortarchive/pub/ovftool/${OVFTOOL_INSTALLER} \
  && wget --no-check-certificate -q https://storage.googleapis.com/mortarchive/pub/ovftool/${OVFTOOL_INSTALLER}.sha256 \
  && sha256sum -c ${OVFTOOL_INSTALLER}.sha256 \
  && sh ${OVFTOOL_INSTALLER} -p /usr/local --eulas-agreed --required \
  && rm -f ${OVFTOOL_INSTALLER}*

# Installs ops_manager_cli
COPY ops_manager_cli-0.1.0.gem /tmp/

RUN gem install /tmp/ops_manager_cli-0.1.0.gem


