# Laeka Call Distribution — Local Chat UI

Standalone Next.js app deployed by `install-laeka.sh`. Provides a chat interface to speak with Laeka via the local `claude` subprocess. Accessible from phone on the same WiFi.

## Prerequisites

- Node.js 20+
- `claude` CLI installed and authenticated (`claude --version`)
- Laeka canonical + memory installed (handled by `install-laeka.sh`)

## Setup

```bash
cd ~/Documents/laeka-call-distribution
npm install
```

## Configure client

Edit `config/client-config.json`:

```json
{
  "clientName": "daniel",
  "port": 8080,
  "userName": "Daniel",
  "claudeModel": ""
}
```

- `clientName` — URL path segment: `http://localhost:8080/daniel`
- `userName` — display name in the chat UI
- `claudeModel` — optional model override (e.g. `claude-sonnet-4-6`). Empty = use claude default.

## Run (dev)

```bash
npm run dev
```

Opens on `http://0.0.0.0:8080`. Access from phone: `http://<mac-local-ip>:8080/<clientName>`

Find your local IP: `ipconfig getifaddr en0`

## Run (production)

```bash
npm run build
npm start
```

## URL structure

- `http://localhost:8080/` → redirects to `/<clientName>`
- `http://localhost:8080/<clientName>` → main chat
- `http://<local-ip>:8080/<clientName>` → phone access (same WiFi)

## Architecture

```
POST /api/chat
  └─ spawn('claude', ['--print']) with stdin = prompt
  └─ stream stdout as SSE text deltas
  └─ client reads SSE and appends to chat
```

Conversation history is passed inline with each request — no database, no auth, trust local network (V1).

## Future: voice integration

The `/api/chat` route is designed for SSE streaming. To add voice:
- STT: POST `/api/stt` (OpenAI Whisper or local Whisper)
- TTS: POST `/api/tts` (ElevenLabs or local TTS)
- Reference: `~/Documents/laeka-field/` for patterns
