<%*
let typeOptions = ["Abstract", "Essay", "Manuscript"];
let typeChoice = await tp.system.suggester(typeOptions, typeOptions, false);
let filename = await tp.system.prompt('Title:', '', true);

await tp.file.rename(filename);


if (typeChoice === "Abstract") {
  tR += `---
Date:
  - ${tp.file.creation_date()}
tags: 
  - abstract
cssclasses:
  - lit-note
aliases:
---`;
} 

else if (typeChoice === "Essay") {
  tR += `---
Date:
  - ${tp.file.creation_date()}
tags: 
  - essay
cssclasses:
  - lit-note
title: {{Title}}
author: {{Author}}
date: {{Date}}
aliases:
---
# ${filename}`;
}

else if (typeChoice === "Manuscript") {
  tR += `---
Date:
  - ${tp.file.creation_date()}
tags: 
  - manuscript
cssclasses:
  - lit-note
title: {{Title}}
author: {{Author}}
date: {{Date}}
aliases:
---
# ${filename}`;
}
%>

