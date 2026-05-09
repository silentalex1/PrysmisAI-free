(function () {
  var history = [];
  var generating = false;
  var pendingImages = [];
  var pluginConnected = false;
  var studioToken = '';

  function getSession() { return JSON.parse(localStorage.getItem('prysmis_session') || 'null'); }
  function getGeminiKey() { return localStorage.getItem('prysmis_gemini_key') || ''; }
  function getStoredToken() { return localStorage.getItem('prysmis_studio_token') || ''; }

  window.toggleInputModelDropdown = function() {
    document.getElementById('input-model-list').classList.toggle('open');
  };

  window.selectInputModel = function(el) {
    document.getElementById('input-model-label').textContent = el.textContent;
    document.getElementById('input-model-list').classList.remove('open');
  };

  window.toggleGeminiKeyVisibility = function() {
    const inp = document.getElementById('gemini-key-input');
    const btn = document.getElementById('gemini-key-toggle');
    if (inp.type === 'password') { inp.type = 'text'; btn.textContent = 'Hide'; }
    else { inp.type = 'password'; btn.textContent = 'Show'; }
  };

  window.saveGeminiSettings = function() {
    const val = document.getElementById('gemini-key-input').value.trim();
    localStorage.setItem('prysmis_gemini_key', val);
    const st = document.getElementById('gemini-key-status');
    st.textContent = 'Settings saved.';
    st.style.color = '#4caf7d';
    setTimeout(() => { st.textContent = ''; }, 3000);
  };

  window.logout = function() {
    localStorage.removeItem('prysmis_session');
    window.location.href = '/auth';
  };

  window.sendMessage = async function () {
    if (generating) return;
    const input = document.getElementById('user-input');
    const text = input.value.trim();
    const apiKey = getGeminiKey();

    if (!apiKey) { alert('Enter Gemini API key in Settings.'); return; }
    if (!text && pendingImages.length === 0) return;

    document.getElementById('welcome').style.display = 'none';
    const images = [...pendingImages];
    input.value = '';
    pendingImages = [];
    document.getElementById('image-preview-row').innerHTML = '';
    
    appendUserMsg(text, images);
    
    const userParts = images.map(img => ({ inline_data: { mime_type: img.type, data: img.dataUrl.split(',')[1] } }));
    userParts.push({ text: text });
    history.push({ role: 'user', parts: userParts });

    await runAiRequest();
  };

  async function runAiRequest() {
    generating = true;
    setStatus('busy');
    const bubble = appendAiMsg(null);
    const apiKey = getGeminiKey();
    
    try {
      const contents = history.map(h => ({
        role: h.role === 'assistant' ? 'model' : 'user',
        parts: h.parts || [{ text: h.content }]
      }));

      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:streamGenerateContent?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents,
          system_instruction: { parts: [{ text: "You are PrysmisAI. Elite Roblox generator. Return code in blocks." }] }
        })
      });

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let fullText = '';
      bubble.innerHTML = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');
        for (const line of lines) {
          if (!line.trim() || line.startsWith('[') || line.startsWith(',')) continue;
          try {
            const cleanLine = line.replace(/^,/, '').trim();
            const json = JSON.parse(cleanLine);
            const text = json.candidates[0].content.parts[0].text;
            if (text) {
              fullText += text;
              bubble.innerHTML = renderMarkdown(fullText);
              scrollBottom();
            }
          } catch(e) {}
        }
      }
      history.push({ role: 'assistant', content: fullText });
    } catch (err) {
      bubble.innerHTML = '<span style="color:#e05555">Error: ' + err.message + '</span>';
    }
    generating = false;
    setStatus('ready');
  }

  function appendUserMsg(text) {
    const msgs = document.getElementById('messages');
    const row = document.createElement('div');
    row.className = 'msg-row user';
    row.innerHTML = `<div class="msg-body"><div class="msg-text">${text}</div></div>`;
    msgs.appendChild(row);
    scrollBottom();
  }

  function appendAiMsg(text) {
    const msgs = document.getElementById('messages');
    const row = document.createElement('div');
    row.className = 'msg-row ai';
    const bubble = document.createElement('div');
    bubble.className = 'msg-text ai-msg-text';
    bubble.innerHTML = text === null ? '<div class="thinking"><span></span><span></span><span></span></div>' : renderMarkdown(text);
    row.innerHTML = `<div class="msg-avatar ai-avatar">P</div>`;
    const body = document.createElement('div');
    body.className = 'msg-body';
    body.appendChild(bubble);
    row.appendChild(body);
    msgs.appendChild(row);
    return bubble;
  }

  function setStatus(s) {
    document.getElementById('status-label').textContent = s === 'busy' ? 'Thinking' : 'Ready';
    document.getElementById('status-dot').className = 'status-dot' + (s === 'busy' ? ' busy' : '');
  }

  function renderMarkdown(t) {
    return t.replace(/```(lua|luau)?([\s\S]*?)```/g, '<pre class="code-block"><code>$2</code></pre>').replace(/\n/g, '<br>');
  }

  function scrollBottom() { const a = document.getElementById('chat-area'); a.scrollTop = a.scrollHeight; }

  window.openSettings = function() {
    document.getElementById('settings-modal').style.display = 'flex';
    document.getElementById('gemini-key-input').value = getGeminiKey();
    const s = getSession();
    if (s) document.getElementById('settings-username').textContent = s.username;
  };

  window.closeSettings = function() { document.getElementById('settings-modal').style.display = 'none'; };
  window.closeSettingsIfBg = function(e) { if(e.target.id === 'settings-modal') closeSettings(); };

  window.newChat = function() { history = []; document.getElementById('messages').innerHTML = ''; document.getElementById('welcome').style.display = 'flex'; };

  window.handleKey = e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); } };
  window.autoGrow = el => { el.style.height = 'auto'; el.style.height = Math.min(el.scrollHeight, 150) + 'px'; };

  if(!getSession() && !window.location.href.includes('auth')) window.location.href = '/auth';
})();
