module cham.lexing.token.token;

import std.format : format;
import lexing.token.token_type;

/// Represents a single token emitted by the lexer.
/// Stores its type, position, and the original source text (lexeme).
struct Token {
    int line, col;     // Line and column where the token appears (for error reporting)
    string lexeme;     // The actual slice of source code (e.g. "42", "+", "foo")
    TT type;           // Token type (from the TT enum)

    /// Returns a formatted string version of the token, useful for debugging.
    /// Example: [IntLiteral: 42] (3 : 5)
    string toString() const {
        return format("[%s: %s] (%s : %s)", type, lexeme, line, col);
    }

    /// A static "end of file" token used to signal the end of input.
    static Token EOF = Token(0, 0, "EOF", TT.Eof);
}
