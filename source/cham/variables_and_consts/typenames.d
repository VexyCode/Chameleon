module cham.variables_and_consts.typenames;

import cham.parsing.nodes.ast_node : Node;
import cham.exceptions.cham_error : throwChamError;
import std.format : format;

/// Enum for the basic type names supported in NexiLang
enum TypeName
{
    Int,
    Float,
    Bool,
    String,
}

/// Converts a string type name (like "int") to the corresponding TypeName enum.
/// Throws a ChamError if the type name is unknown.
TypeName fromString(string type_name, Node n, string[] srcLines)
{
    switch (type_name)
    {
    case "int":
        return TypeName.Int;
    case "float":
        return TypeName.Float;
    case "bool":
        return TypeName.Bool;
    case "string":
        return TypeName.String;
    default:
        throwChamError(format("Unknown type name: %s", type_name), n, srcLines);
        assert(0); // unreachable
    }
}

/// Converts a TypeName enum value back to its string representation.
/// Throws a ChamError if the type is unknown.
///
/// NOTE: function name is a typo (toSting vs toString)
string toSting(TypeName type, Node n, string[] srcLines)
{
    switch (type)
    {
    case TypeName.Int:
        return "int";
    case TypeName.Float:
        return "float";
    case TypeName.Bool:
        return "bool";
    case TypeName.String:
        return "string";
    default:
        throwChamError(format("Unknown type name: %s", type), n, srcLines);
        assert(0); // unreachable
    }
}

string toString(TypeName type)
{
    final switch (type)
    {
    case TypeName.Int:
        return "int";
    case TypeName.Float:
        return "float";
    case TypeName.Bool:
        return "bool";
    case TypeName.String:
        return "char*";
    }
}

TypeName toTypeName(Node n, string[] src)
{
    import cham.parsing.nodes.literals.bool_literal;
    import cham.parsing.nodes.literals.float_literal;
    import cham.parsing.nodes.literals.int_literal;
    import cham.parsing.nodes.literals.string_literal;

    if (cast(IntLiteral) n)
        return TypeName.Int;
    else if (cast(FloatLiteral) n)
        return TypeName.Float;
    else if (cast(StringLiteral) n)
        return TypeName.String;
    else if (cast(BoolLiteral) n)
        return TypeName.Bool;
    else
    {
        throwChamError("Unknown type " ~ typeid(n).toString(), n, src);
        assert(0);
    }
}
