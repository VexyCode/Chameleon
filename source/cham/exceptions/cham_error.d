module cham.exceptions.cham_error;

// Import AST base node to get line/col from token
import cham.parsing.nodes.ast_node : Node;
import cham.lexing.token.token : Token;

/// Custom exception type for ChamLang errors.
/// Contains token position and the actual source line where the error happened.
class ChamError : Exception {
    int line;           // Line number of the error
    int column;         // Column (char index) of the error
    string sourceLine;  // Full source code line for context

    /// Constructor: builds the exception with extra source info
    this(string msg, int line, int column, string sourceLine) {
        super(msg);  // Store the error message in the base Exception class
        this.line = line;
        this.column = column;
        this.sourceLine = sourceLine;
    }
}

void throwChamError(string msg, Node node = null, string[] sourceLines = null) {
    int line = 0;
    int col = 0;
    string srcLine = "<line unavailable>";

    if (node !is null) {
        line = node.token.line;
        col = node.token.col;
        if (sourceLines !is null && line >= 1 && line <= sourceLines.length) {
            srcLine = sourceLines[line - 1];
        }
    }
    
    throw new ChamError(msg, line, col, srcLine);
}


/// Throws a `ChamError` using info from a Token and full source lines.
void throwChamError(string msg, Token token, string[] srcLines) {
    auto line = token.line; // 1-based line nr
    auto col = token.col;   // 0 based column nr

    string srcLine = (line >= 1 && line <= srcLines.length) 
        ? srcLines[line-1]
        : "<line unavailable>"; // Fallback

    throw new ChamError(msg, line, col, srcLine);
}

