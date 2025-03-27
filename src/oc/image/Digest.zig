const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const json = std.json;
const meta = std.meta;

pub const Algorithm = enum { sha256, sha512 };

algorithm: Algorithm,
data: []const u8,

pub fn format(this: *const @This(), comptime _: []const u8, _: fmt.FormatOptions, writer: anytype) !void {
    return writer.print("{s}:{s}", .{ @tagName(this.algorithm), this.data });
}

pub fn jsonStringify(this: *const @This(), jws: anytype) !void {
    try jws.print("\"{s}:{s}\"", .{ @tagName(this.algorithm), this.data });
}

pub fn jsonParse(_: mem.Allocator, source: anytype, _: json.ParseOptions) !@This() {
    return val: switch (try source.next()) {
        inline .string, .allocated_string => |s| {
            var it = mem.tokenizeScalar(u8, s, ':');

            const algorithm = meta.stringToEnum(Algorithm, it.next() orelse break :val error.UnexpectedEndOfInput) orelse return error.InvalidEnumTag;
            const data = it.next() orelse break :val error.UnexpectedToken;

            break :val .{
                .algorithm = algorithm,
                .data = data,
            };
        },
        else => break :val error.UnexpectedToken,
    };
}

pub fn jsonParseFromValue(_: mem.Allocator, source: json.Value, _: json.ParseOptions) !@This() {
    return val: switch (source) {
        .string => |s| {
            var it = mem.tokenizeScalar(u8, s, ':');

            const str = it.next() orelse break :val error.InvalidCharacter;
            const algorithm = meta.stringToEnum(Algorithm, str) orelse return error.InvalidEnumTag;
            const data = it.next() orelse break :val error.InvalidCharacter;

            break :val .{
                .algorithm = algorithm,
                .data = data,
            };
        },
        else => break :val error.UnexpectedToken,
    };
}

test "stringify" {
    const expectEqualDeep = std.testing.expectEqualDeep;
    const allocator = std.testing.allocator;

    const digest: @This() = .{
        .algorithm = .sha256,
        .data = "b5b2b2c507a0944348e0303114d8d93aaaa081732b86451d9bce1f432a537bc7",
    };

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    _ = try json.stringify(digest, .{}, buffer.writer());
    const expected =
        \\"sha256:b5b2b2c507a0944348e0303114d8d93aaaa081732b86451d9bce1f432a537bc7"
    ;

    try expectEqualDeep(expected, buffer.items);
}

test "parse" {
    const expectEqualDeep = std.testing.expectEqualDeep;
    const allocator = std.testing.allocator;

    const expected: @This() = .{
        .algorithm = .sha256,
        .data = "b5b2b2c507a0944348e0303114d8d93aaaa081732b86451d9bce1f432a537bc7",
    };

    const input =
        \\"sha256:b5b2b2c507a0944348e0303114d8d93aaaa081732b86451d9bce1f432a537bc7"
    ;

    var scanner = json.Scanner.initCompleteInput(allocator, input);
    defer scanner.deinit();

    const actual = try json.innerParse(@This(), allocator, &scanner, .{});
    try expectEqualDeep(expected, actual);
}
