//------------------------------------------------------------------------------
// Abstract : IRQ synchronizer
//------------------------------------------------------------------------------
module irq_sync (
    input  wire  RSTn,
    input  wire  CLK,
    input  wire  IRQIN,
    output wire  IRQOUT
);

reg  [2:0] sync_reg;
wire [2:0] nxt_sync_reg;

assign nxt_sync_reg = {sync_reg[1:0],IRQIN};

always @(posedge CLK or negedge RSTn)
begin
    if (~RSTn)
        sync_reg <= 3'b000;
    else
        sync_reg <= nxt_sync_reg;
end

// Only consider valid if it is high for two cycles
assign   IRQOUT  = sync_reg[2] & sync_reg[1];

endmodule
