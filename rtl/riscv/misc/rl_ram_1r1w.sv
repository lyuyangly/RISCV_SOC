/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   1R1W RAM Block                                                //
//                                                                 //
/////////////////////////////////////////////////////////////////////
module rl_ram_1r1w #(
  parameter ABITS      = 10,
  parameter DBITS      = 32
) (
  input                    clk_i,
  input                    rst_ni,
 
  //Write side
  input  [ ABITS     -1:0] waddr_i,
  input  [ DBITS     -1:0] din_i,
  input                    we_i,
  input  [(DBITS+7)/8-1:0] be_i,

  //Read side
  input  [ ABITS     -1:0] raddr_i,
  input                    re_i,
  output [ DBITS     -1:0] dout_o
);
  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic             contention,
                    contention_reg;
  logic [DBITS-1:0] mem_dout,
                    din_dly;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
rl_ram_1r1w_generic #(
  .ABITS ( ABITS ),
  .DBITS ( DBITS ) )
ram_inst (
  .rst_ni  ( rst_ni   ),
  .clk_i   ( clk_i    ),

  .waddr_i ( waddr_i  ),
  .din_i   ( din_i    ),
  .we_i    ( we_i     ),
  .be_i    ( be_i     ),

  .raddr_i ( raddr_i  ),
  .dout_o  ( mem_dout )
);

  //TODO Handle 'be' ... requires partial old, partial new data
  //now ... write-first; we'll still need some bypass logic
  assign contention = we_i && (raddr_i == waddr_i) ? re_i : 1'b0; //prevent 'x' from propagating from eASIC memories

  always @(posedge clk_i)
  begin
      contention_reg <= contention;
      din_dly        <= din_i;
  end

  assign dout_o = contention_reg ? din_dly : mem_dout;

endmodule
