import std.stdio;
import std.file : readText, exists, write;
import std.format : format;

import cham.lexing.lexer.lexer : Lexer;
import cham.lexing.token.token : Token;
import cham.parsing.parser.parser : Parser;
import cham.parsing.nodes.ast_node : Node;
import cham.interpreting.interpreter : Interpreter;
import cham.exceptions.cham_error : ChamError;
import std.string : strip, toLower;
import cham.builtins : BuiltIns;

void main(string[] args)
{
    try {
        const string vrs = "0.5.0";
        const string code_name = "Garnet";

        BuiltIns.initialize();

        // gotta have a filename argument or nah
        if (args.length < 2) {
            throw new Exception("No file provided. Usage: cham <filename>");
        }

        string content = "";

        if (args[1] == "--version") {
            writefln("Chameleon Compiler for NexiLang.\n Version %s - %s", vrs, code_name);
            return;
        }

        // read file content if exists, else roast user with a bozo message
        if (exists(args[1])) {
            content = readText(args[1]);
        } else {
            throw new Exception(format("File \"%s\" doesn't exist. Please use a valid file next time. Bozo!", args[1]));
        }

        debug {
            writeln("File content length: ", content.length);
            if (content.length == 0) {
                writeln("Warning: file is empty!");
            }
        }

        // === LEXING ===
        debug writeln("starting lexer");
        Lexer lexer = new Lexer(content);
        lexer.lex();
        debug lexer.printTokens();
        Token[] tokens = lexer.tokens;
        debug writeln("ended lexer"); 

        // === PARSING ===
        Parser parser = new Parser(tokens, content);
        Node[] nodes = parser.parse();
        debug {
            writeln("\nAST Nodes for input ", args[1], ":");
            parser.printNodes();
        }

        // === INTERPRETING ===
        debug writeln("\nResult:");
        Interpreter interpreter = new Interpreter(nodes, parser.mainScope);
        interpreter.run();
    } catch (ChamError e) {
        printNiceError(e);
    }
}


/// Nicely formats and prints errors coming from the language runtime
void printNiceError(Exception e) {
    import std.string : strip;

    if (auto ce = cast(ChamError) e) {
        writeln("\x1b[31mError:");
        writeln("   -> ", ce.msg.strip());
        writeln("   Line: ", ce.line, ", Column: ", ce.column);
        writeln("   Source: ", ce.sourceLine.strip(), "\x1b[0m");
        if (ce.column > 0) {
            // little caret pointing to error column
            writeln("\x1b[31m            ", repeat(' ', ce.column - 1), "^ here\x1b[0m");
        }
        debug {
            writeln("\n   -> Full stack trace:\n----------------");
            writeln(e.toString());
            writeln("----------------\x1b[0m");
        }
    } else {
        // fallback for random exceptions
        writeln("\x1b[31Internal Error:");
        writeln("   -> ", e.msg);
        debug {
            writeln("\n   -> Full stack trace:\n----------------");
            writeln(e.toString());
            writeln("----------------\x1b[0m");
        }
    }
}

/// Helper to create a string of repeated chars (used for the error caret)
string repeat(char c, size_t count) {
    import std.array : appender;
    auto buf = appender!string();
    foreach (_; 0 .. count) {
        buf.put(c);
    }
    return buf.data;
}
