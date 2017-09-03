FROM BASEIMAGE

COPY prometheus promtool /bin/
COPY prometheus.yml      /etc/prometheus/prometheus.yml
COPY console_libraries/  /usr/share/prometheus/console_libraries/
COPY consoles/           /usr/share/prometheus/consoles/
COPY console_libraries/  /etc/prometheus/console_libraries/
COPY consoles/           /etc/prometheus/consoles/

ENTRYPOINT ["/bin/prometheus"]
