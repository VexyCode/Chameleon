module cham.parsing.nodes.literals.float_literal;

import cham.parsing.nodes.literals.literal : Literal;
import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;
import std.format : format;
import std.variant;


/// Represents a floating-point literal in the AST,
/// storing a fixed `float` value like `3.14` or `-0.001`.
class FloatLiteral : Literal {
    /// Constructor takes the float value and the token metadata.
    this(float value, Token token) {
        super(Variant(value),token);
    }

    /// Evaluating a float literal returns itself, since it's a constant value.
    public override Object eval(Scope _scope) {
        return this;
    }
}
