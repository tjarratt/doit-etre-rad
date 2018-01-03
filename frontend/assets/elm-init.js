(function() {
  var rootNode = document.getElementById("elm-landing-pad");
  var seed = Math.floor(Math.random()*0x0FFFFFFF);
  var app = Elm.App.embed(rootNode, {seed: seed});

  app.ports.setItem.subscribe(function(arguments) {
    var key = arguments[0];
    var encodedValue = JSON.stringify(arguments[1]);
    var latestValue = arguments[2];

    window.localStorage.setItem(key, encodedValue);
    app.ports.setItemResponse.send(latestValue);
  });
  app.ports.getItem.subscribe(function(key) {
    var result = window.localStorage.getItem(key) || "[]";
    var json = JSON.parse(result);

    app.ports.getItemResponse.send([key, json]);
  });

  app.ports.getUserUuid.subscribe(function() {
    var uuid = window.localStorage.getItem("user_uuid");
    if (!uuid) {
      uuid = uuidv4();
      window.localStorage.setItem("user_uuid", uuid)
    }

    app.ports.getUserUuidResponse.send(uuid);
  });

  app.ports.showTooltips.subscribe(function(arguments) {
    requestAnimationFrame(function() {
      $('[data-toggle="tooltip"]').tooltip();
    });
  });

  function uuidv4() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
})();
