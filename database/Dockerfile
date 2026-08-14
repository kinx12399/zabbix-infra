FROM timescale/timescaledb-ha:pg16.14-ts2.28.3-all-oss

USER root

RUN mkdir -p \
      /etc/patroni \
      /opt/zabbix-init \
    && chown -R postgres:postgres \
      /etc/patroni \
      /opt/zabbix-init

COPY --chown=postgres:postgres \
    etc/patroni/patroni.yml \
    /etc/patroni/patroni.yml

COPY --chown=postgres:postgres \
    init/prepare-zabbix-db.sh \
    /opt/zabbix-init/prepare-zabbix-db.sh

COPY --chown=postgres:postgres \
    init/restore-zabbix-config.sh \
    /opt/zabbix-init/restore-zabbix-config.sh

RUN chmod 750 \
    /opt/zabbix-init/prepare-zabbix-db.sh \
    /opt/zabbix-init/restore-zabbix-config.sh

USER postgres
