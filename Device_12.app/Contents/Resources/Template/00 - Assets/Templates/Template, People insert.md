<%*  
// 1. Pick a literature note as before  
const folderPath = "01 - Notes/Source Notes";  
let files = app.vault.getMarkdownFiles()  
  .filter(f => f.path.startsWith(folderPath + "/"))  
  .sort((a,b) => a.basename.localeCompare(b.basename));  

const names = files.map(f => f.basename);  
const chosen = await tp.system.suggester(names, names);  
if (!chosen) return;  

const noteFile = files.find(f => f.basename === chosen);  
const content = await app.vault.read(noteFile);  

// 2. Extract your call‑out entries  
const lines = content.split("\n");  
const start = lines.findIndex(l => l.includes(">>[!purple]- People"));  
if (start < 0) return;  

let entries = [];  
for (let i = start+1; i < lines.length; i++) {  
  if (lines[i].startsWith(">>[!")) break;  
  const m = lines[i].match(/^>>\[\[(.+?)\]\]/);  
  if (m) entries.push(m[1]);  
}  
if (!entries.length) return;  

// 3. Let user pick one  
const pick = await tp.system.suggester(entries, entries);  
if (!pick) return;  

// 4. Write it into THIS note’s frontmatter under “person”  
const thisPath = tp.file.path(true);  
const thisFile = app.vault.getAbstractFileByPath(thisPath);  
app.fileManager.processFrontMatter(thisFile, fm => {  
  fm.person = pick;  
});  
%>
