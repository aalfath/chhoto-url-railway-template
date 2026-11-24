# Chhoto URL for Railway: official upstream image, pinned by version and digest.
# The alpine flavour is used (not scratch) because it ships BusyBox for the start script and `railway ssh`.
FROM sintan1729/chhoto-url:7.11.8-alpine@sha256:f42830e0c6cbd8b582b12d868c7d69b6bca27069a284963d393e440fc78a9d4b

COPY --chmod=755 start.sh /app/start.sh

WORKDIR /app
ENTRYPOINT ["/bin/sh", "/app/start.sh"]
