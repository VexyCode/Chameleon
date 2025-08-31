module cham.parsing.nodes.statements.return_statement;

import cham.parsing.nodes.ast_node : Node;
import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;
import std.format;

class ReturnStmt : Node {
    Node value;

    this(Node value, Token token) {
        this.value = value;
        super(token);
    }
    
    override Object eval(Scope _scope) {
        return value ? value.eval(_scope) : null;
    }
    override string toString() const {
        return format("[Return: %s]", value);
    }
}