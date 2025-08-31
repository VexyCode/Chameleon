
# Chameleon  ![ChamLogo](./logo.svg)
### An interpreter for the NexiLang programming language, written in [D](https://dlang.org).

---

## 🚀 Features  
- Executes NexiLang (`.nl`) files directly.  
- Written in pure [D](https://dlang.org) for speed and simplicity.  
- Easy to modify and extend — perfect for language experimentation.  
- Lightweight codebase with **no external dependencies**; everything built by hand.

---

## 🛠 Installation

### Clone the repo:  
```bash
git clone https://github.com/VexyCode/Chameleon.git
cd Chameleon
```

### Build with Dub:  
```bash
dub build --build=release
# Or use --build=debug to get detailed debug info.
```
### Verify the install:
```nexilang
./cham --version
```
##### Should log something like:
```
Chameleon Compiler for NexiLang
 Version 0.5.0 - Garnet
```

### Run NexiLang files (`.nl`):  
```bash
./cham /path/to/your/file.nl
```
> _Note: Currently, directory imports aren’t supported. When modules/imports land, this will change — see the roadmap below._

---

## 📝 Example

### Example NexiLang file (`hello.nl`):  
```nexilang
log("Hello, World")
```

### Run it:  
```bash
./cham hello.nl
```

### Output:  
```
Hello, World
```

---

## 🎯 Future Plans

### 1. Must-Have Features (coming soon)  
- **Function definitions** — reusable blocks to keep code clean and DRY.  
- **Structs** — custom data types to model complex structures.  
- **Modules** — organize code into neat namespaces.  
- **Packages** — bundle and distribute reusable code.  
- **Package manager** — seamless package installation and updates.  
- **Basic type system enhancements** — more types & stronger type checking.  
- **Error handling** — graceful and expressive error/exception support.  
- **Control flow** — loops, switch statements.

### 2. Nice-to-Have Features (wishlist)  
- **NexiLang compiler** — ahead-of-time compilation for speed & optimization.  
- **Garbage collection / memory management improvements** — safer, easier memory handling.  
- **Concurrency primitives** — async, threads, or coroutines for parallelism.  
- **Standard library** — utilities, collections, I/O, and more out of the box.  
- **Debugger integration** — source-level debugging tools.  
- **REPL (Read-Eval-Print Loop)** — quick interactive coding sessions.  
- **IDE support & tooling** — VSCode extensions, linting, and code completion.  
- **Foreign Function Interface (FFI)** — call C or other native libs easily.

### 3. Out of Scope (not planned)  
- Heavyweight GUI frameworks — keeping it lean and focused on language core.  
- Built-in ORM/database layers — better left to ecosystem libraries.  
- Full-blown JIT compilation — maybe later, but not right now.

---

> Contributions, issues, and feature requests are welcome! Feel free to jump in and help shape NexiLang and Chameleon.

---

## 📜 License  
This project is licensed under the MIT License — see the [LICENSE](LICENSE.md) file for details.

---

Vexor - out!
