module cham.parsing.nodes.operations.bin_op;

import cham.parsing.nodes.ast_node : Node;
import cham.parsing.nodes.literals.float_literal : FloatLiteral;
import cham.parsing.nodes.literals.int_literal : IntLiteral;
import cham.parsing.nodes.literals.bool_literal : BoolLiteral;
import cham.parsing.nodes.literals.string_literal : StringLiteral;
import cham.variables_and_consts.look_up : LookUp;
import cham.parsing.nodes.statements.return_statement : ReturnStmt;
import cham.parsing.nodes.statements.function_call_statement : FuncCall;

import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;
import std.format;
import std.stdio;
import std.algorithm.searching : canFind, startsWith, endsWith;
import std.string : indexOf;

/// Represents a binary operation node in the AST,
/// like `a + b`, `x * y`, or `num / denom`.
class BinOp : Node
{
    Node left; // Left operand node
    Node right; // Right operand node
    string operator; // Operator string, e.g. "+", "-", "*", "/"

    /// Constructor sets operator and operand nodes, plus token metadata
    this(string operator, Node left, Node right, Token token)
    {
        this.left = left;
        this.right = right;
        this.operator = operator;
        super(token);
    }

    /// Evaluates the binary operation by first evaluating both operands,
    /// then performing the correct arithmetic based on operand types and operator.
    override Object eval(Scope _scope)
    {
        // Fully unwrap operands ONCE
        Node left_eval = unwrap(cast(Node) left.eval(_scope), _scope);
        Node right_eval = unwrap(cast(Node) right.eval(_scope), _scope);

        auto lv0 = cast(BoolLiteral) left_eval;
        auto rv0 = cast(BoolLiteral) right_eval;

        // === BOOL LOGIC
        if (lv0 !is null && rv0 !is null)
        {
            bool lval = lv0.as!bool();
            bool rval = rv0.as!bool();

            switch (operator)
            {
            case "&&":
                return new BoolLiteral(lval && rval, token);
            case "||":
                return new BoolLiteral(lval || rval, token);
            case "==":
                return new BoolLiteral(lval == rval, token);
            case "!=":
                return new BoolLiteral(lval != rval, token);
            default:
                throw new Exception("Invalid boolean operator: " ~ operator);
            }
        }

        StringLiteral lv9 = cast(StringLiteral) left_eval;
        StringLiteral rv9 = cast(StringLiteral) right_eval;

        // === STRING OPERATIONS
        if (lv9 !is null && rv9 !is null)
        {
            string lval = lv9.as!string();
            string rval = rv9.as!string();

            switch (operator)
            {
            case "+":
                return lv9.merge(rv9);
            case "==":
                return new BoolLiteral(lval == rval, token);
            case "!=":
                return new BoolLiteral(lval != rval, token);
            case "<":
                return new BoolLiteral(lval < rval, token);
            case ">":
                return new BoolLiteral(lval > rval, token);
            case "<=":
                return new BoolLiteral(lval <= rval, token);
            case ">=":
                return new BoolLiteral(lval >= rval, token);
            default:
                throw new Exception("Invalid string operator: " ~ operator);
            }
        }

        auto lv = cast(IntLiteral) left_eval;
        auto rv = cast(IntLiteral) right_eval;

        // === INT OPERATIONS
        if (lv !is null && rv !is null)
        {
            int lval = lv.as!int();
            int rval = rv.as!int();

            switch (operator)
            {
            case "+":
                return new IntLiteral(lval + rval, token);
            case "-":
                return new IntLiteral(lval - rval, token);
            case "*":
                return new IntLiteral(lval * rval, token);
            case "/":
                if (rval == 0)
                    throw new Exception("Division by 0.");
                return new FloatLiteral(cast(float) lval / rval, token);
            case "==":
                return new BoolLiteral(lval == rval, token);
            case "!=":
                return new BoolLiteral(lval != rval, token);
            case "<":
                return new BoolLiteral(lval < rval, token);
            case ">":
                return new BoolLiteral(lval > rval, token);
            case "<=":
                return new BoolLiteral(lval <= rval, token);
            case ">=":
                return new BoolLiteral(lval >= rval, token);
            default:
                throw new Exception("Unknown int operator: " ~ operator);
            }
        }

        // === FLOAT OPERATIONS (mix of float/int)
        float lval;
        float rval;

        if (auto lv1 = cast(FloatLiteral) left_eval)
            lval = lv1.as!float();
        else if (auto lv1 = cast(IntLiteral) left_eval)
            lval = lv1.as!int();
        else if (auto lv1 = cast(StringLiteral) left_eval) {
            string lval2 = lv9.as!string();
            string rval2 = rv9.as!string();

            switch (operator)
            {
            case "+":
                return lv9.merge(rv9);
            case "==":
                return new BoolLiteral(lval2 == rval2, token);
            case "!=":
                return new BoolLiteral(lval2 != rval2, token);
            case "<":
                return new BoolLiteral(lval2 < rval2, token);
            case ">":
                return new BoolLiteral(lval2 > rval2, token);
            case "<=":
                return new BoolLiteral(lval2 <= rval2, token);
            case ">=":
                return new BoolLiteral(lval2 >= rval2, token);
            default:
                throw new Exception("Invalid string operator: " ~ operator);
            }
        } else
            throw new Exception("Unsupported left operand: " ~ typeid(left_eval).name);

        if (auto rv2 = cast(FloatLiteral) right_eval)
            rval = rv2.as!float();
        else if (auto rv2 = cast(IntLiteral) right_eval)
            rval = rv2.as!int();
        else
            throw new Exception("Unsupported right operand: " ~ typeid(right_eval).name);

        switch (operator)
        {
        case "+":
            return new FloatLiteral(lval + rval, token);
        case "-":
            return new FloatLiteral(lval - rval, token);
        case "*":
            return new FloatLiteral(lval * rval, token);
        case "/":
            if (rval == 0.0f)
                throw new Exception("Division by 0.");
            return new FloatLiteral(lval / rval, token);
        case "==":
            return new BoolLiteral(lval == rval, token);
        case "!=":
            return new BoolLiteral(lval != rval, token);
        case "<":
            return new BoolLiteral(lval < rval, token);
        case ">":
            return new BoolLiteral(lval > rval, token);
        case "<=":
            return new BoolLiteral(lval <= rval, token);
        case ">=":
            return new BoolLiteral(lval >= rval, token);
        default:
            throw new Exception("Unknown float operator: " ~ operator);
        }
    }

    /// Pretty string representation for debugging, e.g. "[BinOp: 1 + 2]"
    public override string toString() const
    {
        return format("[BinOp: %s %s %s]", left, operator, right);
    }
}

string replicateStr(string s, size_t n)
{
    import std.array : appender;

    auto buf = appender!string();
    foreach (_; 0 .. n)
    {
        buf.put(s);
    }
    return buf.data;
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
        else break;

        // If nothing changed, stop (avoid infinite loop)
        if (next is null || next is current)
            break;

        current = next;
    }

    return current;
}
