/* http://www.opensource.apple.com/source/JavaScriptCore/ */

%lex
%%

\/\/[^\n]+			/* single line comment */
\/\*([^*]|\*[^\/])+\*\/		/* multi-line comment */

\"[^"\n]*\"			return 'STRING'
\'[^'\n]*\'			return 'STRING'
[-]?\d+(\.\d*)?([eE]\d+)?	return 'NUMBER'
[-]?\.\d+([eE]\d+)?		return 'NUMBER'
0[xX][0-9a-fA-F]+		return 'NUMBER'

\s+				/* skip whitespace */

"break"				return 'BREAK'
"case"				return 'CASE'
"catch"				return 'CATCH'
"const"				return 'CONSTTOKEN'
"continue"			return 'CONTINUE'
"debugger"			return 'DEBUGGER'
"default"			return 'DEFAULT'
"delete"			return 'DELETETOKEN'
"do"				return 'DO'
"else"				return 'ELSE'
"false"				return 'FALSETOKEN'
"finally"			return 'FINALLY'
"for"				loopStack.push(yylineno); return 'FOR'
"function"			loopStack.push(yylineno); return 'FUNCTION'
"if"				return 'IF'
"instanceof"			return 'INSTANCEOF'
"in"				return 'INTOKEN'
"new"				return 'NEW'
"null"				return 'NULLTOKEN'
"return"			return 'RETURN'
"switch"			return 'SWITCH'
"this"				return 'THISTOKEN'
"throw"				return 'THROW'
"true"				return 'TRUETOKEN'
"try"				return 'TRY'
"typeof"			return 'TYPEOF'
"var"				return 'VAR'
"void"				return 'VOIDTOKEN'
"while"				return 'WHILE'
"with"				return 'WITH'

[$_a-zA-Z][$_a-zA-Z0-9]*	return 'IDENT'

"+="				return 'PLUSEQUAL'
"-="				return 'MINUSEQUAL'
"*="				return 'MULTEQUAL'
"/="				return 'DIVEQUAL'
"%="				return 'MODEQUAL'
"&="				return 'ANDEQUAL'
"|="				return 'OREQUAL'
"^="				return 'XOREQUAL'
"=="				return 'EQEQ'
"!="				return 'NE'
"==="				return 'STREQ'
"!=="				return 'STRNEQ'
">="				return 'GE'
"<="				return 'LE'
">>="				return 'RSHIFTEQUAL'
">>>="				return 'URSHIFTEQUAL'
"<<="				return 'LSHIFTEQUAL'

"&&"				return 'AND'
"||"				return 'OR'
"++"				return 'PLUSPLUS'
"--"				return 'MINUSMINUS'
">>"				return 'RSHIFT'
">>>"				return 'URSHIFT'
"<<"				return 'LSHIFT'
"{"				return 'OPENBRACE'
"}"				return 'CLOSEBRACE'

"+"				return '+'
"-"				return '-'
"*"				return '*'
"/"				return '/'
"%"				return '%'

"="				return '='
"."				return '.'
","				return ','
":"				return ':'
";"				return ';'
"("				return '('
")"				return ')'
"["				return '['
"]"				return ']'
">"				return '>'
"<"				return '<'
"~"				return '~'
"^"				return '^'
"|"				return '|'
"&"				return '&'
"!"				return '!'
"?"				return '?'

/lex

%start Program

%{
var Stack = function() {
	this.array = [];
}
Stack.prototype.get = function(x) {
	return this.array[this.array.length - x];
};
Stack.prototype.consume = function(x) {
	this.array.splice(this.array.length - x - 1, x);
};
Stack.prototype.push = function(x) {
	this.array.push(x);
};
Stack.prototype.pop = function() {
	return this.array.pop();
};
function __postchange(name, val, inc, line) {
	console.log(name + ' = ' + (val + inc) + "(" + (line + 1) + ")");
	return val;
}
function __change(name, val, line) {
	console.log(name + ' = ' + JSON.stringify(val) + "(" + (line + 1) + ")");
	return val;
}
function __loopstart() {
	console.log("{");
}
function __loopend() {
	console.log("}");
}
function __loop() {
	console.log("continue;");
	return true;
}
function __nop(x, y, z) {
	return y;
}
var stack = new Stack();
var loopStack = new Stack();
%}

%nonassoc IF_WITHOUT_ELSE
%nonassoc ELSE

%%

Literal
    : NULLTOKEN { stack.push($1); }
    | TRUETOKEN { stack.push($1); }
    | FALSETOKEN { stack.push($1); }
    | NUMBER { stack.push($1); }
    | STRING { stack.push($1); }
    | '/' { stack.push($1); }
    | DIVEQUAL { stack.push($1); }
    ;

Property
    : IDENT ':' AssignmentExpr
	{ stack.push($1 + $2 + ' ' + stack.pop()); }
    | STRING ':' AssignmentExpr
	{ stack.push($1 + $2 + ' ' + stack.pop()); }
    | NUMBER ':' AssignmentExpr
	{ stack.push($1 + $2 + ' ' + stack.pop()); }
    | IDENT IDENT '(' ')' OPENBRACE FunctionBody CLOSEBRACE
	{ stack.push($1 + $2 + $3 + $4 + $5 + stack.pop() + $7); }
    | IDENT IDENT '(' FormalParameterList ')' OPENBRACE FunctionBody CLOSEBRACE
	{ stack.push($1 + $2 + $3 + stack.get(2) + $5 + $6 + stack.get(1) + $8);
	  stack.consume(2); }
    ;

PropertyList
    : Property
    | PropertyList ',' Property
	{ stack.push(stack.get(2) + $2 + ' ' + stack.get(1));
	  stack.consume(2); }
    ;

PrimaryExpr
    : PrimaryExprNoBrace
    | OPENBRACE CLOSEBRACE
	{ stack.push($1 + $2); }
    | OPENBRACE PropertyList CLOSEBRACE
	{ stack.push($1 + stack.pop() + $3); }
    | OPENBRACE PropertyList ',' CLOSEBRACE
	{ stack.push($1 + stack.pop() + $4); }
    ;

PrimaryExprNoBrace
    : THISTOKEN
	{ stack.push($1); }
    | Literal
    | ArrayLiteral
    | IDENT
	{ stack.push($1); }
    | '(' Expr ')'
	{ stack.push($1 + stack.pop() + $3); }
    ;

ArrayLiteral
    : '[' ElisionOpt ']'
	{ stack.push($1 + stack.pop() + $3); }
    | '[' ElementList ']'
	{ stack.push($1 + stack.pop() + $3); }
    | '[' ElementList ',' ElisionOpt ']'
	{ stack.push($1 + stack.get(2) + $3 + ' ' + stack.get(1));
	  stack.consume(2); }
    ;

ElementList
    : ElisionOpt AssignmentExpr
	{ stack.push(stack.get(2) + ' ' + stack.get(1));
	  stack.consume(2); }
    | ElementList ',' ElisionOpt AssignmentExpr
	{ stack.push(stack.get(3) + ', ' + stack.get(2) + ' ' + stack.get(1));
	  stack.consume(3); }
    ;

ElisionOpt
    :
	{ stack.push(""); }
    | Elision
    ;

Elision
    : ','
	{ stack.push($1); }
    | Elision ','
	{ stack.push(stack.pop() + $2); }
    ;

MemberExpr
    : PrimaryExpr
    | FunctionExpr
    | MemberExpr '[' Expr ']'
	{ stack.push(stack.get(2) + $2 + stack.get(1) + $4);
	  stack.consume(2); }
    | MemberExpr '.' IDENT
	{ stack.push(stack.pop() + $2 + $3); }
    | NEW MemberExpr Arguments
	{ stack.push($1 + ' ' + stack.get(2) + stack.get(1));
	  stack.consume(2); }
    ;

MemberExprNoBF
    : PrimaryExprNoBrace
    | MemberExprNoBF '[' Expr ']'
	{ stack.push(stack.get(2) + $2 + stack.get(1) + $4);
	  stack.consume(2); }
    | MemberExprNoBF '.' IDENT
	{ stack.push(stack.pop() + $2 + $3); }
    | NEW MemberExpr Arguments
	{ stack.push($1 + ' ' + stack.get(2) + stack.get(1));
	  stack.consume(2); }
    ;

NewExpr
    : MemberExpr
    | NEW NewExpr
	{ stack.push($1 + " " + stack.pop()); }
    ;

NewExprNoBF
    : MemberExprNoBF
    | NEW NewExpr
	{ stack.push($1 + " " + stack.pop()); }
    ;

CallExpr
    : MemberExpr Arguments
	{ stack.push('__nop(__loopstart(), ' + stack.get(2) + stack.get(1) + ', __loopend())');
	  stack.consume(2); }
    | CallExpr Arguments
	{ stack.push('__nop(__loopstart(), ' + stack.get(2) + stack.get(1) + ', __loopend())');
	  stack.consume(2); }
    | CallExpr '[' Expr ']'
	{ stack.push(stack.get(2) + $2 + stack.get(1) + $4);
	  stack.consume(2); }
    | CallExpr '.' IDENT
	{ stack.push(stack.pop() + $2 + $3); }
    ;

CallExprNoBF
    : MemberExprNoBF Arguments
	{ stack.push('__nop(__loopstart(), ' + stack.get(2) + stack.get(1) + ', __loopend())');
	  stack.consume(2); }
    | CallExprNoBF Arguments
	{ stack.push('__nop(__loopstart(), ' + stack.get(2) + stack.get(1) + ', __loopend())');
	  stack.consume(2); }
    | CallExprNoBF '[' Expr ']'
	{ stack.push(stack.get(2) + $2 + stack.get(1) + $4);
	  stack.consume(2); }
    | CallExprNoBF '.' IDENT
	{ stack.push(stack.pop() + $2 + $3); }
    ;

Arguments
    : '(' ')'
	{ stack.push($1 + $2); }
    | '(' ArgumentList ')'
	{ stack.push($1 + stack.pop() + $3); }
    ;

ArgumentList
    : AssignmentExpr
    | ArgumentList ',' AssignmentExpr
	{ stack.push(stack.get(2) + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

LeftHandSideExpr
    : NewExpr
    | CallExpr
    ;

LeftHandSideExprNoBF
    : NewExprNoBF
    | CallExprNoBF
    ;

PostfixExpr
    : LeftHandSideExpr
    | LeftHandSideExpr PLUSPLUS
	{ stack.push('__postchange(\'' + stack.get(1) + '\', ' + stack.pop() + $2 + ', 1, ' + yylineno + ')'); }
    | LeftHandSideExpr MINUSMINUS
	{ stack.push('__postchange(\'' + stack.get(1) + '\', ' + stack.pop() + $2 + ', -1, ' + yylineno + ')'); }
    ;

PostfixExprNoBF
    : LeftHandSideExprNoBF
    | LeftHandSideExprNoBF PLUSPLUS
	{ stack.push('__postchange(\'' + stack.get(1) + '\', ' + stack.pop() + $2 + ', 1, ' + yylineno + ')'); }
    | LeftHandSideExprNoBF MINUSMINUS
	{ stack.push('__postchange(\'' + stack.get(1) + '\', ' + stack.pop() + $2 + ', -1, ' + yylineno + ')'); }
    ;

UnaryExprCommon
    : DELETETOKEN UnaryExpr
	{ stack.push($1 + stack.pop()); }
    | VOIDTOKEN UnaryExpr
	{ stack.push($1 + stack.pop()); }
    | TYPEOF UnaryExpr
	{ stack.push($1 + stack.pop()); }
    | PLUSPLUS UnaryExpr
	{ stack.push('__change(\'' + stack.get(1) + '\', ' + $1 + stack.pop() + ', ' + yylineno + ')'); }
    | AUTOPLUSPLUS UnaryExpr
	{ stack.push('__change(\'' + stack.get(1) + '\', ' + $1 + stack.pop() + ', ' + yylineno + ')'); }
    | MINUSMINUS UnaryExpr
	{ stack.push('__change(\'' + stack.get(1) + '\', ' + $1 + stack.pop() + ', ' + yylineno + ')'); }
    | AUTOMINUSMINUS UnaryExpr
	{ stack.push('__change(\'' + stack.get(1) + '\', ' + $1 + stack.pop() + ', ' + yylineno + ')'); }
    | '+' UnaryExpr
	{ stack.push($1 + stack.pop()); }
    | '-' UnaryExpr
	{ stack.push($1 + stack.pop()); }
    | '~' UnaryExpr
	{ stack.push($1 + stack.pop()); }
    | '!' UnaryExpr
	{ stack.push($1 + stack.pop()); }
    ;

UnaryExpr
    : PostfixExpr
    | UnaryExprCommon
    ;

UnaryExprNoBF
    : PostfixExprNoBF
    | UnaryExprCommon
    ;

MultiplicativeExpr
    : UnaryExpr
    | MultiplicativeExpr '*' UnaryExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | MultiplicativeExpr '/' UnaryExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | MultiplicativeExpr '%' UnaryExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

MultiplicativeExprNoBF
    : UnaryExprNoBF
    | MultiplicativeExprNoBF '*' UnaryExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | MultiplicativeExprNoBF '/' UnaryExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | MultiplicativeExprNoBF '%' UnaryExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

AdditiveExpr
    : MultiplicativeExpr
    | AdditiveExpr '+' MultiplicativeExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | AdditiveExpr '-' MultiplicativeExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

AdditiveExprNoBF
    : MultiplicativeExprNoBF
    | AdditiveExprNoBF '+' MultiplicativeExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | AdditiveExprNoBF '-' MultiplicativeExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

ShiftExpr
    : AdditiveExpr
    | ShiftExpr LSHIFT AdditiveExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | ShiftExpr RSHIFT AdditiveExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | ShiftExpr URSHIFT AdditiveExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

ShiftExprNoBF
    : AdditiveExprNoBF
    | ShiftExprNoBF LSHIFT AdditiveExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | ShiftExprNoBF RSHIFT AdditiveExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | ShiftExprNoBF URSHIFT AdditiveExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

RelationalExpr
    : ShiftExpr
    | RelationalExpr '<' ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExpr '>' ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExpr LE ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExpr GE ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExpr INSTANCEOF ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExpr INTOKEN ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

RelationalExprNoIn
    : ShiftExpr
    | RelationalExprNoIn '<' ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExprNoIn '>' ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExprNoIn LE ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExprNoIn GE ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExprNoIn INSTANCEOF ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

RelationalExprNoBF
    : ShiftExprNoBF
    | RelationalExprNoBF '<' ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExprNoBF '>' ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExprNoBF LE ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExprNoBF GE ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExprNoBF INSTANCEOF ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | RelationalExprNoBF INTOKEN ShiftExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

EqualityExpr
    : RelationalExpr
    | EqualityExpr EQEQ RelationalExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | EqualityExpr NE RelationalExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | EqualityExpr STREQ RelationalExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | EqualityExpr STRNEQ RelationalExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

EqualityExprNoIn
    : RelationalExprNoIn
    | EqualityExprNoIn EQEQ RelationalExprNoIn
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | EqualityExprNoIn NE RelationalExprNoIn
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | EqualityExprNoIn STREQ RelationalExprNoIn
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | EqualityExprNoIn STRNEQ RelationalExprNoIn
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

EqualityExprNoBF
    : RelationalExprNoBF
    | EqualityExprNoBF EQEQ RelationalExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | EqualityExprNoBF NE RelationalExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | EqualityExprNoBF STREQ RelationalExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    | EqualityExprNoBF STRNEQ RelationalExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

BitwiseANDExpr
    : EqualityExpr
    | BitwiseANDExpr '&' EqualityExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

BitwiseANDExprNoIn
    : EqualityExprNoIn
    | BitwiseANDExprNoIn '&' EqualityExprNoIn
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

BitwiseANDExprNoBF
    : EqualityExprNoBF
    | BitwiseANDExprNoBF '&' EqualityExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

BitwiseXORExpr
    : BitwiseANDExpr
    | BitwiseXORExpr '^' BitwiseANDExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

BitwiseXORExprNoIn
    : BitwiseANDExprNoIn
    | BitwiseXORExprNoIn '^' BitwiseANDExprNoIn
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

BitwiseXORExprNoBF
    : BitwiseANDExprNoBF
    | BitwiseXORExprNoBF '^' BitwiseANDExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

BitwiseORExpr
    : BitwiseXORExpr
    | BitwiseORExpr '|' BitwiseXORExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

BitwiseORExprNoIn
    : BitwiseXORExprNoIn
    | BitwiseORExprNoIn '|' BitwiseXORExprNoIn
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

BitwiseORExprNoBF
    : BitwiseXORExprNoBF
    | BitwiseORExprNoBF '|' BitwiseXORExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

LogicalANDExpr
    : BitwiseORExpr
    | LogicalANDExpr AND BitwiseORExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

LogicalANDExprNoIn
    : BitwiseORExprNoIn
    | LogicalANDExprNoIn AND BitwiseORExprNoIn
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

LogicalANDExprNoBF
    : BitwiseORExprNoBF
    | LogicalANDExprNoBF AND BitwiseORExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

LogicalORExpr
    : LogicalANDExpr
    | LogicalORExpr OR LogicalANDExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

LogicalORExprNoIn
    : LogicalANDExprNoIn
    | LogicalORExprNoIn OR LogicalANDExprNoIn
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

LogicalORExprNoBF
    : LogicalANDExprNoBF
    | LogicalORExprNoBF OR LogicalANDExpr
	{ stack.push(stack.get(2) + " " + $2 + " " + stack.get(1));
	  stack.consume(2); }
    ;

ConditionalExpr
    : LogicalORExpr
    | LogicalORExpr '?' AssignmentExpr ':' AssignmentExpr
	{ stack.push(stack.get(3) + " " + $2 + " " + stack.get(2) + " " + $4 + ' ' + stack.get(1));
	  stack.consume(3); }
    ;

ConditionalExprNoIn
    : LogicalORExprNoIn
    | LogicalORExprNoIn '?' AssignmentExprNoIn ':' AssignmentExprNoIn
	{ stack.push(stack.get(3) + " " + $2 + " " + stack.get(2) + " " + $4 + ' ' + stack.get(1));
	  stack.consume(3); }
    ;

ConditionalExprNoBF
    : LogicalORExprNoBF
    | LogicalORExprNoBF '?' AssignmentExpr ':' AssignmentExpr
	{ stack.push(stack.get(3) + " " + $2 + " " + stack.get(2) + " " + $4 + ' ' + stack.get(1));
	  stack.consume(3); }
    ;

AssignmentExpr
    : ConditionalExpr
    | LeftHandSideExpr AssignmentOperator AssignmentExpr
	{ stack.push("__change('" + stack.get(3) + "', " + stack.get(3) + ' ' + stack.get(2) + ' ' + stack.get(1) + ", " + yylineno + ")");
	  stack.consume(3); }
    ;

AssignmentExprNoIn
    : ConditionalExprNoIn
    | LeftHandSideExpr AssignmentOperator AssignmentExprNoIn
	{ stack.push("__change('" + stack.get(3) + "', " + stack.get(3) + ' ' + stack.get(2) + ' ' + stack.get(1) + ", " + yylineno + ")");
	  stack.consume(3); }
    ;

AssignmentExprNoBF
    : ConditionalExprNoBF
    | LeftHandSideExprNoBF AssignmentOperator AssignmentExpr
	{ stack.push("__change('" + stack.get(3) + "', " + stack.get(3) + ' ' + stack.get(2) + ' ' + stack.get(1) + ", " + yylineno + ")");
	  stack.consume(3); }
    ;

AssignmentOperator
    : '=' { stack.push($1); }
    | PLUSEQUAL { stack.push($1); }
    | MINUSEQUAL { stack.push($1); }
    | MULTEQUAL { stack.push($1); }
    | DIVEQUAL { stack.push($1); }
    | LSHIFTEQUAL { stack.push($1); }
    | RSHIFTEQUAL { stack.push($1); }
    | URSHIFTEQUAL { stack.push($1); }
    | ANDEQUAL { stack.push($1); }
    | XOREQUAL { stack.push($1); }
    | OREQUAL { stack.push($1); }
    | MODEQUAL { stack.push($1); }
    ;

Expr
    : AssignmentExpr
    | Expr ',' AssignmentExpr
	{ stack.push(stack.get(2) + ' ' + $2 + ' ' + stack.get(1));
	  stack.consume(2); }
    ;

ExprNoIn
    : AssignmentExprNoIn
    | ExprNoIn ',' AssignmentExprNoIn
	{ stack.push(stack.get(2) + ' ' + $2 + ' ' + stack.get(1));
	  stack.consume(2); }
    ;

ExprNoBF
    : AssignmentExprNoBF
    | ExprNoBF ',' AssignmentExpr
	{ stack.push(stack.get(2) + ' ' + $2 + ' ' + stack.get(1));
	  stack.consume(2); }
    ;

Statement
    : Block
    | VariableStatement
    | ConstStatement
    | FunctionDeclaration
    | EmptyStatement
    | ExprStatement
    | IfStatement
    | IterationStatement
    | ContinueStatement
    | BreakStatement
    | ReturnStatement
    | WithStatement
    | SwitchStatement
    | LabelledStatement
    | ThrowStatement
    | TryStatement
    | DebuggerStatement
    ;

Block
    : OPENBRACE CLOSEBRACE
	{ stack.push($1 + $2); }
    | OPENBRACE SourceElements CLOSEBRACE
	{ stack.push($1 + stack.pop() + $3); }
    ;

VariableStatement
    : VAR VariableDeclarationList ';'
	{ stack.push($1 + ' ' + stack.pop() + $3); }
    | VAR VariableDeclarationList error
    ;

VariableDeclarationList
    : IDENT
	{ stack.push($1); }
    | IDENT Initializer
	{ stack.push($1 + ' = ' + '__change(\'' + $1 + '\', ' + stack.pop() + ', ' + yylineno + ')'); }
    | VariableDeclarationList ',' IDENT
	{ stack.push(stack.pop() + $2 + ' ' + $3); }
    | VariableDeclarationList ',' IDENT Initializer
	{ stack.push(stack.get(2) + $2 + ' ' + $3 + ' = ' + '__change(\'' + $3 + '\', ' + stack.get(1) + ', ' + yylineno + ')');
	  stack.consume(2); }
    ;

VariableDeclarationListNoIn
    : IDENT
	{ stack.push($1); }
    | IDENT InitializerNoIn
	{ stack.push($1 + ' = ' + '__change(\'' + $1 + '\', ' + stack.pop() + ', ' + yylineno + ')'); }
    | VariableDeclarationListNoIn ',' IDENT
	{ stack.push(stack.pop() + $2 + ' ' + $3); }
    | VariableDeclarationListNoIn ',' IDENT InitializerNoIn
	{ stack.push(stack.get(2) + $2 + ' ' + $3 + ' = ' + '__change(\'' + $3 + '\', ' + stack.get(1) + ", ' + yylineno + ')");
	  stack.consume(2); }
    ;

ConstStatement
    : CONSTTOKEN ConstDeclarationList ';'
	{ stack.push($1 + ' ' + stack.pop() + $2); }
    | CONSTTOKEN ConstDeclarationList error
    ;

ConstDeclarationList
    : ConstDeclaration
    | ConstDeclarationList ',' ConstDeclaration
	{ stack.push(stack.get(2) + ' ' + $2 + ' ' + stack.get(1));
	  stack.consume(2); }
    ;

ConstDeclaration
    : IDENT
	{ stack.push($1); }
    | IDENT Initializer
	{ stack.push($1 + ' = ' + '__change(\'' + $1 + '\', ' + stack.pop() + ', ' + yylineno + ')'); }
    ;

Initializer
    : '=' AssignmentExpr /* omit the = */
    ;

InitializerNoIn
    : '=' AssignmentExprNoIn /* omit the = */
    ;

EmptyStatement
    : ';' { stack.push($1); }
    ;

ExprStatement
    : ExprNoBF ';'
	{ stack.push(stack.pop() + $2); }
    | ExprNoBF error
    ;

IfStatement
    : IF '(' Expr ')' Statement %prec IF_WITHOUT_ELSE
	{ stack.push($1 + ' ' + $2 + stack.get(2) + $4 + stack.get(1));
	  stack.consume(2); }
    | IF '(' Expr ')' Statement ELSE Statement
	{ stack.push($1 + ' ' + $2 + stack.get(3) + $4 + ' ' + stack.get(2) + ' ' + $6 + ' ' + stack.get(1));
	  stack.consume(3); }
    ;
IterationStatement
    : DO Statement WHILE '(' Expr ')' ';'
	{ stack.push('__loopstart(); ' + $1 + ' ' + ' {__loop(); ' + stack.get(2) + '} ' + $3 + ' ' + $4 + stack.get(1) + $6 + ' __loopend();');
	  stack.consume(2); }
    | DO Statement WHILE '(' Expr ')' error
    | WHILE '(' Expr ')' Statement
	{ stack.push('__loopstart(); ' + $1 + ' ' + $2 + '__loop() && (' + stack.get(2) + ')' + $4 + stack.get(1) + ' __loopend();');
	  stack.consume(2); }
    | FOR '(' ExprNoInOpt ';' ExprOpt ';' ExprOpt ')' Statement
	{ stack.push('__loopstart(); __loop(); ' + $1 + " " + $2 + stack.get(4) + $4 + ' ' + stack.get(3) + $6 + " (function() { __loop();  " + stack.get(2) + '})()' + $8 + ' {__loop(); ' + stack.get(1) + '}');
	  stack.consume(4); }
    | FOR '(' VAR VariableDeclarationListNoIn ';' ExprOpt ';' ExprOpt ')' Statement
	{ stack.push('__loopstart(); __loop(); ' + $1 + ' ' + $2 + $3 + ' ' + stack.get(4) + $5 + ' ' + stack.get(3) + $7 + ' (function() { __loop(); ' + stack.get(2) + '})() ' + $9 + ' ' + stack.get(1) + ' __loopend();');
	  stack.consume(4); }
    | FOR '(' LeftHandSideExpr INTOKEN Expr ')' Statement
	{ stack.push('__loopstart(); ' + $1 + ' ' + $2 + ' ' + stack.get(3) + ' ' + $4 + ' ' + stack.get(2) + $6 + ' {__loop(); __change(\'' + stack.get(3) + '\', ' + stack.get(3) + ', ' + loopStack.pop() + '); ' + stack.get(1) + '} __loopend();');
	  stack.consume(3); }
    | FOR '(' VAR IDENT INTOKEN Expr ')' Statement
	{ stack.push('__loopstart(); ' + $1 + ' ' + $2 + $3 + ' ' + $4 + ' ' + $5 + ' ' + stack.get(2) + $7 + ' {__loop(); __change(\'' + $4 + '\', ' + $4 + ', ' + loopStack.pop() + '); '+ stack.get(1) + '} __loopend();');
	  stack.consume(2); }
    | FOR '(' VAR IDENT InitializerNoIn INTOKEN Expr ')' Statement
	{ stack.push('__loopstart(); ' + $1 + ' ' + $2 + $3 + ' ' + $4 + ' = ' + '__change(\'' + $4 + '\', ' + stack.get(3) + ', ' + loopStack.get(1) + ') ' + $6 + ' ' + stack.get(2) + $8 + ' {__loop(); __change(\'' + $4 + '\', ' + $4 + ', ' + loopStack.get(1) + ');' + stack.get(1) + '} __loopend();');
	  stack.consume(3);
	  loopStack.consume(1); }
    ;

ExprOpt
    : { stack.push(""); }
    | Expr
    ;

ExprNoInOpt
    : { stack.push(""); }
    | ExprNoIn
    ;

ContinueStatement
    : CONTINUE ';'
	{ stack.push($1 + $2); }
    | CONTINUE error
    | CONTINUE IDENT ';'
	{ stack.push($1 + $2 + $3); }
    | CONTINUE IDENT error
    ;

BreakStatement
    : BREAK ';'
	{ stack.push($1 + $2); }
    | BREAK error
    | BREAK IDENT ';'
	{ stack.push($1 + ' ' + $2 + $3); }
    | BREAK IDENT error
    ;

ReturnStatement
    : RETURN ';'
	{ stack.push($1 + $2); }
    | RETURN error
    | RETURN Expr ';'
	{ stack.push($1 + ' ' + stack.pop() + $3); }
    | RETURN Expr error
    ;

WithStatement
    : WITH '(' Expr ')' Statement
	{ stack.push($1 + ' ' + $2 + stack.get(2) + $4 + ' ' + stack.get(1));
	  stack.consume(2); }
    ;

SwitchStatement
    : SWITCH '(' Expr ')' CaseBlock
	{ stack.push($1 + ' ' + $2 + stack.get(2) + $4 + ' ' + stack.get(1));
	  stack.consume(2); }
    ;

CaseBlock
    : OPENBRACE CaseClausesOpt CLOSEBRACE
	{ stack.push($1 + ' ' + stack.pop() + ' ' + $3); }
    | OPENBRACE CaseClausesOpt DefaultClause CaseClausesOpt CLOSEBRACE
	{ stack.push($1 + ' ' + stack.get(3) + ' ' + stack.get(2) + ' ' + stack.get(1) + ' ' + $5);
	  stack.consume(3); }
    ;

CaseClausesOpt
    : { stack.push(""); }
    | CaseClauses
    ;

CaseClauses
    : CaseClause
    | CaseClauses CaseClause
	{ stack.push(stack.get(2) + ' ' + stack.get(1)); stack.consume(2); }
    ;

CaseClause
    : CASE Expr ':'
	{ stack.push($1 + $2); }
    | CASE Expr ':' SourceElements
	{ stack.push($1 + $2 + ' ' + stack.pop()); }
    ;

DefaultClause
    : DEFAULT ':'
	{ stack.push($1 + $2); }
    | DEFAULT ':' SourceElements
	{ stack.push($1 + $2 + ' ' + stack.pop()); }
    ;

LabelledStatement
    : IDENT ':' Statement
	{ stack.push($1 + $2 + ' ' + stack.pop()); }
    ;

ThrowStatement
    : THROW Expr ';'
	{ stack.push($1 + ' ' + stack.pop() + $3); }
    | THROW Expr error
    ;

TryStatement
    : TRY Block FINALLY Block
	{ stack.push($1 + ' ' + stack.get(2) + ' ' + $3 + ' ' + stack.get(1));
	  stack.consume(2); }
    | TRY Block CATCH '(' IDENT ')' Block
	{ stack.push($1 + ' ' + stack.get(2) + ' ' + $3 + ' ' + $4 + $5 + $6 + stack.get(1));
	  stack.consume(2); }
    | TRY Block CATCH '(' IDENT ')' Block FINALLY Block
	{ stack.push($1 + ' ' + stack.get(3) + ' ' + $3 + ' ' + $4 + $5 + $6 + ' ' + stack.get(2) + ' ' + $8 + ' ' + stack.get(1));
	  stack.consume(3); }
    ;

DebuggerStatement
    : DEBUGGER ';'
	{ stack.push($1 + $2); }
    | DEBUGGER error
    ;

FunctionDeclaration
    : FUNCTION IDENT '(' ')' OPENBRACE FunctionBody CLOSEBRACE
	{ stack.push($1 + ' ' + $2 + $3 + $4 + ' ' + $5 + '__loop(); ' + stack.pop() + ' ' + $7);
	  loopStack.pop(); }
    | FUNCTION IDENT '(' FormalParameterList ')' OPENBRACE FunctionBody CLOSEBRACE
	{ stack.push($1 + ' ' + $2 + $3 + stack.get(2) + $5 + ' ' + $6 + '__loop(); ' + stack.get(2).split(',').map(function (f) {
		return '__change(\'' + f + '\', ' + f + ', ' + loopStack.get(1) + ');';
	  }).join(' ') + ' ' + stack.get(1) + ' ' + $8);
	  stack.consume(2);
	  loopStack.pop(); }
    ;

FunctionExpr
    : FUNCTION '(' ')' OPENBRACE FunctionBody CLOSEBRACE
	{ stack.push($1 + $2 + $3 + ' ' + $4 + ' __loop(); ' + stack.pop() + ' ' + $6);
	  loopStack.pop(); }
    | FUNCTION '(' FormalParameterList ')' OPENBRACE FunctionBody CLOSEBRACE
	{ stack.push($1 +  $2 + stack.get(2) + $4 + ' ' + $5 + '__loop(); ' + stack.get(2).split(',').map(function (f) {
		return '__change(\'' + f + '\', ' + f + ', ' + loopStack.get(1) + ');';
	  }).join(' ') + ' ' + stack.get(1) + ' ' + $7);
	  stack.consume(2);
	  loopStack.pop(); }
    | FUNCTION IDENT '(' ')' OPENBRACE FunctionBody CLOSEBRACE
	{ stack.push($1 + ' ' + $2 + $3 + $4 + ' ' + $5 + '__loop(); ' + stack.pop() + ' ' + $7);
	  loopStack.pop(); }
    | FUNCTION IDENT '(' FormalParameterList ')' OPENBRACE FunctionBody CLOSEBRACE
	{ stack.push($1 + ' ' + $2 + $3 + stack.get(2) + $5 + ' ' + $6 + '__loop(); ' + stack.get(2).split(',').map(function (f) {
		return '__change(\'' + f + '\', ' + f + ', ' + loopStack.get(1) + ');';
	  }).join(' ') + ' ' + stack.get(1) + ' ' + $8);
	  stack.consume(2);
	  loopStack.pop(); }
    ;

FormalParameterList
    : IDENT
	{ stack.push($1); }
    | FormalParameterList ',' IDENT
	{ stack.push(stack.pop() + $2 + ' ' + $3); }
    ;

FunctionBody
    : { stack.push(""); } 
    | SourceElements
    ;

Program
    : { return ""; } 
    | SourceElements
	{ return stack.pop(); }
    ;

SourceElements
    : Statement
    | SourceElements Statement
	{ stack.push(stack.get(2) + "\n" + stack.get(1)); stack.consume(2); }
    ;
