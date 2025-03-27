const std = @import("std");
const assert = std.debug.assert;
const builtin = std.builtin;

const Run = @import("Command/Run.zig");
const Pull = @import("Command/Pull.zig");

pub const Tag = enum { run, pull };
const Data = union { run: Run, pull: Pull };

tag: Tag,
data: Data,

pub fn init(tag: Tag, args: anytype) !@This() {
    assert(@typeInfo(@TypeOf(args)) == builtin.Type.@"struct" and @typeInfo(@TypeOf(args)).@"struct".is_tuple);
    return .{
        .tag = tag,
        .data = switch (tag) {
            .run => .{ .run = try @call(.auto, Run.init, args) },
            .pull => .{ .pull = try @call(.auto, Pull.init, args) },
        },
    };
}

pub fn deinit(this: *@This()) void {
    switch (this.tag) {
        .run => this.data.run.deinit(),
        .pull => this.data.pull.deinit(),
    }
}

pub fn run(this: *@This()) !void {
    return switch (this.tag) {
        .run => this.data.run.run(),
        .pull => this.data.pull.run(),
    };
}
