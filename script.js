var editor;
var nesting;
var loopdepth;
var loopstack;

function __clear() {
  $('#debug2').val("");
  $('#code tbody tr').remove();

  nesting = 0;
  loopdepth = 0;
  loopstack = [];
}

function __update(name, val, line) {
  var len = $('#code tbody tr').length;
  for (var i = len; i <= line; i++) {
    $('#code tbody').append($('<tr></tr>'));
  }
  var row = $($('#code tbody tr')[line]);
  len = row.find('td').length;
  for (var i = len; i <= Math.max(0, nesting + loopdepth); i++) {
    row.append($('<td></td>'));
  }
  $(row.find('td')[Math.max(0, nesting + loopdepth)]).append($('<div>' + name + ' = ' + JSON.stringify(val) + '</div>'));
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
  if (nesting == 100) throw 'Stack overflow';
  nesting++;
  loopstack.push(loopdepth);
  loopdepth -= 2;
  $('#debug2').val($('#debug2').val() + '\n' + "{");
}

function __loopend() {
  nesting--;
  loopdepth = loopstack.pop();
  $('#debug2').val($('#debug2').val() + '\n' + "}");
}

function __loop() {
  loopdepth++;
  $('#debug2').val($('#debug2').val() + '\n' + "continue;");
  return true;
}

function __nop(x, y, z) {
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

