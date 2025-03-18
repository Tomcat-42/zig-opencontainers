const params = clap.parseParamsComptime(
    \\-h, --help      Print this message and exit
    \\<str>           The path to the chroot directory
    \\<str>...        The cmd (and its arguments) to run in the chroot
);
const Args = clap.ResultEx(clap.Help, &params, clap.parsers.default);

path: [*:0]const u8,
cmd: [*:null]const ?[*:0]const u8,

pub fn init(allocator: mem.Allocator, args: *process.ArgIterator) !@This() {
    const options = clap.parseEx(
        clap.Help,
        &params,
        clap.parsers.default,
        args,
        .{
            .diagnostic = null,
            .allocator = allocator,
        },
    ) catch usage();
    if (options.args.help != 0) help();

    const path = options.positionals[0] orelse usage();
    if (options.positionals[1].len == 0) usage();

    return @This(){
        .path = try allocator.dupeZ(u8, path),
        .cmd = cmd: {
            const cmd = try allocator.allocSentinel(?[*:0]const u8, options.positionals[1].len, null);
            for (0..options.positionals[1].len) |i| cmd[i] = try allocator.dupeZ(u8, options.positionals[1][i]);
            break :cmd cmd;
        },
    };
}

pub fn run(this: *const @This()) !void {
    std.debug.print("{?s}\n", .{this.cmd[0]});

    const pid = linux.fork();
    log.debug("fork() -> {d}", .{pid});

    if (pid != 0) {
        var status: u32 = undefined;
        const waitpid = linux.waitpid(-1, &status, 0);
        log.debug("waitpid({d}, &status, 0) -> {d}, status {d}", .{ pid, waitpid, status });
        return;
    }

    const res = linux.chroot(@ptrCast(this.path));
    log.debug("chroot({s}) -> {d}", .{ this.path, res });

    const execve = linux.execve(
        this.cmd[0].?,
        this.cmd,
        &[_:null]?[*:0]const u8{}, // TODO: pass env map to container
    );
    log.debug("execve({?s}) -> {d}", .{ this.cmd[0], execve });
}

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

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

const mem = std.mem;
const log = std.log;
const clap = @import("clap");
const runz = @import("runz");
const std = @import("std");
const process = std.process;
const linux = std.os.linux;
const json = std.json;
