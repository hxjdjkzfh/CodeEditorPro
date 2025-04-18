document.addEventListener('DOMContentLoaded', function() {
    const editor = document.getElementById('editor');
    const lineNumbers = document.getElementById('line-numbers');
    const consoleOutput = document.getElementById('console-output');
    const tabsContainer = document.getElementById('tabs');
    const newTabBtn = document.getElementById('new-tab');
    const saveBtn = document.getElementById('save-btn');
    const runBtn = document.getElementById('run-btn');
    const drawerHandle = document.getElementById('drawer-handle');
    const drawer = document.getElementById('drawer');
    const settingsBtn = document.getElementById('settings-btn');
    const settingsModal = document.getElementById('settings-modal');
    const closeSettings = document.getElementById('close-settings');
    const saveSettings = document.getElementById('save-settings');
    const cancelSettings = document.getElementById('cancel-settings');
    
    // State
    const files = {};
    let currentFile = null;
    let unsavedFiles = {};
    let backupInterval = null;
    let settings = {
        theme: 'dark',
        fontSize: 14,
        lineWrap: true,
        showLineNumbers: true,
        autoBackupInterval: 5,
        drawerPosition: 'left'
    };
    
    // Initialize from localStorage if available
    const initFromStorage = () => {
        try {
            // Load settings
            const savedSettings = localStorage.getItem('code-editor-settings');
            if (savedSettings) {
                settings = {...settings, ...JSON.parse(savedSettings)};
                applySettings();
            }
            
            // Load files
            const savedFiles = localStorage.getItem('code-editor-files');
            if (savedFiles) {
                const parsedFiles = JSON.parse(savedFiles);
                Object.keys(parsedFiles).forEach(fileName => {
                    files[fileName] = parsedFiles[fileName];
                });
            }
            
            // Load last opened file
            const lastFile = localStorage.getItem('code-editor-last-file');
            if (lastFile && files[lastFile]) {
                currentFile = lastFile;
            }
            
            // Load unsaved files
            const savedUnsaved = localStorage.getItem('code-editor-unsaved');
            if (savedUnsaved) {
                unsavedFiles = JSON.parse(savedUnsaved);
            }
            
            // If no files or current file, create default
            if (Object.keys(files).length === 0 || !currentFile) {
                files['main.js'] = '// Welcome to Code Editor\n\nfunction greet(name) {\n    return `Hello, ${name}!`;\n}\n\nconsole.log(greet("World"));';
                currentFile = 'main.js';
            }
            
            // Initialize editor with current file
            editor.textContent = files[currentFile] || '';
            updateTabs();
            highlightSyntax();
            updateLineNumbers();
            
            // Start auto-backup
            startAutoBackup();
        } catch (error) {
            console.error('Error initializing from storage:', error);
            // Fallback to default content
            files['main.js'] = '// Welcome to Code Editor\n\nfunction greet(name) {\n    return `Hello, ${name}!`;\n}\n\nconsole.log(greet("World"));';
            currentFile = 'main.js';
            editor.textContent = files[currentFile];
            updateTabs();
            highlightSyntax();
            updateLineNumbers();
        }
    };
    
    // Apply settings to UI
    const applySettings = () => {
        // Apply theme
        document.body.className = settings.theme ? 'theme-' + settings.theme : '';
        
        // Apply font size
        editor.style.fontSize = settings.fontSize + 'px';
        lineNumbers.style.fontSize = settings.fontSize + 'px';
        
        // Apply line wrap
        if (settings.lineWrap) {
            editor.classList.add('line-wrap');
        } else {
            editor.classList.remove('line-wrap');
        }
        
        // Apply line numbers visibility
        lineNumbers.style.display = settings.showLineNumbers ? 'block' : 'none';
        
        // Apply drawer position
        if (settings.drawerPosition === 'right') {
            document.body.classList.add('drawer-position-right');
        } else {
            document.body.classList.remove('drawer-position-right');
        }
        
        // Update settings form
        document.getElementById('theme-select').value = settings.theme;
        document.getElementById('font-size').value = settings.fontSize;
        document.getElementById('line-wrap').checked = settings.lineWrap;
        document.getElementById('show-line-numbers').checked = settings.showLineNumbers;
        document.getElementById('auto-backup').value = settings.autoBackupInterval;
        document.getElementById('drawer-position').value = settings.drawerPosition;
    };
    
    // Start auto-backup interval
    const startAutoBackup = () => {
        // Clear existing interval if any
        if (backupInterval) {
            clearInterval(backupInterval);
        }
        
        // Start new interval based on settings
        const minutes = settings.autoBackupInterval;
        if (minutes > 0) {
            backupInterval = setInterval(saveToLocalStorage, minutes * 60 * 1000);
        }
    };
    
    // Save state to localStorage
    const saveToLocalStorage = () => {
        try {
            // Save current content to unsaved if modified
            if (currentFile && editor.textContent !== files[currentFile]) {
                unsavedFiles[currentFile] = editor.textContent;
            }
            
            // Save all data
            localStorage.setItem('code-editor-files', JSON.stringify(files));
            localStorage.setItem('code-editor-unsaved', JSON.stringify(unsavedFiles));
            localStorage.setItem('code-editor-last-file', currentFile);
            localStorage.setItem('code-editor-settings', JSON.stringify(settings));
        } catch (error) {
            console.error('Error saving to localStorage:', error);
            appendToConsole('Error saving to localStorage: ' + error.message, true);
        }
    };
    
    // Function to highlight syntax
    function highlightSyntax() {
        const text = editor.textContent;
        let html = text
            .replace(/\/\/.*/g, match => `<span class="syntax-comment">${match}</span>`)
            .replace(/\/\*[\s\S]*?\*\//g, match => `<span class="syntax-comment">${match}</span>`)
            .replace(/(".*?"|'.*?'|`.*?`)/g, match => `<span class="syntax-string">${match}</span>`)
            .replace(/\b(function|return|if|else|for|while|var|let|const|class|import|export|from|true|false|null|undefined)\b/g, 
                    match => `<span class="syntax-keyword">${match}</span>`)
            .replace(/\b(\d+(\.\d+)?)\b/g, match => `<span class="syntax-number">${match}</span>`)
            .replace(/\b([A-Za-z_$][A-Za-z0-9_$]*)\s*\(/g, match => {
                const functionName = match.substring(0, match.length - 1);
                return `<span class="syntax-function">${functionName}</span>(`;
            });
            
        // Preserve selection
        const selection = window.getSelection();
        const range = selection.getRangeAt(0);
        const startContainer = range.startContainer;
        const startOffset = range.startOffset;
        const endContainer = range.endContainer;
        const endOffset = range.endOffset;
        
        // Apply highlighting
        editor.innerHTML = html;
        
        // Restore cursor position
        try {
            const newRange = document.createRange();
            newRange.setStart(editor.firstChild || editor, 0);
            newRange.setEnd(editor.firstChild || editor, 0);
            selection.removeAllRanges();
            selection.addRange(newRange);
        } catch (e) {
            // Fallback if we can't restore selection
        }
    }
    
    // Function to update line numbers
    function updateLineNumbers() {
        if (!settings.showLineNumbers) return;
        
        const lines = editor.textContent.split('\n');
        const count = lines.length;
        let lineNumbersHTML = '';
        
        for (let i = 1; i <= count; i++) {
            lineNumbersHTML += i + '<br>';
        }
        
        lineNumbers.innerHTML = lineNumbersHTML;
        
        // Synchronize scrolling
        lineNumbers.scrollTop = editor.scrollTop;
    }
    
    function createNewFile() {
        const fileName = prompt('Enter file name:');
        if (!fileName || files[fileName]) return;
        
        files[fileName] = '';
        currentFile = fileName;
        updateTabs();
        editor.textContent = '';
        highlightSyntax();
        updateLineNumbers();
        
        // Show animation for the new tab
        const newTab = tabsContainer.querySelector(`.tab[data-file="${fileName}"]`);
        if (newTab) {
            newTab.style.animation = 'none';
            setTimeout(() => {
                newTab.style.animation = 'fadeIn 0.3s ease';
            }, 10);
        }
    }
    
    function saveCurrentFile() {
        if (!currentFile) return;
        
        files[currentFile] = editor.textContent;
        delete unsavedFiles[currentFile];
        updateTabs();
        
        // Display saved message in console
        appendToConsole(`File ${currentFile} saved successfully.`);
        
        // Save to localStorage
        saveToLocalStorage();
    }
    
    function runCode() {
        const code = editor.textContent;
        consoleOutput.innerHTML = '';
        
        // Redirect console.log to our console
        const originalLog = console.log;
        const originalError = console.error;
        const originalWarn = console.warn;
        
        console.log = function() {
            const args = Array.from(arguments);
            appendToConsole(args.join(' '));
            originalLog.apply(console, arguments);
        };
        
        console.error = function() {
            const args = Array.from(arguments);
            appendToConsole(args.join(' '), true);
            originalError.apply(console, arguments);
        };
        
        console.warn = function() {
            const args = Array.from(arguments);
            appendToConsole('⚠️ ' + args.join(' '));
            originalWarn.apply(console, arguments);
        };
        
        try {
            // Create a new Function to execute the code
            const result = new Function(code)();
            if (result !== undefined) {
                appendToConsole('> ' + result);
            }
        } catch (error) {
            appendToConsole(`Error: ${error.message}`, true);
        } finally {
            // Restore original console methods
            console.log = originalLog;
            console.error = originalError;
            console.warn = originalWarn;
        }
    }
    
    function appendToConsole(text, isError = false) {
        const line = document.createElement('div');
        line.textContent = text;
        if (isError) {
            line.style.color = '#f44336';
        }
        consoleOutput.appendChild(line);
        consoleOutput.scrollTop = consoleOutput.scrollHeight;
    }
    
    function updateTabs() {
        // Clear all tabs except the add button
        while (tabsContainer.firstChild !== newTabBtn) {
            tabsContainer.removeChild(tabsContainer.firstChild);
        }
        
        // Add tabs for each file
        Object.keys(files).forEach(fileName => {
            const tab = document.createElement('div');
            tab.className = 'tab';
            if (fileName === currentFile) {
                tab.classList.add('active');
            }
            if (unsavedFiles[fileName]) {
                tab.classList.add('unsaved');
            }
            
            // Add file name
            tab.textContent = fileName;
            tab.dataset.file = fileName;
            
            // Add close button
            const closeBtn = document.createElement('span');
            closeBtn.className = 'close-tab';
            closeBtn.textContent = '×';
            closeBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                closeTab(fileName);
            });
            tab.appendChild(closeBtn);
            
            // Add event listeners
            tab.addEventListener('click', () => switchToFile(fileName));
            
            // Add long-press handler for closing tab
            let pressTimer;
            tab.addEventListener('mousedown', () => {
                pressTimer = setTimeout(() => {
                    closeTab(fileName);
                }, 500);
            });
            tab.addEventListener('mouseup', () => clearTimeout(pressTimer));
            tab.addEventListener('mouseleave', () => clearTimeout(pressTimer));
            
            tabsContainer.insertBefore(tab, newTabBtn);
        });
    }
    
    function closeTab(fileName) {
        // Check if file has unsaved changes
        if (unsavedFiles[fileName]) {
            if (!confirm(`${fileName} has unsaved changes. Close anyway?`)) {
                return;
            }
        }
        
        // Remove file
        delete files[fileName];
        delete unsavedFiles[fileName];
        
        // Switch to another file if the closed one was active
        if (fileName === currentFile) {
            const fileNames = Object.keys(files);
            if (fileNames.length > 0) {
                currentFile = fileNames[0];
                editor.textContent = files[currentFile];
                highlightSyntax();
                updateLineNumbers();
            } else {
                currentFile = null;
                editor.textContent = '';
                highlightSyntax();
                updateLineNumbers();
            }
        }
        
        updateTabs();
        saveToLocalStorage();
    }
    
    function switchToFile(fileName) {
        // Save current content to unsaved if modified
        if (currentFile && editor.textContent !== files[currentFile]) {
            unsavedFiles[currentFile] = editor.textContent;
        }
        
        currentFile = fileName;
        editor.textContent = unsavedFiles[fileName] || files[fileName];
        updateTabs();
        highlightSyntax();
        updateLineNumbers();
    }
    
    function toggleDrawer() {
        drawer.classList.toggle('open');
    }
    
    function showSettingsModal() {
        settingsModal.classList.add('active');
    }
    
    function hideSettingsModal() {
        settingsModal.classList.remove('active');
    }
    
    function saveSettingsAndClose() {
        // Get values from form
        settings.theme = document.getElementById('theme-select').value;
        settings.fontSize = parseInt(document.getElementById('font-size').value) || 14;
        settings.lineWrap = document.getElementById('line-wrap').checked;
        settings.showLineNumbers = document.getElementById('show-line-numbers').checked;
        settings.autoBackupInterval = parseInt(document.getElementById('auto-backup').value) || 5;
        settings.drawerPosition = document.getElementById('drawer-position').value;
        
        // Apply settings
        applySettings();
        
        // Save to localStorage
        saveToLocalStorage();
        
        // Restart auto-backup with new interval
        startAutoBackup();
        
        // Close modal
        hideSettingsModal();
    }
    
    // Add event listeners
    newTabBtn.addEventListener('click', createNewFile);
    saveBtn.addEventListener('click', saveCurrentFile);
    runBtn.addEventListener('click', runCode);
    drawerHandle.addEventListener('click', toggleDrawer);
    document.getElementById('new-file-btn').addEventListener('click', createNewFile);
    document.getElementById('save-file-btn').addEventListener('click', saveCurrentFile);
    settingsBtn.addEventListener('click', showSettingsModal);
    closeSettings.addEventListener('click', hideSettingsModal);
    saveSettings.addEventListener('click', saveSettingsAndClose);
    cancelSettings.addEventListener('click', hideSettingsModal);
    
    editor.addEventListener('input', () => {
        if (currentFile) {
            if (editor.textContent !== files[currentFile]) {
                unsavedFiles[currentFile] = editor.textContent;
                updateTabs();
            } else {
                delete unsavedFiles[currentFile];
                updateTabs();
            }
        }
        highlightSyntax();
        updateLineNumbers();
    });
    
    editor.addEventListener('scroll', () => {
        lineNumbers.scrollTop = editor.scrollTop;
    });
    
    // Handle tab drag and drop
    let draggedTab = null;
    
    function handleDragStart(e) {
        if (!e.target.classList.contains('tab')) return;
        
        draggedTab = e.target;
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/plain', draggedTab.dataset.file);
        
        // Add visual feedback
        setTimeout(() => {
            draggedTab.style.opacity = '0.4';
        }, 0);
    }
    
    function handleDragOver(e) {
        if (e.preventDefault) {
            e.preventDefault();
        }
        e.dataTransfer.dropEffect = 'move';
        return false;
    }
    
    function handleDragEnter(e) {
        if (!e.target.classList.contains('tab')) return;
        e.target.classList.add('over');
    }
    
    function handleDragLeave(e) {
        if (!e.target.classList.contains('tab')) return;
        e.target.classList.remove('over');
    }
    
    function handleDrop(e) {
        if (e.stopPropagation) {
            e.stopPropagation();
        }
        
        if (draggedTab && e.target.classList.contains('tab')) {
            const draggedFile = draggedTab.dataset.file;
            const targetFile = e.target.dataset.file;
            
            // Reorder files object by creating new object with desired order
            const newFiles = {};
            
            Object.keys(files).forEach(file => {
                if (file === draggedFile) return; // Skip dragged file
                
                if (file === targetFile) {
                    // Add files in the right order based on drop position
                    if (e.clientX < e.target.getBoundingClientRect().left + e.target.offsetWidth / 2) {
                        newFiles[draggedFile] = files[draggedFile];
                        newFiles[targetFile] = files[targetFile];
                    } else {
                        newFiles[targetFile] = files[targetFile];
                        newFiles[draggedFile] = files[draggedFile];
                    }
                } else {
                    newFiles[file] = files[file];
                }
            });
            
            // Update files object and refresh tabs
            Object.keys(files).forEach(key => delete files[key]);
            Object.keys(newFiles).forEach(key => files[key] = newFiles[key]);
            
            updateTabs();
        }
        
        // Clean up
        Array.from(tabsContainer.querySelectorAll('.tab')).forEach(tab => {
            tab.classList.remove('over');
            tab.style.opacity = '1';
        });
        
        return false;
    }
    
    function handleDragEnd() {
        // Clean up
        Array.from(tabsContainer.querySelectorAll('.tab')).forEach(tab => {
            tab.classList.remove('over');
            tab.style.opacity = '1';
        });
    }
    
    // Add drag and drop event listeners
    tabsContainer.addEventListener('dragstart', handleDragStart, false);
    tabsContainer.addEventListener('dragover', handleDragOver, false);
    tabsContainer.addEventListener('dragenter', handleDragEnter, false);
    tabsContainer.addEventListener('dragleave', handleDragLeave, false);
    tabsContainer.addEventListener('drop', handleDrop, false);
    tabsContainer.addEventListener('dragend', handleDragEnd, false);
    
    // Make tabs draggable
    const makeTabsDraggable = () => {
        Array.from(tabsContainer.querySelectorAll('.tab')).forEach(tab => {
            tab.setAttribute('draggable', 'true');
        });
    };
    
    // Update tabs draggable state when tabs change
    const origUpdateTabs = updateTabs;
    updateTabs = function() {
        origUpdateTabs();
        makeTabsDraggable();
    };
    
    // Initialize
    initFromStorage();
    
    // Add window unload handler to save state
    window.addEventListener('beforeunload', saveToLocalStorage);
    
    // Initial tabs setup
    makeTabsDraggable();
});