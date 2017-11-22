FROM ruby:2.4.1

ENV GEM_NAME ops_manager_cli
ENV GEM_VERSION 0.7.4
ENV OVFTOOL_VERSION 4.1.0-2459827
ENV OVFTOOL_INSTALLER VMware-ovftool-${OVFTOOL_VERSION}-lin.x86_64.bundle
ARG DOWNLOAD_URL

# ================== Installs sshpass ===============
RUN echo "deb http://httpredir.debian.org/debian jessie utils" >> sources.list
RUN apt-get update
RUN apt-get install -y sshpass unzip

# ================== Installs OVF tools ==============
RUN echo $DOWNLOAD_URL
RUN wget -v ${DOWNLOAD_URL} \
  && sh ${OVFTOOL_INSTALLER} -p /usr/local --eulas-agreed --required \
  && rm -f ${OVFTOOL_INSTALLER}*

# ================== Installs Spruce ==============
RUN wget -v --no-check-certificate https://github.com/geofffranks/spruce/releases/download/v1.13.1/spruce-linux-amd64 \
    && chmod +x spruce-linux-amd64 \
    && ln -s /spruce-linux-amd64 /usr/bin/spruce

# ================== Installs JQ ==============
RUN wget -v -O /usr/local/bin/jq --no-check-certificate https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
RUN chmod +x /usr/local/bin/jq

# ================== Installs ops_manager_cli gem ==============
COPY pkg/${GEM_NAME}-${GEM_VERSION}.gem /tmp/
RUN gem install /tmp/${GEM_NAME}-${GEM_VERSION}.gem

