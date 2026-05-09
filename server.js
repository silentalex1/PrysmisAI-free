const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();
const PORT = process.env.PORT || 3000;
const USERS_FILE = path.join(__dirname, 'users.json');

app.use(express.json({ limit: '50mb' }));
app.use(express.static(path.join(__dirname)));

function getUsers() { try { return JSON.parse(fs.readFileSync(USERS_FILE, 'utf8')); } catch(e) { return {}; } }
function saveUsers(u) { fs.writeFileSync(USERS_FILE, JSON.stringify(u, null, 2)); }

app.post('/api/auth/register', (req, res) => {
  const { username, password } = req.body;
  const users = getUsers();
  if (users[username.toLowerCase()]) return res.status(409).json({ error: 'Taken' });
  users[username.toLowerCase()] = { username, password, role: 'user' };
  saveUsers(users);
  res.json({ success: true, username });
});

app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  const user = getUsers()[username.toLowerCase()];
  if (!user || user.password !== password) return res.status(401).json({ error: 'Invalid' });
  res.json({ success: true, username: user.username, role: user.role });
});

app.listen(PORT, () => console.log('Server running on ' + PORT));
