module cham.parsing.nodes.literals.int_literal;

import cham.parsing.nodes.literals.literal : Literal;
import std.format : format;
import std.variant;
import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;

/// Represents an integer literal node in the AST.
/// Holds a fixed int value like `42` or `-7`.
class IntLiteral : Literal {
    /// Constructor takes the int value and the token info from source.
    this(int v, Token token) {
        super(Variant(v), token);
    }

    /// Evaluation of an int literal just returns itself, since it's a fixed value.
    public override Object eval(Scope _scope) {
        return this;
    }
}
