/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   1RW (SP) Memory Block                                         //
//                                                                 //
/////////////////////////////////////////////////////////////////////
module rl_ram_1rw #(
  parameter ABITS      = 10,
  parameter DBITS      = 32
) (
  input                    rst_ni,
  input                    clk_i,

  input  [ ABITS     -1:0] addr_i,
  input                    we_i,
  input  [(DBITS+7)/8-1:0] be_i,
  input  [ DBITS     -1:0] din_i,
  output [ DBITS     -1:0] dout_o
);
  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
rl_ram_1rw_generic #(
  .ABITS ( ABITS ),
  .DBITS ( DBITS ) )
ram_inst (
  .rst_ni ( rst_ni ),
  .clk_i  ( clk_i  ),

  .addr_i ( addr_i ),
  .we_i   ( we_i   ),
  .be_i   ( be_i   ),
  .din_i  ( din_i  ),
  .dout_o ( dout_o )
);

endmodule
