/**
Copyright: Copyright (c) 2017 Andrey Penechko.
License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Andrey Penechko.
*/
import lex;
import ast;

import std.stdio;

/*  <module> ::= <declaration>*
 *  <declaration> ::= <func_declaration>
 *  <func_decl> ::= "func" <id> "(" ")" <block_statement>
 *  <block_statement> ::= "{" <statement>* "}"
 *  <statement> ::= "if" <paren_expr> <statement> /
 *                  "if" <paren_expr> <statement> "else" <statement> /
 *                  "while" <paren_expr> <statement> /
 *                  "do" <statement> "while" <paren_expr> ";" /
 *                  "return" <expr>? ";" /
 *                  <block_statement> /
 *                  <expr> ";" /
 *                  ";"
 *  <paren_expr> ::= "(" <expr> ")"
 *  <expr> ::= <test> | <id> "=" <expr>
 *  <test> ::= <sum> | <sum> ("=="|"!="|"<"|">"|"<="|"<=") <sum>
 *  <sum> ::= <term> | <sum> "+" <term> | <sum> "-" <term>
 *  <term> ::= <id> | <int> | <paren_expr>
 *  <id> ::= "a" | "b" | "c" | "d" | ... | "z"
 *  <int> ::= <an_unsigned_decimal_integer>
 */

string input = q{
	func main(){ return 1; return 2+a; return (result < 3); }
	func sub1(){ return 42; a=b=c; }
	func sub2(){ if (a<b) c=10; }
	func sub3(){ if (a<b) c=10; else c=20; }
	func sub4(){ while(i<100){a=a+i;i=i+1;} }
	func sub5(){ do{a=a+i;i=i+1;}while(i<100); }
};

void main()
{
	IdentifierMap idMap;
	auto stream = CharStream!string(input);
	StringLexer lexer = StringLexer(stream);

	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!'{', TokenType.LCURLY);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!'}', TokenType.RCURLY);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!'(', TokenType.LPAREN);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!')', TokenType.RPAREN);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!'+', TokenType.PLUS);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!'-', TokenType.MINUS);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!'<', TokenType.LT);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!';', TokenType.SEMICOLON);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!'=', TokenType.ASSIGN);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchSymbol!',', TokenType.COMMA);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchId!"func", TokenType.FUNC_SYM);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchId!"return", TokenType.RET_SYM);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchId!"while", TokenType.WHILE_SYM);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchId!"if", TokenType.IF_SYM);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchId!"else", TokenType.ELSE_SYM);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchId!"do", TokenType.DO_SYM);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchIdent, TokenType.ID);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchDecimalNumber, TokenType.DECIMAL_NUM);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchHexNumber, TokenType.HEX_NUM);
	lexer.matchers ~= TokenMatcher(&lexer.stream.matchComment, TokenType.COMMENT);

	Parser parser = Parser(&lexer, &idMap);
	try
	{
		auto root = parser.parseModule();
		printAST(root, &idMap);
	}
	catch(ParsingException e)
	{
		writefln("%s: [ERROR] %s", e.token.start.pos, e.msg);
		writeln(e);
	}
}


void printAST(Module n, IdentifierMap* idMap)
{
	import std.range : repeat;
	import std.algorithm : each;
	if (!n) return;

	int indent = -2;

	void pr(AstNode node)
	{
		indent += 2;
		auto i = ' '.repeat(indent);

		// Declarations
		if (auto m = cast(Module)node) { writeln(i, "MODULE"); foreach(f; m.functions) pr(f); }
		else if (auto f = cast(FunctionDeclaration)node) { writeln(i, "FUNC ", idMap.get(f.id)); pr(f.statements); }
		// Statements
		else if (auto b = cast(BlockStatement)node) { writeln(i, "BLOCK"); foreach(s; b.statements) pr(s); }
		else if (auto n = cast(IfStatement)node) { writeln(i, "IF"); pr(n.condition); pr(n.thenStatement); }
		else if (auto n = cast(IfElseStatement)node) { writeln(i, "IF"); pr(n.condition); pr(n.thenStatement); pr(n.elseStatement); }
		else if (auto w = cast(WhileStatement)node) { writeln(i, "WHILE"); pr(w.condition); pr(w.statement); }
		else if (auto w = cast(DoWhileStatement)node) { writeln(i, "DO"); pr(w.statement); writeln(i, "WHILE"); pr(w.condition); }
		else if (auto r = cast(ReturnStatement)node) { writeln(i, "RETURN"); pr(r.expression); }
		else if (auto e = cast(ExpressionStatement)node) { pr(e.expression); }
		// Expressions
		else if (auto v = cast(VariableExpression)node) { writeln(i, "VAR ", idMap.get(v.id)); }
		else if (auto c = cast(ConstExpression)node) { writeln(i, "CONST ", c.value); }
		else if (auto b = cast(BinaryExpression)node) { writeln(i, "BINOP ", b.op); pr(b.left); pr(b.right);}
		indent -= 2;
	}
	pr(n);
}

class ParsingException : Exception
{
	this(Args...)(Token token, string msg, Args args) {
		this.token = token;
		import std.string : format;
		super(format(msg, args));
	}
	Token token;
}

struct Parser
{
	StringLexer* lexer;
	IdentifierMap* idMap;

	Token tok() { return lexer.current; }

	T make(T, Args...)(Args args) { return new T(args); }

	void nextToken() {
		do {
			lexer.next();
		}
		while (tok.type == TokenType.COMMENT);
	}

	void syntax_error(Args...)(Args args) {
		throw new ParsingException(tok, args);
	}

	Token expectAndConsume(TokenType type) {
		if (tok.type != type) {
			syntax_error("Expected %s, while got %s", type, tok.type);
		}
		scope(exit) nextToken();
		return tok;
	}


	Module parseModule() { // <module> ::= <declaration>*
		FunctionDeclaration[] functions;
		expectAndConsume(TokenType.SOI);
		while (tok.type != TokenType.EOI)
		{
			functions ~= func_declaration();
		}
		return make!Module(functions);
	}

	FunctionDeclaration func_declaration() // <declaration> ::= <func_declaration>
	{
		expectAndConsume(TokenType.FUNC_SYM); // <func_decl> ::= "func" <id> "(" ")" <compound_statement>
		Token funcName = expectAndConsume(TokenType.ID);
		string name = lexer.getTokenString(funcName);
		auto id = idMap.get(name);
		expectAndConsume(TokenType.LPAREN);
		expectAndConsume(TokenType.RPAREN);
		auto statements = block_stmt();
		return make!FunctionDeclaration(id, statements);
	}

	BlockStatement block_stmt() // <compound_statement> ::= "{" <statement>* "}"
	{
		Statement[] statements;
		expectAndConsume(TokenType.LCURLY);
		while (tok.type != TokenType.RCURLY)
		{
			statements ~= statement();
		}
		expectAndConsume(TokenType.RCURLY);
		return make!BlockStatement(statements);
	}

	Statement statement()
	{
		switch (tok.type)
		{
			case TokenType.IF_SYM: /* "if" <paren_expr> <statement> */
				nextToken();
				Expression condition = paren_expr();
				Statement thenStatement = statement();
				if (tok.type == TokenType.ELSE_SYM) { /* ... "else" <statement> */
					nextToken();
					Statement elseStatement = statement();
					return make!IfElseStatement(condition, thenStatement, elseStatement);
				}
				else return make!IfStatement(condition, thenStatement);
			case TokenType.WHILE_SYM:  /* "while" <paren_expr> <statement> */
				nextToken();
				Expression condition = paren_expr();
				Statement statement = statement();
				return make!WhileStatement(condition, statement);
			case TokenType.DO_SYM:  /* "do" <statement> "while" <paren_expr> ";" */
				nextToken();
				Statement statement = statement();
				expectAndConsume(TokenType.WHILE_SYM);
				Expression condition = paren_expr();
				expectAndConsume(TokenType.SEMICOLON);
				return make!DoWhileStatement(condition, statement);
			case TokenType.RET_SYM:  /* return <expr> */
				nextToken();
				Expression expression = tok.type != TokenType.SEMICOLON ? expr() : null;
				expectAndConsume(TokenType.SEMICOLON);
				return make!ReturnStatement(expression);
			case TokenType.SEMICOLON:  /* ";" */
				nextToken();
				return make!BlockStatement(null); // TODO: make this error
			case TokenType.LCURLY:  /* "{" { <statement> } "}" */
				return block_stmt();
			default:  /* <expr> ";" */
				Expression expression = expr();
				expectAndConsume(TokenType.SEMICOLON);
				return make!ExpressionStatement(expression);
		}
	}

	Expression paren_expr() { /* <paren_expr> ::= "(" <expr> ")" */
		expectAndConsume(TokenType.LPAREN);
		auto res = expr();
		expectAndConsume(TokenType.RPAREN);
		return res;
	}

	Expression expr() { /* <expr> ::= <test> | <id> "=" <expr> */
		Expression t, n;
		if (tok.type != TokenType.ID) return test();
		n = test();
		//if (n.type == NodeT.VAR && tok.type == TokenType.ASSIGN)
		if (tok.type == TokenType.ASSIGN)
		{
			nextToken();
			t = n;
			n = make!BinaryExpression(BinOp.ASSIGN, t, expr());
		}
		return n;
	}

	Expression test() { /* <test> ::= <sum> | <sum> "<" <sum> */
		Expression t, n = sum();
		if (tok.type == TokenType.LT)
		{
			nextToken();
			t = n;
			n = make!BinaryExpression(BinOp.LT, t, sum());
		}
		return n;
	}

	Expression sum() { /* <sum> ::= <term> | <sum> "+" <term> | <sum> "-" <term> */
		Expression n = term();
		Expression t;
		loop: while (true)
		{
			BinOp op;
			switch(tok.type) {
				case TokenType.PLUS : op = BinOp.ADD; break;
				case TokenType.MINUS: op = BinOp.SUB; break;
				default: break loop;
			}
			nextToken();
			t = n;
			n = make!BinaryExpression(op, t, term());
		}
		return n;
	}

	Expression term() { /* <term> ::= <id> | <int> | <paren_expr> */
		if (tok.type == TokenType.ID) {
			string name = lexer.getTokenString(tok);
			Identifier id = idMap.get(name);
			nextToken();
			return make!VariableExpression(id);
		}
		else if (tok.type == TokenType.DECIMAL_NUM) {
			string num = lexer.getTokenString(tok);
			import std.conv : to;
			int value=to!int(num);
			nextToken();
			return make!ConstExpression(value);
		}
		else return paren_expr();
	}
}
