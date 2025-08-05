<%*

// 1. Show current file name in a single-option suggester (read-only display)
const fileName = tp.file.title;
await tp.system.prompt(fileName);

// 2. Ask whether to create the document or abort
let createLabels = ["Create", "Don't Create"];
let createChoice = await tp.system.suggester(createLabels, createLabels, false);

if (createChoice === "Don't Create") {
    return; // Abort execution
}

// 2. Gather other inputs
let company   = await tp.system.prompt("Company: ");
let location  = await tp.system.prompt("Location: ");

// "met?" → "Met" / "Not Met" => true/false
let metLabels   = ["Met", "Not Met"];
let metChoice   = await tp.system.suggester(metLabels, metLabels, false);
let metValue    = (metChoice === "Met") ? "true" : "false";

// "dead?" → "Dead" / "Alive" => true/false
let deadLabels  = ["Dead", "Alive"];
let deadChoice  = await tp.system.suggester(deadLabels, deadLabels, false);
let deadValue   = (deadChoice === "Dead") ? "true" : "false";

// For your "deadChange" logic in tags/relationship
let deadChange  = (deadChoice === "Dead") ? "historical" : "professional";

// 3. Build front matter & note content
let content = `---
Date:
  - ${tp.file.creation_date()}
tags:
  - person
  - ${deadChange}
cssclass:
  - lit-note
company: ${company || "Not specified"}
email: 
location: ${location || "Not specified"}
birthday: 
address: 
website: 
interests:
  - 
disinterests:
  - 
relationship: ${deadChange}
summary: 
met?: ${metValue}
dead?: ${deadValue}
---
## Notes
- 

>[!multi-column]
>>[!green]+ Virtues
>>- 
>
>>[!red]+ Vices
>>- 


> [!example]+ Meetings
>\`\`\`dataview
>TABLE file.cday as Created, summary AS "Summary"
>FROM "02 - Journal/Meetings" where contains(file.outlinks, [[${fileName}]])
>SORT file.cday DESC
>\`\`\`
`;

// 4. Insert content
tR += content;

// Optional links at the bottom
%>
<% `[[${location}]]` %>
<% `[[${company}]]` %>





