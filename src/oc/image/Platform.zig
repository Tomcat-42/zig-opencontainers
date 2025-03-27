const std = @import("std");

pub const Arch = enum {
    amd64,
    @"386",
    arm,
    arm64,
    ppc64le,
    ppc64,
    mips64le,
    mips64,
    mipsle,
    mips,
    s390x,
    wasm,
};

pub const Os = enum {
    android,
    darwin,
    dragonfly,
    freebsd,
    illumos,
    ios,
    js,
    linux,
    netbsd,
    openbsd,
    plan9,
    solaris,
    wasip1,
    windows,
};

pub const Variant = enum {
    // 386, mips, mipsle, mips64, mips64le
    softfloat,
    hardfloat,
    sse,
    // arm
    @"5",
    @"6",
    @"7",
    // amd64
    v1,
    v2,
    v3,
    v4,
    // ppc64, ppc64le
    power8,
    power9,
    // riscv64
    rva20u64,
    rva22u64,
    // wasm
    satconv,
    signext,
};

architecture: Arch,
os: Os,
@"os.version": ?[]const u8 = null,
@"os.features": ?[]const []const u8 = null,
variant: ?Variant = null,
features: ?[]const []const u8 = null,
