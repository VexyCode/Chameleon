module cham.parsing.nodes.constants.decl_const;

import cham.parsing.nodes.ast_node : Node;
import cham.variables_and_consts.typenames : TypeName;
import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;
import std.format;

/// AST node representing a constant declaration, e.g., `const int x = 42`
class DeclConst : Node {
    public Node expr;      // The expression/value assigned to the constant
    public string name;    // Constant's identifier/name
    public TypeName type;  // Type of the constant (int, float, etc.)
    Scope _scope;          // The scope in which this constant is defined

    /// Constructor: takes expression, name, type, scope, and token metadata
    this(Node expr, string name, TypeName type, Scope _scope, Token token) {
        super(token);
        this.expr = expr;
        this.name = name;
        this.type = type;
        this._scope = _scope;
    }

    /// Evaluates the constant declaration by defining it in the current scope
    override Object eval(Scope _scope) {
        // Define the constant in the scope with the `isConst = true` flag
        _scope.define(name, type, expr, true);

        // Debug dump of scope's current state (handy during development)
        debug _scope.dump();

        return null; // Declarations don't produce runtime values directly
    }

    /// String representation for debugging, showing name, type, and assigned expression
    override string toString() const {
        return format("[DeclConst: name: %s; type: %s; value: %s]", name, type, expr);
    }
}
