<%*
 let filename = await tp.system.prompt('Title:', '', true)

 await tp.file.rename(filename)
 await tp.file.move("/02 - Journal/Notes/" + filename);
 -%>
---
Date:
  - <% tp.file.creation_date() %>
tags: 
  - alloy
cssclasses:
  - lit-note
aliases:
---
# <%= filename %>
