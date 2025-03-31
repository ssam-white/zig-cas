const std = @import("std");
const Expression = @import("expression.zig").Expression;

pub fn Factory(comptime T: type) type {
    return struct {
        alloc: std.mem.Allocator,

        const Self = @This();
    
        pub fn init(alloc: std.mem.Allocator)  Self {
            return .{
                .alloc = alloc
            };
        }

        pub fn deinit(self: Self) void {
            _ = self;
        }
        
        pub fn variable(name: []const u8) Expression(T) {
            return .{ .Variable = .{ .name = name } };
        }

        pub fn variableAlloc(self: Self, name: []const u8) !*Expression(T) {
            const exp = try self.alloc.create(Expression(T));
            exp.* = .{ .Variable = .{ .name = name } };
            return exp;
        }

        pub fn constant(value: T) Expression(T) {
            return .{ .Const = .{ .value = value } };
        }

        pub fn constantAlloc(self: Self, value: T) !*Expression(T) {
            const exp = try self.alloc.create(Expression(T));
            exp.* = .{ .Const = .{ .value = value } };
            return exp;
        }

        pub fn addAlloc(self: Self, operands: []const Expression(T)) !*Expression(T) {
            const operands_ptr = try self.alloc.alloc(Expression(T), operands.len);
            operands_ptr.* = operands;
            
            const exp = try self.alloc.create(Expression(T));
            exp.* = .{ .Add = .{ .operands = operands_ptr } };

            return exp;
        }

        pub fn add(operands: []const Expression(T)) !Expression(T) {
            return .{ .Add = .{ .operands = operands } };
        }

        pub fn mulAlloc(self: Self, operands: []const Expression(T)) !*Expression(T) {
            const operands_ptr = try self.alloc.alloc(Expression(T), operands.len);
            @memcpy(operands_ptr, operands);
            
            const exp = try self.alloc.create(Expression(T));
            exp.* = .{ .Mul = .{ .operands = operands_ptr } };

            return exp;
        }

        pub fn pow(base: *Expression(f32), exponent: *Expression(f32)) Expression(f32) {
            return .{ .Pow = .{ .base = base, .exponent = exponent } };
        }

        pub fn powAlloc(self: Self, base: *Expression(T), exponent: *Expression(T)) !*Expression(T) {
            const exp = try self.alloc.create(Expression(T));
            exp.* = .{ .Pow = .{ .base = base, .exponent = exponent } };
            return exp;
        }

        pub fn negAlloc(self: Self, exp: Expression(T)) !*Expression(T) {
            return try self.mul(&.{ .{ .Const = .{ .value = -1 } }, exp });
        }

        pub fn div(num: *Expression(f32), den: *Expression(f32)) Expression(f32) {
            _ = num; _ = den;
        }

        pub fn divAlloc(self: Self, num: Expression(f32), den: Expression(f32)) !*Expression(f32) {
            const base_ptr = try self.alloc.create(Expression(f32));
            base_ptr.* = den;
            const p = .{ .Pow = .{ .base = base_ptr, .exponent = try self.constantAlloc(-1) } };
            return self.mulAlloc(&.{ num, p });
        }
    };
}
