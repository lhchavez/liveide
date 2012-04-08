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

function update() {
        var src = jsparser.parse($('#source').val());
        $('#debug').val(src);
        __clear();
        eval(src);
}

$(document).ready(function () {
        update();
        $('#source').keyup(update);
});
