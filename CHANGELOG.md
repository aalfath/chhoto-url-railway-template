# Changelog

## 7.11.8 (2026-11-24)

First release of the Railway template.

- Chhoto URL 7.11.8, official image `sintan1729/chhoto-url:7.11.8-alpine@sha256:f42830e0c6cbd8b582b12d868c7d69b6bca27069a284963d393e440fc78a9d4b`.
- SQLite database in WAL mode on the `/data` volume.
- Generated admin password, API key and session key; the public URL is set as the site URL.
- Start script: listens on `PORT`, refuses an empty password, exits non-zero when the app dies or its health endpoint stops answering.
