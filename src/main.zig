const std = @import("std");
const lexer = @import("lexer/lexer.zig");
const parser = @import("parser/parser.zig");
const codegen = @import("codegen/codegen.zig");
const utils = @import("utils/utils.zig");
const ast = @import("ast/ast.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: slatec <input.sl> [-o output]\n", .{});
        return error.InvalidArguments;
    }

    const input_file = args[1];
    const output_file = if (args.len >= 4 and std.mem.eql(u8, args[2], "-o")) args[3] else "a.out";

    const source = try utils.readFile(input_file, allocator);
    defer allocator.free(source);

    var lex = lexer.Lexer.init(source, allocator);
    var tokens = try lex.tokenize();
    defer tokens.deinit(allocator);

    var par = parser.Parser.init(tokens, allocator);
    const program = try par.parse();
    defer ast.deinit(program, allocator);

    const assembly_code = try codegen.compileToAssembly(program, allocator);
    defer allocator.free(assembly_code);

    const asm_file = try std.fmt.allocPrint(allocator, "{s}.s", .{output_file});
    defer allocator.free(asm_file);

    try utils.writeFile(asm_file, assembly_code);

    const runtime_file = try std.fmt.allocPrint(allocator, "{s}_runtime.s", .{output_file});
    defer allocator.free(runtime_file);

    const runtime_out = try std.fs.cwd().createFile(runtime_file, .{});
    defer runtime_out.close();
    try codegen.writeRuntime(runtime_out);

    var child = std.process.Child.init(&.{ "gcc", asm_file, runtime_file, "-o", output_file }, allocator);
    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    const term = try child.spawnAndWait();

    if (term != .Exited or term.Exited != 0) {
        std.debug.print("Linker error\n", .{});
        return error.LinkerFailed;
    }

    std.debug.print("Compiled successfully: {s}\n", .{output_file});
}
