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

function getDeepinfraKey(reqBody) {
  return (reqBody && reqBody.apiKey) || process.env.DEEPINFRA_API_KEY || '';
}

async function deepinfraStream(apiKey, model, messages, res) {
  const response = await fetch('https://api.deepinfra.com/v1/openai/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + apiKey
    },
    body: JSON.stringify({ model, messages, stream: true, max_tokens: 4096, temperature: 0.7 })
  });
  if (!response.ok) {
    const errText = await response.text().catch(() => '');
    throw new Error('DeepInfra error ' + response.status + ': ' + errText.slice(0, 200));
  }
  return response;
}

async function deepinfraComplete(apiKey, model, messages) {
  const response = await fetch('https://api.deepinfra.com/v1/openai/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + apiKey
    },
    body: JSON.stringify({ model, messages, stream: false, max_tokens: 4096, temperature: 0.7 })
  });
  if (!response.ok) {
    const errText = await response.text().catch(() => '');
    throw new Error('DeepInfra error ' + response.status + ': ' + errText.slice(0, 200));
  }
  const data = await response.json();
  return data.choices[0].message.content || '';
}

async function streamDeepinfraToRes(apiKey, model, messages, res) {
  const deepResp = await deepinfraStream(apiKey, model, messages, res);
  const reader = deepResp.body;
  let buffer = '';
  for await (const chunk of reader) {
    buffer += Buffer.isBuffer(chunk) ? chunk.toString() : chunk;
    const lines = buffer.split('\n');
    buffer = lines.pop();
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed === 'data: [DONE]') continue;
      if (trimmed.startsWith('data: ')) {
        try {
          const parsed = JSON.parse(trimmed.slice(6));
          const delta = parsed.choices && parsed.choices[0] && parsed.choices[0].delta;
          const text = (delta && delta.content) ? delta.content : '';
          if (text) res.write('data: ' + JSON.stringify({ text }) + '\n\n');
        } catch(e) {}
      }
    }
  }
  res.write('data: [DONE]\n\n');
  res.end();
}


app.use('/aichat', express.static(path.join(__dirname, 'aichat')));
app.use('/auth', express.static(path.join(__dirname, 'auth')));
app.use('/API', express.static(path.join(__dirname, 'API')));
app.use('/screenshare', express.static(path.join(__dirname, 'screenshare')));
app.use(express.static(path.join(__dirname)));

app.get('/', function(req, res) {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/aichat', function(req, res) {
  res.sendFile(path.join(__dirname, 'aichat', 'index.html'));
});

app.get('/auth', function(req, res) {
  res.sendFile(path.join(__dirname, 'auth', 'index.html'));
});

app.get('/API', function(req, res) {
  res.sendFile(path.join(__dirname, 'API', 'index.html'));
});

app.post('/api/chat', async function(req, res) {
  const { messages, system, apiKey: bodyKey } = req.body;
  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: 'Missing messages' });
  }

  const apiKey = bodyKey || process.env.DEEPINFRA_API_KEY || '';
  if (!apiKey) {
    res.setHeader('Content-Type', 'text/event-stream');
    res.write('data: ' + JSON.stringify({ error: 'No DeepInfra API key configured.' }) + '\n\n');
    res.write('data: [DONE]\n\n');
    return res.end();
  }

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  try {
    const deepMessages = [];
    if (system) deepMessages.push({ role: 'system', content: system });
    for (const msg of messages) {
      if (Array.isArray(msg.content)) {
        const text = msg.content.filter(p => p.type === 'text').map(p => p.text).join('\n');
        deepMessages.push({ role: msg.role, content: text || '' });
      } else {
        deepMessages.push({ role: msg.role, content: typeof msg.content === 'string' ? msg.content : JSON.stringify(msg.content) });
      }
    }
    const model = req.body.model || 'deepseek-ai/DeepSeek-V3';
    await streamDeepinfraToRes(apiKey, model, deepMessages, res);
  } catch (err) {
    res.write('data: ' + JSON.stringify({ error: err.message || 'AI error' }) + '\n\n');
    res.write('data: [DONE]\n\n');
    res.end();
  }
});

app.get('/api/bot/stats', function(req, res) {
  const botSecret = req.headers['x-bot-secret'];
  if (!botSecret || botSecret !== process.env.BOT_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  return res.json({
    status: 'online',
    port: PORT,
    activeSessions: studioSessions.size,
    connectedPlugins: Array.from(studioSessions.values()).filter(s => s.pluginConnected).length,
    uptime: process.uptime()
  });
});

app.post('/api/bot/setadmin', function(req, res) {
  const botSecret = req.headers['x-bot-secret'];
  if (!botSecret || botSecret !== process.env.BOT_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const { username, code } = req.body;
  if (!username || !code) return res.status(400).json({ error: 'Missing username or code' });

  adminCodes.set(code, {
    username: username.toLowerCase(),
    createdAt: Date.now(),
    expiresAt: Date.now() + 30 * 60 * 1000
  });

  return res.json({ success: true });
});

app.post('/api/bot/verify', function(req, res) {
  const { code, username } = req.body;
  if (!code || !username) return res.status(400).json({ error: 'Missing code or username' });

  const entry = adminCodes.get(code);
  if (!entry) return res.status(404).json({ error: 'Invalid code' });
  if (Date.now() > entry.expiresAt) {
    adminCodes.delete(code);
    return res.status(410).json({ error: 'Code expired' });
  }
  if (entry.username !== username.toLowerCase()) {
    return res.status(403).json({ error: 'Code does not match this username' });
  }

  adminCodes.delete(code);

  const users = getUsers();
  if (!users[username.toLowerCase()]) {
    return res.status(404).json({ error: 'User not found on site' });
  }
  users[username.toLowerCase()].role = 'admin';
  saveUsers(users);

  return res.json({ success: true, username: username });
});

app.post('/api/bot/run', function(req, res) {
  const botSecret = req.headers['x-bot-secret'];
  if (!botSecret || botSecret !== process.env.BOT_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const { command } = req.body;
  if (!command) return res.status(400).json({ error: 'Missing command' });

  const { exec } = require('child_process');
  exec(command, { timeout: 15000 }, function(err, stdout, stderr) {
    return res.json({
      success: !err,
      stdout: stdout || '',
      stderr: stderr || '',
      error: err ? err.message : null
    });
  });
});

const fs = require('fs');
const USERS_FILE = path.join(__dirname, 'users.json');

function getUsers() {
  try {
    if (fs.existsSync(USERS_FILE)) return JSON.parse(fs.readFileSync(USERS_FILE, 'utf8'));
    return {};
  } catch(e) { return {}; }
}

function saveUsers(users) {
  try { fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2)); } catch(e) {}
}

app.post('/api/auth/register', function(req, res) {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: 'Missing fields' });
  const users = getUsers();
  if (users[username.toLowerCase()]) return res.status(409).json({ error: 'Username taken' });
  users[username.toLowerCase()] = { username, password, role: 'user', createdAt: Date.now() };
  saveUsers(users);
  return res.json({ success: true, username, role: 'user' });
});

app.post('/api/auth/login', function(req, res) {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: 'Missing fields' });
  const users = getUsers();
  const user = users[username.toLowerCase()];
  if (!user || user.password !== password) return res.status(401).json({ error: 'Invalid credentials' });
  return res.json({ success: true, username: user.username, role: user.role || 'user' });
});

app.post('/api/studio/connect', function(req, res) {
  const { token } = req.body;
  if (!token) return res.status(400).json({ success: false, error: 'No token provided' });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false, error: 'Invalid token' });
  session.connectedAt = Date.now();
  session.pluginConnected = true;
  pendingCommands.set(token, []);
  return res.json({ success: true, username: session.username, model: process.env.OLLAMA_MODEL || 'llama3.2-vision' });
});

app.post('/api/studio/files', function(req, res) {
  const { token, files } = req.body;
  if (!token || !files) return res.status(400).json({ success: false, error: 'Missing token or files' });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false, error: 'Invalid token' });
  studioFiles.set(token, { files, uploadedAt: Date.now() });
  return res.json({ success: true });
});

app.get('/api/studio/poll', function(req, res) {
  const token = req.query.token;
  if (!token) return res.status(400).json({ commands: [] });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ commands: [] });
  const cmds = pendingCommands.get(token) || [];
  pendingCommands.set(token, []);
  return res.json({ commands: cmds });
});

app.post('/api/studio/ack', function(req, res) {
  return res.json({ success: true });
});

app.post('/api/studio/command', function(req, res) {
  const { token, command } = req.body;
  if (!token || !command) return res.status(400).json({ success: false });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false });
  const cmds = pendingCommands.get(token) || [];
  command.id = crypto.randomUUID();
  cmds.push(command);
  pendingCommands.set(token, cmds);
  return res.json({ success: true, commandId: command.id });
});

app.post('/api/studio/register-token', function(req, res) {
  const { token, username } = req.body;
  if (!token || !username) return res.status(400).json({ success: false });
  studioSessions.set(token, { username, createdAt: Date.now(), pluginConnected: false });
  return res.json({ success: true });
});

app.get('/api/studio/files', function(req, res) {
  const token = req.query.token;
  if (!token) return res.status(400).json({ success: false });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false });
  const data = studioFiles.get(token);
  if (!data) return res.json({ success: true, files: null });
  return res.json({ success: true, files: data.files, uploadedAt: data.uploadedAt });
});

app.get('/api/studio/status', function(req, res) {
  const token = req.query.token;
  if (!token) return res.status(400).json({ connected: false });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ connected: false });
  return res.json({ connected: session.pluginConnected, username: session.username });
});

app.get('/screenshare', function(req, res) {
  res.sendFile(path.join(__dirname, 'screenshare', 'index.html'));
});

app.post('/api/studio/animate', async function(req, res) {
  const { token, prompt } = req.body;
  if (!token || !prompt) return res.status(400).json({ success: false, error: 'Missing token or prompt' });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false, error: 'Invalid token' });

  const animApiKey = req.body.apiKey || process.env.DEEPINFRA_API_KEY || '';
  if (!animApiKey) return res.json({ success: false, error: 'No DeepInfra API key configured.' });
  try {
    const systemPrompt = 'You are an elite Roblox Lua animation engineer. You write buttery-smooth, visually stunning, professional-grade animations using TweenService. Rules: use EasingStyle.Quint or EasingStyle.Sine with EasingDirection.InOut for professional easing. Layer multiple tweens for complex motion. Use RepeatCount=-1 and Reverses=true for seamless loops. Always access instances safely with game.Workspace. Return ONLY raw executable Lua code. No markdown. No code fences. No comments. No explanation.';
    const msgs = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: `Create this Roblox Studio animation: ${prompt}. Make it look professional, smooth, and visually impressive. Use TweenService. Access target parts from game.Workspace. Ensure it runs correctly in a plugin context.` }
    ];
    let code = await deepinfraComplete(animApiKey, 'deepseek-ai/DeepSeek-V3', msgs);
    code = code.replace(/```lua[\n]?/gi, '').replace(/```[\n]?/g, '').trim();
    return res.json({ success: true, code });
  } catch(err) {
    return res.json({ success: false, error: err.message || 'AI error' });
  }
});

const screenCaptures = new Map();

app.post('/api/studio/screen-frame', function(req, res) {
  const { token, frame } = req.body;
  if (!token || !frame) return res.status(400).json({ success: false });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false });
  screenCaptures.set(token, { frame, capturedAt: Date.now() });
  return res.json({ success: true });
});

app.get('/api/studio/screen-frame', function(req, res) {
  const token = req.query.token;
  if (!token) return res.status(400).json({ success: false });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false });
  const capture = screenCaptures.get(token);
  if (!capture) return res.json({ success: true, frame: null });
  return res.json({ success: true, frame: capture.frame, capturedAt: capture.capturedAt });
});

app.post('/api/studio/screen-chat', async function(req, res) {
  const { token, message, frame } = req.body;
  if (!token || !message) return res.status(400).json({ success: false, error: 'Missing fields' });
  const session = studioSessions.get(token);
  if (!session) return res.status(401).json({ success: false, error: 'Invalid token' });

  const chatApiKey = req.body.apiKey || process.env.DEEPINFRA_API_KEY || '';
  if (!chatApiKey) return res.json({ success: false, error: 'No DeepInfra API key configured.' });
  try {
    const systemPrompt = 'You are PrysmisAI, an expert Roblox Studio AI assistant. You can see the user screen. When suggesting Lua code changes, always wrap code at the END of your response like this: PRYSMIS_CODE_START{"code":"-- lua here"}PRYSMIS_CODE_END. Only include this block if you have actual code to apply. Keep your response helpful and concise.';
    const userContent = [];
    if (frame) {
      const base64Data = frame.replace(/^data:image\/[a-z]+;base64,/, '');
      userContent.push({ type: 'image_url', image_url: { url: 'data:image/jpeg;base64,' + base64Data } });
    }
    userContent.push({ type: 'text', text: message });
    const msgs = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userContent }
    ];
    let fullResponse = await deepinfraComplete(chatApiKey, 'deepseek-ai/DeepSeek-V3', msgs);
    let code = null;
    const codeMatch = fullResponse.match(/PRYSMIS_CODE_START({.*?})PRYSMIS_CODE_END/s);
    if (codeMatch) {
      try { const parsed = JSON.parse(codeMatch[1]); code = parsed.code || null; } catch(e) {}
    }
    const displayText = fullResponse.replace(/PRYSMIS_CODE_START.*?PRYSMIS_CODE_END/s, '').trim();
    return res.json({ success: true, text: displayText, code });
  } catch(err) {
    return res.json({ success: false, error: err.message || 'AI error' });
  }
});

app.listen(PORT, function() {
  console.log('PrysmisAI running on http://localhost:' + PORT);
});
