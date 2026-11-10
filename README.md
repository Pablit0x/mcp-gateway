# mcp-gateway

Jeden serwis Render (Docker, darmowy plan) z dwoma serwerami MCP. W kontenerze dziala:

- Caddy na porcie `$PORT` (publiczny), rozdziela ruch,
- Intervals MCP (Python, `127.0.0.1:8001`),
- Fitatu MCP (Node, `127.0.0.1:8002`).

Jesli ktorykolwiek proces padnie, `start.sh` konczy caly kontener i Render go uruchamia ponownie.

## Sciezki

| Sciezka | Dokad trafia |
| --- | --- |
| `/health` | Caddy odpowiada sam: `200 {"status":"ok"}` (Render health check, cron-job.org) |
| `/intervals/mcp` | Intervals MCP (prefiks `/intervals` jest obcinany) |
| `/mcp` | Fitatu MCP (z OAuth) |
| `/.well-known/*`, `/register`, `/authorize`, `/token`, `/oauth/confirm` | endpointy OAuth Fitatu, musza byc w katalogu glownym domeny |

Adresy do connectora w Claude: `https://TWOJ-SERWIS.onrender.com/intervals/mcp` oraz `https://TWOJ-SERWIS.onrender.com/mcp`.

## Zmienne srodowiskowe (ustaw w Render, bez wartosci w repo)

| Zmienna | Dla czego |
| --- | --- |
| `API_KEY` | Intervals: klucz API z Intervals.icu |
| `ATHLETE_ID` | Intervals: ID atlety |
| `FITATU_EMAIL` | Fitatu: login |
| `FITATU_PASSWORD` | Fitatu: haslo |
| `MCP_AUTH_PASSWORD` | Fitatu: haslo OAuth do autoryzacji klienta (min. 16 znakow) |

`PORT` ustawia Render. Kazdy serwer dostaje tylko swoje sekrety (patrz `start.sh`).

## Przypiete wersje

Dockerfile klonuje oba repozytoria w czasie builda i przelacza je na konkretny commit:

- `ARG INTERVALS_REF` - `Pablit0x/intervals-mcp-server`, galaz `develop` (tylko tam jest obsluga `FASTMCP_PORT` i komplet narzedzi; `main` tego nie ma)
- `ARG FITATU_REF` - `Pablit0x/fitatu-mcp-unofficial`

Jak zaktualizowac:

1. Pobierz aktualne SHA galezi (Intervals: `develop`, Fitatu: `main`):

   ```bash
   git ls-remote https://github.com/Pablit0x/intervals-mcp-server.git refs/heads/develop
   git ls-remote https://github.com/Pablit0x/fitatu-mcp-unofficial.git refs/heads/main
   ```

2. Wpisz nowe SHA jako wartosci domyslne `ARG INTERVALS_REF=` i `ARG FITATU_REF=` w `Dockerfile`.
3. Zrob commit i push. Render zbuduje nowy obraz.

Jednorazowo mozna tez zbudowac z innym SHA bez zmiany pliku: `docker build --build-arg INTERVALS_REF=SHA -t mcp-gateway .`

## Test lokalny

```bash
docker build -t mcp-gateway .
docker run -d --name mcpgw -p 10000:10000 -e PORT=10000 \
  -e API_KEY=test -e ATHLETE_ID=i0 -e FITATU_EMAIL=test@example.com \
  -e FITATU_PASSWORD=test -e MCP_AUTH_PASSWORD=testtesttesttest1234 mcp-gateway
curl -i localhost:10000/health
```
