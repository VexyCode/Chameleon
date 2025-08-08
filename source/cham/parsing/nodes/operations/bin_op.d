module cham.parsing.nodes.operations.bin_op;

import cham.parsing.nodes.ast_node : Node;
import cham.parsing.nodes.literals.float_literal : FloatLiteral;
import cham.parsing.nodes.literals.int_literal : IntLiteral;
import cham.parsing.nodes.literals.bool_literal : BoolLiteral;
import cham.parsing.nodes.literals.string_literal : StringLiteral;
import cham.scopes.scopes : Scope;
import cham.lexing.token.token : Token;
import std.format;
import std.stdio;

/// Represents a binary operation node in the AST,
/// like `a + b`, `x * y`, or `num / denom`.
class BinOp : Node {
    Node left;       // Left operand node
    Node right;      // Right operand node
    string operator; // Operator string, e.g. "+", "-", "*", "/"

    /// Constructor sets operator and operand nodes, plus token metadata
    this(string operator, Node left, Node right, Token token) {
        this.left = left;
        this.right = right;
        this.operator = operator;
        super(token);
    }

    /// Evaluates the binary operation by first evaluating both operands,
    /// then performing the correct arithmetic based on operand types and operator.
    override Object eval(Scope _scope) {
        auto left_eval = left.eval(_scope);
        auto right_eval = right.eval(_scope);

        // Casts
        auto leftInt = cast(IntLiteral)left_eval;
        auto rightInt = cast(IntLiteral)right_eval;
        auto leftFloat = cast(FloatLiteral)left_eval;
        auto rightFloat = cast(FloatLiteral)right_eval;
        auto leftBool = cast(BoolLiteral)left_eval;
        auto rightBool = cast(BoolLiteral)right_eval;
        auto leftStr = cast(StringLiteral)left_eval;
        auto rightStr = cast(StringLiteral)right_eval;

        // === BOOL LOGIC
        if (leftBool !is null && rightBool !is null) {
            bool lval = leftBool.as!bool();
            bool rval = rightBool.as!bool();

            switch (operator) {
                case "&&": return new BoolLiteral(lval && rval, token);
                case "||": return new BoolLiteral(lval || rval, token);
                case "==": return new BoolLiteral(lval == rval, token);
                case "!=": return new BoolLiteral(lval != rval, token);
                default: throw new Exception("Invalid boolean operator: " ~ operator);
            }
        }

        // === STRING COMPARE (equality only for now)
        if (leftStr !is null && rightStr !is null) {
            string lval = leftStr.as!string();
            string rval = rightStr.as!string();

            switch (operator) {
                case "==": return new BoolLiteral(lval == rval, token);
                case "!=": return new BoolLiteral(lval != rval, token);
                default: throw new Exception("Invalid string operator: " ~ operator);
            }
        }

        // === INT ARITHMETIC
        if (leftInt !is null && rightInt !is null) {
            int lval = leftInt.as!int();
            int rval = rightInt.as!int();

            switch (operator) {
                case "+": return new IntLiteral(lval + rval, token);
                case "-": return new IntLiteral(lval - rval, token);
                case "*": return new IntLiteral(lval * rval, token);
                case "/":
                    if (rval == 0) throw new Exception("Division by 0.");
                    return new FloatLiteral(cast(float)lval / rval, token);
                case "==": return new BoolLiteral(lval == rval, token);
                case "!=": return new BoolLiteral(lval != rval, token);
                case "<":  return new BoolLiteral(lval < rval, token);
                case ">":  return new BoolLiteral(lval > rval, token);
                case "<=": return new BoolLiteral(lval <= rval, token);
                case ">=": return new BoolLiteral(lval >= rval, token);
                default: throw new Exception("Unknown int operator: " ~ operator);
            }
        }

        // === FLOAT ARITHMETIC (mix of float and/or int)
        float lval;
        float rval;

        if (leftFloat !is null) lval = leftFloat.as!float();
        else if (leftInt !is null) lval = cast(float)leftInt.as!float();
        else throw new Exception("Unsupported left operand: " ~ typeid(left_eval).name);

        if (rightFloat !is null) rval = rightFloat.as!float();
        else if (rightInt !is null) rval = cast(float)rightInt.as!float();
        else throw new Exception("Unsupported right operand: " ~ typeid(right_eval).name);

        switch (operator) {
            case "+": return new FloatLiteral(lval + rval, token);
            case "-": return new FloatLiteral(lval - rval, token);
            case "*": return new FloatLiteral(lval * rval, token);
            case "/":
                if (rval == 0.0f) throw new Exception("Division by 0.");
                return new FloatLiteral(lval / rval, token);
            case "==": return new BoolLiteral(lval == rval, token);
            case "!=": return new BoolLiteral(lval != rval, token);
            case "<":  return new BoolLiteral(lval < rval, token);
            case ">":  return new BoolLiteral(lval > rval, token);
            case "<=": return new BoolLiteral(lval <= rval, token);
            case ">=": return new BoolLiteral(lval >= rval, token);
            default: throw new Exception("Unknown float operator: " ~ operator);
        }
    }


    /// Pretty string representation for debugging, e.g. "[BinOp: 1 + 2]"
    public override string toString() const {
        return format("[BinOp: %s %s %s]", left, operator, right);
    }
}
