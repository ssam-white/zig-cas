const std = @import("std");
const Expression = @import("expression.zig").Expression;

pub fn Factory(comptime T: type) type {
    return struct {
        arena: *std.heap.ArenaAllocator,
        allocator: std.mem.Allocator,
        parent_alloc: std.mem.Allocator,

        const Self = @This();
    
        pub fn init(parent_alloc: std.mem.Allocator) !Self {
            const arena = try parent_alloc.create(std.heap.ArenaAllocator);
            arena.* = std.heap.ArenaAllocator.init(parent_alloc);
            const allocator = arena.*.allocator();
            return .{
                .arena = arena,
                .allocator = allocator,
                .parent_alloc = parent_alloc
            };
        }

        pub fn deinit(self: Self) void {
            self.arena.*.deinit();
            self.parent_alloc.destroy(self.arena);
        }
        

        pub fn create(self: Self, exp: Expression(T)) !*Expression(T) {
            const exp_ptr = try self.allocator.create(Expression(T));
            exp_ptr.* = exp;
            return exp_ptr;
        }

        pub fn allocAll(self: Self, operands: []const Expression(T)) ![]Expression(T) {
            const operands_ptr = try self.alloc(operands.len);
            @memcpy(operands_ptr, operands);
            return operands_ptr;
        }

        pub fn alloc(self: Self, len: usize) ![]Expression(T) {
            return try self.allocator.alloc(Expression(T), len);
        }

        fn GetFactories(comptime tag: Expression(T).Tag) type {
            return std.meta.TagPayload(Expression(T), tag).Factories;
        }

        pub usingnamespace GetFactories(.Variable);
        pub usingnamespace GetFactories(.Const);
        pub usingnamespace GetFactories(.Add);
        pub usingnamespace GetFactories(.Mul);
        pub usingnamespace GetFactories(.Pow);
        pub usingnamespace GetFactories(.Log);
        pub usingnamespace GetFactories(.Div);
        pub usingnamespace GetFactories(.Sub);
        pub usingnamespace GetFactories(.Neg);
    };
}
