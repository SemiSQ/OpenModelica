header {

}

options {
  language = "Cpp";
}

class modelica_lexer extends Lexer;

options {
  k=2;
  charVocabulary = '\3'..'\377';
  exportVocab = modelica;
  testLiterals = false;
}

tokens {
	ALGORITHM	= "algorithm"	;
	AND			= "and"			;
	ANNOTATION	= "annotation"	;
	ASSERT		= "assert"		;
	BLOCK		= "block"		;
	BOUNDARY	= "boundary"	;
	CLASS		= "class"		;
	CONNECT		= "connect"		;
	CONNECTOR	= "connector"	;
	CONSTANT	= "constant"	;
	DISCRETE	= "discrete"	;
	ELSE		= "else"		;
	ELSEIF		= "elseif"		;
	ELSEWHEN	= "elsewhen"	;
  	END			= "end"			;
	EQUATION	= "equation"	;
	ENCAPSULATED= "encapsulated";
	EXTENDS		= "extends"		;
	EXTERNAL	= "external"	;
	FALSE		= "false"		;
	FINAL		= "final"		;
	FLOW		= "flow"		;
	FOR			= "for"			;
	FUNCTION	= "function"	;
	IF			= "if"			;
	IMPORT		= "import"		;
	IN			= "in"			;
	INNER		= "inner"		;
	INPUT		= "input"		;
	LOOP		= "loop"		;
	MODEL		= "model"		;
	NOT			= "not"			;
	OUTER		= "outer"		;
	OR			= "or"			;
	OUTPUT		= "output"		;
	PACKAGE		= "package"		;
	PARAMETER	= "parameter"	;
	PARTIAL		= "partial"		;
	PROTECTED	= "protected"	;
	PUBLIC		= "public"		;
	RECORD		= "record"		;
	REDECLARE	= "redeclare"	;
	REPLACEABLE	= "replaceable"	;
	RESULTS		= "results"		;
	THEN		= "then"		;
	TERMINATE	= "terminate"	;
	TRUE		= "true"		;
	TYPE		= "type"		;
	UNSIGNED_REAL= "unsigned_real";
	WHEN		= "when"		;
	WHILE		= "while"		;
	WITHIN		= "within" 		;
}


// ---------
// Operators
// ---------

LPAR		: '('	;
RPAR		: ')'	;
LBRACK		: '['	;
RBRACK		: ']'	;
LBRACE		: '{'	;
RBRACE		: '}'	;
EQUALS		: '='	;
ASSIGN		: ":="	;
PLUS		: '+'	;
MINUS		: '-'	;
STAR		: '*'	;
SLASH		: '/'	;
DOT		: '.'	;
COMMA		: ','	;
LESS		: '<'	;
LESSEQ		: "<="	;
GREATER		: '>'	;
GREATEREQ	: ">="	;
EQEQ		: "=="	;
LESSGT		: "<>"	;
COLON		: ':'	;
SEMICOLON	: ';'	;
POWER		: '^'	;




WS :
	(	' '
	|	'\t'
	|	( "\r\n" | '\r' |	'\n' ) { newline(); }
	)
	{ $setType(antlr::Token::SKIP); }
	;

ML_COMMENT :
		"/*"
		(options { generateAmbigWarnings=false; } : ML_COMMENT_CHAR
		| {LA(2)!='/'}? '*')*
		"*/" { $setType(antlr::Token::SKIP); } ;

protected
ML_COMMENT_CHAR :	
		("\r\n" | '\n') { newline(); }	
		| ~('*'|'\n'|'\r')
		;
		
SL_COMMENT :
		"//" (~('\n' | '\r'))* ('\n' | '\r')
		{  $setType(antlr::Token::SKIP);/*newline();*/ }
  	;

IDENT options { testLiterals = true;} :
		NONDIGIT (NONDIGIT | DIGIT)*;

protected
NONDIGIT : 	('_' | 'a'..'z' | 'A'..'Z');

protected 
DIGIT :
	'0'..'9'
	;

protected
EXPONENT :
	('e'|'E') ('+' | '-')? (DIGIT)+
	;


UNSIGNED_INTEGER :
	(( (DIGIT)+ '.' ) => (DIGIT)+ ( '.' (DIGIT)+ ) 
			{ 
				$setType(UNSIGNED_REAL); 
			}
	| 	(DIGIT)+
	)
	(EXPONENT)?
	;

STRING : '"'! (SCHAR | SESCAPE)* '"'!;

		
protected 
SCHAR :	(options { generateAmbigWarnings=false; } : ('\n' | "\r\n"))	{ newline(); }
	| '\t'
	| ~('\n' | '\t' | '\r' | '\\' | '"');

protected
SESCAPE : '\\' ('\\' | '"' | "'" | '?' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v');


protected
ESC :
	'\\'
	(	'"'
	|	'\\'
	)
	;



