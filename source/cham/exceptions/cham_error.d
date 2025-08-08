module cham.exceptions.cham_error;

// Import AST base node to get line/col from token
import cham.parsing.nodes.ast_node : Node;

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

/// Throws a `ChamError` using info from a Node and full source lines.
/// This is your one-stop error raiser with full context attached.
void throwChamError(string msg, Node node, string[] sourceLines) {
    auto line = node.token.line;  // 1-based line number
    auto col = node.token.col;    // 0-based column
    string srcLine = (line >= 1 && line <= sourceLines.length)
        ? sourceLines[line - 1]
        : "<line unavailable>"; // Fallback in case line number is invalid
    
    throw new ChamError(msg, line, col, srcLine);
}
