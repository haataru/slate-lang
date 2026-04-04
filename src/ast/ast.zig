// Copyright 2026 Slate Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

const std = @import("std");

pub const TokenType = enum {
    fn_keyword,
    let_keyword,
    return_keyword,
    print_keyword,
    ident,
    number,
    lparen,
    rparen,
    lbrace,
    rbrace,
    colon,
    semicolon,
    comma,
    equals,
    eof,
    invalid,
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: u32,
    column: u32,
};

pub const Expression = union(enum) {
    variable_decl: *VariableDecl,
    assignment: *Assignment,
    print_call: *PrintCall,
    return_stmt: *ReturnStmt,
    number_literal: *NumberLiteral,
    identifier: *Identifier,
    block: *Block,
};

pub const VariableDecl = struct {
    name: []const u8,
    value: *Expression,
};

pub const Assignment = struct {
    name: []const u8,
    value: *Expression,
};

pub const PrintCall = struct {
    argument: *Expression,
};

pub const ReturnStmt = struct {
    value: *Expression,
};

pub const NumberLiteral = struct {
    value: i32,
};

pub const Identifier = struct {
    name: []const u8,
};

pub const Block = struct {
    statements: std.ArrayList(*Expression),
};

pub const Function = struct {
    name: []const u8,
    body: std.ArrayList(*Expression),
};

pub const Program = struct {
    functions: std.ArrayList(*Function),
};

pub fn deinit(ast: *Program, allocator: std.mem.Allocator) void {
    for (ast.functions.items) |func| {
        for (func.body.items) |expr| {
            deinitExpression(expr, allocator);
        }
        func.body.deinit(allocator);
        allocator.destroy(func);
    }
    ast.functions.deinit(allocator);
    allocator.destroy(ast);
}

fn deinitExpression(expr: *Expression, allocator: std.mem.Allocator) void {
    switch (expr.*) {
        .variable_decl => |vd| {
            deinitExpression(vd.value, allocator);
            allocator.destroy(vd.value);
            allocator.destroy(vd);
        },
        .assignment => |as| {
            deinitExpression(as.value, allocator);
            allocator.destroy(as.value);
            allocator.destroy(as);
        },
        .print_call => |pc| {
            deinitExpression(pc.argument, allocator);
            allocator.destroy(pc.argument);
            allocator.destroy(pc);
        },
        .return_stmt => |rs| {
            deinitExpression(rs.value, allocator);
            allocator.destroy(rs.value);
            allocator.destroy(rs);
        },
        .number_literal => |nl| {
            allocator.destroy(nl);
        },
        .identifier => |id| {
            allocator.destroy(id);
        },
        .block => |b| {
            for (b.statements.items) |stmt| {
                deinitExpression(stmt, allocator);
            }
            b.statements.deinit(allocator);
            allocator.destroy(b);
        },
    }
}
