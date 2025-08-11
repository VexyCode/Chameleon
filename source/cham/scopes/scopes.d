module cham.scopes.scopes;

import cham.variables_and_consts.typenames : TypeName;
import std.format : format;
import cham.parsing.nodes.ast_node : Node;
import cham.parsing.nodes.literals.int_literal;
import cham.parsing.nodes.literals.float_literal;
import cham.parsing.nodes.literals.bool_literal;
import cham.parsing.nodes.literals.string_literal;
import cham.parsing.nodes.statements.function_call_statement : FuncCall;
import cham.parsing.nodes.statements.function_def : FuncDef;
import cham.interpreting.interpreter : Interpreter;
import std.stdio;
import std.conv;
import cham.exceptions.cham_error : ChamError, throwChamError;
import cham.lexing.token.token : Token;
import std.string : splitLines;
import std.array : join;
import std.typecons : Nullable;

/// Holds info about a symbol stored in a scope (variable or constant)
struct SymbolInfo
{
    Node node; // The AST node representing the value/expression of the symbol
    bool isConst; // True if symbol is a constant, false if mutable variable
    TypeName type; // Symbol type (int, float, etc.)
}

/// Holds info about a function's parameter
struct ParamInfo 
{
    string name;
    TypeName type;
    Token token;
}

/// Holds info about a function stored in a scope
struct FunctionInfo
{
    Node[] body;
    bool returns;
    Nullable!TypeName retType;
    ParamInfo[] params;
    string name;
    Scope _scope;
}

/// Represents a lexical scope (with optional parent for nested scopes)
class Scope
{
    Scope parent; // Parent scope, null if root/global scope
    SymbolInfo[string] symbols; // Map from symbol name to its info in this scope
    FunctionInfo[string] functions; // Map from function name to its info in the current scope   
    string[] srcLines; // Source code lines, used for error reporting/context

    /// Creates a new scope, optionally linked to a parent and source code for errors
    this(Scope parent = null, string src)
    {
        this.srcLines = src.splitLines();
        this.parent = parent;
    }

    /// Defines a new symbol in the current scope, throws if re-defining a constant
    void define(string name, TypeName type, Node value, bool isConst = false)
    {
        // Prevent overwriting a constant symbol
        if (name in symbols && symbols[name].isConst == true)
            throwChamError(format("%s is a constant literal.", name), value, srcLines);

        if (auto fn = cast(FuncCall) value)
        {
            value = cast(Node) value.eval(this);
        }

        SymbolInfo info = SymbolInfo(cast(Node) value.eval(this), isConst, type);

        // Enforce type correctness on symbol value
        typeCheck(name, info);

        symbols[name] = info;
    }

    /// Defines a function symbol in this scope
    void defineFunc(FuncDef fn)
    {
        if (fn.name in functions)
            throwChamError(format("Function '%s' already defined in this scope.", fn.name),
                fn, srcLines);

        FunctionInfo fnInfo;

        fnInfo.name = fn.name;
        fnInfo.body = fn.body;
        fnInfo.params = fn.params;
        fnInfo.retType = fn.retType;
        fnInfo.returns = fn.returns;
        fnInfo._scope = fn._scope;

        functions[fn.name] = fnInfo;
    }

    /// Defines a function parameter symbol in this scope
    void defineParam(FunctionInfo func, ParamInfo p)
    {
        // Parameters are mutable variables by default (not const)
        if (p.name in func._scope.symbols)
        {
            // Could be an error or just overwrite if shadowing is allowed
            throwChamError(format("Parameter '%s' already defined in this scope.", p.name),
                p.token, srcLines);
        }

        // Create a placeholder AST Node for the param — 
        // usually params start uninitialized or with a default literal like 'null'
        Node paramNode = createDefaultValueNode(p.type, p);

        func._scope.symbols[p.name] = SymbolInfo(paramNode, false, p.type);
    }

    /// Helper: creates a default AST node based on the type (e.g. zero for int, false for bool)
    Node createDefaultValueNode(TypeName type, ParamInfo p)
    {
        switch (type)
        {
        case TypeName.Int:
            return new IntLiteral(0, p.token);
        case TypeName.Float:
            return new FloatLiteral(0.0, p.token);
        case TypeName.Bool:
            return new BoolLiteral(false, p.token);
        case TypeName.String:
            return new StringLiteral("", p.token);
        default:
            throwChamError(
                format("Unsupported parameter type: '%s'", type.to!string),
                p.token,
                srcLines
            );
            assert(0);
        }
    }

    /// Redefines an existing symbol with a new value, keeping its original type and mutable
    void reDefine(string name, Node newVal)
    {
        Scope current = this;
        while (current !is null)
        {
            if (name in current.symbols)
            {
                TypeName type = current.symbols[name].type;
                current.define(name, type, newVal, false);
                return;
            }
            current = current.parent;
        }
        throwChamError("Cannot reassign undefined variable: " ~ name, newVal, srcLines);
    }

    /// Looks up the AST node of a symbol by name, searching up through parent scopes
    Node lookup(string name)
    {
        if (auto val = name in symbols)
            return val.node;
        else if (parent !is null)
            return parent.lookup(name);
        else
            throw new Exception(format("Undefined symbol: %s", name));
    }


    /// Looks up the body of a function by name, searching through parent scopes too
    FunctionInfo lookUpFunction(string name) {
        if (auto fn = name in functions) {
            return *fn;
        } else if (parent !is null) {
            return parent.lookUpFunction(name);
        } else {
            throwChamError(format("Undefined function being called: %s.", name), null, srcLines);
            assert(0);
        }
    }

    /// Returns whether the symbol is constant, searching up the scope chain
    bool isConst(string name)
    {
        if (auto val = name in symbols)
            return val.isConst;
        else if (parent !is null)
            return parent.isConst(name);
        else
            throw new Exception(format("Undefined symbol: %s", name));
    }

    /// Checks if a symbol exists in this scope or any parent scope
    bool exists(string name)
    {
        return (name in symbols) !is null ||
            (parent !is null && parent.exists(name));
    }

    /// Creates a child scope inheriting this scope as parent, copies source lines for errors
    Scope createChild()
    {
        string combined = join(srcLines, "\n");
        return new Scope(this, combined);
    }

    /// Prints current scope’s symbols for debugging (shows name, node, mutability)
    void dump()
    {
        writeln("ScopeVars {");
        foreach (k, v; symbols)
            writeln("   ", k, " => ", v.node, " (Const: ", v.isConst, ")");
        writeln("}");

        writeln("ScopeFunctions {");
        foreach (k, v; functions)
        {
            writeln("   ", k, " => ", v.params);
        }
        writeln("}");
    }

    /// Template mapping TypeName enum to the corresponding AST node type
    template getType(TypeName type)
    {
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
    void typeCheck(string name, SymbolInfo info)
    {
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
    string getSymbolName(SymbolInfo info)
    {
        foreach (k, v; symbols)
        {
            if (v is info)
                return k;
        }
        return "<unknown>";
    }
}
