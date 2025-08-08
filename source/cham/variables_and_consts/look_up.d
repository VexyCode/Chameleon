module cham.variables_and_consts.look_up;

import cham.parsing.nodes.ast_node : Node;
import cham.lexing.token.token : Token;
import cham.scopes.scopes : Scope;
import std.format : format;


class LookUp : Node {
    string name;

    this(string name, Token token) {
        this.name = name;
        super(token);
    }

    override Object eval(Scope _scope) {
        return _scope.lookup(this.name);
    }

    override string toString() const {
        return format("[LookUp: %s]", this.name);
    }
}