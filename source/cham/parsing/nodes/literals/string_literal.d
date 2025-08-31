module cham.parsing.nodes.literals.string_literal;

import cham.parsing.nodes.literals.literal : Literal;
import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;

import std.format : format;
import std.variant;

class StringLiteral : Literal {
    this(string value, Token token) {
        super(Variant(value), token);
    }


    override Object eval(Scope _scope) {
        return this;
    }

    StringLiteral merge(StringLiteral other) {
        return new StringLiteral(this.as!string() ~ other.as!string(), this.token);
    }    
}