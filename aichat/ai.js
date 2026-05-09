(function () {
  var history = [];
  var generating = false;
  var pendingImages = [];
  var pluginConnected = false;
  var studioToken = '';
  var lastAiBubble = null;
  var lastAiText = '';

  function getSession() { return JSON.parse(localStorage.getItem('prysmis_session') || 'null'); }
  function getGeminiKey() { return localStorage.getItem('prysmis_gemini_key') || ''; }
  function getStoredToken() { return localStorage.getItem('prysmis_studio_token') || ''; }
  function getPfp() { return localStorage.getItem('prysmis_pfp') || ''; }

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
    st.textContent = 'Settings saved successfully.';
    st.style.color = '#4caf7d';
    setTimeout(() => { st.textContent = ''; }, 3000);
  };

  window.sendMessage = async function () {
    if (generating) return;
    const input = document.getElementById('user-input');
    const text = input.value.trim();
    if (!text && pendingImages.length === 0) return;

    const apiKey = getGeminiKey();
    if (!apiKey) {
      alert('Please enter your Gemini API key in Settings.');
      return;
    }

    document.getElementById('welcome').style.display = 'none';
    const images = [...pendingImages];
    input.value = '';
    pendingImages = [];
    document.getElementById('image-preview-row').innerHTML = '';
    
    appendUserMsg(text, images);
    
    const userParts = [];
    for (const img of images) {
      userParts.push({ inline_data: { mime_type: img.type, data: img.dataUrl.split(',')[1] } });
    }
    userParts.push({ text: text });
    history.push({ role: 'user', parts: userParts });

    await runAiRequest();
  };

  async function runAiRequest() {
    generating = true;
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
          system_instruction: { parts: [{ text: "You are PrysmisAI, an elite Roblox developer. Always provide complete, production-ready Luau code." }] }
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
          if (line.startsWith('["') || line.startsWith(',')) continue; 
          try {
            const json = JSON.parse(line.replace(/^,/, ''));
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
  }

  function appendUserMsg(text, images) {
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
    scrollBottom();
    return bubble;
  }

  function scrollBottom() {
    const area = document.getElementById('chat-area');
    area.scrollTop = area.scrollHeight;
  }

  function renderMarkdown(text) {
    return text.replace(/```(lua|luau)?([\s\S]*?)```/g, '<pre class="code-block"><code>$2</code></pre>')
               .replace(/\n/g, '<br>');
  }

  window.openSettings = function () {
    document.getElementById('settings-modal').style.display = 'flex';
    document.getElementById('gemini-key-input').value = getGeminiKey();
  };

  document.getElementById('user-input').addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  });
})();
