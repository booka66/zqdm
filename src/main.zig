const std = @import("std");

pub const ProgressBar = struct {
    total: usize,
    current: usize,
    width: usize,
    start_time: i64,
    last_update: i64,
    min_update_interval: i64,

    pub fn init(total: usize) !ProgressBar {
        return ProgressBar{
            .total = total,
            .current = 0,
            .width = 40,
            .start_time = std.time.milliTimestamp(),
            .last_update = std.time.milliTimestamp(),
            .min_update_interval = 100,
        };
    }

    pub fn update(self: *ProgressBar, n: usize) !void {
        self.current = @min(self.current + n, self.total);
        const current_time = std.time.milliTimestamp();

        if (current_time - self.last_update < self.min_update_interval) {
            return;
        }

        const progress = @as(f64, @floatFromInt(self.current)) / @as(f64, @floatFromInt(self.total));
        const filled_width = @as(usize, @intFromFloat(progress * @as(f64, @floatFromInt(self.width))));
        const empty_width = self.width - filled_width;

        const elapsed_secs = @as(f64, @floatFromInt(current_time - self.start_time)) / 1000.0;
        const speed = @as(f64, @floatFromInt(self.current)) / elapsed_secs;
        const remaining_items = self.total - self.current;
        const eta_secs = @as(f64, @floatFromInt(remaining_items)) / speed;

        const writer = std.io.getStdOut().writer();
        try writer.print("\r[", .{});

        var i: usize = 0;
        while (i < filled_width) : (i += 1) {
            try writer.print("=", .{});
        }

        i = 0;
        while (i < empty_width) : (i += 1) {
            try writer.print(" ", .{});
        }

        try writer.print("] {d:>3.1}% | {d}/{d} [{d:.1}it/s, ETA: {d:.1}s]", .{
            progress * 100.0,
            self.current,
            self.total,
            speed,
            eta_secs,
        });

        if (self.current == self.total) {
            try writer.print("\n", .{});
        }

        self.last_update = current_time;
    }
};

// Add some basic tests
test "ProgressBar initialization" {
    const bar = try ProgressBar.init(100);
    try std.testing.expectEqual(bar.total, 100);
    try std.testing.expectEqual(bar.current, 0);
    try std.testing.expectEqual(bar.width, 40);
}
