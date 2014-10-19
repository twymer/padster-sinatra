var scheme   = "ws://";
var uri      = scheme + window.document.location.host + "/";
var ws       = new WebSocket(uri);

ws.onmessage = function(message) {
  var data = JSON.parse(message.data);

  if (data.usernames) {
    $("#user-list").text("Connected users: " + data.usernames.join(', '));
  }

  if (data.text && data.text !== $("#input-text").text()) {
    $("#input-text")[0].value = data.text;
  }
};

$("#input-text").on("change keyup paste", function () {
  var name = $("#name-field")[0].value;
  var text = $("#input-text")[0].value;

  ws.send(JSON.stringify({
    action: "text_change",
    username: name,
    text: text
  }));
});

$("#name-field").on("change", function () {
  var name = $("#name-field")[0].value;
  var text = $("#input-text")[0].value;

  ws.send(JSON.stringify({
    action: "name_change",
    username: name,
  }));
});
