const std = @import("std");
const builtin = @import("builtin");
const net = @import("std").net;

pub const Socket = struct {
    _address: net.Address,
    _stream: net.Stream,
    _socket: std.posix.socket_t,

    pub fn init() !Socket {
        const host = [4]u8{ 0, 0, 0, 0 };
        const port = 3490;
        const addr = net.Address.initIp4(host, port);
        const socket = try std.posix.socket(
            addr.any.family,
            std.posix.SOCK.STREAM,
            std.posix.IPPROTO.TCP,
        );
        const stream = net.Stream{ .handle = socket };
        return Socket{ ._address = addr, ._stream = stream, ._socket = socket };
    }
    pub fn deinit(self: Socket) void {
        std.posix.close(self._socket);
    }
};
