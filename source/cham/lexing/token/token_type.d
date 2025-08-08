module lexing.token.token_type;

/// Token Types (TT)
/// Represents the different categories of tokens that the lexer can produce.
enum TT {
    String,     // String literal (e.g. "Hello, World!")
    Bool,       // Boolean literal (e.g. true, no)
    Int,        // Integer literal (e.g. 42, -7)
    Float,      // Floating-point literal (e.g. 3.14, -0.001)
    Op,         // Operator (e.g. +, -, *, /, ==)
    Id,         // Identifier (e.g. variable or function names like foo, bar)
    LParan,     // Left parenthesis '('
    RParan,     // Right parenthesis ')'
    Comma,      // Commas ','
    Keyword,    // Language keyword (e.g. var, if, while, return)
    TypeName,   // Type name (e.g. int, float, string) — might be parsed separately from Ids
    Unk,        // Unknown token — when the lexer can't categorize input
    Eof         // End of file — signals the lexer reached the end of input
}
