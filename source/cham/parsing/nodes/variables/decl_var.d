module cham.parsing.nodes.variables.decl_var;

import cham.parsing.nodes.ast_node : Node;
import cham.variables_and_consts.typenames : TypeName;
import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;
import std.format;

/// Represents a variable declaration node in the AST
class DeclVar : Node {
    public Node expr;       // The expression node holding the initial value of the variable
    public string name;     // Variable name (identifier)
    public TypeName type;   // Variable type (int, float, etc.)
    Scope _scope;           // Scope in which this variable is declared (used during eval)
    public string evalType = "decvar";

    /// Constructs a DeclVar node with the initial value, name, type, scope, and token info
    this(Node expr, string name, TypeName type, Scope _scope, Token token) {
        super(token);
        this.expr = expr;
        this.name = name;
        this.type = type;
        this._scope = _scope;
    }

    /// Evaluates the variable declaration by adding it to the given scope
    override Object eval(Scope _scope) {
        // Define the variable in the current scope with its type and initial value
        _scope.define(name, type, expr);

        // Debug output: dump current scope symbols (helpful during development)
        debug _scope.dump();
        return null;
    }

    /// String representation for debugging and printing AST nodes
    override string toString() const {
        return format("[DeclVar: name: %s; type: %s; value: %s]", name, type, expr);
    }
}
