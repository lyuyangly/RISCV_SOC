`timescale 1ns / 1ps
module apb_pio
(
// --------------------------------------------------------------------------
// Port Definitions
// --------------------------------------------------------------------------
	input  wire                 HCLK,       // Clock
	input  wire                 HRESETn,    // Reset
	input  wire                 HSEL,       // Device select
	input  wire     [31:0]      HADDR,      // Address
	input  wire     [1:0]       HTRANS,     // Transfer control
	input  wire     [2:0]       HSIZE,      // Transfer size
	input  wire     [3:0]       HPROT,      // Protection control
	input  wire                 HWRITE,     // Write control
	input  wire                 HREADY,     // Transfer phase done
	input  wire     [31:0]      HWDATA,     // Write data
	output wire                 HREADYOUT,  // Device ready
	output reg      [31:0]      HRDATA,     // Read data output
	output wire                 HRESP,      // Device response
    output wire     [31:0]      GPIO        // IO Port
);

// Registers
reg    [31:0]   pio_reg;
reg		        ram_wr, ram_rd;

always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
		ram_wr <= 1'b0;
	else begin
		if (HSEL && (HTRANS[1] == 1'b1) && HWRITE)
			ram_wr <= 1'b1;
		else
			ram_wr <= 1'b0;
	end
end

always @(*)
begin
	if (HSEL && (HTRANS[1] == 1'b1) && !HWRITE)
		ram_rd = 1'b1;
	else
		ram_rd = 1'b0;
end

always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn) begin
        pio_reg <= 'd0;
		HRDATA  <= 'd0;
    end
	else begin
		if (ram_wr)
			pio_reg <= HWDATA;
		else if (ram_rd)
			HRDATA <= pio_reg;
        else
            HRDATA <= 'd0;
	end
end

assign HREADYOUT = 1'b1;
assign HRESP     = 1'b0;
assign GPIO      = pio_reg;

endmodule

