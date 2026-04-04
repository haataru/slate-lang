// Copyright 2026 Slate Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

const std = @import("std");
const Token = @import("../ast/ast.zig").Token;
const TokenType = @import("../ast/ast.zig").TokenType;

pub const Lexer = struct {
    source: []const u8,
    current: usize = 0,
    line: u32 = 1,
    column: u32 = 1,
    allocator: std.mem.Allocator,

    pub fn init(source: []const u8, allocator: std.mem.Allocator) Lexer {
        return .{
            .source = source,
            .allocator = allocator,
        };
    }

    pub fn tokenize(self: *Lexer) !std.ArrayList(Token) {
        var tokens = try std.ArrayList(Token).initCapacity(self.allocator, 64);
        errdefer tokens.deinit(self.allocator);

        while (!self.isAtEnd()) {
            try self.scanToken(&tokens);
        }

        try tokens.append(self.allocator, .{
            .type = .eof,
            .lexeme = "",
            .line = self.line,
            .column = self.column,
        });

        return tokens;
    }

    fn scanToken(self: *Lexer, tokens: *std.ArrayList(Token)) !void {
        const c = self.advance();

        switch (c) {
            '(' => try self.addToken(tokens, .lparen),
            ')' => try self.addToken(tokens, .rparen),
            '{' => try self.addToken(tokens, .lbrace),
            '}' => try self.addToken(tokens, .rbrace),
            ':' => try self.addToken(tokens, .colon),
            ';' => try self.addToken(tokens, .semicolon),
            '=' => try self.addToken(tokens, .equals),
            ',' => try self.addToken(tokens, .comma),
            ' ', '\t', '\r' => {},
            '\n' => {
                self.line += 1;
                self.column = 1;
            },
            else => {
                if (self.isDigit(c)) {
                    try self.number(tokens);
                } else if (self.isAlpha(c)) {
                    try self.identifier(tokens);
                } else {
                    return error.InvalidCharacter;
                }
            },
        }
    }

    fn advance(self: *Lexer) u8 {
        const c = self.source[self.current];
        self.current += 1;
        self.column += 1;
        return c;
    }

    fn peek(self: *Lexer) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn isDigit(_: *Lexer, c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isAlpha(_: *Lexer, c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
    }

    fn isAlphaNumeric(self: *Lexer, c: u8) bool {
        return self.isAlpha(c) or self.isDigit(c);
    }

    fn number(self: *Lexer, tokens: *std.ArrayList(Token)) !void {
        const start = self.current - 1;
        while (self.isDigit(self.peek())) {
            _ = self.advance();
        }

        const lexeme = self.source[start..self.current];
        try tokens.append(self.allocator, .{
            .type = .number,
            .lexeme = lexeme,
            .line = self.line,
            .column = self.column - @as(u32, @intCast(lexeme.len)),
        });
    }

    fn identifier(self: *Lexer, tokens: *std.ArrayList(Token)) !void {
        const start = self.current - 1;
        while (self.isAlphaNumeric(self.peek())) {
            _ = self.advance();
        }

        const lexeme = self.source[start..self.current];
        const token_type = keywordType(lexeme);

        try tokens.append(self.allocator, .{
            .type = token_type,
            .lexeme = lexeme,
            .line = self.line,
            .column = self.column - @as(u32, @intCast(lexeme.len)),
        });
    }

    fn keywordType(lexeme: []const u8) TokenType {
        if (std.mem.eql(u8, lexeme, "fn")) return .fn_keyword;
        if (std.mem.eql(u8, lexeme, "let")) return .let_keyword;
        if (std.mem.eql(u8, lexeme, "return")) return .return_keyword;
        if (std.mem.eql(u8, lexeme, "print")) return .print_keyword;
        if (std.mem.eql(u8, lexeme, "i32")) return .ident;
        return .ident;
    }

    fn addToken(self: *Lexer, tokens: *std.ArrayList(Token), token_type: TokenType) !void {
        try tokens.append(self.allocator, .{
            .type = token_type,
            .lexeme = "",
            .line = self.line,
            .column = self.column,
        });
    }
};
