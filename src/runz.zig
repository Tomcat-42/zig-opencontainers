const params = clap.parseParamsComptime(
    \\-v, --verbosity Verbosity level
    \\-V, --version   Print version and exit
    \\-h, --help      Print this message and exit
    \\<command>
    \\    run <path> <cmd> [args...]
    \\    Run a container
);
const Command = enum { help, version, run };
const parsers = .{ .command = clap.parsers.enumeration(Command) };
const Args = clap.ResultEx(clap.Help, &params, &parsers);

pub fn main() !void {
    var debug_allocator: heap.DebugAllocator(.{}) = .init;
    const gpa, const is_debug = gpa: {
        if (builtin.os.tag == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) switch (debug_allocator.deinit()) {
        .leak => @panic("memory leak detected"),
        .ok => {},
    };
    var arena = heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const ally = arena.allocator();

    var iter = try process.ArgIterator.initWithAllocator(ally);
    _ = iter.next();

    const options = clap.parseEx(clap.Help, &params, &parsers, &iter, .{
        .diagnostic = null,
        .allocator = ally,
        .terminating_positional = 0,
    }) catch usage();

    if (options.args.help != 0) return help();
    if (options.args.version != 0) return help();

    const logLevel: log.Level = @enumFromInt(options.args.verbosity);
    _ = logLevel; // autofix

    const command = switch (options.positionals[0] orelse usage()) {
        .help => return help(),
        .version => return version(),
        .run => try Run.init(ally, &iter),
    };
    return command.run();
}

const stdout = io.getStdOut().writer();
const stderr = io.getStdErr().writer();

inline fn usage() noreturn {
    clap.usage(stderr, clap.Help, &params) catch @panic("failed to write usage message");
    stderr.writeByte('\n') catch @panic("failed to write newline");
    process.exit(0);
}

inline fn help() noreturn {
    clap.help(stdout, clap.Help, &params, .{}) catch @panic("failed to write help message");
    stdout.writeByte('\n') catch @panic("failed to write newline");
    process.exit(0);
}

inline fn version() !void {
    try stdout.print("{any}\n", .{oc.config.version});
    process.exit(0);
}

const Run = @import("runz/Run.zig");
const std = @import("std");
const process = std.process;
const io = std.io;
const log = std.log;
const heap = std.heap;
const builtin = @import("builtin");
const clap = @import("clap");
const oc = @import("oc");
