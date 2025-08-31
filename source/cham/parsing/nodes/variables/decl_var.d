module cham.parsing.nodes.variables.decl_var;

import cham.parsing.nodes.ast_node : Node;
import cham.variables_and_consts.look_up : LookUp;
import cham.parsing.nodes.statements.function_call_statement : FuncCall;
import cham.parsing.nodes.statements.return_statement : ReturnStmt;
import cham.parsing.nodes.operations.bin_op : BinOp;
import cham.variables_and_consts.typenames : TypeName;
import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;
import std.format;
import std.stdio;

/// Represents a variable declaration node in the AST
class DeclVar : Node
{
    public Node expr; // The expression node holding the initial value of the variable
    public string name; // Variable name (identifier)
    public TypeName type; // Variable type (int, float, etc.)
    Scope _scope; // Scope in which this variable is declared (used during eval)
    public string evalType = "decvar";

    /// Constructs a DeclVar node with the initial value, name, type, scope, and token info
    this(Node expr, string name, TypeName type, Scope _scope, Token token)
    {
        super(token);
        this.expr = expr;
        this.name = name;
        this.type = type;
        this._scope = _scope;
    }

    /// Evaluates the variable declaration by adding it to the given scope
    override Object eval(Scope _scope)
    {
        // Evaluate the initializer first (eager)
        auto evaluated = expr.eval(_scope);

        // If your interpreter uses an unwrap function (like in bin_op.d),
        // use it here to reduce to a literal/terminal node:
        try
        {
            evaluated = cast(Node) unwrap(cast(Node) evaluated, _scope);
        }
        catch (Exception e)
        {
            // if unwrap isn't in scope here, just cast — unwrap is best
            evaluated = cast(Node) evaluated;
        }

        // store the actual Node into the scope's symbol table as a SymbolInfo
        // (SymbolInfo is used elsewhere, see FuncCall; signature used there: SymbolInfo(node, isConst, type))
        _scope.define(name, type, cast(Node) evaluated, false);

        debug _scope.dump();
        return null;
    }

    /// String representation for debugging and printing AST nodes
    override string toString() const
    {
        return format("[DeclVar: name: %s; type: %s; value: %s]", name, type, expr);
    }
}

Node unwrap(Node n, Scope _scope)
{
    Node current = n;

    debug writefln("Got to unwrapping: %s", current);

    while (true)
    {
        Node next = null;

        // BinOp
        if (auto bin = cast(BinOp) current)
            next = cast(Node) bin.eval(_scope);

        // LookUp (variables)
        else if (auto lookup = cast(LookUp) current)
            next = cast(Node) lookup.eval(_scope);

        // Return statement
        else if (auto ret = cast(ReturnStmt) current)
            next = cast(Node) ret.eval(_scope);

        // FunctionCall
        else if (auto call = cast(FuncCall) current)
            next = cast(Node) call.eval(_scope);

        // nothing matched, we’re done
        else
            break;

        // If nothing changed, stop (avoid infinite loop)
        if (next is null || next is current)
            break;

        current = next;
    }

    return current;
}
