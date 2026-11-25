// Injected into ttyd's page (entrypoint.sh builds the index with it). Clipboard rules like the exam's remote terminal:
// - Ctrl+Shift+V pastes the system clipboard (text copied from the question panel), on Windows, Linux and macOS.
//   On macOS Cmd+Shift+V does the same.
// - Right-click -> Paste works too (the exam terminal allows its context menu). Ctrl+V / Cmd+V send nothing.
// - Text selected in the terminal never reaches the system clipboard; the middle mouse button pastes the last selection.
//
// Ctrl+Shift+V has three ways to get at the clipboard, tried in this order:
// 1. The browser's own paste event: Chrome and Edge fire one for Ctrl+Shift+V (and for Cmd+Shift+V on macOS).
//    It can arrive a little after the key, so the other two wait for it first.
// 2. navigator.clipboard.readText(): for browsers that don't (Firefox). Only on https or localhost, and the browser
//    may ask for permission or show its own "Paste" button. Safari isn't supported (README).
// 3. A small paste box over the terminal: paste into it with the system shortcut (Cmd+V / Ctrl+V) and it goes to the
//    terminal. Always works, e.g. when the exam is opened from another machine by IP address.
// Whichever comes first wins; one key press never pastes twice.
(function () {
  const WAIT_FOR_NATIVE_PASTE = 150;                               // ms
  let allowPaste = false, pending = false, selection = '', box = null;
  const mac = /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent);

  // Right-click opens the browser's context menu on xterm's input field; its "Paste" fires a normal paste event.
  // Allow that one paste. Any key or left/middle click in between closes the window again, so Ctrl+V / Cmd+V stay blocked.
  let menuTimer = null;
  const closeMenuWindow = () => { allowPaste = false; clearTimeout(menuTimer); };
  document.addEventListener('contextmenu', () => {
    allowPaste = true; clearTimeout(menuTimer); menuTimer = setTimeout(closeMenuWindow, 30000);
  }, true);
  document.addEventListener('keydown', closeMenuWindow, true);
  document.addEventListener('mousedown', e => { if (e.button !== 2) closeMenuWindow(); }, true);

  const execCommand = document.execCommand.bind(document);       // ttyd copies every selection with execCommand('copy')
  document.execCommand = (cmd, ...args) => cmd === 'copy' ? false : execCommand(cmd, ...args);
  document.addEventListener('copy', e => { e.preventDefault(); e.stopImmediatePropagation(); }, true);
  document.addEventListener('cut', e => { e.preventDefault(); e.stopImmediatePropagation(); }, true);
  document.addEventListener('paste', e => {
    if (box && box.contains(e.target)) return;                    // the paste box handles its own paste
    if (!allowPaste) { e.preventDefault(); e.stopImmediatePropagation(); return; }
    allowPaste = false; pending = false;                           // the browser's paste goes through, nothing else
    if (box) closeBox(window.term);                                // a late native paste: the box isn't needed any more
  }, true);

  const closeBox = term => {
    pending = false; allowPaste = false;
    if (box) { box.remove(); box = null; }
    if (term) term.focus();
  };
  const openBox = term => {
    if (box) return;
    box = document.createElement('div');
    box.style.cssText = 'position:fixed;left:50%;top:30%;transform:translateX(-50%);z-index:1000;width:min(460px,90vw);' +
      'background:#2d2d2d;color:#eee;border:1px solid #666;border-radius:6px;padding:12px;font:14px sans-serif;' +
      'box-shadow:0 4px 16px rgba(0,0,0,.5)';
    box.innerHTML = '<div style="margin-bottom:8px">The browser doesn\'t let the terminal read the clipboard. ' +
      'Paste here with <b>' + (mac ? 'Cmd+V' : 'Ctrl+V') + '</b> and it goes to the terminal. <b>Esc</b> cancels.</div>' +
      '<textarea rows="2" style="width:100%;box-sizing:border-box;background:#1e1e1e;color:#eee;border:1px solid #888;' +
      'font:13px monospace;resize:none"></textarea>';
    const ta = box.querySelector('textarea');
    ta.addEventListener('paste', e => {
      e.preventDefault();
      const t = (e.clipboardData || window.clipboardData).getData('text');
      closeBox(term);
      if (t) term.paste(t);
    });
    ta.addEventListener('keydown', e => {
      e.stopPropagation();                                         // keys typed here are not terminal keys
      if (e.key === 'Escape') { e.preventDefault(); closeBox(term); }
      else if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); const t = ta.value; closeBox(term); if (t) term.paste(t); }
    });
    document.body.appendChild(box);
    ta.focus();
  };

  // no native paste came: read the clipboard, or open the box
  const pasteFromClipboard = term => {
    if (!pending) return;
    if (!window.isSecureContext || !navigator.clipboard || !navigator.clipboard.readText) { openBox(term); return; }
    navigator.clipboard.readText()
      .then(t => { if (!pending) return; pending = false; allowPaste = false; if (t) term.paste(t); })
      .catch(() => { if (pending) openBox(term); });
  };

  const hook = setInterval(() => {
    const term = window.term;
    if (!term || !term.element) return;
    clearInterval(hook);
    term.attachCustomKeyEventHandler(e => {
      const v = e.code === 'KeyV' || e.key.toLowerCase() === 'v', c = e.code === 'KeyC' || e.key.toLowerCase() === 'c';
      // Shift+V with exactly one of Ctrl / Cmd; Cmd only counts on macOS (elsewhere it's the Windows/Super key)
      const pasteKey = v && e.shiftKey && !e.altKey && (e.ctrlKey !== e.metaKey) && (e.ctrlKey || mac);
      if (pasteKey) {
        if (e.type === 'keydown' && !e.repeat && !box) {
          allowPaste = true; pending = true;
          setTimeout(() => pasteFromClipboard(term), WAIT_FOR_NATIVE_PASTE);
        }
        return false;                                              // xterm itself sends nothing for the key
      }
      if (e.metaKey && v) { e.preventDefault(); return false; }    // Cmd+V on macOS: no paste, like the exam terminal
      if (e.ctrlKey && e.shiftKey && c) { e.preventDefault(); return false; }   // no copy (and no DevTools inspector)
      return true;
    });
    term.onSelectionChange(() => { const s = term.getSelection(); if (s) selection = s; });
    const middle = e => { if (e.button === 1) { e.preventDefault(); e.stopImmediatePropagation(); } };
    term.element.addEventListener('mousedown', e => { if (e.button === 1) { middle(e); if (selection) term.paste(selection); } }, true);
    term.element.addEventListener('mouseup', middle, true);
    term.element.addEventListener('auxclick', middle, true);
  }, 100);
})();
