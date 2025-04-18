document.addEventListener('DOMContentLoaded', function() {
    const editor = document.getElementById('editor');
    const consoleOutput = document.getElementById('console-output');
    const tabsContainer = document.getElementById('tabs');
    const newTabBtn = document.getElementById('new-tab');
    const saveBtn = document.getElementById('save-btn');
    const runBtn = document.getElementById('run-btn');
    
    // State
    let files = {
        'main.js': '// Welcome to Code Editor\n\nfunction greet(name) {\n    return `Hello, ${name}!`;\n}\n\nconsole.log(greet("World"));'
    };
    let currentFile = 'main.js';
    let unsavedFiles = {};
    
    // Initialize editor with default file
    editor.textContent = files[currentFile];
    highlightSyntax();
    
    // Add event listeners
    newTabBtn.addEventListener('click', createNewFile);
    saveBtn.addEventListener('click', saveCurrentFile);
    runBtn.addEventListener('click', runCode);
    editor.addEventListener('input', () => {
        markFileAsUnsaved(currentFile);
        highlightSyntax();
    });
    
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
    
    function createNewFile() {
        const fileName = prompt('Enter file name:');
        if (!fileName || files[fileName]) return;
        
        files[fileName] = '';
        currentFile = fileName;
        updateTabs();
        editor.textContent = '';
        highlightSyntax();
    }
    
    function saveCurrentFile() {
        files[currentFile] = editor.textContent;
        delete unsavedFiles[currentFile];
        updateTabs();
        
        // Display saved message in console
        appendToConsole(`File ${currentFile} saved successfully.`);
    }
    
    function runCode() {
        const code = editor.textContent;
        consoleOutput.innerHTML = '';
        
        // Redirect console.log to our console
        const originalLog = console.log;
        console.log = function() {
            const args = Array.from(arguments);
            appendToConsole(args.join(' '));
            originalLog.apply(console, arguments);
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
            // Restore original console.log
            console.log = originalLog;
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
            tab.textContent = fileName;
            tab.dataset.file = fileName;
            tab.addEventListener('click', () => switchToFile(fileName));
            tabsContainer.insertBefore(tab, newTabBtn);
        });
    }
    
    function switchToFile(fileName) {
        currentFile = fileName;
        editor.textContent = files[fileName];
        updateTabs();
        highlightSyntax();
    }
    
    function markFileAsUnsaved(fileName) {
        unsavedFiles[fileName] = true;
        updateTabs();
    }
    
    // Initialize tabs
    updateTabs();
});
