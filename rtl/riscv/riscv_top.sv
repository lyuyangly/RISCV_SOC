//##################################################################################################
//  Project     : RISC-V SOPC
//  Author      : Lyu Yang
//  Date        : 2020-05-10
//  Description : RISC-V TOP
//##################################################################################################
module riscv_top #(
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
    input   wire                            ext_nmi                 ,
    input   wire                            ext_tint                ,
    input   wire                            ext_sint                ,
    input   wire   [3:0]                    ext_int                 ,
    input   wire                            dbg_stall               ,
    input   wire                            dbg_strb                ,
    input   wire                            dbg_we                  ,
    input   wire   [DBG_ADDR_SIZE -1:0]     dbg_addr                ,
    input   wire   [XLEN -1:0]              dbg_dati                ,
    output  wire   [XLEN -1:0]              dbg_dato                ,
    output  wire                            dbg_ack                 ,
    output  wire                            dbg_bp
);

wire                            if_stall_nxt_pc;
wire    [XLEN-1:0]              if_nxt_pc;
wire                            if_stall;
wire                            if_flush;
wire    [PARCEL_SIZE-1:0]       if_parcel;
wire    [XLEN-1:0]              if_parcel_pc;
wire    [PARCEL_SIZE/16-1:0]    if_parcel_valid;
wire                            if_parcel_misaligned;
wire                            if_parcel_page_fault;
wire    [XLEN-1:0]              dmem_adr;
wire    [XLEN-1:0]              dmem_d;
wire    [XLEN-1:0]              dmem_q;
wire                            dmem_we;
biu_size_t                      dmem_size;
wire                            dmem_req;
wire                            dmem_ack;
wire                            dmem_err;
wire                            dmem_misaligned;
wire                            dmem_page_fault;

riscv_core u_riscv_core (
    .clk                (hclk           ),
    .rstn               (hreset_n       ),
    .st_prv             (),
    .st_pmpcfg          (),
    .st_pmpaddr         (),
    .bu_cacheflush      (),
    .*
);

riscv_biu u_riscv_biu (
    .*
);

endmodule
