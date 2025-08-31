module cham.interpreting.interpreter;

import cham.parsing.nodes.ast_node : Node;
import cham.parsing.nodes.constants.decl_const;
import cham.parsing.nodes.variables.decl_var;
import cham.parsing.nodes.statements.if_statement;
import cham.parsing.nodes.statements.function_def : FuncDef;
import cham.scopes.scopes : Scope;
import std.stdio;

/// Simple interpreter to evaluate parsed AST nodes in a given scope
class Interpreter {
    Node[] nodes;      // List of AST nodes to interpret
    Scope _scope;      // Current scope for variable/constant lookups and evaluation

    /// Construct with AST nodes and the initial scope
    this(Node[] nodes, Scope _scope) {
        this.nodes = nodes;
        this._scope = _scope;
    }

    /// Runs the interpreter: evaluates all nodes except declarations and prints their result
    void run() {
        foreach (Node node; nodes) {
            auto result = node.eval(_scope);
            if (result !is null) {
                writeln(result);
            }
            debug _scope.dump();
        }
    }
}

/// Helper to check if an object is an instance of type T
bool instanceOf(T)(Object obj) {
    return cast(T) obj !is null;
}
