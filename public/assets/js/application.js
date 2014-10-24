var scheme = "ws://";
var uri = scheme + window.document.location.host + "/";
var ws = new WebSocket(uri);

var currentText = "";

ws.onmessage = function(message) {
  var data = JSON.parse(message.data);

  if (data.usernames) {
    $("#user-list").text("Connected users: " + data.usernames.join(', '));
  }

  if (data.text && data.text !== $("#input-text").text()) {
    $("#input-text")[0].value = data.text;
  }
};

biggestStrLength = function (string1, string2) {
  return string1.length > string2.length ? string1.length : string2.length
}

calculateDiff = function (newText, oldText) {
  var start = end = null;
  var longestTextLength = biggestStrLength(newText, oldText)

  // iterate from start and end of strings to find the range
  // that has been edited
  for (var i = 0; i < longestTextLength; i++) {
    if (start == null && newText[i] !== oldText[i]) {
      start = i;
    }
    if (end == null && newText[newText.length - i] !== oldText[oldText.length - i]) {
      end = newText.length - i + 1;
    }
  }

  return {
    'start': start,
    'length': end - start,
    'diff': newText.slice(start, end)
  };
}

$("#input-text").on("change keyup paste", function () {
  var textBox = $("#input-text")[0];
  var nameBox = $("#name-field")[0];

  var diffResults = calculateDiff(textBox.value, currentText);

  currentText = textBox.value

  ws.send(JSON.stringify({
    action: "text_change",
    username: nameBox.value,
    text: textBox.value
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
