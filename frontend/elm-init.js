(function() {
  var app = Elm.App.embed(document.getElementById("elm-landing-pad"));

  app.ports.setItem.subscribe(function(arguments) {
    var key = arguments[0];
    var encodedValue = JSON.stringify(arguments[1]);

    window.localStorage.setItem(key, encodedValue);
  });
  app.ports.getItem.subscribe(function(key) {
    var result = window.localStorage.getItem(key) || "[]";
    var json = JSON.parse(result);

    app.ports.getItemResponse.send([key, json]);
  });
})();
