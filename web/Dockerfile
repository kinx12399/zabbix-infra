FROM zabbix/zabbix-web-nginx-pgsql:ubuntu-7.0.29

USER root

# ==========================================================
# Korean locale + Korean fonts
# ==========================================================
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        fonts-nanum \
    && sed -i 's/^# *ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen ko_KR.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ko_KR.UTF-8
ENV LC_ALL=ko_KR.UTF-8

# ==========================================================
# Custom Zabbix modules
# ==========================================================
COPY usr/share/zabbix/modules/ \
     /usr/share/zabbix/modules/

# ==========================================================
# Customized Honeycomb widget
# ==========================================================
COPY usr/share/zabbix/widgets/honeycomb/assets/js/class.svghoneycomb.js \
     /usr/share/zabbix/widgets/honeycomb/assets/js/class.svghoneycomb.js

COPY usr/share/zabbix/widgets/honeycomb/assets/js/class.widget.js \
     /usr/share/zabbix/widgets/honeycomb/assets/js/class.widget.js
