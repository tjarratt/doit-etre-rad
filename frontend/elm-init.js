(function() {
  var rootNode = document.getElementById("elm-landing-pad");
  var seed = Math.floor(Math.random()*0x0FFFFFFF);
  var app = Elm.App.embed(rootNode, {seed: seed});

  app.ports.setItem.subscribe(function(arguments) {
    var key = arguments[0];
    var encodedValue = JSON.stringify(arguments[1]);

    window.localStorage.setItem(key, encodedValue);
    app.ports.setItemResponse.send(arguments[1]);
  });
  app.ports.getItem.subscribe(function(key) {
    var result = window.localStorage.getItem(key) || "[]";
    var json = JSON.parse(result);

    app.ports.getItemResponse.send([key, json]);
  });

  app.ports.setUserUuid.subscribe(function(uuid) {
    window.localStorage.setItem("user_uuid", uuid);
  });

  app.ports.getUserUuid.subscribe(function() {
    var uuid = window.localStorage.getItem("user_uuid");

    app.ports.getUserUuidResponse.send(uuid);
  });
})();
