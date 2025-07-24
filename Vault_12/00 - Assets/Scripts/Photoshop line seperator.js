if (app.documents.length > 0) {

  var myDocument = app.activeDocument;

  var theLayer = myDocument.activeLayer;

  if (theLayer.kind == LayerKind.TEXT) {

    // get text an dleading;

    var theText = theLayer.textItem.contents.split("\r");

    try {

      var theLeading = theLayer.textItem.leading;

    }

    catch (e) {

      var theLeading = theLayer.textItem.size * 1.2;

    };

    var theOffset = 0;

    // work off the array;

    for (var m = 0; m < theText.length; m++) {

      // duplicate layer, change its contents and move it;

      var theNewText = theLayer.duplicate(theLayer, ElementPlacement.PLACEBEFORE);

      theNewText.textItem.contents = theText[m];

      theNewText.translate(0, theOffset);

      // amend offset;

      theOffset = theOffset + theLeading

    }

  }

};