//##################################################################################################
//  Project     : RISC-V SOPC
//  Author      : Lyu Yang
//  Date        : 2020-05-10
//  Description : RISC-V CPU Core
//##################################################################################################
import riscv_pkg::*;

module riscv_core #(
  parameter            XLEN                  = 32,
  parameter [XLEN-1:0] PC_INIT               = 'h200,
  parameter            HAS_USER              = 0,
  parameter            HAS_SUPER             = 0,
  parameter            HAS_HYPER             = 0,
  parameter            HAS_FPU               = 1,
  parameter            HAS_MMU               = 0,
  parameter            HAS_RVA               = 0,
  parameter            IS_RV32E              = 0,
  parameter            PMP_CNT               = 16,
  parameter            BREAKPOINTS           = 3,
  parameter            MULT_LATENCY          = 0,
  parameter            BP_LOCAL_BITS         = 10,
  parameter            BP_GLOBAL_BITS        = 2,
  parameter            PARCEL_SIZE           = 32,
  parameter            MNMIVEC_DEFAULT       = PC_INIT -'h004,
  parameter            MTVEC_DEFAULT         = PC_INIT -'h040,
  parameter            HTVEC_DEFAULT         = PC_INIT -'h080,
  parameter            STVEC_DEFAULT         = PC_INIT -'h0C0,
  parameter            UTVEC_DEFAULT         = PC_INIT -'h100
) (
  input                             clk,    //Clock
  input                             rstn,   //Reset

  //Instruction Memory Access bus
  input                             if_stall_nxt_pc,
  output       [XLEN          -1:0] if_nxt_pc,
  output                            if_stall,
                                    if_flush,
  input        [PARCEL_SIZE   -1:0] if_parcel,
  input        [XLEN          -1:0] if_parcel_pc,
  input        [PARCEL_SIZE/16-1:0] if_parcel_valid,
  input                             if_parcel_misaligned,
  input                             if_parcel_page_fault,

  //Data Memory Access bus
  output       [XLEN          -1:0] dmem_adr,
                                    dmem_d,
  input        [XLEN          -1:0] dmem_q,
  output                            dmem_we,
  output biu_size_t                 dmem_size,
  output                            dmem_req,
  input                             dmem_ack,
                                    dmem_err,
                                    dmem_misaligned,
                                    dmem_page_fault,

  //cpu state
  output       [               1:0] st_prv,
  output pmpcfg_t [15:0]            st_pmpcfg,
  output [15:0][XLEN          -1:0] st_pmpaddr,
  output                            bu_cacheflush,

  //Interrupts
  input                             ext_nmi,
                                    ext_tint,
                                    ext_sint,
  input        [               3:0] ext_int,

  //Debug Interface
  input                             dbg_stall,
  input                             dbg_strb,
  input                             dbg_we,
  input        [DBG_ADDR_SIZE -1:0] dbg_addr,
  input        [XLEN          -1:0] dbg_dati,
  output       [XLEN          -1:0] dbg_dato,
  output                            dbg_ack,
  output                            dbg_bp
);

  ////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic [XLEN          -1:0] bu_nxt_pc,
                             st_nxt_pc,
                             if_pc,
                             id_pc,
                             ex_pc,
                             mem_pc,
                             wb_pc;

  logic [XLEN          -1:0] if_instr,
                             id_instr,
                             ex_instr,
                             mem_instr,
                             wb_instr;

  logic                      if_bubble,
                             id_bubble,
                             ex_bubble,
                             mem_bubble,
                             wb_bubble;

  logic                      bu_flush,
                             st_flush,
                             du_flush;

  logic                      id_stall,
                             ex_stall,
                             wb_stall,
                             du_stall,
                             du_stall_dly;

  //Branch Prediction
  logic [               1:0] bp_bp_predict,
                             if_bp_predict,
                             id_bp_predict,
                             bu_bp_predict;

  logic [BP_GLOBAL_BITS-1:0] bu_bp_history;
  logic                      bu_bp_btaken,
                             bu_bp_update;


  //Exceptions
  logic [EXCEPTION_SIZE-1:0] if_exception,
                             id_exception,
                             ex_exception,
                             mem_exception,
                             wb_exception;

  //RF access
  logic [XLEN          -1:0] id_srcv2;
  logic [               4:0] rf_src1 [1],
                             rf_src2 [1],
                             rf_dst  [1];
  logic [XLEN          -1:0] rf_srcv1[1],
                             rf_srcv2[1],
                             rf_dstv [1];
  logic [               0:0] rf_we;


  //ALU signals
  logic [XLEN          -1:0] id_opA,
                             id_opB,
                             ex_r,
                             ex_memadr,
                             mem_r,
                             mem_memadr;

  logic                      id_userf_opA,
                             id_userf_opB,
                             id_bypex_opA,
                             id_bypex_opB,
                             id_bypmem_opA,
                             id_bypmem_opB,
                             id_bypwb_opA,
                             id_bypwb_opB;

  //CPU state
  logic [               1:0] st_xlen;
  logic                      st_tvm,
                             st_tw,
                             st_tsr;
  logic [XLEN          -1:0] st_mcounteren,
                             st_scounteren;
  logic                      st_interrupt;
  logic [              11:0] ex_csr_reg;
  logic [XLEN          -1:0] ex_csr_wval,
                             st_csr_rval;
  logic                      ex_csr_we;

  //Write back
  logic [               4:0] wb_dst;
  logic [XLEN          -1:0] wb_r;
  logic [               0:0] wb_we;
  logic [XLEN          -1:0] wb_badaddr;

  //Debug
  logic                      du_we_rf,
                             du_we_frf,
                             du_we_csr,
                             du_we_pc;
  logic [DU_ADDR_SIZE  -1:0] du_addr;
  logic [XLEN          -1:0] du_dato,
                             du_dati_rf,
                             du_dati_csr;
  logic [              31:0] du_ie,
                             du_exceptions;


  ////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * Instruction Fetch
   *
   * Calculate next Program Counter
   * Fetch next instruction
   */
  riscv_if #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ),
    .PARCEL_SIZE    ( PARCEL_SIZE    ) )
  u_ifu ( .* );

  /*
   * Instruction Decoder
   *
   * Data from RF/ROB is available here
   */
  riscv_id #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ),
    .HAS_USER       ( HAS_USER       ),
    .HAS_SUPER      ( HAS_SUPER      ),
    .HAS_HYPER      ( HAS_HYPER      ),
    .HAS_RVA        ( HAS_RVA        ),
    .MULT_LATENCY   ( MULT_LATENCY   ) )
  u_idu (
    .id_src1  ( rf_src1[0]  ),
    .id_src2  ( rf_src2[0]  ),
    .*
  );

  /*
   * Execution units
   */
  riscv_ex #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ),
    .BP_GLOBAL_BITS ( BP_GLOBAL_BITS ),
    .MULT_LATENCY   ( MULT_LATENCY   ) )
  u_exu (
    .rf_srcv1 ( rf_srcv1[0] ),
    .rf_srcv2 ( rf_srcv2[0] ),
    .*
  );

  /*
   * Memory access
   */
  riscv_mem #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ) )
  u_mem   ( .* );

  /*
   * Memory acknowledge + Write Back unit
   */
  riscv_wb #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ) )
  u_wbu   (
    .rst_ni            ( rstn            ),
    .clk_i             ( clk             ),
    .mem_pc_i          ( mem_pc          ),
    .mem_instr_i       ( mem_instr       ),
    .mem_bubble_i      ( mem_bubble      ),
    .mem_r_i           ( mem_r           ),
    .mem_exception_i   ( mem_exception   ),
    .mem_memadr_i      ( mem_memadr      ),
    .wb_pc_o           ( wb_pc           ),
    .wb_stall_o        ( wb_stall        ),
    .wb_instr_o        ( wb_instr        ),
    .wb_bubble_o       ( wb_bubble       ),
    .wb_exception_o    ( wb_exception    ),
    .wb_badaddr_o      ( wb_badaddr      ),
    .dmem_ack_i        ( dmem_ack        ),
    .dmem_err_i        ( dmem_err        ),
    .dmem_q_i          ( dmem_q          ),
    .dmem_misaligned_i ( dmem_misaligned ),
    .dmem_page_fault_i ( dmem_page_fault ),
    .wb_dst_o          ( wb_dst          ),
    .wb_r_o            ( wb_r            ),
    .wb_we_o           ( wb_we           )
  );

  assign rf_dst [0] = wb_dst;
  assign rf_dstv[0] = wb_r;
  assign rf_we  [0] = wb_we;

  /*
   * Thread state
   */
  riscv_st #(
    .XLEN                  ( XLEN                  ),
    .PC_INIT               ( PC_INIT               ),
    .HAS_FPU               ( HAS_FPU               ),
    .HAS_MMU               ( HAS_MMU               ),
    .HAS_USER              ( HAS_USER              ),
    .HAS_SUPER             ( HAS_SUPER             ),
    .HAS_HYPER             ( HAS_HYPER             ),
    .PMP_CNT               ( PMP_CNT               ),
    .MNMIVEC_DEFAULT       ( MNMIVEC_DEFAULT       ),
    .MTVEC_DEFAULT         ( MTVEC_DEFAULT         ),
    .HTVEC_DEFAULT         ( HTVEC_DEFAULT         ),
    .STVEC_DEFAULT         ( STVEC_DEFAULT         ),
    .UTVEC_DEFAULT         ( UTVEC_DEFAULT         ) )
  u_csr    ( .* );

  /*
   *  Integer Register File
   */
  riscv_rf #(
    .XLEN    ( XLEN ),
    .RDPORTS ( 1    ),
    .WRPORTS ( 1    ) )
  u_rgf    ( .* );

  /*
   * Branch Prediction Unit
   *
   * Get Branch Prediction for Next Program Counter
   */
  riscv_bp #(
    .XLEN              ( XLEN           ),
    .PC_INIT           ( PC_INIT        ),
    .BP_GLOBAL_BITS    ( BP_GLOBAL_BITS ),
    .BP_LOCAL_BITS     ( BP_LOCAL_BITS  ),
    .BP_LOCAL_BITS_LSB ( 2              ) )
  u_bpu (
    .clk_i           ( clk           ),
    .rst_ni          ( rstn          ),

    .id_stall_i      ( id_stall      ),
    .if_parcel_pc_i  ( if_parcel_pc  ),
    .bp_bp_predict_o ( bp_bp_predict ),

    .ex_pc_i         ( ex_pc         ),
    .bu_bp_history_i ( bu_bp_history ),
    .bu_bp_predict_i ( bu_bp_predict ),
    .bu_bp_btaken_i  ( bu_bp_btaken  ),
    .bu_bp_update_i  ( bu_bp_update  )
  );

  /*
   * Debug Unit
   */
  riscv_du #(
    .XLEN           ( XLEN           ),
    .BREAKPOINTS    ( BREAKPOINTS    ) )
  u_dbg ( .* );

endmodule
