module cham.parsing.nodes.statements.function_call_statement;

import cham.parsing.nodes.ast_node : Node;
import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;
import cham.exceptions.cham_error : throwChamError;
import cham.parsing.nodes.literals.string_literal : StringLiteral;

import std.format : format;
import std.conv : to;
import std.stdio : writeln;
import std.algorithm.iteration : map; 
import std.array : array, join, replace;       
import std.variant ;

class FunctionCall : Node {
    string name;
    Node[] args;
    string p;
    

    this(string name, Node[] args, Token token) {
        this.name = name;
        this.args = args;
        super(token);

        if (args.length != 0) {
            this.p = args    
                .map!(n => n.toString())
                .array()
                .join(",");
        } else {
            this.p = "";
        }
    }

    override Object eval(Scope _scope) {
        if (name == "log") {
            if (args.length != 1) {
                throwChamError("Basic NexiLang log function expects exactly one argument", this, _scope.srcLines);
            }
            auto val = args[0].eval(_scope);
            auto s = val.toString().replace("\\n", "\n");

            // super basic, just print whatever .toString() gives
            import std.stdio : write;        

            write(s is null ? "<null>" : s);

            return null;
        } else if (name == "input") {
            import std.stdio : readln;
            import std.string : strip;

            if (args.length != 0) {
                throwChamError("Basic NexiLang input function expects exactly no arguments", this, _scope.srcLines);
            }
            string val = readln().strip();

            return new StringLiteral(val, this.token);
        }

        throwChamError("Function `" ~ name ~ "` not found", this, _scope.srcLines);
        assert(0);
    }


    override string toString() const {
        string smallP = p;
        if (p == "") smallP = "none";
        return format("[FunctionCall: name: %s, params: %s]", name, smallP);
    }
}

import std.traits : staticMap;
import std.meta : AliasSeq;

template MaxTypeSize(T...) {
    enum MaxTypeSize = computeMaxSize!(T);
}

private template computeMaxSize(Ts...) {
    static if (Ts.length == 1) {
        enum computeMaxSize = Ts[0].sizeof;
    } else static if (Ts.length > 1) {
        enum restMax = computeMaxSize!(Ts[1 .. $]);
        enum computeMaxSize = Ts[0].sizeof > restMax ? Ts[0].sizeof : restMax;
    } else {
        enum computeMaxSize = 0;
    }
}
alias MyVariant = VariantN!(MaxTypeSize!(int, float, bool, string), int, float, bool, string);

class VariantValue {
    MyVariant val;
    this(MyVariant v) { val = v; }
}

import std.conv : to;

string toS(MyVariant v) {
    auto t = v.type;

    if (t == typeid(int)) {
        return v.get!int.to!string;
    } else if (t == typeid(float)) {
        return v.get!float.to!string;
    } else if (t == typeid(bool)) {
        return v.get!bool ? "true" : "false";
    } else if (t == typeid(string)) {
        return v.get!string;
    } else {
        try {
            return v.to!string;
        } catch (Throwable) { // @suppress(dscanner.suspicious.catch_em_all)
            return "<unknown>";
        }
    }
}
