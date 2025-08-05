---
tags:
  - DailyNotes
cssclasses:
  - daily
  - <%tp.date.now("dddd",0,tp.file.title,'"YYYYMMDD").toLowerCase()')%>
  - grain-paper-1
---
```calendar-nav
```
---
### Thoughts

---

>[!multi-column]
>```meta-bind-button
>label: + Meeting
>icon: ""
>hidden: false
>class: ""
>tooltip: ""
>id: ""
>style: default
>actions:
>  - type: templaterCreateNote
>    templateFile: 03 - Assets/Templates/Template, Meeting.md
>    folderPath: 02 - Journal/Meetings
>    fileName: ""
>    openNote: true
>    openIfAlreadyExists: true
>```
>
>```meta-bind-button
>label: + People
>icon: ""
>hidden: false
>class: ""
>tooltip: ""
>id: ""
>style: default
>actions:
>  - type: templaterCreateNote
>    templateFile: 03 - Assets/Templates/Template, People.md
>    folderPath: 02 - Journal/People
>    fileName: ""
>    openNote: true
>    openIfAlreadyExists: true
>```
>
>```meta-bind-button
>label: + Note
>icon: ""
>hidden: false
>class: ""
>tooltip: ""
>id: ""
>style: default
>actions:
>  - type: templaterCreateNote
>    templateFile: 03 - Assets/Templates/Template, Blank.md
>    folderPath: 02 - Journal/Organize
>    fileName: ""
>    openNote: true
>    openIfAlreadyExists: true
>```

>[!multi-column]
>>[!quote]+ Meetings
>>```dataview
>>TABLE start AS "Start", end AS "End"
>>FROM "02 - Journal/Meetings"
>>WHERE occurred = date(<%tp.date.now("YYYY-MM-DD")%>)
>>SORT start ASC
>>```
>
>> [!quote]+ People
>>```dataview
>>List FROM "02 - Journal/People" WHERE file.mday = date(<%tp.date.now("YYYY-MM-DD")%>) or file.cday = date(<%tp.date.now("YYYY-MM-DD")%>) SORT file.mtime asc
>>```
>
>>[!quote]+ Notes
>>```dataview
>>List FROM "" WHERE file.cday = date(<%tp.date.now("YYYY-MM-DD")%>) SORT file.ctime asc
>>```


---

>[!multi-column]
>>[!danger] Overdue
>>```tasks
>>due before "<%tp.date.now("YYYY-MM-DD")%>"
>>not done
>
>>[!warning] Due Today
>>```tasks
>>due "<%tp.date.now("YYYY-MM-DD")%>"
>>not done
>>```
>
>>[!example] Due This Week
>>```tasks
>>due after <%tp.date.now("YYYY-MM-DD")%>
>>due before <%tp.date.now("YYYY-MM-DD", +7)%>
>>not done
>>```


---

>[!multi-column]
>>[!abstract] Done
>>```tasks
>>done <%tp.date.now("YYYY-MM-DD")%>
>>```

---
>[!multi-column]
>>[!quote]- Notes created today
>>```dataview
>>List FROM "" WHERE file.cday = date(<%tp.date.now("YYYY-MM-DD")%>) SORT file.ctime asc
>>```
>
>>[!quote]- Notes last touched today
>>```dataview
>>List FROM "" WHERE file.mday = date(<%tp.date.now("YYYY-MM-DD")%>) SORT file.mtime asc
>>```
