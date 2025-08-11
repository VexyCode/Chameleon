module cham.parsing.parser.parser;

// === Imports ===
// Token & AST building
import cham.lexing.token.token : Token;
import cham.parsing.nodes.ast_node : Node;
import cham.parsing.nodes.literals.float_literal : FloatLiteral;
import cham.parsing.nodes.literals.int_literal : IntLiteral;
import cham.parsing.nodes.operations.bin_op : BinOp;
import cham.parsing.nodes.literals.bool_literal : BoolLiteral;
import cham.parsing.nodes.literals.string_literal : StringLiteral;
import cham.variables_and_consts.typenames : TypeName, fromString;
import cham.parsing.nodes.statements.if_statement : IfStmt;
import cham.parsing.nodes.statements.function_call_statement : FuncCall;
import cham.parsing.nodes.statements.function_def : FuncDef;

// Const / Var declaration & lookup
import cham.parsing.nodes.constants.decl_const : DeclConst;
import cham.parsing.nodes.variables.decl_var: DeclVar;
import cham.variables_and_consts.look_up : LookUp;
import cham.parsing.nodes.variables.reassign_var : ReassignVar;

// Misc utils
import lexing.token.token_type : TT;
import cham.scopes.scopes : Scope, ParamInfo, FunctionInfo;
import cham.exceptions.cham_error : ChamError;
import std.conv : to, ConvException;
import std.format : format;
import std.stdio;
import std.string : splitLines;
import std.typecons : Nullable;

class Parser {
    // === Parser State ===
    Token[] tokens;     // List of all tokens to parse
    int index;          // Current token index
    Token cur;          // Current token
    Node[] nodes;       // Top-level parsed AST nodes
    Scope mainScope;    // Global scope (shared across file)
    string src;         // Original source code (for error messages)

    /// Initializes parser with token list and source string
    this(Token[] tokens, string src) {
        this.tokens = tokens;
        this.index = 0;
        
        if (tokens.length > 0)
            this.cur = tokens[0];
        else
            throwChamError("No tokens provided", cur); // no tokens, big oof

        this.mainScope = new Scope(null, src);
        this.src = src;
    }

    /// Prints all parsed nodes (for debugging purposes)
    public void printNodes() {
        foreach (Node node; nodes) writeln(node);
    }

    /// Parses all top-level expressions until EOF
    public Node[] parse() {
        while (cur.type != TT.Eof) {
            nodes ~= parseExpr();
        }
        return nodes;
    }

    /// Parses a single expression depending on token context
    Node parseExpr() {
        if (cur.type == TT.Eof) {
            throwChamError("Unexpected end of input", cur);
        }

        if (cur.type == TT.Keyword && cur.lexeme == "const") return parseConstDecl();
        else if (cur.type == TT.Keyword && cur.lexeme == "var") return parseVarDecl();
        else if (cur.type == TT.Keyword && cur.lexeme == "if") return parseIfElse();
        else if (cur.type == TT.Id && peek().type == TT.LParan) return parseFuncCall(); 
        else if (cur.type == TT.Keyword && cur.lexeme == "define") return parseFuncDef();
        else if (cur.type == TT.Id && peek().type != TT.TypeName && peek(2).type == TT.Op && peek(2).lexeme == "=")
                    return parseVarReDef();

        // Fallback: arithmetic expression
        else return parseComparison();
    }

    Node parseFuncDef() {
        expect(TT.Keyword, "define");
        advance(); // skip the `define` kw
        expect(TT.Id); 
        string fnName = cur.lexeme;
        advance(); // skip the fn name now that we've contained it
        expect(TT.LParan);
        advance();
        ParamInfo[] params = parseParams();
        string ret = cur.lexeme;
        Nullable!TypeName retType;
        bool returns = true;
        if (ret == "nothing") {
            retType = Nullable!TypeName.init;
            returns = false;
        } else {
            retType = fromString(ret, new IntLiteral(0, cur), mainScope.srcLines);
        }
        advance();

        Node[] body = parseBlock();

        return new FuncDef(fnName, body, params, retType, returns, mainScope, cur);
    }

    ParamInfo[] parseParams() {
        ParamInfo[] params;

        if (cur.type != TT.RParan) {
            do {
                if (params.length != 0) {
                    expect(TT.Comma);
                    advance(); // skip the comma
                }
                expect(TT.TypeName);
                TypeName type = fromString(cur.lexeme, new IntLiteral(0, cur), mainScope.srcLines);
                advance(); // advance past the typename

                expect(TT.Id);
                Token nameToken = cur;
                string name = cur.lexeme;
                advance(); // advance past the name;

                params ~= ParamInfo(name, type, nameToken); 
            } while (cur.type == TT.Comma);
        }

        expect(TT.RParan);
        advance();

        return params;
    }

    Node parseFuncCall() {
        expectAny([TT.Id]);
        string name = cur.lexeme;
        advance(); // skip the name of the function, now that we've contained it
        expect(TT.LParan);
        advance();
        Node[] args = [];

        if (cur.type != TT.RParan) {
            args ~= parseExpr();
            while (cur.type == TT.Comma) {
                advance();
                args ~= parseExpr();
            }
        }

        expect(TT.RParan); advance();
        return new FuncCall(name, args, cur);
    }

    Node parseIfElse() {
        advance(); // skip `if`
        expect(TT.LParan);
        advance(); // skip `(`
        Node cond = parseComparison();
        expect(TT.RParan);
        advance(); // skip `)`

        Node[] ifBody = parseBlock();

        Node[] elseBody = null;
        if (cur.type == TT.Keyword && cur.lexeme == "else") {
            advance(); // skip `else`
            elseBody = parseBlock();
        }

        return new IfStmt(ifBody, elseBody, cond, cur, mainScope);
    }


    /// Parses a block of expressions surrounded by `run` and `end`
    Node[] parseBlock() {
        Node[] body = [];

        expect(TT.Keyword, "run");
        advance(); // skip `run`

        while (!(cur.type == TT.Keyword && cur.lexeme == "end")) {
            if (cur.type == TT.Eof)
                throwChamError("Unexpected EOF while parsing block", cur);

            body ~= parseExpr();
        }

        expect(TT.Keyword, "end");
        advance(); // skip `end`

        return body;
    }


    /// Parses a reassignment of an existing variable (e.g., `x = 5`)
    Node parseVarReDef() {
        // Capture variable name
        string id = cur.lexeme;
        advance();

        advance(); // Skip '=' operator

        // Parse the new value expression
        Node value = parseComparison();
        
        // Create and eval the reassignment node
        ReassignVar reVar = new ReassignVar(id, value, cur);
        return reVar;
    }

    /// Parses a lookup expression (`<id>`)
    Node parseLookUp() {
        string name = cur.lexeme;
        advance(); // skip identifier
        LookUp lookUp = new LookUp(name, cur);
        return lookUp;
    }

    /// Parses a variable declaration: `var <type> <id> = <value>`
    Node parseVarDecl() {
        expect(TT.Keyword, "var");
        advance(); // Skip 'var'

        expect(TT.TypeName);
        TypeName type = fromString(cur.lexeme, new IntLiteral(0, cur), src.splitLines()); 
        advance(); // Skip type

        string name = cur.lexeme;
        advance(); // Skip identifier

        expect(TT.Op, "=");
        advance(); // Skip '='

        Node expr = parseExpr();

        DeclVar var_decl = new DeclVar(expr, name, type, this.mainScope, cur);
        return var_decl;
    }

    /// Parses a const declaration: `const <type> <id> = <value>`
    Node parseConstDecl() {
        expect(TT.Keyword, "const");
        advance(); // Skip 'const'

        expect(TT.TypeName);
        TypeName type = fromString(cur.lexeme, new IntLiteral(0, cur), src.splitLines()); 
        advance(); // Skip type

        string name = cur.lexeme;
        advance(); // Skip identifier

        expect(TT.Op, "=");
        advance(); // Skip '='

        Node expr = parseComparison();

        DeclConst const_decl = new DeclConst(expr, name, type, this.mainScope, cur);
        return const_decl;
    }

    Node parseComparison() {
        Node left = parseAdditive();

        while (cur.type == TT.Op && 
            (cur.lexeme == "<="
            || cur.lexeme == ">=" || cur.lexeme == "!=" || cur.lexeme == "&&" || cur.lexeme == "||"
            || cur.lexeme == "==" || cur.lexeme == ">"  || cur.lexeme == "<"  || cur.lexeme == "!"
            )
        ) {
            string op = cur.lexeme;
            advance();

            Node right = parseAdditive();
            left = new BinOp(op, left, right, cur);
        }
        return left;
    }

    /// Parses additive expressions: `a + b - c`
    Node parseAdditive() {
        Node left = parseMultiplicative();
        while (cur.type == TT.Op && (cur.lexeme == "+" || cur.lexeme == "-")) {
            string op = cur.lexeme;
            advance();

            Node right = parseMultiplicative();
            left = new BinOp(op, left, right, cur);
        }
        return left;
    }

    /// Parses multiplicative expressions: `a * b / c`
    Node parseMultiplicative() {
        Node left = parsePrimary();
        while (cur.type == TT.Op && (cur.lexeme == "*" || cur.lexeme == "/")) {
            string op = cur.lexeme;
            advance();

            Node right = parsePrimary();
            left = new BinOp(op, left, right, cur);
        }
        return left;
    }

    /// Parses literal values, parenthesized expressions, or identifiers
    Node parsePrimary() {
        Node val;

        if (cur.type == TT.Eof)
            throwChamError("Unexpected end of input", cur);

        // Handle grouped expressions like (a + b)
        if (cur.type == TT.LParan) {
            advance();
            Node expr = parseComparison();

            if (cur.type != TT.RParan)
                throwChamError("Expected ')'", cur);
            advance();

            return expr;
        }

        try {
            switch (cur.type) {
                case TT.Int:
                    try {
                        val = new IntLiteral(to!int(cur.lexeme), cur);
                        advance();
                        return val;
                    } catch (ConvException e) {
                        throwChamError("Invalid integer literal: " ~ cur.lexeme, cur);
                    }
                    break;

                case TT.Float:
                    try {
                        val = new FloatLiteral(to!float(cur.lexeme), cur);
                        advance();
                        return val;
                    } catch (ConvException e) {
                        throwChamError("Invalid float literal: " ~ cur.lexeme, cur);
                    }
                    break;

                case TT.Bool:
                    switch (cur.lexeme) {
                        case "yes":
                        case "true":
                            val = new BoolLiteral(true, cur);
                            advance();
                            return val;

                        case "no":
                        case "false":
                            val = new BoolLiteral(false, cur);
                            advance();
                            return val;

                        default:
                            throwChamError("Invalid boolean literal: " ~ cur.lexeme, cur);
                    }
                    break;
                case TT.String:
                    val = new StringLiteral(cur.lexeme, cur);
                    advance();
                    return val;
                case TT.Id:
                    if (peek().type == TT.LParan) {
                        return parseFuncCall();
                    }
                    string name = cur.lexeme;
                    if (peek(-1).type != TT.TypeName && peek().type == TT.Op && peek().lexeme == "=") {
                        return parseVarReDef();
                    }
                    advance();
                    return new LookUp(name, cur);

                default:
                    throwChamError(format("Unknown token type: %s", cur.type), cur);
            }
        } catch (ConvException e) {
            throwChamError(format("Failed to convert literal '%s' to number: %s", cur.lexeme, e.msg), cur);
        }

        advance();
        return val;
    }

    /// Moves to the next token
    void advance() {
        if (index + 1 < tokens.length) {
            index++;
            cur = tokens[index];
        } else {
            cur = Token.EOF;
        }
    }

    /// Checks if the parser has reached the end of token stream
    bool isEnd() {
        return index >= tokens.length;
    }

    /// Asserts that the current token has the expected type
    void expect(TT type) {
        if (cur.type != type)
            throwChamError(format("Expected %s, got %s", type, cur.type), cur);
    }

    /// Asserts that the current token matches both type and value
    void expect(TT type, string value) {
        if (cur.type != type || cur.lexeme != value)
            throwChamError(format(
                "Expected type %s of value %s, got type %s of value %s",
                type, value, cur.type, cur.lexeme
            ), cur);
    }

    /// Asserts that the current token matches one of the types given
    void expectAny(TT[] types) {
        foreach (t; types) {
            if (cur.type == t) return;
        }
        throwChamError(format("Expected one of %s, got %s", types, cur.type), cur);
    }

    /// Retrieves a line of source by line number (for error messages)
    string getSrcLine(int line) {
        auto lines = src.splitLines();
        if (line >= 1 && line <= lines.length)
            return lines[line - 1];
        else
            return "<line unavailable>"; // because Vexor is a dumb ass piece of shit
    }

    /// Throws a nicely formatted ChamError with line/col info
    void throwChamError(string msg, Token token) {
        string lineSrc = getSrcLine(token.line);
        throw new ChamError(msg, token.line, token.col, lineSrc);
    }

    /// Peeks ahead in token stream without consuming
    Token peek(int offset = 1) {
        int peekIndex = index + offset;
        if (peekIndex < 0 || peekIndex >= tokens.length)
            return Token.EOF;
        return tokens[peekIndex];
    }

}
