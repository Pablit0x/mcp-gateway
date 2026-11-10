# Jeden kontener: Caddy (port publiczny) + Intervals (Python) + Fitatu (Node).
# Oba repozytoria sa klonowane w czasie builda. Dla powtarzalnosci podaj SHA zamiast main (ARG ponizej).
ARG PY_IMAGE=python:3.12-slim

# --- Intervals (Python): venv z zaleznosciami ---
FROM ${PY_IMAGE} AS intervals-build
ARG INTERVALS_REF=2668ed19702ad046348ed22ceb8e1456455c5d45
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/Pablit0x/intervals-mcp-server.git /src \
    && git -C /src checkout "${INTERVALS_REF}"
RUN python -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir /src

# --- Fitatu (Node): build vite + tylko zaleznosci produkcyjne ---
FROM node:22-slim AS fitatu-build
ARG FITATU_REF=ced4ad3fd870b8f08cf268760f80d6460c9b0a05
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/Pablit0x/fitatu-mcp-unofficial.git /src \
    && git -C /src checkout "${FITATU_REF}"
WORKDIR /src
RUN npm ci --include=dev && npm run build && npm prune --omit=dev

# --- Obraz koncowy ---
FROM ${PY_IMAGE}
# libstdc++ dla binarki node skopiowanej z obrazu node:22-slim
RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=caddy:2 /usr/bin/caddy /usr/local/bin/caddy
COPY --from=fitatu-build /usr/local/bin/node /usr/local/bin/node
COPY --from=intervals-build /opt/venv /opt/venv
COPY --from=fitatu-build /src/dist /app/fitatu/dist
COPY --from=fitatu-build /src/node_modules /app/fitatu/node_modules
COPY --from=fitatu-build /src/package.json /app/fitatu/package.json
COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh && useradd --create-home app
USER app
ENV PYTHONUNBUFFERED=1 HOME=/home/app
# Render podaje PORT (domyslnie 10000); Caddy slucha na nim, procesy MCP tylko na 127.0.0.1/wewnatrz kontenera.
EXPOSE 10000
CMD ["/app/start.sh"]
