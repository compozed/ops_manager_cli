FROM ruby:2.3.0

ENV GEM_NAME ops_manager_cli
ENV GEM_VERSION 0.2.5
ENV OVFTOOL_VERSION 4.1.0-2459827
ENV OVFTOOL_INSTALLER vmware-ovftool-${OVFTOOL_VERSION}-lin.x86_64.bundle 
ARG DOWNLOAD_URL=https://storage.googleapis.com/mortarchive/pub/ovftool/${OVFTOOL_INSTALLER} 
ENV DOWNLOAD_URL ${DOWNLOAD_URL}

# ================== Installs OVF tools ==============
RUN echo $DOWNLOAD_URL
RUN wget -q ${DOWNLOAD_URL} \
  && wget -q ${DOWNLOAD_URL}.sha256 \
  && sha256sum -c ${OVFTOOL_INSTALLER}.sha256 \
  && sh ${OVFTOOL_INSTALLER} -p /usr/local --eulas-agreed --required \
  && rm -f ${OVFTOOL_INSTALLER}*

# ================== Installs Spruce ==============
RUN wget --no-check-certificate -q https://github.com/geofffranks/spruce/releases/download/v1.0.1/spruce_1.0.1_linux_amd64.tar.gz \
    && tar -xvf spruce_1.0.1_linux_amd64.tar.gz \
    && chmod +x /spruce_1.0.1_linux_amd64/spruce \
    && ln -s /spruce_1.0.1_linux_amd64/spruce /usr/bin/.

# ================== Installs JQ ==============
RUN wget -q -O /usr/local/bin/jq --no-check-certificate https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
RUN chmod +x /usr/local/bin/jq

# ================== Installs ops_manager_cli gem ==============
COPY pkg/${GEM_NAME}-${GEM_VERSION}.gem /tmp/

RUN gem install /tmp/${GEM_NAME}-${GEM_VERSION}.gem


