`timescale 1ns / 1ns
module riscv_sopc_tb;

logic           clk;
logic           rst_n;
logic           uart_tx;
logic           uart_rx;
logic   [3:0]   pio;

riscv_sopc U_SOPC (
    .clk                (clk            ),
    .rst_n              (rst_n          ),
    .uart_txd           (uart_tx        ),
    .uart_rxd           (uart_rx        ),
    .pio                (pio            )
);

initial forever #10ns clk = ~clk;

initial begin
    clk     = 1'b0;
    rst_n   = 1'b0;
    repeat(10) @(posedge clk);
    rst_n   = 1'b1;
    #10ms;
    $finish;
end

initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars;
    $fsdbDumpMDA;
end

endmodule
