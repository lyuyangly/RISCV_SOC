`timescale 1ns/1ps
module ahb_addr_decode (
    // System Address
    input wire [31:0]       haddr,

    // Memory Selection
    output wire             ram_hsel,
    
    // PIO Selection
    output wire             pio_hsel,
    
    // Peripheral Selection
    output wire             apbsys_hsel
);

assign ram_hsel    = (haddr[31:16]==16'h1000); // 0x10000000
assign pio_hsel    = (haddr[31:16]==16'h2000); // 0x20000000
assign apbsys_hsel = (haddr[31:16]==16'h3000); // 0x30000000

endmodule
