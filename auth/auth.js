(function () {

  function showAlert(id, msg, isError) {
    var el = document.getElementById(id);
    if (!el) return;
    el.textContent = msg;
    el.className = 'auth-alert show ' + (isError ? 'error' : 'success');
  }

  function clearAlert(id) {
    var el = document.getElementById(id);
    if (!el) return;
    el.textContent = '';
    el.className = 'auth-alert';
  }

  window.switchTab = function (tab) {
    document.querySelectorAll('.auth-tab').forEach(function (b) {
      b.classList.toggle('active', b.dataset.tab === tab);
    });
    document.querySelectorAll('.auth-panel').forEach(function (p) {
      p.classList.toggle('active', p.id === 'panel-' + tab);
    });
    clearAlert('login-alert');
    clearAlert('create-alert');
    clearAlert('admin-alert');
  };

  window.togglePw = function (inputId, btn) {
    var inp = document.getElementById(inputId);
    if (!inp) return;
    if (inp.type === 'password') {
      inp.type = 'text';
      btn.innerHTML = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';
    } else {
      inp.type = 'password';
      btn.innerHTML = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
    }
  };

  function getUsers() {
    try { return JSON.parse(localStorage.getItem('prysmis_users') || '{}'); } catch(e) { return {}; }
  }

  function saveUsers(users) {
    try { localStorage.setItem('prysmis_users', JSON.stringify(users)); } catch(e) {}
  }

  window.loginAccount = async function () {
    var username = (document.getElementById('login-username').value || '').trim();
    var password = (document.getElementById('login-password').value || '').trim();
    clearAlert('login-alert');
    if (!username || !password) {
      showAlert('login-alert', 'Please fill in all fields.', true);
      return;
    }
    try {
      var users = getUsers();
      var user = users[username.toLowerCase()];
      if (!user || user.password !== password) {
        showAlert('login-alert', 'Invalid username or password.', true);
        return;
      }
      localStorage.setItem('prysmis_session', JSON.stringify({ username: user.username, role: user.role || 'user' }));
      window.location.href = 'https://prysmisai-free.onrender.com/aichat/index.html';
    } catch (e) {
      showAlert('login-alert', 'Login failed. Please try again.', true);
    }
  };

  window.createAccount = async function () {
    var username = (document.getElementById('create-username').value || '').trim();
    var password = (document.getElementById('create-password').value || '').trim();
    clearAlert('create-alert');
    if (!username || !password) {
      showAlert('create-alert', 'Please fill in all fields.', true);
      return;
    }
    if (username.length < 3) {
      showAlert('create-alert', 'Username must be at least 3 characters.', true);
      return;
    }
    if (password.length < 6) {
      showAlert('create-alert', 'Password must be at least 6 characters.', true);
      return;
    }
    try {
      var users = getUsers();
      if (users[username.toLowerCase()]) {
        showAlert('create-alert', 'Username already taken.', true);
        return;
      }
      users[username.toLowerCase()] = { username: username, password: password, role: 'user', createdAt: Date.now() };
      saveUsers(users);
      localStorage.setItem('prysmis_session', JSON.stringify({ username: username, role: 'user' }));
      window.location.href = 'https://prysmisai-free.onrender.com/aichat/index.html';
    } catch (e) {
      showAlert('create-alert', 'Registration failed. Please try again.', true);
    }
  };

  window.adminLogin = async function () {
    var username = (document.getElementById('admin-username').value || '').trim();
    var password = (document.getElementById('admin-password').value || '').trim();
    var passcode = (document.getElementById('admin-passcode').value || '').trim();
    clearAlert('admin-alert');
    if (!username || !password || !passcode) {
      showAlert('admin-alert', 'Please fill in all fields.', true);
      return;
    }
    if (passcode !== 'admin123') {
      showAlert('admin-alert', 'Invalid admin passcode.', true);
      return;
    }
    try {
      var users = getUsers();
      var user = users[username.toLowerCase()];
      if (!user || user.password !== password) {
        showAlert('admin-alert', 'Invalid credentials.', true);
        return;
      }
      user.role = 'admin';
      saveUsers(users);
      localStorage.setItem('prysmis_session', JSON.stringify({ username: user.username, role: 'admin' }));
      window.location.href = 'https://prysmisai-free.onrender.com/aichat/index.html';
    } catch (e) {
      showAlert('admin-alert', 'Admin login failed. Please try again.', true);
    }
  };

  var session = null;
  try { session = JSON.parse(localStorage.getItem('prysmis_session') || 'null'); } catch (e) {}
  if (session && session.username) {
    window.location.href = 'https://prysmisai-free.onrender.com/aichat/index.html';
  }

})();
