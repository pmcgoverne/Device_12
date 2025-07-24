<%*
const times = Array.from({ length: 48 }, (_, i) => 
    `${String(Math.floor(i / 2)).padStart(2, "0")}_${i % 2 === 0 ? "00" : "30"}`
);

let resultDate = "";
let resultFormat = "YYYY-MM-DD";

let dateString = await tp.system.suggester(["today", "yesterday", "tomorrow", "> weekday", "> calendar"], ["today", "yesterday", "tomorrow", "> weekday", "> calendar"]);
if (dateString) {
    if (dateString == "today") resultDate = tp.date.now(resultFormat);
    else if (dateString == "yesterday") resultDate = tp.date.yesterday(resultFormat);
    else if (dateString == "tomorrow") resultDate = tp.date.tomorrow(resultFormat);
    else if (dateString == "> weekday") {
        let weekday = await tp.system.suggester(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], [1, 2, 3, 4, 5, 6, 0]);
        let offset = weekday - tp.date.now("d");
        resultDate = tp.date.now(resultFormat, offset <= 0 ? offset + 7 : offset);
    } else {
        resultDate = await tp.system.prompt("Enter date (YYYY-MM-DD):");
    }
}

const start = await tp.system.suggester(times, times, false);
const end = await tp.system.suggester(times, times, false);
const type = await tp.system.suggester(["1:1", "Group"], ["1:1", "Group"], false);

let withWhom = "";
let groupName = "";

if (type === "1:1") {
    withWhom = await tp.system.prompt("With whom:");
} else {
    groupName = await tp.system.prompt("Group name:");
    withWhom = await tp.system.prompt("Who are the members of the group?", null, false, true);
}

const objective = await tp.system.prompt("Objective (single line):");
const summary = await tp.system.prompt("Summary (single line):");
const actionItems = await tp.system.prompt("Enter action items:", null, false, true);

const tasks = actionItems
    .split("\n")
    .filter(item => item.trim() !== "")
    .map(item => `> - [ ] ${item.trim()} 📅 ${resultDate}`)
    .join("\n");

const attendeesDisplay = withWhom
    .split("\n")
    .map(person => `>> [[${person.trim()}]]`)
    .join("\n");

let content = `-
Date:
  - ${tp.file.creation_date()}
tags:
  - meeting
occurred: ${resultDate || ""}
start: ${start || ""}
end: ${end || ""}
summary: ${summary || ""}
people: 
${peopleList || "  - None"}
---
${app.commands.executeCommandById("super-duper-audio-recorder:start-stop-recording")}
\`\`\`meta-bind-button
label: Start/Stop
icon: ""
style: destructive
class: ""
cssStyle: ""
tooltip: ""
id: ""
hidden: false
actions:
  - type: command
    command: super-duper-audio-recorder:start-stop-recording
\`\`\`
\`\`\`meta-bind-button
label: Play/Pause
icon: ""
style: default
class: ""
cssStyle: ""
backgroundImage: ""
tooltip: ""
id: ""
hidden: false
actions:
  - type: command
    command: super-duper-audio-recorder:pause-resume-recording
\`\`\`

>[!multi-column]
>> [!Blue] Notes
>>- Summary: ${summary}
>
>> [!people] Attendees
${attendeesDisplay || ">> None"}
>
>> [!green] Action Items
${tasks || "> - No action items"}
`;

const fileName = type === "1:1" 
    ? `-${(withWhom || "Unknown").trim().replace(/ /g, "_")}.${resultDate}` 
    : `_${(groupName || "Group").trim().replace(/ /g, "_")}.${resultDate}`;

await tp.file.rename(fileName);
tR += content;
%>