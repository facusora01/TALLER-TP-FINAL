# TAL-22 · Setup proyecto React + Vite

El front lo armamos con Vite, en un comando:

```bash
npm create vite@latest frontend -- --template react
cd frontend && npm install
```

- `frontend` => carpeta donde se crea
- `--template react` => usa la plantilla de React (JS)

Queda en `frontend/` con todo lo que arma Vite por defecto (`src/`, `public/`,
`index.html`, `vite.config.js`). Por ahora es solo eso: el routing, las vistas y
el cliente WebSocket los sumamos en M4.

Para levantarlo en modo dev: `npm run dev`.
