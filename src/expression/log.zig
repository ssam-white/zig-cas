const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

const Allocator = std.mem.Allocator;

pub fn Log(comptime T: type) type {
    return struct {
        b: *Expression(T),
        x: *Expression(T),

        const Self = @This();

        pub fn initExp(b: *Expression(T), x: *Expression(T)) Expression(T) {
            return .log(b, x);
        }

        pub fn isLn(self: Self) bool {
            return self.b.*.eqlStructure(.constant(std.math.e));
        }
        
        pub fn eval(self: Self, args: Expression(T).Args) T {
            const b = self.b.*.eval(args);
            const x = self.x.*.eval(args);
            return std.math.log(T, b, x);
        }

        pub fn print(self: Self) void {
            if (self.isLn()) {
                std.debug.print("Ln(", .{});
            } else {
                std.debug.print("Log(", .{});
                self.b.*.print();
                std.debug.print(", ", .{});
            }


            self.x.*.print();
            std.debug.print(")", .{});
        }


        fn changeBaseD(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            return .div(
                try factory.lnPtr(self.x),
                try factory.lnPtr(self.b)
            ).d(var_name, factory);
        }

        fn logD(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            return .div(
                try factory.create(try self.x.*.d(var_name, factory)),
                try factory.create(self.x.*)
            );
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            return if (self.isLn()) try self.logD(var_name, factory)
            else try self.changeBaseD(var_name, factory);
        }

        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            const simple_b = try self.b.*.rewrite(factory);
            const simple_x = try self.x.*.rewrite(factory);

            return if (
                (simple_b.eqlStructure(.constant(0))) or
                (simple_x.eqlStructure(.constant(1)))
            )
                .constant(0)
            else if (simple_b.eqlStructure(simple_x))
                .constant(1)
            else .log(
                try factory.create(simple_b),
                try factory.create(simple_x)
            );
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Log) return false;
            
            const eql_b_structure = self.b.*.eqlStructure(exp.Log.b.*);
            const eql_x_structure = self.x.*.eqlStructure(exp.Log.x.*);
            return eql_b_structure and eql_x_structure;
        }

        pub const Factories = struct {
            pub fn logPtr(factory: Factory(T), b: *Expression(T), x: *Expression(T)) !*Expression(T) {
                return try factory.logPtr(.log(b, x));
            }

            pub fn ln(factory: Factory(T), x: *Expression(T)) !Expression(T) {
                return .log(try factory.constantPtr(std.math.e), x);
            }

            pub fn lnPtr(factory: Factory(T), x: *Expression(T)) !*Expression(T) {
                const e = try factory.constantPtr(std.math.e);
                return try factory.logPtr(e, x);
            }
        };
    };
}
