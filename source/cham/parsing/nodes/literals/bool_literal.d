module cham.parsing.nodes.literals.bool_literal;

import cham.parsing.nodes.literals.literal : Literal;
import cham.lexing.token.token : Token;
import cham.scopes.scopes : Scope;

import std.format : format;
import std.variant;

class BoolLiteral : Literal {
    this(bool value, Token token) {
        super(Variant(value), token);
    }

    override Object eval(Scope _scope) {
        return this;
    }
}