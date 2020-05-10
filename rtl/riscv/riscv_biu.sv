//##################################################################################################
//  Project     : RISC-V SOPC
//  Author      : Lyu Yang
//  Date        : 2020-05-10
//  Description : RISC-V BIU
//##################################################################################################
module riscv_biu #(
    parameter   XLEN        = 32,
    parameter   PARCEL_SIZE = 32
) (
    input   wire                            hclk                    ,
    input   wire                            hreset_n                ,
    output  reg                             ihbusreq                ,
    input   wire                            ihgrant                 ,
    output  reg     [XLEN-1:0]              ihaddr                  ,
    output  reg     [1:0]                   ihtrans                 ,
    output  reg     [2:0]                   ihsize                  ,
    output  wire    [2:0]                   ihburst                 ,
    output  wire    [3:0]                   ihprot                  ,
    output  wire                            ihwrite                 ,
    output  wire    [XLEN-1:0]              ihwdata                 ,
    output  wire                            ihmasterlock            ,
    input   wire                            ihready                 ,
    input   wire    [XLEN-1:0]              ihrdata                 ,
    input   wire    [1:0]                   ihresp                  ,
    output  reg                             dhbusreq                ,
    input   wire                            dhgrant                 ,
    output  reg     [XLEN-1:0]              dhaddr                  ,
    output  reg     [1:0]                   dhtrans                 ,
    output  reg     [2:0]                   dhsize                  ,
    output  wire    [2:0]                   dhburst                 ,
    output  wire    [3:0]                   dhprot                  ,
    output  reg                             dhwrite                 ,
    output  reg     [XLEN-1:0]              dhwdata                 ,
    output  wire                            dhmasterlock            ,
    input   wire                            dhready                 ,
    input   wire    [XLEN-1:0]              dhrdata                 ,
    input   wire    [1:0]                   dhresp                  ,
    output  reg                             if_stall_nxt_pc         ,
    input   wire    [XLEN-1:0]              if_nxt_pc               ,
    input   wire                            if_stall                ,
    input   wire                            if_flush                ,
    output  wire    [PARCEL_SIZE-1:0]       if_parcel               ,
    output  reg     [XLEN-1:0]              if_parcel_pc            ,
    output  wire    [PARCEL_SIZE/16-1:0]    if_parcel_valid         ,
    output  wire                            if_parcel_misaligned    ,
    output  wire                            if_parcel_page_fault    ,
    input   wire    [XLEN-1:0]              dmem_adr                ,
    input   wire    [XLEN-1:0]              dmem_d                  ,
    output  reg     [XLEN-1:0]              dmem_q                  ,
    input   wire                            dmem_we                 ,
    input   biu_size_t                      dmem_size               ,
    input   wire                            dmem_req                ,
    output  reg                             dmem_ack                ,
    output  wire                            dmem_err                ,
    output  wire                            dmem_misaligned         ,
    output  wire                            dmem_page_fault
);

localparam      S_IDLE   = 2'h0,
                S_BUSREQ = 2'h1,
                S_BURST0 = 2'h2,
                S_BURST1 = 2'h3;

logic   [1:0]   istate;
logic   [1:0]   dstate;

// Instruction Bus
always_ff @(posedge hclk, negedge hreset_n)
    if(~hreset_n) begin
        istate          <= S_IDLE;
        ihbusreq        <= 1'b0;
        ihtrans         <= 2'h0;
        ihsize          <= 3'h0;
        ihaddr          <= 'h0;
        if_parcel_pc    <= 'h0;
        if_stall_nxt_pc <= 1'b0;
    end
    else begin
        case(istate)
            S_IDLE: begin
                if(if_flush) begin
                    istate          <= S_IDLE;
                    ihbusreq        <= 1'b0;
                    ihtrans         <= 2'h0;
                    ihsize          <= 3'h0;
                    ihaddr          <= 32'h0;
                    if_stall_nxt_pc <= 1'b1;
                end
                else if(~if_stall) begin
                    istate          <= S_BUSREQ;
                    ihbusreq        <= 1'b1;
                    ihtrans         <= 2'h0;
                    ihsize          <= 3'h2;
                    ihaddr          <= {if_nxt_pc[XLEN-1:2], 2'h0};
                    if_parcel_pc    <= if_nxt_pc;
                    if_stall_nxt_pc <= 1'b1;
                end
                else begin
                    istate          <= S_IDLE;
                    ihbusreq        <= 1'b0;
                    ihtrans         <= 2'h0;
                    ihsize          <= 3'h0;
                    ihaddr          <= 32'h0;
                    if_stall_nxt_pc <= 1'b1;
                end
            end
            S_BUSREQ : begin
                if(if_flush) begin
                    istate          <= S_IDLE;
                    ihbusreq        <= 1'b0;
                    ihtrans         <= 2'h0;
                    ihsize          <= 3'h0;
                    ihaddr          <= 32'h0;
                    if_stall_nxt_pc <= 1'b1;
                end
                else if(ihready & ihbusreq & ihgrant) begin
                    istate          <= S_BURST0;
                    ihtrans         <= 2'h2;
                end
                else begin
                    istate          <= S_BUSREQ;
                end
            end
            S_BURST0 : begin
                if(if_flush) begin
                    istate          <= S_IDLE;
                    ihbusreq        <= 1'b0;
                    ihtrans         <= 2'h0;
                    ihsize          <= 3'h0;
                    ihaddr          <= 32'h0;
                    if_stall_nxt_pc <= 1'b1;
                end
                else begin
                    istate          <= S_BURST1;
                    ihtrans         <= 2'h0;
                    ihbusreq        <= 1'b0;
                end
            end
            S_BURST1 : begin
                if(if_flush) begin
                    istate          <= S_IDLE;
                    ihbusreq        <= 1'b0;
                    ihtrans         <= 2'h0;
                    ihsize          <= 3'h0;
                    ihaddr          <= 32'h0;
                    if_stall_nxt_pc <= 1'b1;
                end
                else if(~if_stall_nxt_pc) begin
                    if_stall_nxt_pc <= 1'b1;
                    istate          <= S_IDLE;
                end
                else if(ihready) begin
                    if_stall_nxt_pc <= 1'b0;
                    istate          <= S_BURST1;
                end
                else begin
                    if_stall_nxt_pc <= 1'b1;
                    istate          <= S_BURST1;
                end
            end
        endcase
    end

assign ihmasterlock         = 1'b0;
assign ihburst              = 3'h0;
assign ihwrite              = 1'b0;
assign ihwdata              = INSTR_NOP;
assign ihprot               = 4'h1;
assign if_parcel            = ihrdata;
assign if_parcel_valid      = {2{ihready & (istate == S_BURST1)}};
assign if_parcel_misaligned = 1'b0;
assign if_parcel_page_fault = 1'b0;

// Data Bus
always_ff @(posedge hclk, negedge hreset_n)
    if(~hreset_n) begin
        dstate          <= S_IDLE;
        dhbusreq        <= 1'b0;
        dhtrans         <= 2'h0;
        dhwrite         <= 1'b0;
        dhsize          <= 3'h0;
        dhaddr          <= 'h0;
        dmem_q          <= 'h0;
        dmem_ack        <= 1'b0;
    end
    else begin
        case(dstate)
            S_IDLE: begin
                if(dmem_req) begin
                    dstate          <= S_BUSREQ;
                    dhbusreq        <= 1'b1;
                    dhtrans         <= 2'h0;
                    dhwrite         <= dmem_we;
                    dhsize          <= dmem_size;
                    dhaddr          <= dmem_adr;
                    dhwdata         <= dmem_d;
                    dmem_ack        <= 1'b0;
                end
                else begin
                    dstate          <= S_IDLE;
                    dhbusreq        <= 1'b0;
                    dhtrans         <= 2'h0;
                    dhwrite         <= 1'b0;
                    dhsize          <= 3'h0;
                    dhaddr          <= 32'h0;
                end
            end
            S_BUSREQ : begin
                if(dhready & dhbusreq & dhgrant) begin
                    dstate          <= S_BURST0;
                    dhtrans         <= 2'h2;
                end
                else begin
                    dstate          <= S_BUSREQ;
                end
            end
            S_BURST0 : begin
                dstate              <= S_BURST1;
                dhtrans             <= 2'h0;
                dhbusreq            <= 1'b0;
            end
            S_BURST1 : begin
                if(~dmem_req && dmem_ack) begin
                    dstate          <= S_IDLE;
                end
                else if(dhready) begin
                    dmem_ack        <= 1'b1;
                    dmem_q          <= dhrdata;
                    dstate          <= S_BURST1;
                end
                else begin
                    dstate          <= S_BURST1;
                end
            end
        endcase
    end

assign dhmasterlock         = 1'b0;
assign dhburst              = 3'h0;
assign dhprot               = 4'h1;
assign dmem_err             = 1'b0;
assign dmem_misaligned      = 1'b0;
assign dmem_page_fault      = 1'b0;

endmodule
