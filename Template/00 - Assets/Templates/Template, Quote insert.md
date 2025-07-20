<%*
const folderPath = "01 - Notes/Source Notes"; // Change if needed
let files = app.vault.getMarkdownFiles().filter(f => f.path.startsWith(folderPath + "/"));
files = files.sort((a, b) => a.basename.localeCompare(b.basename));

// Prompt to select literature note
const fileNames = files.map(f => f.basename);
const selectedFile = await tp.system.suggester(fileNames, fileNames);
const selectedTFile = files.find(f => f.basename === selectedFile);
const content = await app.vault.read(selectedTFile);

// Supported highlight colors from Zotero
const allowedColors = ["#3e6e20", "#994141", "#998a26"];
const quoteRegex = new RegExp(
  `> - <mark style="background: (${allowedColors.join('|')});">([\\s\\S]*?)<\\/mark>\\n> <span style="display: inline-block; width: 100%; text-align: right;">\\[(\\d+)\\]\\((zotero:\\/\\/open-pdf\\/library\\/items\\/.*?)\\)<\\/span>`,
  "g"
);

// Extract matching highlights
let matches = [...content.matchAll(quoteRegex)];
if (matches.length === 0) {
  tR += `⚠️ No matching Zotero highlights found in "${selectedFile}".`;
  return;
}

// Build preview options
let options = matches.map((match) => {
  const quoteText = match[2]?.trim().replace(/\n/g, " ");
  const pageNum = match[3] || "??";
  return `“${quoteText.slice(0, 100)}...” [p.${pageNum}]`;
});

let insertedQuotes = "";

while (options.length > 0) {
  const selected = await tp.system.suggester(options, options);
  if (!selected) break;

  const selectedIndex = options.indexOf(selected);
  const [_, color, quoteRaw] = matches[selectedIndex];
  const quote = quoteRaw.trim().replace(/\n/g, " ");
  const wordCount = quote.split(/\s+/).length;

  if (wordCount > 40) {
    insertedQuotes += `> ${quote}\n[[${selectedFile}]]\n\n`;
  } else {
    insertedQuotes += `"${quote}" [[${selectedFile}]]\n\n`;
  }

  // Remove used quote
  options.splice(selectedIndex, 1);
  matches.splice(selectedIndex, 1);

  const more = await tp.system.suggester(["Yes", "No"], ["Yes", "No"]);
  if (more !== "Yes") break;
}

// Output result
tR += insertedQuotes;
%>