# Simple Markdown Blog

A tiny Node.js app that serves Markdown posts from the `posts/` folder.

Quick start (PowerShell):

```powershell
cd c:\hua\mcp-learning
npm install
npm start
# open http://localhost:3000 in your browser
```

Features:
- Lists `.md` files in `posts/`
- Renders Markdown to HTML
- Add new posts with a simple form at `/new`

Notes:
- Filenames are sanitized; collisions are rejected.
- Static assets served from `/public`.

