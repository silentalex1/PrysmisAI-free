const express = require('express');
const path = require('path');
const crypto = require('crypto');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json({ limit: '50mb' }));

const studioSessions = new Map();
const studioFiles = new Map();
const pendingCommands = new Map();
const adminCodes = new Map();

async function geminiComplete(apiKey, model, messages, systemInstruction = '') {
  const contents = messages.map(msg => ({
    role: msg.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: msg.content }]
  }));

  const body = {
    contents,
    generationConfig: { maxOutputTokens: 4096, temperature: 0.7 }
  };

  if (systemInstruction) {
    body.system_instruction = { parts: [{ text: systemInstruction }] };
  }

  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error('Gemini error ' + response.status + ': ' + errText.slice(0, 200));
  }
  const data = await response.json();
  return data.candidates[0].content.parts[0].text || '';
}

app.use('/aichat', express.static(path.join(__dirname, 'aichat')));
app.use('/auth', express.static(path.join(__dirname, 'auth')));
app.use('/API', express.static(path.join(__dirname, 'API')));
app.use('/screenshare', express.static(path.join(__dirname, 'screenshare')));
app.use(express.static(path.join(__dirname)));

app.get('/', (req, res) => res.sendFile(path.join(__dirname, 'index.html')));
app.get('/aichat', (req, res) => res.sendFile(path.join(__dirname, 'aichat', 'index.html')));
app.get('/auth', (req, res) => res.sendFile(path.join(__dirname, 'auth', 'index.html')));
app.get('/API', (req, res) => res.sendFile(path.join(__dirname, 'API', 'index.html')));

app.get('/api/bot/stats', (req, res) => {
  const botSecret = req.headers['x-bot-secret'];
  if (!botSecret || botSecret !== process.env.BOT_SECRET) return res.status(401).json({ error: 'Unauthorized' });
  return res.json({
    status: 'online',
    activeSessions: studioSessions.size,
    uptime: process.uptime()
  });
});

const fs = require('fs');
const USERS_FILE = path.join(__dirname, 'users.json');

function getUsers() {
  try { return fs.existsSync(USERS_FILE) ? JSON.parse(fs.readFileSync(USERS_FILE, 'utf8')) : {}; } catch(e) { return {}; }
}
function saveUsers(users) {
  try { fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2)); } catch(e) {}
}

app.post('/api/auth/register', (req, res) => {
  const { username, password } = req.body;
  const users = getUsers();
  if (users[username.toLowerCase()]) return res.status(409).json({ error: 'Username taken' });
  users[username.toLowerCase()] = { username, password, role: 'user', createdAt: Date.now() };
  saveUsers(users);
  return res.json({ success: true, username, role: 'user' });
});

app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  const users = getUsers();
  const user = users[username.toLowerCase()];
  if (!user || user.password !== password) return res.status(401).json({ error: 'Invalid credentials' });
  return res.json({ success: true, username: user.username, role: user.role || 'user' });
});

app.post('/api/studio/connect', (req, res) => {
  const { token } = req.body;
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false });
  session.pluginConnected = true;
  pendingCommands.set(token, []);
  return res.json({ success: true, username: session.username, model: 'gemini-1.5-pro' });
});

app.post('/api/studio/command', (req, res) => {
  const { token, command } = req.body;
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false });
  const cmds = pendingCommands.get(token) || [];
  command.id = crypto.randomUUID();
  cmds.push(command);
  pendingCommands.set(token, cmds);
  return res.json({ success: true, commandId: command.id });
});

app.post('/api/studio/register-token', (req, res) => {
  const { token, username } = req.body;
  studioSessions.set(token, { username, createdAt: Date.now(), pluginConnected: false });
  return res.json({ success: true });
});

app.post('/api/studio/animate', async (req, res) => {
  const { token, prompt, apiKey } = req.body;
  if (!apiKey) return res.json({ success: false, error: 'No Gemini API key.' });
  try {
    const system = 'You are an elite Roblox Lua animation engineer. Return ONLY raw executable Lua code using TweenService. No markdown. No comments.';
    const code = await geminiComplete(apiKey, 'gemini-1.5-pro', [{ role: 'user', content: prompt }], system);
    return res.json({ success: true, code: code.replace(/```lua|```/gi, '').trim() });
  } catch(err) { return res.json({ success: false, error: err.message }); }
});

app.listen(PORT, () => console.log('PrysmisAI running on http://localhost:' + PORT));
