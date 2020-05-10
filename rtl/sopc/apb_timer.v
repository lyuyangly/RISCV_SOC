//-----------------------------------------------------------------------------
// Abstract : Simple APB timer
//-----------------------------------------------------------------------------
//
//-------------------------------------
// Programmer's model
// 0x00 RW    CTRL[3:0]
//              [3] Timer Interrupt Enable
//              [2] Select External input as Clock
//              [1] Select External input as Enable
//              [0] Enable
// 0x04 RW    Current Value[31:0]
// 0x08 RW    Reload Value[31:0]
// 0x0C R/Wc  Timer Interrupt
//              [0] Interrupt, right 1 to clear
// 0x3E0 - 0x3FC  ID registers
//-------------------------------------
module apb_timer (
    input  wire        PCLK,    // PCLK for timer operation
    input  wire        PCLKG,   // Gated clock
    input  wire        PRESETn, // Reset
    input  wire        PSEL,    // Device select
    input  wire [11:2] PADDR,   // Address
    input  wire        PENABLE, // Transfer control
    input  wire        PWRITE,  // Write control
    input  wire [31:0] PWDATA,  // Write data
    input  wire  [3:0] ECOREVNUM,// Engineering-change-order revision bits
    output wire [31:0] PRDATA,  // Read data
    output wire        PREADY,  // Device ready
    output wire        PSLVERR, // Device error response
    input  wire        EXTIN,   // External input
    output wire        TIMERINT // Timer interrupt output
);

// Local ID parameters, APB timer part number is 0x822
localparam  ARM_CMSDK_APB_TIMER_PID0 = 8'h22;
localparam  ARM_CMSDK_APB_TIMER_PID1 = 8'hB8;
localparam  ARM_CMSDK_APB_TIMER_PID2 = 8'h1B;
localparam  ARM_CMSDK_APB_TIMER_PID3 = 4'h0;
localparam  ARM_CMSDK_APB_TIMER_PID4 = 8'h04;
localparam  ARM_CMSDK_APB_TIMER_PID5 = 8'h00;
localparam  ARM_CMSDK_APB_TIMER_PID6 = 8'h00;
localparam  ARM_CMSDK_APB_TIMER_PID7 = 8'h00;
localparam  ARM_CMSDK_APB_TIMER_CID0 = 8'h0D;
localparam  ARM_CMSDK_APB_TIMER_CID1 = 8'hF0;
localparam  ARM_CMSDK_APB_TIMER_CID2 = 8'h05;
localparam  ARM_CMSDK_APB_TIMER_CID3 = 8'hB1;

// Signals for read/write controls
wire          read_enable;
wire          write_enable;
wire          write_enable00; // Write enable for Control register
wire          write_enable04; // Write enable for Current Value register
wire          write_enable08; // Write enable for Reload Value register
wire          write_enable0c; // Write enable for Interrupt register
reg     [7:0] read_mux_byte0;
reg     [7:0] read_mux_byte0_reg;
reg    [31:0] read_mux_word;
wire    [3:0] pid3_value;

// Signals for Control registers
reg     [3:0] reg_ctrl;
reg    [31:0] reg_curr_val;
reg    [31:0] reg_reload_val;
reg    [31:0] nxt_curr_val;

// Internal signals
reg           ext_in_sync1;  // Synchronisation registers for external input
reg           ext_in_sync2;  // Synchronisation registers for external input
reg           ext_in_delay;  // Delay register for edge detection
wire          ext_in_enable; // enable control for external input
wire          dec_ctrl;      // Decrement control
wire          clk_ctrl;      // Clk select result
wire          enable_ctrl;   // Enable select result
wire          edge_detect;   // Edge detection
reg           reg_timer_int; // Timer interrupt output register
wire          timer_int_clear; // Clear timer interrupt status
wire          timer_int_set;   // Set timer interrupt status
wire          update_timer_int;// Update Timer interrupt output register

// Start of main code
// Read and write control signals
assign  read_enable  = PSEL & (~PWRITE); // assert for whole APB read transfer
assign  write_enable = PSEL & (~PENABLE) & PWRITE; // assert for 1st cycle of write transfer
assign  write_enable00 = write_enable & (PADDR[11:2] == 10'h000);
assign  write_enable04 = write_enable & (PADDR[11:2] == 10'h001);
assign  write_enable08 = write_enable & (PADDR[11:2] == 10'h002);
assign  write_enable0c = write_enable & (PADDR[11:2] == 10'h003);

// Write operations
// Control register
always @(posedge PCLKG or negedge PRESETn)
begin
  if (~PRESETn)
    reg_ctrl <= {4{1'b0}};
  else if (write_enable00)
    reg_ctrl <= PWDATA[3:0];
end

// Current Value register
always @(posedge PCLK or negedge PRESETn)
begin
  if (~PRESETn)
    reg_curr_val <= {32{1'b0}};
  else if (write_enable04 | dec_ctrl)
    reg_curr_val <= nxt_curr_val;
end

// Reload Value register
always @(posedge PCLKG or negedge PRESETn)
begin
  if (~PRESETn)
    reg_reload_val <= {32{1'b0}};
  else if (write_enable08)
    reg_reload_val <= PWDATA[31:0];
end

// Read operation, partitioned into two parts to reduce gate counts
// and improve timing
assign pid3_value  = ARM_CMSDK_APB_TIMER_PID3;

// lower 8 bits -registered. Current value register mux not done here
// because the value can change every cycle
always @(PADDR or reg_ctrl or reg_reload_val or reg_timer_int or ECOREVNUM or pid3_value)
begin
 if (PADDR[11:4] == 8'h00) begin
   case (PADDR[3:2])
   2'h0: read_mux_byte0 =  {{4{1'b0}}, reg_ctrl};
   2'h1: read_mux_byte0 =   {8{1'b0}};
   2'h2: read_mux_byte0 =  reg_reload_val[7:0];
   2'h3: read_mux_byte0 =  {{7{1'b0}}, reg_timer_int};
   default:  read_mux_byte0 =   {8{1'bx}}; // x propagation
   endcase
 end
 else if (PADDR[11:6] == 6'h3F) begin
   case  (PADDR[5:2])
     4'h0, 4'h1,4'h2,4'h3: read_mux_byte0 =   {8{1'b0}};
 // ID register - constant values
     4'h4: read_mux_byte0 = ARM_CMSDK_APB_TIMER_PID4; // 0xFD0 : PID 4
     4'h5: read_mux_byte0 = ARM_CMSDK_APB_TIMER_PID5; // 0xFD4 : PID 5
     4'h6: read_mux_byte0 = ARM_CMSDK_APB_TIMER_PID6; // 0xFD8 : PID 6
     4'h7: read_mux_byte0 = ARM_CMSDK_APB_TIMER_PID7; // 0xFDC : PID 7
     4'h8: read_mux_byte0 = ARM_CMSDK_APB_TIMER_PID0; // 0xFE0 : PID 0  APB timer part number[7:0]
     4'h9: read_mux_byte0 = ARM_CMSDK_APB_TIMER_PID1; // 0xFE0 : PID 1 [7:4] jep106_id_3_0. [3:0] part number [11:8]
     4'hA: read_mux_byte0 = ARM_CMSDK_APB_TIMER_PID2; // 0xFE0 : PID 2 [7:4] revision, [3] jedec_used. [2:0] jep106_id_6_4
     4'hB: read_mux_byte0 = {ECOREVNUM[3:0],pid3_value[3:0]};
                                                     // 0xFE0 : PID 3 [7:4] ECO revision, [3:0] modification number
     4'hC: read_mux_byte0 = ARM_CMSDK_APB_TIMER_CID0; // 0xFF0 : CID 0
     4'hD: read_mux_byte0 = ARM_CMSDK_APB_TIMER_CID1; // 0xFF4 : CID 1 PrimeCell class
     4'hE: read_mux_byte0 = ARM_CMSDK_APB_TIMER_CID2; // 0xFF8 : CID 2
     4'hF: read_mux_byte0 = ARM_CMSDK_APB_TIMER_CID3; // 0xFFC : CID 3
     default : read_mux_byte0 = {8{1'bx}}; // x propogation
    endcase
  end
  else begin
     read_mux_byte0 =   {8{1'b0}};     //default read out value
  end
end

// Register read data
always @(posedge PCLKG or negedge PRESETn)
begin
  if (~PRESETn)
    read_mux_byte0_reg <= {8{1'b0}};
  else if (read_enable)
    read_mux_byte0_reg <= read_mux_byte0;
end

// Second level of read mux
always @(PADDR or read_mux_byte0_reg or reg_curr_val or reg_reload_val)
begin
    if (PADDR[11:4] == 8'h00) begin
      case (PADDR[3:2])
        2'b01:   read_mux_word = {reg_curr_val[31:0]};
        2'b10:   read_mux_word = {reg_reload_val[31:8],read_mux_byte0_reg};
        2'b00,2'b11:  read_mux_word = {{24{1'b0}} ,read_mux_byte0_reg};
        default : read_mux_word = {32{1'bx}};
      endcase
    end
    else begin
      read_mux_word = {{24{1'b0}}  ,read_mux_byte0_reg};
    end
end

// Output read data to APB
assign PRDATA = (read_enable) ? read_mux_word : {32{1'b0}};
assign PREADY  = 1'b1; // Always ready
assign PSLVERR = 1'b0; // Always okay

assign ext_in_enable = reg_ctrl[1] | reg_ctrl[2] | PSEL;

// Synchronize input and delay for edge detection
always @(posedge PCLK or negedge PRESETn)
begin
  if (~PRESETn)
    begin
    ext_in_sync1 <= 1'b0;
    ext_in_sync2 <= 1'b0;
    ext_in_delay <= 1'b0;
    end
  else if (ext_in_enable)
    begin
    ext_in_sync1 <= EXTIN;
    ext_in_sync2 <= ext_in_sync1;
    ext_in_delay <= ext_in_sync2;
    end
end

// Edge detection
assign edge_detect = ext_in_sync2 & (~ext_in_delay);

// Clock selection
assign clk_ctrl    = reg_ctrl[2] ? edge_detect : 1'b1;

// Enable selection
assign enable_ctrl = reg_ctrl[1] ? ext_in_sync2 : 1'b1;

// Overall decrement control
assign dec_ctrl    = reg_ctrl[0] & enable_ctrl & clk_ctrl;

// Decrement counter
always @(write_enable04 or PWDATA or dec_ctrl or reg_curr_val or reg_reload_val)
begin
    if (write_enable04)
      nxt_curr_val = PWDATA[31:0]; // Software write to timer
    else if (dec_ctrl)
      begin
      if (reg_curr_val == {32{1'b0}})
        nxt_curr_val = reg_reload_val; // Reload
      else
        nxt_curr_val = reg_curr_val - 1'b1; // Decrement
      end
    else
      nxt_curr_val = reg_curr_val; // Unchanged
end

// Interrupt generation
// Trigger an interrupt when decrement to 0 and interrupt enabled
// and hold it until clear by software
assign timer_int_set   = (dec_ctrl & reg_ctrl[3] & (reg_curr_val==32'h00000001));
assign timer_int_clear = write_enable0c & PWDATA[0];
assign update_timer_int= timer_int_set | timer_int_clear;

// Registering interrupt output
always @(posedge PCLK or negedge PRESETn)
begin
  if (~PRESETn)
    reg_timer_int <= 1'b0;
  else if (update_timer_int)
    reg_timer_int <= timer_int_set;
end

// Connect to external
assign TIMERINT = reg_timer_int;

endmodule
