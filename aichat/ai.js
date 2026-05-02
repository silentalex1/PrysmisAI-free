let currentChatId = null;
let currentModel = 'deepseek-ai/DeepSeek-V3';
let deepinfraApiKey = '';

function getDeepinfraKey() { return localStorage.getItem('prysmis_deepinfra_key') || ''; }
function saveDeepinfraKey(k) { localStorage.setItem('prysmis_deepinfra_key', k); }

function getCurrentUsername() { return localStorage.getItem('prysmis_username') || 'User'; }
function setCurrentUsername(u) { localStorage.setItem('prysmis_username', u); }

function getChats() { try { return JSON.parse(localStorage.getItem('prysmis_chats') || '[]'); } catch { return []; } }
function saveChats(c) { localStorage.setItem('prysmis_chats', JSON.stringify(c)); }

function getChatHistory(chatId) { try { return JSON.parse(localStorage.getItem('prysmis_chat_' + chatId) || '[]'); } catch { return []; } }
function saveChatHistory(chatId, h) { localStorage.setItem('prysmis_chat_' + chatId, JSON.stringify(h)); }

function getPfp() { return localStorage.getItem('prysmis_pfp') || ''; }
function savePfp(d) { localStorage.setItem('prysmis_pfp', d); }

function getCommMessages() { try { return JSON.parse(localStorage.getItem('prysmis_comm_msgs') || '[]'); } catch { return []; } }
function saveCommMessages(msgs) { localStorage.setItem('prysmis_comm_msgs', JSON.stringify(msgs.slice(-200))); }

function getGames() { try { return JSON.parse(localStorage.getItem('prysmis_games') || '[]'); } catch { return []; } }
function saveGames(g) { localStorage.setItem('prysmis_games', JSON.stringify(g)); }

function newChat() {
  currentChatId = 'chat_' + Date.now();
  const chats = getChats();
  chats.push({ id: currentChatId, name: 'New Chat', createdAt: Date.now() });
  saveChats(chats);
  saveChatHistory(currentChatId, []);
  renderChatHistory();
  clearChatArea();
}

function loadChat(chatId) {
  currentChatId = chatId;
  clearChatArea();
  const history = getChatHistory(chatId);
  history.forEach(msg => {
    appendMessage(msg.role, msg.content);
  });
}

function clearChatArea() {
  document.getElementById('messages').innerHTML = '';
  document.getElementById('welcome').style.display = 'flex';
}

function appendMessage(role, content) {
  const messagesDiv = document.getElementById('messages');
  const msgRow = document.createElement('div');
  msgRow.className = 'msg-row ' + (role === 'user' ? 'user' : 'ai');
  
  const avatar = document.createElement('div');
  avatar.className = 'msg-avatar';
  if (role === 'user') {
    avatar.textContent = 'U';
  } else {
    avatar.textContent = 'AI';
  }
  
  const body = document.createElement('div');
  body.className = 'msg-body';
  
  const label = document.createElement('div');
  label.className = 'msg-label';
  label.textContent = role === 'user' ? 'You' : 'Prysmis AI';
  
  const text = document.createElement('div');
  text.className = 'msg-text';
  text.innerHTML = content;
  
  body.appendChild(label);
  body.appendChild(text);
  msgRow.appendChild(avatar);
  msgRow.appendChild(body);
  messagesDiv.appendChild(msgRow);
  messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

async function sendMessage() {
  const input = document.getElementById('user-input');
  const message = input.value.trim();
  
  if (!message) return;
  
  deepinfraApiKey = getDeepinfraKey();
  if (!deepinfraApiKey) {
    alert('Please set your DeepInfra API key in Settings first.');
    openSettings();
    return;
  }
  
  if (!currentChatId) newChat();
  
  appendMessage('user', message);
  input.value = '';
  input.style.height = 'auto';
  
  document.getElementById('welcome').style.display = 'none';
  
  const history = getChatHistory(currentChatId);
  history.push({ role: 'user', content: message });
  saveChatHistory(currentChatId, history);
  
  const loadingDiv = document.createElement('div');
  loadingDiv.className = 'msg-row ai';
  loadingDiv.innerHTML = '<div class="msg-avatar">AI</div><div class="msg-body"><div class="msg-label">Prysmis AI</div><div class="thinking"><span></span><span></span><span></span></div></div>';
  document.getElementById('messages').appendChild(loadingDiv);
  document.getElementById('messages').scrollTop = document.getElementById('messages').scrollHeight;
  
  try {
    const response = await fetch('https://api.deepinfra.com/v1/openai/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + deepinfraApiKey
      },
      body: JSON.stringify({
        model: currentModel,
        messages: history.map(m => ({ role: m.role, content: m.content })),
        temperature: 0.7,
        max_tokens: 2000
      })
    });
    
    if (!response.ok) {
      throw new Error('API Error: ' + response.status);
    }
    
    const data = await response.json();
    const aiResponse = data.choices[0].message.content;
    
    loadingDiv.remove();
    
    appendMessage('assistant', aiResponse);
    
    history.push({ role: 'assistant', content: aiResponse });
    saveChatHistory(currentChatId, history);
    
  } catch (error) {
    loadingDiv.remove();
    appendMessage('assistant', 'Error: ' + error.message);
  }
}

function handleKey(event) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    sendMessage();
  }
}

function autoGrow(element) {
  element.style.height = 'auto';
  element.style.height = Math.min(element.scrollHeight, 200) + 'px';
}

function toggleInputModelDropdown() {
  const list = document.getElementById('input-model-list');
  list.style.display = list.style.display === 'none' ? 'block' : 'none';
}

function selectInputModel(element) {
  currentModel = element.getAttribute('data-value');
  document.getElementById('input-model-label').textContent = element.textContent;
  document.getElementById('input-model-list').style.display = 'none';
}

function chipSend(prefix) {
  const input = document.getElementById('user-input');
  input.value = prefix;
  input.focus();
}

function switchMainTab(tab, element) {
  document.querySelectorAll('.nav-tab').forEach(el => el.classList.remove('active'));
  element.classList.add('active');
  
  document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
  document.getElementById('tab-' + tab).classList.add('active');
}

function switchStab(element, panel) {
  document.querySelectorAll('.stab').forEach(el => el.classList.remove('active'));
  element.classList.add('active');
  
  document.querySelectorAll('.spanel').forEach(el => el.classList.remove('active'));
  document.getElementById('spanel-' + panel).classList.add('active');
}

function openSettings() {
  document.getElementById('settings-username').textContent = getCurrentUsername();
  document.getElementById('deepinfra-key-input').value = getDeepinfraKey();
  document.getElementById('settings-modal').style.display = 'flex';
}

function closeSettings() {
  document.getElementById('settings-modal').style.display = 'none';
}

function closeSettingsIfBg(event) {
  if (event.target.id === 'settings-modal') closeSettings();
}

function saveAISettings() {
  const key = document.getElementById('deepinfra-key-input').value.trim();
  if (key) {
    saveDeepinfraKey(key);
    alert('Settings saved successfully!');
    closeSettings();
  } else {
    alert('Please enter your DeepInfra API key.');
  }
}

function logout() {
  localStorage.clear();
  location.reload();
}

function handleImageAttach(event) {
  const file = event.target.files[0];
  if (file) {
    const reader = new FileReader();
    reader.onload = (e) => {
      const preview = document.getElementById('image-preview-row');
      const wrap = document.createElement('div');
      wrap.className = 'img-thumb-wrap';
      const img = document.createElement('img');
      img.className = 'img-thumb';
      img.src = e.target.result;
      const btn = document.createElement('button');
      btn.className = 'img-thumb-remove';
      btn.textContent = '×';
      btn.onclick = () => wrap.remove();
      wrap.appendChild(img);
      wrap.appendChild(btn);
      preview.appendChild(wrap);
    };
    reader.readAsDataURL(file);
  }
}

function handlePfpUpload(event) {
  const file = event.target.files[0];
  if (file) {
    const reader = new FileReader();
    reader.onload = (e) => {
      const img = document.getElementById('pfp-img');
      img.src = e.target.result;
      img.style.display = 'block';
      document.getElementById('pfp-placeholder').style.display = 'none';
      savePfp(e.target.result);
    };
    reader.readAsDataURL(file);
  }
}

function openShareScreen() {
  const canvas = document.createElement('canvas');
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#0e0e0e';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  
  ctx.fillStyle = '#f0ece5';
  ctx.font = '24px DM Sans';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('Screen Share Active', canvas.width / 2, canvas.height / 2);
  
  const frameData = canvas.toDataURL('image/jpeg', 0.8);
  localStorage.setItem('prysmis_screen_frame', frameData);
  alert('Screen share initiated!');
}

function connectPlugin() {
  const token = 'plugin_' + Math.random().toString(36).substr(2, 9);
  localStorage.setItem('prysmis_plugin_token', token);
  document.getElementById('studio-token-display').value = token;
  alert('Plugin token generated and set!');
}

function toggleTokenVisibility() {
  const input = document.getElementById('studio-token-display');
  const btn = document.getElementById('token-show-btn');
  if (input.type === 'text') {
    input.type = 'password';
    btn.textContent = 'Show';
  } else {
    input.type = 'text';
    btn.textContent = 'Hide';
  }
}

function copyStudioToken() {
  const input = document.getElementById('studio-token-display');
  input.select();
  document.execCommand('copy');
  alert('Token copied to clipboard!');
}

function regenToken() {
  const token = 'plugin_' + Math.random().toString(36).substr(2, 9);
  localStorage.setItem('prysmis_plugin_token', token);
  document.getElementById('studio-token-display').value = token;
  alert('New token generated!');
}

function toggleStudioPanel() {
  const panel = document.getElementById('studio-panel');
  panel.classList.toggle('closed');
}

function renderChatHistory() {
  const list = document.getElementById('chat-history-list');
  list.innerHTML = '';
  const chats = getChats();
  chats.reverse().forEach(chat => {
    const item = document.createElement('div');
    item.className = 'chat-history-item';
    item.textContent = chat.name;
    item.onclick = () => loadChat(chat.id);
    list.appendChild(item);
  });
}

function sendCommMessage() {
  const input = document.getElementById('comm-input');
  const msg = input.value.trim();
  if (!msg) return;
  
  const msgs = getCommMessages();
  msgs.push({
    username: getCurrentUsername(),
    text: msg,
    time: new Date().toLocaleTimeString(),
    isAdmin: false
  });
  saveCommMessages(msgs);
  input.value = '';
  
  renderCommMessages();
}

function commHandleKey(event) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    sendCommMessage();
  }
}

function renderCommMessages() {
  const container = document.getElementById('comm-messages');
  container.innerHTML = '';
  const msgs = getCommMessages();
  msgs.forEach(msg => {
    const msgEl = document.createElement('div');
    msgEl.className = 'comm-msg';
    msgEl.innerHTML = `
      <div class="comm-msg-header">
        <div class="comm-msg-user">${msg.username}</div>
        <div class="comm-msg-time">${msg.time}</div>
      </div>
      <div class="comm-msg-text">${msg.text}</div>
    `;
    container.appendChild(msgEl);
  });
  container.scrollTop = container.scrollHeight;
}

function openPostGame() {
  document.getElementById('post-game-modal').style.display = 'flex';
}

function closePostGame() {
  document.getElementById('post-game-modal').style.display = 'none';
}

function closePostGameIfBg(event) {
  if (event.target.id === 'post-game-modal') closePostGame();
}

function submitGame() {
  const name = document.getElementById('pg-name').value.trim();
  const desc = document.getElementById('pg-desc').value.trim();
  const link = document.getElementById('pg-link').value.trim();
  
  if (!name || !link) {
    alert('Please fill in game name and link.');
    return;
  }
  
  const games = getGames();
  games.push({ name, desc, link, submittedBy: getCurrentUsername(), submittedAt: Date.now() });
  saveGames(games);
  
  document.getElementById('pg-name').value = '';
  document.getElementById('pg-desc').value = '';
  document.getElementById('pg-link').value = '';
  closePostGame();
  alert('Game submitted successfully!');
  renderGamesGrid();
}

function renderGamesGrid() {
  const grid = document.getElementById('games-grid');
  const games = getGames();
  
  if (games.length === 0) {
    grid.innerHTML = '<div class="no-games"><div class="no-games-title">Community Projects</div><div class="no-games-sub">Browse and share Roblox projects built with PrysmisAI. Be the first to post yours.</div></div>';
    return;
  }
  
  grid.innerHTML = '';
  games.forEach(game => {
    const card = document.createElement('div');
    card.className = 'game-card';
    card.innerHTML = `
      <div class="game-card-title">${game.name}</div>
      <a href="${game.link}" target="_blank" class="game-card-link">${game.link}</a>
      <div class="game-card-desc">${game.desc}</div>
    `;
    grid.appendChild(card);
  });
}

function closePremiumIfBg(event) {
  if (event.target.id === 'premium-modal') closePremiumModal();
}

function closePremiumModal() {
  document.getElementById('premium-modal').style.display = 'none';
}

function copyCode() {
  const code = document.getElementById('cp-code').textContent;
  navigator.clipboard.writeText(code);
  alert('Code copied to clipboard!');
}

function fixCode() {
  alert('Code fixing feature coming soon!');
}

function closeCodePanel() {
  document.getElementById('code-panel').classList.add('closed');
}

function acceptChange() {
  alert('Change accepted!');
}

function declineChange() {
  alert('Change declined!');
}

function continueResponse() {
  alert('Continue feature coming soon!');
}

document.addEventListener('DOMContentLoaded', () => {
  const pfp = getPfp();
  if (pfp) {
    document.getElementById('pfp-img').src = pfp;
    document.getElementById('pfp-img').style.display = 'block';
    document.getElementById('pfp-placeholder').style.display = 'none';
  }
  
  renderChatHistory();
  renderCommMessages();
  renderGamesGrid();
  
  const token = localStorage.getItem('prysmis_plugin_token');
  if (token) {
    document.getElementById('studio-token-display').value = token;
  }
  
  document.getElementById('app').style.display = 'flex';
});