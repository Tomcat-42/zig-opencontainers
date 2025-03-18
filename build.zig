pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const manifest = try zon.parse.fromSlice(
        struct { version: []const u8 },
        b.allocator,
        @embedFile("build.zig.zon"),
        null,
        .{
            .ignore_unknown_fields = true,
        },
    );

    // Modules and Deps
    const oc_mod = b.createModule(.{
        .root_source_file = b.path("src/oc.zig"),
        .target = target,
        .optimize = optimize,
    });
    const runz_mod = b.createModule(.{
        .root_source_file = b.path("src/runz.zig"),
        .target = target,
        .optimize = optimize,
    });

    const oc_deps: []const Import = &.{
        .{
            .name = "config",
            .module = mod: {
                const opts = b.addOptions();
                opts.addOption(SemanticVersion, "version", try SemanticVersion.parse(manifest.version));
                break :mod opts.createModule();
            },
        },
        .{ .name = "oc", .module = oc_mod },
    };
    for (oc_deps) |dep| oc_mod.addImport(dep.name, dep.module);

    const runz_deps: []const Import = &.{
        .{ .name = "runz", .module = runz_mod },
        .{ .name = "oc", .module = oc_mod },
        .{
            .name = "clap",
            .module = b.dependency("clap", .{
                .optimize = optimize,
                .target = target,
            }).module("clap"),
        },
    };
    for (runz_deps) |dep| runz_mod.addImport(dep.name, dep.module);

    // Targets
    const oc = b.addLibrary(.{
        .linkage = .static,
        .name = "oc",
        .root_module = oc_mod,
    });
    const oc_tests = b.addTest(.{
        .root_module = oc_mod,
    });
    const oc_check = b.addLibrary(.{
        .name = "oc_check",
        .root_module = oc_mod,
    });
    const runz = b.addExecutable(.{
        .linkage = .static,
        .link_libc = true,
        .name = "runz",
        .root_module = runz_mod,
    });
    const runz_tests = b.addTest(.{
        .root_module = runz_mod,
    });
    const runz_check = b.addExecutable(.{
        .name = "runz_check",
        .root_module = runz_mod,
    });

    // Install
    b.installArtifact(oc);
    b.installArtifact(runz);

    // Run
    const run_cmd = b.addRunArtifact(runz);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Test
    const run_oc_tests = b.addRunArtifact(oc_tests);
    const run_runz_tests = b.addRunArtifact(runz_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_oc_tests.step);
    test_step.dependOn(&run_runz_tests.step);

    // Clean
    const clean_step = b.step("clean", "Remove build artifacts");
    clean_step.dependOn(&b.addRemoveDirTree(b.path(fs.path.basename(b.install_path))).step);
    if (builtin.os.tag != .windows)
        clean_step.dependOn(&b.addRemoveDirTree(b.path(".zig-cache")).step);

    // Check Step
    const check_step = b.step("check", "Check that the build artifacts are up-to-date");
    check_step.dependOn(&oc_check.step);
    check_step.dependOn(&runz_check.step);
}

const std = @import("std");
const SemanticVersion = std.SemanticVersion;
const zon = std.zon;
const fs = std.fs;
const Build = std.Build;
const Step = Build.Step;
const Module = Build.Module;
const Import = Module.Import;
const builtin = @import("builtin");
