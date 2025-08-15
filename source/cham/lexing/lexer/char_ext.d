module cham.lexing.lexer.char_ext;

import std.algorithm.searching : canFind;
import std.string : toLower;

/// Checks if a single character is a "small" operator, like +, -, *, /, etc.
/// These are typically single-char operators used in expressions.
bool isSmallOp(char c) {
    return ['+', '-', '*', '/', '#', '%', '=', '!'].canFind(c);
}

/// Checks if a string is a valid operator token, including compound ops like "+=", "**=", "&&", etc.
/// This is used to detect multi-char operators during lexing.
bool isOp(string c) {
    return [
        "**=",
        "+=",
        "-=",
        "/=",
        "*=",
        "#=",
        "%=",
        "**",
        "<=",
        ">=",
        "!=",
        "&&",
        "||",
        "==",
        "+",
        "-",
        "/",
        "*",
        "#",
        "<",
        ">",
        "!",
        "=",
    ].canFind(c);
}

/// Checks if a character is punctuation relevant to the language syntax.
/// Includes parentheses, semicolon, dot, and comma.
bool isPunct(char c) {
    return c == '(' || c == ')' || c == '.' || c == ',';
}

/// A map of NexiLang keywords for quick lookup during lexing.
/// Value is unused (empty string) just to leverage keys as the set.
immutable string[string] keywords = 
    [
        "var"   : "",
        "if"    : "", 
        "else"  : "", 
        "run"   : "", 
        "end"   : "", 
        "const" : "", 
        "yes"   : "", 
        "no"    : "", 
        "true"  : "", 
        "false" : "",
        "define": "",
        "return": "",
    ];

/// Returns true if the given string (case-sensitive) is a keyword.
bool isKeyword(string c) {
    return (c in keywords) != null;
}

/// A map of recognized type names for quick lookup.
/// Useful when lexing or parsing to identify type tokens.
immutable string[string] typeNames = 
    ["int" : "", "bool": "", "string": "", "float": ""];

/// Returns true if the given string (case-sensitive) is a recognized type name.
bool isTypeName(string c) {
    return (c in typeNames) != null;
}
