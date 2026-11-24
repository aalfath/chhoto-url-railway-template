[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/chhoto-url?utm_medium=integration&utm_source=button&utm_campaign=chhoto-url)

# Chhoto URL on Railway

One-click Railway template for [Chhoto URL](https://github.com/SinTan1729/chhoto-url), a small and very fast self-hosted URL shortener written in Rust, with a web UI, a REST API, custom slugs, link expiry, QR codes and hit counts.

- **Version:** Chhoto URL **7.11.8**, official image `sintan1729/chhoto-url:7.11.8-alpine`, pinned by digest `sha256:f42830e0c6cbd8b582b12d868c7d69b6bca27069a284963d393e440fc78a9d4b`.
- **Services:** one service, `Chhoto URL`, built from this repo's `Dockerfile`. Its SQLite database (WAL mode) and the app's daily backups live on a Railway volume at `/data`.
- **Resources:** fits Railway's Free plan easily (about 5 MB RAM in use, 0.5 GB limit tested).

## What you get after deploy

1. Open the service's public URL and log in with the password in the service's **Variables** tab (`CHHOTO_PASSWORD`).
2. Create short links in the web UI, or with the API using `CHHOTO_API_KEY`:

```sh
curl -X POST -H "X-API-Key: YOUR-API-KEY" -H "Content-Type: application/json" \
  -d '{"shortlink":"docs","longlink":"https://example.com/docs"}' \
  https://YOUR-DOMAIN/api/new
```

Leave `shortlink` out to get a generated adjective-noun slug. The full API is in upstream's [CLI.md](https://github.com/SinTan1729/chhoto-url/blob/main/docs/CLI.md).

## Variables

| Variable | Default | What it does |
|---|---|---|
| `CHHOTO_PASSWORD` | `${{secret(32)}}` | Admin password for the web UI. Generated; change it any time. |
| `CHHOTO_API_KEY` | `${{secret(88, base64url)}}` | API key for the `X-API-Key` header (512+ bits, as upstream recommends). |
| `CHHOTO_SESSION_MASTER_KEY` | `${{secret(88, base64url)}}` | Signs login cookies, so you stay logged in across redeploys. |
| `CHHOTO_SITE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL used for copy buttons and QR codes. Set it to your custom domain if you add one. |
| `PORT` | `4567` | Port the app listens on (Railway routes the public domain to it). |

The start script sets the rest: database at `/data/urls.sqlite`, WAL mode, temporary (307) redirects, adjective-noun slugs, and `CHHOTO_EXIT_ON_NO_AUTH=True`. Every other upstream option from [INSTALLATION.md](https://github.com/SinTan1729/chhoto-url/blob/main/docs/INSTALLATION.md) (public mode, OIDC login, custom title, slug style and length, permanent redirects) can be added as a variable on the service.

## How this wrapper behaves

- Listens on Railway's `PORT`, on IPv4 and IPv6. Health check path: `/api/version`.
- Refuses to start with an empty password, so the admin UI is never open.
- Watches the app's internal `/healthz` endpoint (it also checks the database) and exits non-zero if the app stops or stops answering, so Railway's `ON_FAILURE` restart policy restarts it.

## Updates

Railway shows an "update available" notice to everyone who deployed this template when a change is merged to this repo's `main` branch. We bump the pinned upstream image there (see `CHANGELOG.md`, breaking changes first). Your links stay on the `/data` volume across updates. Upstream also keeps daily backups of the database in `/data/backups`.

## Local test

`test/compose.yaml` runs the same image with a 512 MB / 1 CPU limit (`API_KEY` and `MASTER_KEY` from a `.env` file).

## Licence

Chhoto URL is MIT-licensed by Sayantan Santra. This wrapper is MIT too.
