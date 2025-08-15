module cham.parsing.nodes.statements.function_def;

import cham.parsing.nodes.ast_node : Node;
import cham.lexing.token.token : Token;
import cham.exceptions.cham_error : throwChamError;
import cham.parsing.nodes.literals.string_literal : StringLiteral;
import std.typecons : Nullable;
import cham.scopes.scopes : Scope, FunctionInfo, ParamInfo, SymbolInfo;
import cham.variables_and_consts.typenames : TypeName, toSting;
import cham.parsing.nodes.statements.if_statement : indent;
import std.format : format;
import std.conv : to;
import std.stdio : writeln;
import std.algorithm.iteration : map; 
import std.array;       
import std.variant;
import std.algorithm;

class FuncDef : Node {
    string name;
    Node[] body;
    ParamInfo[] params;
    Nullable!TypeName retType;
    bool returns;
    Scope _scope;

    this(
        string name,
        Node[] body,
        ParamInfo[] params,
        Nullable!TypeName retType,
        bool returns,
        Scope _scope,
        Token token
    ) {
        super(token);
        this.name    = name;
        this.body    = body;
        this.params  = params;
        this.retType = retType;
        this.returns = returns;
        this._scope  = _scope;
        if (this.retType.isNull()) this.returns = false; // what do you return if there's no return type; 
    }

    override Object eval(Scope _scope) {
        foreach (ParamInfo param; params)
        {
            Node val = this._scope.createDefaultValueNode(param.type, param);
            this._scope.symbols[param.name] = SymbolInfo(val, false, param.type);
        }
        this._scope.defineFunc(this);
        return null;
    }

    override string toString() const {
        string p = "(";
        int i;
        int len = cast(int)params.length;

        string bdy = body
            .map!(n => indent(n.toString()))
            .array
            .join("\n");

        foreach (ParamInfo param; params)
        {
            p ~= param.name;
            p ~= i != (len - 1) ? ", " : ")";
            i++;
        }
        return format(
            "[FunctionDef: %s, params: %s returns?: %s, return type: %s, \nbody: \n %s]", 
            name, 
            p, 
            returns, 
            retType.isNull() ? "nothing" : toSting(retType.get(), cast(Node) this, cast(string[]) this._scope.srcLines),
            bdy
        );
    }
}