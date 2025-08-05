---
Date:
  - <% tp.file.creation_date() %>
tags:
  - people
company: 
email: 
location: 
birthday: 
address: 
website: 
interests:
---
## Notes
- 

## Meetings
```dataview
TABLE file.cday as Created, summary AS "Summary"
FROM "Timestamps/Meetings" where contains(file.outlinks, [[<% tp.file.title %>]])
SORT file.cday DESC
```
