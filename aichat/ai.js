(function () {
  var history = [];
  var generating = false;
  var pendingImages = [];

  window.switchStab = function (btn, panelId) {
    document.querySelectorAll('.stab').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    document.querySelectorAll('.spanel').forEach(p => p.classList.remove('active'));
    document.getElementById('spanel-' + panelId).classList.add('active');
  };

  window.switchMainTab = function (tabId, btn) {
    document.querySelectorAll('.nav-tab').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    document.querySelectorAll('.tab-content').forEach(p => p.classList.remove('active'));
    document.getElementById('tab-' + tabId).classList.add('active');
  };

  window.openSettings = function () {
    const modal = document.getElementById('settings-modal');
    modal.style.display = 'flex';
    const session = JSON.parse(localStorage.getItem('prysmis_session') || '{}');
    document.getElementById('settings-username').textContent = session.username || 'Guest';
    document.getElementById('gemini-key-input').value = localStorage.getItem('prysmis_gemini_key') || '';
    document.getElementById('studio-token-display').value = localStorage.getItem('prysmis_studio_token') || 'No token generated';
  };

  window.closeSettings = () => document.getElementById('settings-modal').style.display = 'none';
  window.closeSettingsIfBg = (e) => { if (e.target.id === 'settings-modal') closeSettings(); };

  window.saveGeminiSettings = function() {
    const key = document.getElementById('gemini-key-input').value.trim();
    localStorage.setItem('prysmis_gemini_key', key);
    const status = document.getElementById('gemini-key-status');
    status.textContent = "Settings Saved!";
    status.style.color = "#4caf7d";
    setTimeout(() => status.textContent = "", 3000);
  };

  window.logout = function() {
    localStorage.removeItem('prysmis_session');
    window.location.href = '/auth';
  };

  window.sendMessage = async function () {
    if (generating) return;
    const input = document.getElementById('user-input');
    const text = input.value.trim();
    const key = localStorage.getItem('prysmis_gemini_key');

    if (!key) { alert('Please enter Gemini API key in Settings.'); return; }
    if (!text) return;

    document.getElementById('welcome').style.display = 'none';
    input.value = '';
    appendUserMsg(text);
    
    history.push({ role: 'user', parts: [{ text: text }] });
    await runGeminiRequest(key);
  };

  async function runGeminiRequest(apiKey) {
    generating = true;
    const bubble = appendAiMsg(null);
    try {
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:streamGenerateContent?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: history,
          system_instruction: { parts: [{ text: "You are PrysmisAI, an elite Roblox developer. Write code in blocks." }] }
        })
      });

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let fullText = "";
      bubble.innerHTML = "";

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');
        for (const line of lines) {
          if (!line.trim() || line.startsWith('[') || line.startsWith(',')) continue;
          try {
            const json = JSON.parse(line.replace(/^,/, '').trim());
            const text = json.candidates[0].content.parts[0].text;
            if (text) {
              fullText += text;
              bubble.innerHTML = fullText.replace(/```(lua|luau)?([\s\S]*?)```/g, '<pre class="code-block"><code>$2</code></pre>');
              const area = document.getElementById('chat-area');
              area.scrollTop = area.scrollHeight;
            }
          } catch(e) {}
        }
      }
      history.push({ role: 'assistant', parts: [{ text: fullText }] });
    } catch (e) { bubble.innerHTML = "Error: " + e.message; }
    generating = false;
  }

  window.appendUserMsg = (t) => {
    const m = document.getElementById('messages');
    const d = document.createElement('div');
    d.className = 'msg-row user';
    d.innerHTML = `<div class="msg-body"><div class="msg-text">${t}</div></div>`;
    m.appendChild(d);
  };

  window.appendAiMsg = (t) => {
    const m = document.getElementById('messages');
    const d = document.createElement('div');
    d.className = 'msg-row ai';
    const b = document.createElement('div');
    b.className = 'msg-text ai-msg-text';
    b.innerHTML = t === null ? 'Thinking...' : t;
    d.innerHTML = `<div class="msg-avatar ai-avatar">P</div>`;
    const body = document.createElement('div'); body.className='msg-body'; body.appendChild(b);
    d.appendChild(body); m.appendChild(d);
    return b;
  };

  window.toggleInputModelDropdown = () => document.getElementById('input-model-list').classList.toggle('open');
  window.selectInputModel = (el) => {
    document.getElementById('input-model-label').textContent = el.textContent;
    document.getElementById('input-model-list').classList.remove('open');
  };

  window.toggleGeminiKeyVisibility = function() {
    const inp = document.getElementById('gemini-key-input');
    inp.type = inp.type === 'password' ? 'text' : 'password';
  };

  window.newChat = () => { history = []; document.getElementById('messages').innerHTML = ''; document.getElementById('welcome').style.display = 'flex'; };
  window.handleKey = (e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); } };
  window.autoGrow = (el) => { el.style.height = 'auto'; el.style.height = el.scrollHeight + 'px'; };
  
  if (!localStorage.getItem('prysmis_session')) window.location.href = '/auth';

})();
