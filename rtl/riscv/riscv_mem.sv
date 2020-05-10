//##################################################################################################
//  Project     : RISC-V
//  Author      : Lyu Yang
//  Date        : 2020-05-10
//  Description : Memory Unit
//##################################################################################################
module riscv_mem #(
  parameter            XLEN    = 32,
  parameter [XLEN-1:0] PC_INIT = 'h200
) (
  input                           clk,
  input                           rstn,

  input                           wb_stall,

  //Program counter
  input      [XLEN          -1:0] ex_pc,
  output reg [XLEN          -1:0] mem_pc,

  //Instruction
  input                           ex_bubble,
  input      [ILEN          -1:0] ex_instr,
  output reg                      mem_bubble,
  output reg [ILEN          -1:0] mem_instr,

  input      [EXCEPTION_SIZE-1:0] ex_exception,
                                  wb_exception,
  output reg [EXCEPTION_SIZE-1:0] mem_exception,
 


  //From EX
  input      [XLEN          -1:0] ex_r,
                                  dmem_adr,

  //To WB
  output reg [XLEN          -1:0] mem_r,
  output reg [XLEN          -1:0] mem_memadr
);
  ////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * Program Counter
   */
  always @(posedge clk,negedge rstn)
    if      (!rstn    ) mem_pc <= PC_INIT;
    else if (!wb_stall) mem_pc <= ex_pc;


  /*
   * Instruction
   */
  always @(posedge clk)
    if (!wb_stall) mem_instr <= ex_instr;


  always @(posedge clk,negedge rstn)
    if      (!rstn    ) mem_bubble <= 1'b1;
    else if (!wb_stall) mem_bubble <= ex_bubble;


  /*
   * Data
   */
  always @(posedge clk)
    if (!wb_stall) mem_r <= ex_r;

  always @(posedge clk)
    if (!wb_stall) mem_memadr <= dmem_adr;


  /*
   * Exception
   */
  always @(posedge clk, negedge rstn)
    if      (!rstn    ) mem_exception <= 'h0;
    else if (|mem_exception ||
             |wb_exception) mem_exception <= 'h0;
    else if (!wb_stall) mem_exception <= ex_exception;

endmodule
