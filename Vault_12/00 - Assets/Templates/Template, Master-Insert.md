<%*
const options = ["Quote", "Person", "Idea", "Event", "Group", "Document"];
const fileNames = { 
    "Quote": "[[Template, Quote insert]]",
    "Person": "[[Template, People insert]]", 
    "Idea": "[[Template, Idea insert]]", 
    "Event": "[[Template, Event insert]]", 
    "Group": "[[Template, Group insert]]", 
    "Document": "[[Template, Document insert]]",
};

// Prompt user for type
const choice = await tp.system.suggester(options, options);

// Handle special case for Zotero citation
if (choice === "Citation") {
    app.commands.executeCommandById("obsidian-zotero-desktop-connector:zdc-exp-Journal");
    return;
}

// Insert the chosen template content
if (choice && fileNames[choice]) {
    const fileName = fileNames[choice];
    tR += await tp.file.include(fileName);
} else {
    return; // do nothing if selection cancelled or unrecognized
}
%>