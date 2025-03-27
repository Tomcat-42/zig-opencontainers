const std = @import("std");
const mem = std.mem;
const process = std.process;
const log = std.log;

const clap = @import("clap");

const runz = @import("runz");
const util = runz.util;

const params = clap.parseParamsComptime(
    \\-h, --help         Print this message and exit
    \\<str>              The container image to pull
);
const Args = clap.ResultEx(clap.Help, &params, clap.parsers.default);

allocator: mem.Allocator,
image: []const u8,

pub fn init(allocator: mem.Allocator, args: *process.ArgIterator) !@This() {
    var options = clap.parseEx(
        clap.Help,
        &params,
        clap.parsers.default,
        args,
        .{
            .diagnostic = null,
            .allocator = allocator,
        },
    ) catch usage();
    defer options.deinit();

    if (options.args.help != 0) help();
    const image = options.positionals[0] orelse usage();

    return @This(){
        .allocator = allocator,
        .image = image,
    };
}

pub fn deinit(this: *@This()) void {
    _ = this; // autofix
    @panic("not implemented");
}

pub fn run(this: *const @This()) !void {
    _ = this; // autofix
    @panic("not implemented");
}

inline fn usage() noreturn {
    clap.usage(runz.stderr, clap.Help, &params) catch @panic("failed to write usage message");
    runz.stderr.writeByte('\n') catch @panic("failed to write newline");
    process.exit(0);
}

inline fn help() noreturn {
    clap.help(runz.stdout, clap.Help, &params, .{
        .markdown_lite = false,
        .spacing_between_parameters = 1,
        .description_on_new_line = true,
        .description_indent = 2,
        .indent = 2,
    }) catch @panic("failed to write help message");
    runz.stdout.writeByte('\n') catch @panic("failed to write newline");
    process.exit(0);
}
