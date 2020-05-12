//##################################################################################################
//  Project     : RISC-V
//  Author      : Lyu Yang
//  Date        : 2020-05-10
//  Description : Correlating Branch Prediction Unit
//##################################################################################################
module riscv_bp #(
  parameter            XLEN              = 32,
  parameter [XLEN-1:0] PC_INIT           = 'h200,
  parameter            HAS_BPU           = 0,
  parameter            BP_GLOBAL_BITS    = 2,
  parameter            BP_LOCAL_BITS     = 10,
  parameter            BP_LOCAL_BITS_LSB = 2
) (
  input                       clk_i,
  input                       rst_ni,
 
  //Read side
  input                       id_stall_i,
  input  [XLEN          -1:0] if_parcel_pc_i,
  output [               1:0] bp_bp_predict_o,


  //Write side
  input  [XLEN          -1:0] ex_pc_i,
  input  [BP_GLOBAL_BITS-1:0] bu_bp_history_i,      //branch history
  input  [               1:0] bu_bp_predict_i,      //prediction bits for branch
  input                       bu_bp_btaken_i,
  input                       bu_bp_update_i
);


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  localparam ADR_BITS     = BP_GLOBAL_BITS + BP_LOCAL_BITS;
  localparam MEMORY_DEPTH = 1 << ADR_BITS;

  logic [ADR_BITS-1:0] radr,
                       wadr;

  logic [XLEN    -1:0] if_parcel_pc_dly;
  logic [         1:0] new_prediction;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  always @(posedge clk_i,negedge rst_ni)
    if      (!rst_ni    ) if_parcel_pc_dly <= PC_INIT;
    else if (!id_stall_i) if_parcel_pc_dly <= if_parcel_pc_i;


  assign radr = id_stall_i ? {bu_bp_history_i, if_parcel_pc_dly[BP_LOCAL_BITS_LSB +: BP_LOCAL_BITS]}
                           : {bu_bp_history_i, if_parcel_pc_i  [BP_LOCAL_BITS_LSB +: BP_LOCAL_BITS]};
  assign wadr = {bu_bp_history_i, ex_pc_i[BP_LOCAL_BITS_LSB +: BP_LOCAL_BITS]};


  /*
   *  Calculate new prediction bits
   *
   *  00<-->01<-->11<-->10
   */
  assign new_prediction[0] = bu_bp_predict_i[1] ^ bu_bp_btaken_i;
  assign new_prediction[1] = (bu_bp_predict_i[1] & ~bu_bp_predict_i[0]) | (bu_bp_btaken_i & bu_bp_predict_i[0]);

  /*
   * Hookup 1R1W memory
   */
  rl_ram_1r1w #(
    .ABITS   ( ADR_BITS        ),
    .DBITS   ( 2               ))
  u_bp_ram (
    .clk_i   ( clk_i           ),
    .rst_ni  ( rst_ni          ),
 
    //Write side
    .waddr_i ( wadr            ),
    .din_i   ( new_prediction  ),
    .we_i    ( bu_bp_update_i  ),
    .be_i    ( 1'b1            ),

    //Read side
    .raddr_i ( radr            ),
    .re_i    ( 1'b1            ),
    .dout_o  ( bp_bp_predict_o )
  );

endmodule
