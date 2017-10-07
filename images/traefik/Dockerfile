FROM scratch
COPY traefik /
ADD https://raw.githubusercontent.com/containous/traefik/master/script/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["/traefik"]
