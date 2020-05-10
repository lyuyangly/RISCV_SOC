/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   Technology Independent (Inferrable) 1RW RAM Memory            //
//                                                                 //
/////////////////////////////////////////////////////////////////////
module rl_ram_1rw_generic #(
  parameter ABITS      = 10,
  parameter DBITS      = 32
) (
  input                        clk_i,
  input                        rst_ni,

  input      [ ABITS     -1:0] addr_i,
  input                        we_i,
  input      [(DBITS+7)/8-1:0] be_i,
  input      [ DBITS     -1:0] din_i,
  output reg [ DBITS     -1:0] dout_o
);

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  genvar i;

  reg [DBITS-1:0] mem_array [2**ABITS -1:0];  //memory array
  reg [ABITS-1:0] addr_reg;                   //latched read address


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //write side
generate
  for (i=0; i<(DBITS+7)/8; i++)
  begin: write
     if (i*8 +8 > DBITS)
     begin
         always @(posedge clk_i)
           if (we_i && be_i[i]) mem_array[ addr_i ] [DBITS-1:i*8] <= din_i[DBITS-1:i*8];
     end
     else
     begin
         always @(posedge clk_i)
           if (we_i && be_i[i]) mem_array[ addr_i ][i*8+:8] <= din_i[i*8+:8];
     end
  end
endgenerate

  //read side
  //per Altera's recommendations; avoids bypass logic
  always @(posedge clk_i)
    dout_o <= mem_array[ addr_i ];

endmodule
