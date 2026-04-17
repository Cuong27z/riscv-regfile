`timescale 1ns/1ps

module tb_regfile;

    reg         clk;
    reg         rst;
    reg         we;
    reg  [4:0]  addr_a;
    reg  [4:0]  addr_b;
    reg  [4:0]  addr_d;
    reg  [31:0] data_d;
    wire [31:0] data_a;
    wire [31:0] data_b;

    integer pass_count;
    integer fail_count;

    regfile dut (
        .clk   (clk),
        .rst   (rst),
        .we    (we),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .addr_d(addr_d),
        .data_d(data_d),
        .data_a(data_a),
        .data_b(data_b)
    );

    // Clock 10ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Task kiểm tra giá trị
    task check_equal;
        input [31:0] actual;
        input [31:0] expected;
        input [255:0] msg;
        begin
            if (actual === expected) begin
                $display("[PASS] %s | actual = 0x%08h", msg, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s | actual = 0x%08h, expected = 0x%08h", msg, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        // Khởi tạo tín hiệu
        rst        = 1'b0;
        we         = 1'b0;
        addr_a     = 5'd0;
        addr_b     = 5'd0;
        addr_d     = 5'd0;
        data_d     = 32'd0;
        pass_count = 0;
        fail_count = 0;

        $display("========================================");
        $display("START UNIT TEST FOR REGFILE");
        $display("========================================");

        // =========================================================
        // TEST 1: Sau khi khởi tạo, tất cả thanh ghi đều = 0
        // =========================================================
        #1;
        addr_a = 5'd1;
        addr_b = 5'd2;
        #1;
        check_equal(data_a, 32'd0, "Initial value of x1 must be 0");
        check_equal(data_b, 32'd0, "Initial value of x2 must be 0");

        addr_a = 5'd10;
        addr_b = 5'd31;
        #1;
        check_equal(data_a, 32'd0, "Initial value of x10 must be 0");
        check_equal(data_b, 32'd0, "Initial value of x31 must be 0");

        // =========================================================
        // TEST 2: x0 luôn đọc ra 0
        // =========================================================
        addr_a = 5'd0;
        addr_b = 5'd0;
        #1;
        check_equal(data_a, 32'd0, "Read x0 on port A");
        check_equal(data_b, 32'd0, "Read x0 on port B");

        // =========================================================
        // TEST 3: Ghi vào một thanh ghi bình thường
        // =========================================================
        we     = 1'b1;
        addr_d = 5'd5;
        data_d = 32'h12345678;

        @(posedge clk);
        #1;

        we     = 1'b0;
        addr_a = 5'd5;
        #1;
        check_equal(data_a, 32'h12345678, "Write x5 = 0x12345678");

        // =========================================================
        // TEST 4: Ghi đồng thời, đọc từ cổng B
        // =========================================================
        we     = 1'b1;
        addr_d = 5'd12;
        data_d = 32'hA5A5F0F0;

        @(posedge clk);
        #1;

        we     = 1'b0;
        addr_b = 5'd12;
        #1;
        check_equal(data_b, 32'hA5A5F0F0, "Write x12 = 0xA5A5F0F0 and read from port B");

        // =========================================================
        // TEST 5: we = 0 thì không được ghi
        // =========================================================
        addr_a = 5'd8;
        #1;
        check_equal(data_a, 32'd0, "Before no-write test, x8 must be 0");

        we     = 1'b0;
        addr_d = 5'd8;
        data_d = 32'hFFFFFFFF;

        @(posedge clk);
        #1;

        addr_a = 5'd8;
        #1;
        check_equal(data_a, 32'd0, "x8 must remain 0 when we = 0");

        // =========================================================
        // TEST 6: Ghi vào x0 phải bị bỏ qua
        // =========================================================
        we     = 1'b1;
        addr_d = 5'd0;
        data_d = 32'hFFFFFFFF;

        @(posedge clk);
        #1;

        we     = 1'b0;
        addr_a = 5'd0;
        #1;
        check_equal(data_a, 32'd0, "Write to x0 must be ignored");

        // =========================================================
        // TEST 7: Đọc đồng thời 2 cổng sau khi đã ghi
        // =========================================================
        we     = 1'b1;
        addr_d = 5'd3;
        data_d = 32'h000000AA;
        @(posedge clk);
        #1;

        addr_d = 5'd7;
        data_d = 32'h00000055;
        @(posedge clk);
        #1;

        we     = 1'b0;
        addr_a = 5'd3;
        addr_b = 5'd7;
        #1;
        check_equal(data_a, 32'h000000AA, "Read x3 on port A");
        check_equal(data_b, 32'h00000055, "Read x7 on port B");

        // =========================================================
        // TEST 8: Reset phải đưa tất cả thanh ghi về 0
        // =========================================================
        rst = 1'b1;
        @(posedge clk);
        #1;
        rst = 1'b0;

        addr_a = 5'd5;
        addr_b = 5'd12;
        #1;
        check_equal(data_a, 32'd0, "After reset, x5 must be 0");
        check_equal(data_b, 32'd0, "After reset, x12 must be 0");

        addr_a = 5'd3;
        addr_b = 5'd7;
        #1;
        check_equal(data_a, 32'd0, "After reset, x3 must be 0");
        check_equal(data_b, 32'd0, "After reset, x7 must be 0");

        addr_a = 5'd0;
        #1;
        check_equal(data_a, 32'd0, "After reset, x0 must still be 0");

        // =========================================================
        // Tổng kết
        // =========================================================
        $display("========================================");
        $display("UNIT TEST FINISHED");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("FINAL RESULT: ALL TESTS PASSED");
        else
            $display("FINAL RESULT: SOME TESTS FAILED");

        $finish;
    end

endmodule