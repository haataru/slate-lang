// Copyright 2026 Slate Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

const std = @import("std");
const ast = @import("../ast/ast.zig");
const Token = ast.Token;
const TokenType = ast.TokenType;

pub const ParseError = error{
    UnexpectedToken,
    InvalidNumber,
    OutOfMemory,
    ExpectedIdentifier,
    VariableNotFound,
};

pub const Parser = struct {
    tokens: std.ArrayList(Token),
    current: usize = 0,
    allocator: std.mem.Allocator,

    pub fn init(tokens: std.ArrayList(Token), allocator: std.mem.Allocator) Parser {
        return .{ .tokens = tokens, .allocator = allocator };
    }

    pub fn parse(self: *Parser) ParseError!*ast.Program {
        var program = try self.allocator.create(ast.Program);
        program.* = .{ .functions = try std.ArrayList(*ast.Function).initCapacity(self.allocator, 8) };

        while (!self.isAtEnd()) {
            const func = try self.parseFunction();
            try program.functions.append(self.allocator, func);
        }
        return program;
    }

    fn parseFunction(self: *Parser) ParseError!*ast.Function {
        try self.expect(.fn_keyword);
        const name = self.expectIdent();
        try self.expect(.lparen);
        try self.expect(.rparen);
        try self.expect(.lbrace);

        var body = try std.ArrayList(*ast.Expression).initCapacity(self.allocator, 16);

        while (!self.check(.rbrace)) {
            const expr = try self.parseStatement();
            try body.append(self.allocator, expr);
        }

        try self.expect(.rbrace);

        const func = try self.allocator.create(ast.Function);
        func.* = .{ .name = name, .body = body };
        return func;
    }

    fn parseStatement(self: *Parser) ParseError!*ast.Expression {
        if (self.check(.let_keyword)) return try self.parseVariableDecl();
        if (self.check(.print_keyword)) return try self.parsePrintCall();
        if (self.check(.return_keyword)) return try self.parseReturnStmt();
        if (self.check(.ident)) return try self.parseAssignmentOrIdent();
        if (self.check(.lbrace)) return try self.parseBlock();

        return error.UnexpectedToken;
    }

    fn parseVariableDecl(self: *Parser) ParseError!*ast.Expression {
        _ = self.advance(); // let
        const name = self.expectIdent();

        // Тип опционален
        if (self.check(.colon)) {
            _ = self.advance(); // пропускаем :
            _ = self.expectIdent(); // пропускаем тип
        }

        try self.expect(.equals);
        const value = try self.parseExpression();

        const vd = try self.allocator.create(ast.VariableDecl);
        vd.* = .{ .name = name, .value = value };

        const expr = try self.allocator.create(ast.Expression);
        expr.* = .{ .variable_decl = vd };
        return expr;
    }

    fn parseAssignmentOrIdent(self: *Parser) ParseError!*ast.Expression {
        const name = self.expectIdent();
        if (self.check(.equals)) {
            _ = self.advance();
            const value = try self.parseExpression();
            const as = try self.allocator.create(ast.Assignment);
            as.* = .{ .name = name, .value = value };
            const expr = try self.allocator.create(ast.Expression);
            expr.* = .{ .assignment = as };
            return expr;
        }
        const id = try self.allocator.create(ast.Identifier);
        id.* = .{ .name = name };
        const expr = try self.allocator.create(ast.Expression);
        expr.* = .{ .identifier = id };
        return expr;
    }

    fn parseBlock(self: *Parser) ParseError!*ast.Expression {
        try self.expect(.lbrace);
        var statements = try std.ArrayList(*ast.Expression).initCapacity(self.allocator, 8);

        while (!self.check(.rbrace)) {
            const stmt = try self.parseStatement();
            try statements.append(self.allocator, stmt);
        }
        try self.expect(.rbrace);

        const b = try self.allocator.create(ast.Block);
        b.* = .{ .statements = statements };
        const expr = try self.allocator.create(ast.Expression);
        expr.* = .{ .block = b };
        return expr;
    }

    fn parsePrintCall(self: *Parser) ParseError!*ast.Expression {
        _ = self.advance(); // print
        try self.expect(.lparen);
        const arg = try self.parseExpression();
        try self.expect(.rparen);

        const pc = try self.allocator.create(ast.PrintCall);
        pc.* = .{ .argument = arg };

        const expr = try self.allocator.create(ast.Expression);
        expr.* = .{ .print_call = pc };
        return expr;
    }

    fn parseReturnStmt(self: *Parser) ParseError!*ast.Expression {
        _ = self.advance(); // return
        const value = try self.parseExpression();

        const rs = try self.allocator.create(ast.ReturnStmt);
        rs.* = .{ .value = value };

        const expr = try self.allocator.create(ast.Expression);
        expr.* = .{ .return_stmt = rs };
        return expr;
    }

    fn parseExpression(self: *Parser) ParseError!*ast.Expression {
        if (self.check(.number)) return try self.parseNumberLiteral();
        if (self.check(.ident)) return try self.parseAssignmentOrIdent();
        return error.UnexpectedToken;
    }

    fn parseNumberLiteral(self: *Parser) ParseError!*ast.Expression {
        const token = self.advance();
        const value = std.fmt.parseInt(i32, token.lexeme, 10) catch return error.InvalidNumber;

        const nl = try self.allocator.create(ast.NumberLiteral);
        nl.* = .{ .value = value };

        const expr = try self.allocator.create(ast.Expression);
        expr.* = .{ .number_literal = nl };
        return expr;
    }

    // Helpers
    fn isAtEnd(self: *Parser) bool {
        return self.peek().type == .eof;
    }

    fn check(self: *Parser, t: TokenType) bool {
        if (self.isAtEnd()) return false;
        return self.peek().type == t;
    }

    fn peek(self: *Parser) Token {
        return self.tokens.items[self.current];
    }

    fn advance(self: *Parser) Token {
        if (!self.isAtEnd()) self.current += 1;
        return self.tokens.items[self.current - 1];
    }

    fn expect(self: *Parser, t: TokenType) ParseError!void {
        if (self.check(t)) {
            _ = self.advance();
        } else {
            return error.UnexpectedToken;
        }
    }

    fn expectIdent(self: *Parser) []const u8 {
        const token = self.advance();
        return token.lexeme;
    }
};
