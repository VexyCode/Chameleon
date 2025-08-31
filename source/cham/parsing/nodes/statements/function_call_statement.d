module cham.parsing.nodes.statements.function_call_statement;

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

alias BuiltIn = Node delegate(Scope _scope, Node[] args, Token t);

class FuncCall : Node
{
    string name;
    Node[] args;
    string p;

    // Built-ins map
    public static BuiltIn[string] builtins;

    static this()
    {
        // LOG
        builtins["log"] = (Scope _scope, Node[] args, Token t) {
            if (args.length != 1)
                throwChamError("log expects exactly one argument", t, _scope.srcLines);

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

            write(s);
            return null;
        };

        // INPUT
        builtins["input"] = (Scope _scope, Node[] args, Token t) {
            if (args.length != 0)
                throwChamError("input expects no arguments", t, _scope.srcLines);

            import std.stdio : readln;

            string val = readln().strip();
            return new StringLiteral(val, t); // pass the token properly
        };
    }

    this(string name, Node[] args, Token token)
    {
        this.name = name;
        this.args = args;
        super(token);

        if (args.length != 0)
            this.p = args.map!(n => n.toString()).array().join(",");
        else
            this.p = "";
    }

    override Object eval(Scope _scope)
    {
        // Check built-ins first
        if (auto f = name in builtins)
        {
            return (*f)(_scope, args, token);
        }

        // Otherwise treat as user-defined function
        auto fnInfo = _scope.lookUpFunction(name);
        Scope fnScope = _scope.createChild();

        if (args.length != fnInfo.params.length)
            throwChamError(format("Function %s expected %s arguments, got %s", name, fnInfo.params.length, args
                    .length), this, _scope.srcLines);

        foreach (i, param; fnInfo.params)
        {
            Object argVal = args[i].eval(_scope);
            Node argNode = cast(Node) args[i];
            fnScope.symbols[param.name] = SymbolInfo(argNode, false, param.type);
        }

        foreach (stmt; fnInfo.body)
        {
            if (ReturnStmt ret = cast(ReturnStmt) stmt)
            {
                Node retVal = cast(Node) ret.eval(fnScope);
                if (!fnInfo.returns)
                    throwChamError(
                        format("Function %s does not return but used return statement", fnInfo.name),
                        ret,
                        _scope.srcLines
                    );
                if (retVal is null)
                    throwChamError(
                        format("Function %s expects return value but got none", fnInfo.name),
                        ret,
                        _scope.srcLines
                    );
                return ret.eval(fnScope);
            }

            auto result = stmt.eval(fnScope);
        }

        return null;
    }

    override string toString() const
    {
        string smallP = p.length ? p : "none";
        return format("[FunctionCall: name: %s, params: %s]", name, smallP);
    }
}
