module cham.parsing.nodes.ast_node;

import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;

/// Base class for all AST (Abstract Syntax Tree) nodes in NexiLang.
/// Every concrete node type (like expressions, statements, declarations) will inherit this.
public abstract class Node {
    /// The token associated with this node — helps track source location for errors, debugging, etc.
    public Token token;

    /// The core method every node must implement:
    /// Evaluates this node within the given scope and returns a result (or null).
    /// This is where the node "does its thing" (interpretation, evaluation).
    public abstract Object eval(Scope _scope);

    /// Constructor to store the token info for the node.
    this(Token token) {
        this.token = token;
    }
    
    /// Basic toString override for debug printing.
    override string toString() const {
        return "[Node]";
    }
}
