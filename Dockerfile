FROM docker.io/louislam/uptime-kuma:2.5.9@sha256:e88415a90dd2f7efecdbc18de0490aff292764a3ac471531bf1d0481725591bd

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENTRYPOINT []
CMD ["/app/start.sh"]
