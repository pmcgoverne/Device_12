<%*
const folderPath = "01 - Notes";
let files = app.vault.getMarkdownFiles()
  .filter(f => f.path.startsWith(folderPath + "/"));
files = files.sort((a, b) => a.basename.localeCompare(b.basename));

const fileNames = files.map(f => f.basename);
const selectedFile = await tp.system.suggester(fileNames, fileNames);
if (!selectedFile) return;

const tfile = files.find(f => f.basename === selectedFile);
const content = await app.vault.read(tfile);

const lines = content.split("\n");
const start = lines.findIndex(l => l.includes(">>[!pink]- Events"));
if (start < 0) return;

let entries = [];
for (let i = start + 1; i < lines.length; i++) {
  const line = lines[i];
  if (line.startsWith(">>[!")) break;
  const m = line.match(/^>>\[\[(.+?)\]\]/);
  if (m) {
    entries.push(m[1]);
  }
}
if (!entries.length) return;

const pick = await tp.system.suggester(entries, entries);
if (!pick) return;

// output only the wikilink to the event
tR = `[[${pick}]]`;
%>