const std = @import("std");
const mem = std.mem;
const json = std.json;

const oc = @import("oc");
const image = oc.image;

schemaVersion: image.SchemaVersion = .@"2",
mediaType: image.MediaType = .@"application/vnd.oci.image.index.v1+json",
artifactType: ?image.MediaType = null,
manifests: []const image.Descriptor,
subject: ?image.Descriptor = null,
annotations: ?json.ArrayHashMap([]const u8) = null,

test "parse" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const indexes = [_][]const u8{
        \\{
        \\  "schemaVersion": 2,
        \\  "mediaType": "application/vnd.oci.image.index.v1+json",
        \\  "manifests": [
        \\    {
        \\      "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\      "size": 7143,
        \\      "digest": "sha256:e692418e4cbaf90ca69d05a66403747baa33ee08806650b51fab815ad7fc331f",
        \\      "platform": {
        \\        "architecture": "ppc64le",
        \\        "os": "linux"
        \\      }
        \\    },
        \\    {
        \\      "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\      "size": 7682,
        \\      "digest": "sha256:5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
        \\      "platform": {
        \\        "architecture": "amd64",
        \\        "os": "linux"
        \\      }
        \\    }
        \\  ],
        \\  "annotations": {
        \\    "com.example.key1": "value1",
        \\    "com.example.key2": "value2"
        \\  }
        \\}
        ,
        \\{
        \\  "schemaVersion": 2,
        \\  "mediaType": "application/vnd.oci.image.index.v1+json",
        \\  "manifests": [
        \\    {
        \\      "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\      "size": 7143,
        \\      "digest": "sha256:e692418e4cbaf90ca69d05a66403747baa33ee08806650b51fab815ad7fc331f",
        \\      "platform": {
        \\        "architecture": "ppc64le",
        \\        "os": "linux"
        \\      }
        \\    },
        \\    {
        \\      "mediaType": "application/vnd.oci.image.index.v1+json",
        \\      "size": 7682,
        \\      "digest": "sha256:601570aaff1b68a61eb9c85b8beca1644e698003e0cdb5bce960f193d265a8b7"
        \\    }
        \\  ],
        \\  "annotations": {
        \\    "com.example.key1": "value1",
        \\    "com.example.key2": "value2"
        \\  }
        \\}
    };

    var actual: [indexes.len]@This() = undefined;
    inline for (0..indexes.len) |i| {
        const parsed = try json.parseFromSlice(@This(), allocator, indexes[i], .{});
        actual[i] = parsed.value;
    }

    const expected = [indexes.len]@This(){
        .{
            .schemaVersion = .@"2",
            .mediaType = .@"application/vnd.oci.image.index.v1+json",
            .manifests = &.{
                .{
                    .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
                    .size = 7143,
                    .digest = .{
                        .algorithm = .sha256,
                        .data = "e692418e4cbaf90ca69d05a66403747baa33ee08806650b51fab815ad7fc331f",
                    },
                    .platform = .{
                        .architecture = .ppc64le,
                        .os = .linux,
                    },
                },
                .{
                    .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
                    .size = 7682,
                    .digest = .{
                        .algorithm = .sha256,
                        .data = "5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
                    },
                    .platform = .{
                        .architecture = .amd64,
                        .os = .linux,
                    },
                },
            },
            .annotations = actual[0].annotations,
        },
        .{
            .schemaVersion = .@"2",
            .mediaType = .@"application/vnd.oci.image.index.v1+json",
            .manifests = &.{
                .{
                    .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
                    .size = 7143,
                    .digest = .{
                        .algorithm = .sha256,
                        .data = "e692418e4cbaf90ca69d05a66403747baa33ee08806650b51fab815ad7fc331f",
                    },
                    .platform = .{
                        .architecture = .ppc64le,
                        .os = .linux,
                    },
                },
                .{
                    .mediaType = .@"application/vnd.oci.image.index.v1+json",
                    .size = 7682,
                    .digest = .{
                        .algorithm = .sha256,
                        .data = "601570aaff1b68a61eb9c85b8beca1644e698003e0cdb5bce960f193d265a8b7",
                    },
                },
            },
            .annotations = actual[1].annotations,
        },
    };

    try expectEqualDeep(expected, actual);
}

test "stringify" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const indexes = [_]@This(){
        .{
            .schemaVersion = .@"2",
            .mediaType = .@"application/vnd.oci.image.index.v1+json",
            .manifests = &.{
                .{
                    .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
                    .size = 7143,
                    .digest = .{
                        .algorithm = .sha256,
                        .data = "e692418e4cbaf90ca69d05a66403747baa33ee08806650b51fab815ad7fc331f",
                    },
                    .platform = .{
                        .architecture = .ppc64le,
                        .os = .linux,
                    },
                },
                .{
                    .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
                    .size = 7682,
                    .digest = .{
                        .algorithm = .sha256,
                        .data = "5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
                    },
                    .platform = .{
                        .architecture = .amd64,
                        .os = .linux,
                    },
                },
            },
            .annotations = (try json.parseFromSlice(json.ArrayHashMap([]const u8), allocator,
                \\{
                \\  "com.example.key1": "value1",
                \\  "com.example.key2": "value2"
                \\}
            , .{})).value,
        },
        .{
            .schemaVersion = .@"2",
            .mediaType = .@"application/vnd.oci.image.index.v1+json",
            .manifests = &.{
                .{
                    .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
                    .size = 7143,
                    .digest = .{
                        .algorithm = .sha256,
                        .data = "e692418e4cbaf90ca69d05a66403747baa33ee08806650b51fab815ad7fc331f",
                    },
                    .platform = .{
                        .architecture = .ppc64le,
                        .os = .linux,
                    },
                },
                .{
                    .mediaType = .@"application/vnd.oci.image.index.v1+json",
                    .size = 7682,
                    .digest = .{
                        .algorithm = .sha256,
                        .data = "601570aaff1b68a61eb9c85b8beca1644e698003e0cdb5bce960f193d265a8b7",
                    },
                },
            },
            .annotations = (try json.parseFromSlice(json.ArrayHashMap([]const u8), allocator,
                \\{
                \\  "com.example.key1": "value1",
                \\  "com.example.key2": "value2"
                \\}
            , .{})).value,
        },
    };

    const expected = [_][]const u8{
        \\{
        \\  "schemaVersion": 2,
        \\  "mediaType": "application/vnd.oci.image.index.v1+json",
        \\  "manifests": [
        \\    {
        \\      "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\      "digest": "sha256:e692418e4cbaf90ca69d05a66403747baa33ee08806650b51fab815ad7fc331f",
        \\      "size": 7143,
        \\      "platform": {
        \\        "architecture": "ppc64le",
        \\        "os": "linux"
        \\      }
        \\    },
        \\    {
        \\      "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\      "digest": "sha256:5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
        \\      "size": 7682,
        \\      "platform": {
        \\        "architecture": "amd64",
        \\        "os": "linux"
        \\      }
        \\    }
        \\  ],
        \\  "annotations": {
        \\    "com.example.key1": "value1",
        \\    "com.example.key2": "value2"
        \\  }
        \\}
        ,
        \\{
        \\  "schemaVersion": 2,
        \\  "mediaType": "application/vnd.oci.image.index.v1+json",
        \\  "manifests": [
        \\    {
        \\      "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\      "digest": "sha256:e692418e4cbaf90ca69d05a66403747baa33ee08806650b51fab815ad7fc331f",
        \\      "size": 7143,
        \\      "platform": {
        \\        "architecture": "ppc64le",
        \\        "os": "linux"
        \\      }
        \\    },
        \\    {
        \\      "mediaType": "application/vnd.oci.image.index.v1+json",
        \\      "digest": "sha256:601570aaff1b68a61eb9c85b8beca1644e698003e0cdb5bce960f193d265a8b7",
        \\      "size": 7682
        \\    }
        \\  ],
        \\  "annotations": {
        \\    "com.example.key1": "value1",
        \\    "com.example.key2": "value2"
        \\  }
        \\}
    };

    var actual: [indexes.len][]u8 = undefined;
    inline for (0..indexes.len) |i|
        actual[i] = try json.stringifyAlloc(allocator, indexes[i], .{
            .whitespace = .indent_2,
            .emit_null_optional_fields = false,
        });

    try expectEqualDeep(expected, actual);
}
