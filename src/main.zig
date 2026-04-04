// Copyright 2026 Slate Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

const std = @import("std");
const lexer = @import("lexer/lexer.zig");
const parser = @import("parser/parser.zig");
const interpreter = @import("interpreter/interpreter.zig");
const utils = @import("utils/utils.zig");
const ast = @import("ast/ast.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: slatec <input.sl>\n", .{});
        return error.InvalidArguments;
    }

    const input_file = args[1];
    const source = try utils.readFile(input_file, allocator);
    defer allocator.free(source);

    var lex = lexer.Lexer.init(source, allocator);
    var tokens = try lex.tokenize();
    defer tokens.deinit(allocator);

    var par = parser.Parser.init(tokens, allocator);
    const program = try par.parse();
    defer ast.deinit(program, allocator);

    var interp = try interpreter.Interpreter.init(allocator);
    defer interp.deinit();

    try interp.interpret(program);
}
