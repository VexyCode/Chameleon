module cham.builtins;

import cham.parsing.nodes.statements.function_call_statement : FuncCall;
import cham.parsing.nodes.ast_node : Node;
import cham.lexing.token.token : Token;
import cham.exceptions.cham_error : throwChamError;
import cham.parsing.nodes.literals.string_literal : StringLiteral;
import cham.parsing.nodes.literals.int_literal : IntLiteral;
import cham.parsing.nodes.literals.float_literal : FloatLiteral;
import cham.parsing.nodes.literals.bool_literal : BoolLiteral;
import cham.parsing.nodes.statements.return_statement : ReturnStmt;
import cham.scopes.scopes : Scope, FunctionInfo, SymbolInfo;

import std.stdio : writeln, write;
import std.string : strip;
import std.array : array, join;
import std.format : format;
import std.conv;
import std.algorithm;

class BuiltIns {
    private this() {}
    
    static void initialize() {
        FuncCall.builtins["logln"] = (Scope _scope, Node[] args, Token t) {
            if (args.length != 1) 
                throwChamError("Function logln expects exactly one argument.", t, _scope.srcLines);
            Node raw = cast(Node) args[0].eval(_scope);
            string s;

            if (auto str = cast(StringLiteral) raw)
                s = str.as!string();
            else if (auto i = cast(IntLiteral) raw)
                s = i.as!int().to!string();
            else if (auto f = cast(FloatLiteral) raw)
                s = f.as!float().to!string();
            else if (auto b = cast(BoolLiteral) raw)
                s = b.as!bool() ? "yes" : "no";
            else
                s = raw is null ? "<null>" : raw.toString();

            writeln(s);
            return null;
        };

        // PROMPT
        FuncCall.builtins["prompt"] = (Scope _scope, Node[] args, Token t) {
            if (args.length != 2)
                throwChamError(format("prompt expects 2 arguments, got %s.", args.length), t, _scope
                        .srcLines);

            auto mess = cast(StringLiteral) args[0];
            auto newLine = cast(BoolLiteral) args[1];

            if (mess is null || newLine is null)
                throwChamError("Invalid argument types for prompt", t, _scope.srcLines);

            if (newLine.as!bool())
                writeln(mess);
            else
                write(mess);

            import std.stdio : readln;

            string val = readln().strip();
            return new StringLiteral(val, t); // pass token
        };

        debug writeln("Initialized functions: ");
        foreach (key, _; FuncCall.builtins) debug writeln(format(" - %s", key));
    }
}