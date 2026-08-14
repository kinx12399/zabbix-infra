FROM zabbix/zabbix-proxy-sqlite3:ubuntu-7.0.29

USER root

RUN mkdir -p /etc/zabbix/zabbix_proxy.d \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        dnsutils \
        rtmpdump \
        gawk \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY usr/lib/zabbix/externalscripts/ \
     /usr/lib/zabbix/externalscripts/

COPY etc/zabbix/zabbix_proxy.conf \
     /etc/zabbix/zabbix_proxy.conf

RUN chmod 755 \
    /usr/lib/zabbix/externalscripts/*.sh

