const std = @import("std");

pub fn getEnvMap(allocator: std.mem.Allocator, path: []const u8) !std.StringHashMap([]const u8) {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var map = std.StringHashMap([]const u8).init(allocator);

    const reader = file.reader();

    while (reader.readUntilDelimiterAlloc(allocator, '\n', 1024) catch null) |value| {
        defer allocator.free(value);

        var iter = std.mem.splitAny(u8, value, "=");
        const k = try allocator.dupe(u8, iter.next() orelse continue);
        var v = iter.next() orelse continue;

        if (std.mem.startsWith(u8, v, "\"")) {
            v = v[1..];
        }

        if (std.mem.endsWith(u8, v, "\"")) {
            v = v[0 .. v.len - 1];
        }

        try map.put(k, try allocator.dupe(u8, v));
    }

    return map;
}

pub fn getEnvVar(allocator: std.mem.Allocator, path: []const u8, name: []const u8) ![]const u8 {
    var map = try getEnvMap(allocator, path);
    defer {
        var iter = map.iterator();
        while (iter.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            allocator.free(entry.value_ptr.*);
        }

        map.deinit();
    }

    return try allocator.dupe(u8, map.get(name) orelse return DotEnvError.ValueNotFound);
}

pub const DotEnvError = error{ValueNotFound};

test "get env var" {
    const value = try getEnvVar(std.testing.allocator, ".env.testing", "some_var");
    defer std.testing.allocator.free(value);

    try std.testing.expect(std.mem.eql(u8, value, "testing"));
}
