const express = require('express');
const fs = require('fs');
const path = require('path');
const marked = require('marked');
const multer = require('multer');

const app = express();
const PORT = process.env.PORT || 3000;

const POSTS_DIR = path.join(__dirname, 'posts');

// ensure posts dir exists
if (!fs.existsSync(POSTS_DIR)) fs.mkdirSync(POSTS_DIR, { recursive: true });

app.use(express.urlencoded({ extended: false }));
app.use('/public', express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  const files = fs.readdirSync(POSTS_DIR).filter(f => f.endsWith('.md'));
  const posts = files.map(f => {
    const content = fs.readFileSync(path.join(POSTS_DIR, f), 'utf8');
    const firstLine = content.split('\n').find(l => l.trim());
    const title = firstLine && firstLine.startsWith('#') ? firstLine.replace(/^#+\s*/, '') : f.replace('.md', '');
    return { file: f, title };
  });

  res.send(`<!doctype html>
  <html>
    <head>
      <meta charset="utf-8">
      <title>Simple Markdown Blog</title>
      <link rel="stylesheet" href="/public/style.css">
    </head>
    <body>
      <div class="container">
        <h1>Simple Markdown Blog</h1>
        <a class="new-post" href="/new">+ New Post</a>
        <ul class="posts">
          ${posts.map(p => `<li><a href="/post/${encodeURIComponent(p.file)}">${p.title}</a></li>`).join('\n')}
        </ul>
      </div>
    </body>
  </html>`);
});

app.get('/post/:file', (req, res) => {
  const file = req.params.file;
  const filePath = path.join(POSTS_DIR, file);
  if (!filePath.startsWith(POSTS_DIR) || !fs.existsSync(filePath)) {
    return res.status(404).send('Not found');
  }
  const md = fs.readFileSync(filePath, 'utf8');
  const html = marked.parse(md);
  res.send(`<!doctype html>
  <html>
    <head>
      <meta charset="utf-8">
      <title>Post</title>
      <link rel="stylesheet" href="/public/style.css">
    </head>
    <body>
      <div class="container">
        <a href="/">← Back</a>
        <div class="post">${html}</div>
      </div>
    </body>
  </html>`);
});

app.get('/new', (req, res) => {
  res.send(`<!doctype html>
  <html>
    <head>
      <meta charset="utf-8">
      <title>New Post</title>
      <link rel="stylesheet" href="/public/style.css">
    </head>
    <body>
      <div class="container">
        <a href="/">← Back</a>
        <h2>New Post</h2>
        <form action="/new" method="post">
          <label>Filename (no extension):<br><input name="filename" required></label><br>
          <label>Content (Markdown):<br><textarea name="content" rows="15" cols="80" required></textarea></label><br>
          <button type="submit">Create</button>
        </form>
      </div>
    </body>
  </html>`);
});

app.post('/new', (req, res) => {
  const filename = req.body.filename.replace(/[^a-z0-9-_.]/gi, '-');
  const content = req.body.content || '';
  const filePath = path.join(POSTS_DIR, filename + '.md');
  if (!filePath.startsWith(POSTS_DIR)) return res.status(400).send('Invalid filename');
  if (fs.existsSync(filePath)) return res.status(400).send('File exists');
  fs.writeFileSync(filePath, content, 'utf8');
  res.redirect('/post/' + encodeURIComponent(path.basename(filePath)));
});

app.listen(PORT, () => console.log(`Server listening on http://localhost:${PORT}`));
