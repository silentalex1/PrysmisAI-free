(function () {
  var history = [];
  var generating = false;

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
    document.getElementById('studio-token-display').value = localStorage.getItem('prysmis_studio_token') || '';
  };

  window.closeSettings = () => document.getElementById('settings-modal').style.display = 'none';
  window.closeSettingsIfBg = (e) => { if (e.target.id === 'settings-modal') closeSettings(); };

  window.saveGeminiSettings = function() {
    const key = document.getElementById('gemini-key-input').value.trim();
    localStorage.setItem('prysmis_gemini_key', key);
    const status = document.getElementById('gemini-key-status');
    document.getElementById('quota-box').style.display = 'none';
    status.textContent = "✓ Settings Saved Successfully";
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
    if (!key) { alert('Go to Settings and add your Gemini API Key first.'); return; }
    if (!text) return;

    document.getElementById('welcome').style.display = 'none';
    input.value = '';
    appendUserMsg(text);
    
    history.push({ role: "user", parts: [{ text: text }] });
    await runGeminiRequest(key);
  };

  async function runGeminiRequest(apiKey) {
    generating = true;
    setStatus('busy');
    const bubble = appendAiMsg(null);
    const quotaBox = document.getElementById('quota-box');
    
    try {
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:streamGenerateContent?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: history,
          systemInstruction: { parts: [{ text: "You are PrysmisAI, an elite Roblox engineer. Write high-quality Luau code. Use code blocks." }] }
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error?.message || `HTTP ${response.status}`);
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let fullText = "";
      bubble.innerHTML = "";

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        const chunk = decoder.decode(value);
        
        const jsonParts = chunk.split(/}\s*\r?\n\s*{/);
        
        for (let i = 0; i < jsonParts.length; i++) {
          let part = jsonParts[i].trim();
          if (!part.startsWith('{')) part = '{' + part;
          if (!part.endsWith('}')) part = part + '}';
          
          try {
            const data = JSON.parse(part.replace(/^\[/, '').replace(/\]$/, ''));
            const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) {
              fullText += text;
              bubble.innerHTML = fullText.replace(/```(lua|luau)?([\s\S]*?)```/g, '<pre class="code-block"><code>$2</code></pre>');
            }
          } catch(e) {}
        }
        document.getElementById('chat-area').scrollTop = document.getElementById('chat-area').scrollHeight;
      }
      history.push({ role: "model", parts: [{ text: fullText }] });
    } catch (e) { 
        bubble.innerHTML = `<span style="color:#ff8080">Error: ${e.message}</span>`;
        quotaBox.style.display = 'block';
    }
    generating = false;
    setStatus('ready');
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
    b.innerHTML = t === null ? '<div class="thinking"><span></span><span></span><span></span></div>' : t;
    d.innerHTML = `<div class="msg-avatar ai-avatar">P</div>`;
    const body = document.createElement('div'); body.className='msg-body'; body.appendChild(b);
    d.appendChild(body); m.appendChild(d);
    return b;
  };

  window.setStatus = (s) => {
    const dot = document.getElementById('status-dot');
    const lbl = document.getElementById('status-label');
    if (s === 'busy') { dot.classList.add('busy'); lbl.textContent = 'Thinking'; }
    else { dot.classList.remove('busy'); lbl.textContent = 'Ready'; }
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
