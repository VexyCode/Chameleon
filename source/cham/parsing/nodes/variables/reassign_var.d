module cham.parsing.nodes.variables.reassign_var;

// Core node structure
import cham.parsing.nodes.ast_node : Node;

// Scope system to track variables
import cham.scopes.scopes;

// Token metadata (used for error localization)
import cham.lexing.token.token;

// Custom error throwing for pretty errors
import cham.exceptions.cham_error : throwChamError;

import std.format : format;
import std.stdio;

/// AST node representing a variable reassignment (e.g. `x = 5`)
class ReassignVar : Node {
    public string name;   // The variable being reassigned
    public Node value;    // The new expression assigned to the variable
    
    /// Constructor: stores the variable name, the new value, and the originating token
    this(string name, Node value, Token token) {
        this.name = name;
        this.value = value;
        super(token); // Calls base class (Node) constructor to attach token metadata
    }

    /// Evaluates the reassignment in the given scope
    override Object eval(Scope _scope) {
        // Check if the variable actually exists in the current scope
        if (!_scope.exists(this.name)) 
            throwChamError(
                format("Symbol %s not found in current scope", name),
                this.value,
                _scope.srcLines
            );

        // Redefine the variable with the new value node
        _scope.reDefine(this.name, this.value);

        // Debug output — helps during dev to trace what’s happening
        debug writeln(format("Redefined the value of %s to %s", name, value));

        return null; // Nothing returned for a statement node
    }

    override string toString() const {
        return format("[VarReAssign: %s: %s]", name, value);
    }
}
