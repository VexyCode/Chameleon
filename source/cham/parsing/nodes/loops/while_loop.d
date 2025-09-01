module cham.parsing.nodes.loops.while_loop;

import cham.parsing.nodes.ast_node : Node;
import cham.parsing.nodes.literals.bool_literal : BoolLiteral;
import cham.lexing.token.token : Token;

import std.stdio : writeln;
import std.algorithm.iteration : map;
import std.array : array, join, replace;
import std.variant;
import std.algorithm;
import std.array;
import std.format;
import cham.scopes.scopes : Scope;

class WhileLoop : Node
{
    Node[] body;
    Node condition;

    this(Node[] body, Node condition, Token token)
    {
        this.body = body;
        this.condition = condition;
        super(token);
    }

    override Object eval(Scope _scope)
    {
        while (true)
        {
            BoolLiteral cond = cast(BoolLiteral) condition.eval(_scope);
            if (cond is null)
                throw new Exception("WhileLoop condition did not evaluate to a BoolLiteral");
            if (!cond.as!bool())
                break;

            foreach (Node n; body)
                n.eval(_scope);
        }
        return null;
    }

    override string toString() const
    {
        auto indentedBody = body
            .map!(n => indent(n.toString()))
            .array
            .join("\n");

        return format("[While loop %s:\n  body:\n%s\n]", condition, indentedBody);
    }
}

string indent(string text, string prefix = "    ")
{
    import std.algorithm.iteration : map;
    import std.array : join, array;
    import std.string : split;

    auto lines = split(text, "\n");
    auto indentedLines = lines
        .map!(line => prefix ~ line)
        .array;

    return indentedLines.join("\n");
}
