define hi(string who) string run
    return "Hi, " + who + "!"
end

define logln(string message) string run
    log(message)
    log("\n")
end

var string name = prompt("Enter your name: ", yes)
logln(hi(name))

