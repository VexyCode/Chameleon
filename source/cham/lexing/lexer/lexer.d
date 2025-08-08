module cham.lexing.lexer.lexer;

// Token definition
import cham.lexing.token.token;
// Token type enum (TT)
import lexing.token.token_type;

// Character classification helpers (your own utils!)
import cham.lexing.lexer.char_ext : isSmallOp, isOp, isPunct, isKeyword, isTypeName;

// Custom error for lexer crashes
import cham.exceptions.cham_error : ChamError;

import std.string : splitLines;
import std.uni : isWhite, isNumber, isAlpha, isAlphaNum;
import std.algorithm : canFind, all;
import std.conv;
import std.stdio;

/// The Lexer turns a raw input string into a list of Tokens.
/// This is the first phase of most compilers/interpreters.
class Lexer {
public:
    Token[] tokens; // Output: token stream

    /// Constructor: initializes with source input
    this(string s) {
        this.src = s;
        line = 1;
        col = 0;
        index = 0;
        cur = (index < src.length) ? src[index] : '\0';
        tokens = [];
    }

    /// Main lexing loop: repeatedly grab the next token until done
    void lex() {
        tokens = [];
        while (!isEnd())
            tokens ~= nextToken();
        tokens ~= Token(line, col, "EOF_EOF_EOF", TT.Eof); // EOF marker
    }

    /// Returns the tokens (lazily lexes if not already done)
    Token[] giveTokens() {
        if (tokens == [])
            lex();
        return tokens;
    }

    /// Debug printing: show all tokens in order
    void printTokens() {
        writeln("Tokens for input " ~ src);
        if (tokens == [])
            lex();
        foreach (token; tokens)
            writeln(token);
    }

private:
    string src;   // Full source input
    int line, col, index; // Cursor position tracking
    char cur;     // Current character

    /// Reads an int or float literal
    Token readNumber() {
        int start = index;
        int startCol = col;
        bool isFloat = false;

        while (isNumber(cur) || cur == '.') {
            if (cur == '.') {
                if (isFloat)
                    throwLexerError("Multiple decimal points in float", Token(line, col, ".", TT.Unk));
                isFloat = true;
            }
            advance();
        }

        string num = src[start..index];
        return Token(line, startCol, num, isFloat ? TT.Float : TT.Int);
    }

    /// Determines and returns the next token
    Token nextToken() {
        Token ret;
        skipWs(); // ignore spaces/newlines/etc.

        if (isEnd()) return Token(line, col, "", TT.Eof);

        else if (cur.isAlpha())
            ret = readLetters();

        else if (cur == '"') 
            ret = readString();

        else if (cur.isSmallOp())
            ret = readOp();

        else if (cur.isNumber())
            ret = readNumber();

        else if (cur.isPunct())
            ret = readPunct();

        else if (isOp(cur.to!string()))
            ret = Token(line, col, cur.to!string(), TT.Op);

        else ret = Token(line, col, cur.to!string(), TT.Unk); // fallback unknown

        debug writeln("cur: "~ret.toString());
        return ret;
    }

    Token readString() {
        int start = index;
        int startCol = col;

        advance(); // skip the first `"` character 
        while (cur != '"') {
            if (cur == '\n') {
                throwLexerError(
                    "String literal not ended", 
                    Token(
                        line,
                        startCol, 
                        src[start..index], 
                        TT.String
                    )
                );
            }
            advance();
        }
        advance(); // skip the second `"` sign

        string thing = src[start..index];

        return Token(
            line,
            startCol, 
            thing.length >= 2 ? thing[1 .. $ - 1] : "", 
            TT.String
        );
    }

    /// Reads identifiers, type names, or keywords
    Token readLetters() {
        int start = index;
        int startCol = col;

        while (cur.isAlphaNum() || cur == '_')
            advance();

        string thing = src[start..index];

        if (isKeyword(thing)) {
            if (thing == "yes" 
                || thing == "no"
                || thing == "true"
                || thing == "false") {
                    return Token(line, startCol, thing, TT.Bool);
                }
            return Token(line, startCol, thing, TT.Keyword);
        }
        else if (isTypeName(thing))
            return Token(line, startCol, thing, TT.TypeName);
        else
            return Token(line, startCol, thing, TT.Id);
    }

    /// Reads single-character punctuation (right now only parens), because only they are needed
    Token readPunct() {
        int startCol = col;

        switch (cur) {
            case '(':
                advance();
                return Token(line, startCol, "(", TT.LParan);
            case ')':
                advance();
                return Token(line, startCol, ")", TT.RParan);
            case ',':
                advance();
                return Token(line, startCol, ",", TT.Comma);
            default:
                throwLexerError("Unknown punctuation: " ~ cur.to!string,
                                Token(line, col, cur.to!string(), TT.Unk)); assert(0);
        }
    }

    /// Reads operators (supports 1 or 2-char ops like `==`, `!=`)
    Token readOp() {
        int startCol = col;
        char first = cur;
        advance();

        // Lookahead only if not at EOF
        if (!isEnd()) {
            string op = first.to!string ~ cur.to!string;
            if (op.isOp()) {
                advance();
                return Token(line, startCol, op, TT.Op);
            }
        }

        // fallback: single-char op
        return Token(line, startCol, first.to!string, TT.Op);
    }


    /// Skips whitespace characters
    void skipWs() {
        while (isWhite(cur))
            advance();
    }

    /// Moves cursor forward, updates line/col/cur char
    void advance() {
        if (!isEnd()) {
            if (cur == '\n') {
                line++;
                col = 0;
            } else {
                col++;
            }

            index++;
            cur = (index < src.length) ? src[index] : '\0';
        }
    }

    /// Returns true if we've reached the end of input
    bool isEnd() {
        return index >= src.length;
    }

    /// Throws a ChamError with source line context
    void throwLexerError(string msg, Token token) {
        string ln = (token.line >= 1 && token.line <= src.splitLines().length)
            ? src.splitLines()[token.line - 1]
            : "<line unavailable>";
        throw new ChamError(msg, token.line, token.col, ln);
    }
}
