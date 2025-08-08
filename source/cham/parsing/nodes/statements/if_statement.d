module cham.parsing.nodes.statements.if_statement;

import cham.parsing.nodes.ast_node : Node;
import cham.parsing.nodes.literals.bool_literal : BoolLiteral;
import cham.scopes.scopes : Scope;
import cham.interpreting.interpreter : Interpreter;
import cham.lexing.token.token : Token;
import std.algorithm;
import std.array;


class IfStmt : Node {
    Node[] ifBranch;
    Node[] elseBranch;
    Node condition;
    Scope _scope;
    Scope _elseScope;
    public string evalType = "if";

    this(Node[] ifBody, Node[] elseBody, Node condition, Token token, Scope mainScope) {
        this.ifBranch = ifBody;
        this.elseBranch = elseBody;
        this.condition = condition;
        super(token);
        this._scope = mainScope.createChild();
        this._elseScope = mainScope.createChild();
    }

    override Object eval(Scope parentScope) {
        auto condValue = condition.eval(parentScope);
        auto result = cast(BoolLiteral) condValue;
        if (result is null) {
            throw new Exception("If condition did not evaluate to a boolean.");
        }
    
        if (result.as!bool()) {
            auto childScope = parentScope.createChild();
            auto ifRun = new Interpreter(ifBranch, childScope);
            ifRun.run();
        } else if (elseBranch !is null && elseBranch.length > 0) {
            auto childScope = parentScope.createChild();
            auto elseRun = new Interpreter(elseBranch, childScope);
            elseRun.run();
        }
    
        return null;
    }


    override string toString() const {
        auto indentedThen = ifBranch
            .map!(n => indent(n.toString()))
            .array
            .join("\n");

        string indentedElse;
        if (elseBranch.length > 0) {
            indentedElse = elseBranch
                .map!(n => indent(n.toString()))
                .array
                .join("\n");
        } else {
            indentedElse = indent("null");
        }

        return
            "[IfStmt:\n" ~
            "  condition: " ~ condition.toString() ~ "\n" ~
            "  then:\n" ~ indentedThen ~ "\n" ~
            "  else:\n" ~ indentedElse ~ "\n" ~
            "]"; 
    }
}

string indent(string text, string prefix = "    ") {
    import std.algorithm.iteration : map;
    import std.array : join, array;
    import std.string : split;

    auto lines = split(text, "\n");
    auto indentedLines = lines
        .map!(line => prefix ~ line)
        .array;

    return indentedLines.join("\n");
}
