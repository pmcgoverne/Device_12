<%*
let typeOptions = ["Misc", "Literature Note",];
let typeChoice = await tp.system.suggester(typeOptions, typeOptions, false);
let filename = await tp.system.prompt('Title:', '', true);

await tp.file.rename(filename);

if (typeChoice === "Misc") {
  tR += `---
Date:
  - ${tp.file.creation_date()}
tags: 
  - misc
cssclasses:
  - lit-note
aliases:
---`;
  
} else if (typeChoice === "Literature Note") {
  await tp.file.move("/02 - Journal/Notes/" + filename);
  tR += `---
Date:
  - ${tp.file.creation_date()}
tags: 
  - lit-Note
cssclasses:
  - lit-note
aliases:
---
# ${filename}`;

%>
