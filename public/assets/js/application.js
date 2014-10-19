var scheme   = "ws://";
var uri      = scheme + window.document.location.host + "/";
var ws       = new WebSocket(uri);
ws.onmessage = function(message) {
  var data = JSON.parse(message.data);
  $("#history ul").append("<li>" + data.name + "</li>");
  $("#input-text")[0].value = data.text;
};

$("#input-form").on("submit", function(event) {
  event.preventDefault();
  var name = $("#input-name")[0].value;
  var text   = $("#input-text")[0].value;
  ws.send(JSON.stringify({ name: name, text: text }));
  $("#input-text")[0].value = "";
});
