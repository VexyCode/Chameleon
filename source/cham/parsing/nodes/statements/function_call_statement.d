module cham.parsing.nodes.statements.function_call_statement;

import cham.parsing.nodes.ast_node : Node;
import cham.lexing.token.token : Token;
import cham.exceptions.cham_error : throwChamError;
import cham.parsing.nodes.literals.string_literal : StringLiteral;
import cham.parsing.nodes.literals.int_literal : IntLiteral;
import cham.parsing.nodes.literals.float_literal : FloatLiteral;
import cham.parsing.nodes.literals.bool_literal : BoolLiteral;
import cham.parsing.nodes.literals.literal : Literal;
import cham.parsing.nodes.statements.function_def : FuncDef;
import cham.scopes.scopes : Scope, FunctionInfo, SymbolInfo;
import cham.parsing.nodes.statements.return_statement : ReturnStmt;
import cham.variables_and_consts.typenames;

import std.format : format;
import std.conv : to;
import std.stdio : writeln;
import std.algorithm.iteration : map;
import std.array : array, join, replace;
import std.variant;

class FuncCall : Node
{
    string name;
    Node[] args;
    string p;

    this(string name, Node[] args, Token token)
    {
        this.name = name;
        this.args = args;
        super(token);

        if (args.length != 0)
        {
            this.p = args
                .map!(n => n.toString())
                .array()
                .join(",");
        }
        else
        {
            this.p = "";
        }
    }

    override Object eval(Scope _scope)
    {
        // --- Built-in: log ---
        if (name == "log")
        {
            if (args.length != 1)
                throwChamError("Basic NexiLang log function expects exactly one argument", this, _scope
                        .srcLines);

            auto val = args[0].eval(_scope);
            string s;

            if (auto lit = cast(StringLiteral) val)
                s = lit._value.get!string;
            else if (auto ilit = cast(IntLiteral) val)
                s = ilit._value.get!string;
            else if (auto flit = cast(FloatLiteral) val)
                s = flit._value.get!string;
            else if (auto blit = cast(BoolLiteral) val)
                s = blit._value.get!string ? "yes" : "no";
            else
                s = val.toString();

            import std.stdio : write;

            s = s.replace("\\n", "\n");
            write(s is null ? "<null>" : s);

            return null;
        }

        // --- Built-in: input ---
        if (name == "input")
        {
            import std.stdio : readln;
            import std.string : strip;

            if (args.length != 0)
                throwChamError("Basic NexiLang input function expects exactly no arguments", this, _scope
                        .srcLines);

            string val = readln().strip();
            return new StringLiteral(val, this.token);
        }

        // --- User-defined function ---
        FunctionInfo fn = _scope.lookUpFunction(name);
        Scope fnScope = _scope.createChild();

        // check argument count
        if (args.length != fn.params.length)
            throwChamError(
                format("Function %s expected %s arguments, but got %s.", name, fn.params.length, args
                    .length),
                this,
                _scope.srcLines
            );

        // evaluate arguments and assign to parameters in child scope
        foreach (i, param; fn.params)
        {
            Object argVal = args[i].eval(_scope); // evaluate in caller scope
            fnScope.symbols[param.name] = SymbolInfo(argVal, false, param.type);
        }

        // execute function body
        foreach (stmt; fn.body)
        {
            auto result = stmt.eval(fnScope);

            if (result !is null)
            {
                import cham.parsing.nodes.statements.return_statement : ReturnStmt;

                auto retStmt = cast(ReturnStmt) stmt;
                if (retStmt !is null)
                {
                    return result; // propagate value
                }
            }
        }

        // if function expected a return but none was given
        if (fn.returns)
            throwChamError(
                format("Function %s expected a return value but none was returned", name),
                this,
                _scope.srcLines
            );

        return null;
    }

    override string toString() const
    {
        string smallP = p;
        if (p == "")
            smallP = "none";
        return format("[FunctionCall: name: %s, params: %s]", name, smallP);
    }
}

import std.traits : staticMap;
import std.meta : AliasSeq;

template MaxTypeSize(T...)
{
    enum MaxTypeSize = computeMaxSize!(T);
}

private template computeMaxSize(Ts...)
{
    static if (Ts.length == 1)
    {
        enum computeMaxSize = Ts[0].sizeof;
    }
    else static if (Ts.length > 1)
    {
        enum restMax = computeMaxSize!(Ts[1 .. $]);
        enum computeMaxSize = Ts[0].sizeof > restMax ? Ts[0].sizeof : restMax;
    }
    else
    {
        enum computeMaxSize = 0;
    }
}

alias MyVariant = VariantN!(MaxTypeSize!(int, float, bool, string), int, float, bool, string);

class VariantValue
{
    MyVariant val;
    this(MyVariant v)
    {
        val = v;
    }
}

import std.conv : to;

string toS(MyVariant v)
{
    auto t = v.type;

    if (t == typeid(int))
    {
        return v.get!int
            .to!string;
    }
    else if (t == typeid(float))
    {
        return v.get!float
            .to!string;
    }
    else if (t == typeid(bool))
    {
        return v.get!bool ? "true" : "false";
    }
    else if (t == typeid(string))
    {
        return v.get!string;
    }
    else
    {
        try
        {
            return v.to!string;
        }
        catch (Throwable) // @suppress(dscanner.suspicious.catch_em_all)
        {
            return "<unknown>";
        }
    }
}
