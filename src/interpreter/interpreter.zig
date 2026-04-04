// Copyright 2026 Slate Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

const std = @import("std");
const ast = @import("../ast/ast.zig");

pub const Interpreter = struct {
    memory: []u8,
    sp: usize = 0,
    hp: usize,
    symbols: std.StringHashMap(usize),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Interpreter {
        const mem = try allocator.alloc(u8, 64 * 1024);
        return .{
            .memory = mem,
            .hp = mem.len / 2,
            .symbols = std.StringHashMap(usize).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Interpreter) void {
        self.symbols.deinit();
        self.allocator.free(self.memory);
    }

    pub fn interpret(self: *Interpreter, program: *ast.Program) !void {
        for (program.functions.items) |func| {
            if (std.mem.eql(u8, func.name, "main")) {
                try self.evalFunction(func);
                return;
            }
        }
    }

    fn evalFunction(self: *Interpreter, func: *ast.Function) !void {
        const old_sp = self.sp;
        defer self.sp = old_sp;
        self.symbols.clearRetainingCapacity();

        for (func.body.items) |expr| {
            _ = try self.evalExpression(expr);
        }
    }

    const Value = union(enum) {
        int: i32,
    };

    fn evalExpression(self: *Interpreter, expr: *ast.Expression) !Value {
        switch (expr.*) {
            .number_literal => |nl| return .{ .int = nl.value },

            .identifier => |id| {
                const offset = self.symbols.get(id.name) orelse return error.VariableNotFound;
                const val = std.mem.readInt(i32, self.memory[offset..][0..4], .little);
                return .{ .int = val };
            },

            .variable_decl => |vd| {
                const val = try self.evalExpression(vd.value);
                const offset = self.sp;
                try self.symbols.put(vd.name, offset);

                std.mem.writeInt(i32, self.memory[offset..][0..4], val.int, .little);
                self.sp += 4;
                return val;
            },

            .assignment => |as| {
                const val = try self.evalExpression(as.value);
                const offset = self.symbols.get(as.name) orelse return error.VariableNotFound;

                std.mem.writeInt(i32, self.memory[offset..][0..4], val.int, .little);
                return val;
            },

            .print_call => |pc| {
                const val = try self.evalExpression(pc.argument);
                std.debug.print("{}\n", .{val.int});
                return val;
            },

            .return_stmt => |rs| return try self.evalExpression(rs.value),

            .block => |b| {
                const old_sp = self.sp;
                defer self.sp = old_sp;
                for (b.statements.items) |stmt| {
                    _ = try self.evalExpression(stmt);
                }
                return .{ .int = 0 };
            },
        }
    }
};
