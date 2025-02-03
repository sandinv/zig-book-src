const std = @import("std");

const Base64 = struct {
    _table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symb = "0123456789+/";
        return Base64{
            ._table = upper ++ lower ++ numbers_symb,
        };
    }

    pub fn _char_at(self: Base64, index: u8) !u8 {
        if (index >= self._table.len) {
            return error.OutOfIndex;
        }
        return self._table[index];
    }

    pub fn _char_index(self: Base64, char: u8) !u8 {
        if (char == '=') {
            return 64;
        }
        var index: u8 = 0;
        for (0..63) |_| {
            if (try self._char_at(index) == char) {
                break;
            }
            index += 1;
        }
        return index;
    }

    pub fn encode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const n_out = try _calc_encode_length(input);
        var out = try allocator.alloc(u8, n_out);
        var buf = [3]u8{ 0, 0, 0 };
        var count: u8 = 0;
        var iout: usize = 0;

        for (input, 0..) |_, i| {
            buf[count] = input[i];
            count += 1;
            if (count == 3) {
                out[iout] = try self._char_at(buf[0] >> 2);
                out[iout + 1] = try self._char_at(
                    ((buf[0] & 0x03) << 4) + (buf[1] >> 4),
                );
                out[iout + 2] = try self._char_at(
                    ((buf[1] & 0x0f) << 2) + (buf[2] >> 6),
                );
                out[iout + 3] = try self._char_at(
                    (buf[2] & 0x3f),
                );
                iout += 4;
                count = 0;
            }
        }
        if (count == 1) {
            out[iout] = try self._char_at(buf[0] >> 2);
            out[iout + 1] = try self._char_at(((buf[0] & 0x03) << 4));
            out[iout + 2] = '=';
            out[iout + 3] = '=';
        }
        if (count == 2) {
            out[iout] = try self._char_at(buf[0] >> 2);
            out[iout + 1] = try self._char_at(
                ((buf[0] & 0x03) << 4) + (buf[1] >> 4),
            );
            out[iout + 2] = try self._char_at(
                ((buf[1] & 0x0f) << 2),
            );
            out[iout + 3] = '=';
        }
        return out;
    }
    pub fn decode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const n_out = try _calc_decode_length(input);
        var out = try allocator.alloc(u8, n_out);
        var buf = [4]u8{ 0, 0, 0, 0 };
        var count: u8 = 0;
        var iout: usize = 0;
        for (0..out.len) |i| {
            out[i] = 0;
        }

        for (input, 0..) |_, i| {
            buf[count] = try self._char_index(input[i]);
            count += 1;
            if (count == 4) {
                out[iout] = (buf[0] << 2) + (buf[1] >> 4);
                if (buf[2] != 64) {
                    out[iout + 1] = (buf[1] << 4) + (buf[2] >> 2);
                }
                if (buf[3] != 64) {
                    out[iout + 2] = (buf[2] << 6) + buf[3];
                }
                iout += 3;
                count = 0;
            }
        }

        return out;
    }
};

fn _calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        const n_output: usize = 4;
        return n_output;
    }
    const n_output: usize = try std.math.divCeil(usize, input.len, 3);
    return n_output * 4;
}

fn _calc_decode_length(input: []const u8) !usize {
    if (input.len < 4) {
        const n_output: usize = 3;

        return n_output;
    }

    const n_output: usize = try std.math.divFloor(usize, input.len, 4);

    return n_output * 3;
}

pub fn main() !void {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();
    const base64 = Base64.init();
    std.debug.print("{s}\n", .{try base64.decode(allocator, try base64.encode(allocator, "victor1"))});
}
