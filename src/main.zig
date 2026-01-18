const std = @import("std");

pub const Edge = struct {
    id: i32,
    from: i32,
    to: i32,
};

pub const Node = struct {
    id: i32,
    data: []const u8,

    incoming_edges: []i32,
    outgoing_edges: []i32,
};

pub const Graph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(Node),
    edges: std.ArrayList(Edge),
    node_index: std.AutoHashMap(i32, usize),
    edge_index: std.AutoHashMap(i32, usize),
    current_idx: i32,
    current_edge_idx: i32,

    pub fn new(allocator: std.mem.Allocator) Graph {
        return .{
            .allocator = allocator,
            .nodes = std.ArrayList(Node).empty,
            .edges = std.ArrayList(Edge).empty,
            .current_idx = 0,
            .current_edge_idx = 0,
            .node_index = std.AutoHashMap(i32, usize).init(allocator),
            .edge_index = std.AutoHashMap(i32, usize).init(allocator),
        };
    }

    pub fn deinit(self: *Graph) void {
        for (self.nodes.items) |node| {
            self.allocator.free(node.outgoing_edges);
            self.allocator.free(node.incoming_edges);
        }
        self.nodes.deinit(self.allocator);
        self.edges.deinit(self.allocator);
        self.node_index.deinit();
        self.edge_index.deinit();
    }

    pub fn exists(self: *Graph, node_to_check: i32) bool {
        return self.node_index.contains(node_to_check);
    }

    pub fn add(self: *Graph, node: Node) !i32 {
        var new_node = node;
        new_node.id = self.current_idx + 1;
        try self.nodes.append(self.allocator, new_node);
        try self.node_index.put(new_node.id, self.nodes.items.len - 1);
        self.current_idx += 1;
        return new_node.id;
    }

    pub fn connect(self: *Graph, from: i32, to: i32) !void {
        if (!self.exists(from) or !self.exists(to)) {
            return error.OneOrBothNodesDoNotExist;
        }

        const new_edge = Edge{ .id = self.current_edge_idx + 1, .from = from, .to = to };
        try self.edges.append(self.allocator, new_edge);
        self.current_edge_idx += 1;
        try self.edge_index.put(new_edge.id, self.edges.items.len - 1);

        const from_node_index = self.node_index.get(from);
        if (from_node_index) |from_index| {
            const from_node = &self.nodes.items[from_index];
            const old_len = from_node.outgoing_edges.len;
            from_node.outgoing_edges = try self.allocator.realloc(from_node.outgoing_edges, old_len + 1);
            from_node.outgoing_edges[old_len] = new_edge.id;
        }

        const to_node_index = self.node_index.get(to);
        if (to_node_index) |to_index| {
            const to_node = &self.nodes.items[to_index];
            const old_len = to_node.incoming_edges.len;
            to_node.incoming_edges = try self.allocator.realloc(to_node.incoming_edges, old_len + 1);
            to_node.incoming_edges[old_len] = new_edge.id;
        }
    }

    pub fn print(self: *Graph) void {
        std.debug.print("Nodes: {d}\n", .{self.nodes.items.len});
        std.debug.print("Edges: {d}\n\n", .{self.edges.items.len});

        for (self.nodes.items) |node| {
            std.debug.print("Node {d}: {s}\n", .{ node.id, node.data });
            std.debug.print("  Outgoing edges: ", .{});
            for (node.outgoing_edges) |edge_id| {
                std.debug.print("{d} ", .{edge_id});
            }
            std.debug.print("\n  Incoming edges: ", .{});
            for (node.incoming_edges) |edge_id| {
                std.debug.print("{d} ", .{edge_id});
            }
            std.debug.print("\n\n", .{});
        }

        for (self.edges.items) |edge| {
            std.debug.print("Edge {d}: {d} -> {d}\n", .{ edge.id, edge.from, edge.to });
        }
    }
};
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var graph = Graph.new(allocator);
    defer graph.deinit();

    const test_node = Node{
        .id = undefined,
        .data = "test",
        .incoming_edges = &.{},
        .outgoing_edges = &.{},
    };

    const test_node2 = Node{
        .id = undefined,
        .data = "test2",
        .incoming_edges = &.{},
        .outgoing_edges = &.{},
    };

    const id1 = try graph.add(test_node);
    const id2 = try graph.add(test_node2);
    try graph.connect(id1, id2);
    graph.print();
}
