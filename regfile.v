`timescale 1ns/1ps

module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [4:0]  addr_a,
    input  wire [4:0]  addr_b,
    input  wire [4:0]  addr_d,
    input  wire [31:0] data_d,
    output wire [31:0] data_a,
    output wire [31:0] data_b
);

    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else begin
            if (we && (addr_d != 5'd0))
                regs[addr_d] <= data_d;
        end
        regs[0] <= 32'b0;
    end

    // Đọc bất đồng bộ
    assign data_a = (addr_a == 5'd0) ? 32'b0 : regs[addr_a];
    assign data_b = (addr_b == 5'd0) ? 32'b0 : regs[addr_b];

endmodule