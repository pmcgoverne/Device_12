<%*
const options = ["01 - Notes", "02 - Drafts",];
const fileNames = { 
    "02 - Drafts": "[[Template, Draft]]",
};

// Prompt user for type
const choice = await tp.system.suggester(options, options);

// Handle special case for Zotero citation
if (choice === "01 - Notes") {
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
