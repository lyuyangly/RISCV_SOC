//##################################################################################################
//  Project     : AMBA AHB RAM
//  Author      : Lyu Yang
//  Date        : 2020-05-10
//  Description : AHB RAM
//##################################################################################################
module ahb_ram (
    input   wire                hclk        ,
    input   wire                hreset_n    ,
    input   wire                hsel        ,
    input   wire    [1:0]       htrans      ,
    input   wire                hwrite      ,
    input   wire    [2:0]       hsize       ,
    input   wire    [31:0]      haddr       ,
    input   wire    [31:0]      hwdata      ,
    input   wire                hready_in   ,
    output  reg     [31:0]      hrdata      ,
    output                      hready_out  ,
    output  wire    [1:0]       hresp
);

localparam      MEM_SIZE = 4096;

integer         k;
wire            hbus_ena;
reg             hbus_ena_d;
reg     [3:0]   mem_wstrb;
reg     [31:0]  mem_addr;
reg     [31:0]  mem[MEM_SIZE-1:0];

// Memory Init
`ifdef SYNTHESIS
initial $readmemh("../../frw/app_test.txt", mem);
`else
initial $readmemh("../frw/app_test.txt", mem);
`endif

// AHB response always OKAY
assign hresp = 2'h0;
assign hready_out = 1'b1;
assign hbus_ena = hsel & hready_in & htrans[1];

always @(posedge hclk, negedge hreset_n)
    if(~hreset_n)
        hbus_ena_d <= 1'b0;
    else
        hbus_ena_d <= hbus_ena;

always @(posedge hclk, negedge hreset_n)
    if(~hreset_n)
        mem_addr <= 32'd0;
    else if(hbus_ena)
        mem_addr <= haddr;

always @(posedge hclk, negedge hreset_n)
    if(~hreset_n)
        mem_wstrb <= 4'h0;
    else if(hbus_ena & hwrite) begin
        case(hsize)
            3'b000: begin
                case(haddr[1:0])
                    2'b00: mem_wstrb <= 4'b0001;
                    2'b01: mem_wstrb <= 4'b0010;
                    2'b10: mem_wstrb <= 4'b0100;
                    2'b11: mem_wstrb <= 4'b1000;
                endcase
            end
            3'b001: begin
                case(haddr[0])
                    1'b0: mem_wstrb <= 4'b0011;
                    1'b1: mem_wstrb <= 4'b1100;
                endcase
            end
            3'b010: begin
                mem_wstrb <= 4'b1111;
            end
            default: begin
                mem_wstrb <= 4'b0000;
            end
        endcase
    end
    else begin
        mem_wstrb <= 4'b0000;
    end

always @(posedge hclk)
    for(k=0; k<4; k=k+1)
        if(mem_wstrb[k] && hbus_ena_d)
            mem[mem_addr[31:2]][k*8+:8] <= hwdata[k*8+:8];

always @(posedge hclk)
    if(hbus_ena)
        hrdata <= mem[haddr[31:2]];

endmodule

