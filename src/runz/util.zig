const std = @import("std");
const assert = std.debug.assert;
const builtin = std.builtin;
const linux = std.os.linux;
const log = std.log;

pub inline fn syscall(comptime @"fn": anytype, args: anytype) !usize {
    assert(@typeInfo(@TypeOf(@"fn")) == builtin.Type.@"fn");
    assert(@typeInfo(@TypeOf(args)) == builtin.Type.@"struct" and @typeInfo(@TypeOf(args)).@"struct".is_tuple);

    const result: usize = @intCast(@call(.auto, @"fn", args));

    return ret: switch (linux.E.init(result)) {
        .SUCCESS => {
            log.debug("{s} ({any}) -> {d}", .{ @typeName(@TypeOf(@"fn")), args, result });
            break :ret result;
        },
        else => |errno| {
            log.err("{s} ({any}) -> {any}", .{ @typeName(@TypeOf(@"fn")), args, errno });
            break :ret error.SyscallFailed;
        },
    };
}

pub const sys = @cImport({
    @cInclude("linux/sched.h");
    @cInclude("sys/wait.h");
    @cInclude("sys/stat.h");
    @cInclude("sched.h");
    @cInclude("unistd.h");
    @cInclude("stdlib.h");
    @cInclude("err.h");
    @cInclude("limits.h");
    @cInclude("sched.h");
    @cInclude("signal.h");
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("sys/mman.h");
    @cInclude("sys/mount.h");
    @cInclude("sys/stat.h");
    @cInclude("sys/syscall.h");
    @cInclude("sys/wait.h");
    @cInclude("unistd.h");
});
