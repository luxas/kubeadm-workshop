FROM BASEIMAGE

COPY prometheus promtool /bin/
COPY prometheus.yml      /etc/prometheus/prometheus.yml
COPY console_libraries/  /usr/share/prometheus/console_libraries/
COPY consoles/           /usr/share/prometheus/consoles/
COPY console_libraries/  /etc/prometheus/console_libraries/
COPY consoles/           /etc/prometheus/consoles/

ENTRYPOINT ["/bin/prometheus"]
CMD [ "-config.file=/etc/prometheus/prometheus.yml", \
      "-storage.local.path=/prometheus", \
      "-web.console.libraries=/usr/share/prometheus/console_libraries", \
      "-web.console.templates=/usr/share/prometheus/consoles" ]
