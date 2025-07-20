<%*
 let filename = await tp.system.prompt('Title:', '', true)

 await tp.file.rename(filename)
 -%>
---
Date:
  - <% tp.file.creation_date() %>
tags: 
  - atom
cssclasses:
  - lit-note
aliases:
---
