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

test "read env" {
    var map = try getEnvMap(std.testing.allocator, ".env.testing");
    defer {
        var iter = map.iterator();
        while (iter.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            std.testing.allocator.free(entry.value_ptr.*);
        }

        map.deinit();
    }

    const value = map.get("some_var").?;
    try std.testing.expect(std.mem.eql(u8, value, "testing"));

    const other_value = map.get("other_var").?;
    try std.testing.expect(std.mem.eql(u8, other_value, "more_testing"));
}
