<%*
let name = await tp.system.prompt("Name: ");
let summary = await tp.system.prompt("Summary: ");
let relationshipOptions = ["personal", "professional", "historical", "other"];
let relationship = await tp.system.suggester(relationshipOptions, relationshipOptions, false);
let company = await tp.system.prompt("Company: ");
let location = await tp.system.prompt("Location: ");
await tp.file.rename(name)
await tp.file.move("/02 - Journal/People/" + name);

// Create the output structure
let content = `---
Date:
  - ${tp.file.creation_date()}
tags:
  - person
  - ${relationship || "Not specified"}
cssclass:
  - daily
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
relationship: ${relationship || "Not specified"}
summary: ${summary || "Not specified"}
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
>FROM "02 - Journal/Meetings" where contains(file.outlinks, [[${name}]])
>SORT file.cday DESC
>\`\`\`
`;

tR += content;
%>

<% `[[${location}]]` %>
<% `[[${company}]]` %>



