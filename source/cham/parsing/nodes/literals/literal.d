module cham.parsing.nodes.literals.literal;

import cham.parsing.nodes.ast_node : Node;
import cham.lexing.token.token : Token;
import std.variant : Variant;
import std.conv;

/// Abstract base class for all literal nodes (int, float, bool, string, etc.)
abstract class Literal : Node {
    Variant _value;  // private storage for the literal value

    this(Variant value, Token token) {
        super(token);
        _value = value;
    }

    T as(T)() const {
        // Extract the stored value safely as type T
        return _value.get!T;
    }

    override string toString() const {
        auto t = _value.type;

        if (t == typeid(int)) {
            return text(_value.get!int);
        } else if (t == typeid(float)) {
            return text(_value.get!float);
        } else if (t == typeid(bool)) {
            return _value.get!bool ? "true" : "false";
        } else if (t == typeid(string)) {
            return _value.get!string;
        } else {
            try {
                return _value.to!string;
            } catch (Throwable) { // @suppress(dscanner.suspicious.catch_em_all)
                return "<unknown>";
            }
        }
    }

    string asString() const {
        return "\"" ~ toString() ~ "\"";
    }
}
