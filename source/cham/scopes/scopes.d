module cham.scopes.scopes;

import cham.variables_and_consts.typenames : TypeName;
import std.format : format;
import cham.parsing.nodes.ast_node : Node;
import cham.parsing.nodes.literals.int_literal;
import cham.parsing.nodes.literals.float_literal;
import cham.parsing.nodes.literals.bool_literal;
import cham.parsing.nodes.literals.string_literal;
import cham.parsing.nodes.statements.function_call_statement : FunctionCall;
import cham.interpreting.interpreter : Interpreter;
import std.stdio;
import cham.exceptions.cham_error : ChamError, throwChamError;
import std.string : splitLines;
import std.array : join;

/// Holds info about a symbol stored in a scope (variable or constant)
struct SymbolInfo {
    Node node;        // The AST node representing the value/expression of the symbol
    bool isConst;     // True if symbol is a constant, false if mutable variable
    TypeName type;    // Symbol type (int, float, etc.)
}

/// Represents a lexical scope (with optional parent for nested scopes)
class Scope {
    Scope parent;                       // Parent scope, null if root/global scope
    SymbolInfo[string] symbols;        // Map from symbol name to its info in this scope
    string[] srcLines;                 // Source code lines, used for error reporting/context

    /// Creates a new scope, optionally linked to a parent and source code for errors
    this(Scope parent = null, string src) {
        this.srcLines = src.splitLines();
        this.parent = parent;
    }

    /// Defines a new symbol in the current scope, throws if re-defining a constant
    void define(string name, TypeName type, Node value, bool isConst = false) {
        // Prevent overwriting a constant symbol
        if (name in symbols && symbols[name].isConst == true)
            throwChamError(format("%s is a constant literal.", name), value, srcLines);

        if (auto fn = cast(FunctionCall) value)  { 
            value = cast(Node) value.eval(this);
        }

        SymbolInfo info = SymbolInfo(cast(Node) value.eval(this), isConst, type);

        // Enforce type correctness on symbol value
        typeCheck(name, info);

        symbols[name] = info;
    }

    /// Redefines an existing symbol with a new value, keeping its original type and mutable
    void reDefine(string name, Node newVal) {
        Scope current = this;
        while (current !is null) {
            if (name in current.symbols) {
                TypeName type = current.symbols[name].type;
                current.define(name, type, newVal, false);
                return;
            }
            current = current.parent;
        }
        throwChamError("Cannot reassign undefined variable: " ~ name, newVal, srcLines);
    }


    /// Looks up the AST node of a symbol by name, searching up through parent scopes
    Node lookup(string name) {
        if (auto val = name in symbols) 
            return val.node;
        else if (parent !is null)
            return parent.lookup(name);
        else 
            throw new Exception(format("Undefined symbol: %s", name));
    }

    /// Returns whether the symbol is constant, searching up the scope chain
    bool isConst(string name) {
        if (auto val = name in symbols) 
            return val.isConst;
        else if (parent !is null)
            return parent.isConst(name);
        else 
            throw new Exception(format("Undefined symbol: %s", name));
    }

    /// Checks if a symbol exists in this scope or any parent scope
    bool exists(string name) {
        return (name in symbols) !is null ||
               (parent !is null && parent.exists(name));
    }

    /// Creates a child scope inheriting this scope as parent, copies source lines for errors
    Scope createChild() {
        string combined = join(srcLines, "\n");
        return new Scope(this, combined);
    }

    /// Prints current scope’s symbols for debugging (shows name, node, mutability)
    void dump() {
        writeln("Scope {");
        foreach (k, v; symbols)
            writeln("   ", k, " => ", v.node, " (Const: ", v.isConst, ")");
        writeln("}");
    }

    /// Template mapping TypeName enum to the corresponding AST node type
    template getType(TypeName type){
        static if (type == TypeName.Int) 
            alias getType = IntLiteral;
        else static if (type == TypeName.Float) 
            alias getType = FloatLiteral;
        else
            static assert(0, "Unknown type name");
    }

    /// List of TypeInfo for type checking, indexed by TypeName
    static TypeInfo[] typenames = [
        typeid(IntLiteral),
        typeid(FloatLiteral),
        typeid(BoolLiteral),
        typeid(StringLiteral),
    ];

    /// Checks that the node’s type matches the expected type for the symbol
    void typeCheck(string name, SymbolInfo info) {
        TypeInfo expected = typenames[info.type];
        if (typeid(info.node.eval(this)) !is expected)
            throwChamError(
                format("Type mismatch. Expected %s, got %s for symbol `%s`.", 
                    expected.toString(),
                    typeid(info.node).toString(),
                    name
                ),
                info.node,
                this.srcLines
            );
    }

    /// Gets symbol name from SymbolInfo by scanning symbols dictionary (rarely used)
    string getSymbolName(SymbolInfo info) {
        foreach (k, v; symbols) {
            if (v is info)
                return k;
        }
        return "<unknown>";
    }
}
