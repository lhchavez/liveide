var editor;

function __clear() {
  $('#debug2').val("");
  $('#code tbody tr').remove();
}

function __update(name, val, line) {
  var len = $('#code tbody tr').length;
  for (var i = len; i <= line; i++) {
    $('#code tbody').append($('<tr></tr>'));
  }
  $($('#code tbody tr')[line]).append($('<td>' + name + ' = ' + JSON.stringify(val) + '</td>'));
}

function __postchange(name, val, inc, line) {
  $('#debug2').val($('#debug2').val() + '\n' + name + ' = ' + (val + inc) + "(" + (line + 1) + ")");
  __update(name, val + inc, line);
  return val;
}

function __change(name, val, line) {
  $('#debug2').val($('#debug2').val() + '\n' + name + ' = ' + JSON.stringify(val) + "(" + (line + 1) + ")");
  __update(name, val, line);
  return val;
}

function __loopstart() {
  $('#debug2').val($('#debug2').val() + '\n' + "{");
}

function __loopend() {
  $('#debug2').val($('#debug2').val() + '\n' + "}");
}

function __loop() {
  $('#debug2').val($('#debug2').val() + '\n' + "continue;");
  return true;
}

function __nop(x, y) {
  return y;
}

function update() {
  var src = jsparser.parse(editor.getValue());
  $('#debug').val(src);
  __clear();
  eval(src);
}

$(document).ready(function () {
  editor = CodeMirror.fromTextArea(document.getElementById("source"), {
    lineNumbers: true,
    matchBrackets: true,
    onChange: update,
    tabSize: 4
  });

  update();
  
  $('.CodeMirror-lines pre:not(.CodeMirror-cursor), #code tr').live('mouseover', function() {
    var index = $(this).index() + 1;
    $('#code tr:nth-child('+index+')').addClass('hover');
    var other = $('.CodeMirror-lines > div > div > pre:nth-child('+index+')');
    other.addClass('hover');
  });
  
  $('.CodeMirror-lines pre:not(.CodeMirror-cursor), #code tr').live('mouseout', function() {
    var index = $(this).index() + 1;
    $('#code tr:nth-child('+index+')').removeClass('hover');
    $('.CodeMirror-lines > div > div > pre:nth-child('+index+')').removeClass('hover');
  });
});

