//------------------------------------------------------------------------------
// Abstract : APB sub system
//------------------------------------------------------------------------------
module apb_subsystem #(
    // If peripherals are generated with asynchronous clock domain to HCLK of the processor
    // You might need to add synchroniser to the IRQ signal.
    // In this example APB subsystem, the IRQ synchroniser is used to all peripherals
    // when the INCLUDE_IRQ_SYNCHRONIZER parameter is set to 1. In practice you may have
    // some IRQ signals need to be synchronised and some do not.
    parameter  INCLUDE_IRQ_SYNCHRONIZER=0,
  
    // By default the APB subsystem include a simple test slave use in ARM for
    // validation purpose.  You can remove this test slave by setting the
    // INCLUDE_APB_TEST_SLAVE paramater to 0,
    parameter  INCLUDE_APB_TEST_SLAVE = 1,
  
    // Parameter options for including peripherals
    parameter  INCLUDE_APB_UART0      = 1,  // Include simple UART #0
  
    // Big endian - Add additional endian conversion logic to support big endian.
    //              (for ARM internal testing and evaluation of the processor in
    //              big endian configuration).
    //              0 = little endian, 1 = big endian
    //
    //              The example systems including this APB subsystem are designed as
    //              little endian. Most of the peripherals and memory system are
    //              little endian. This parameter is introduced to allows ARM to
    //              perform system level tests to verified behaviour of bus
    //              components in big endian configuration, and to allow designers
    //              to evaluate the processor in big endian configuration.
    //
    //              Use of this parameter is not recommended for actual product
    //              development as this adds extra hardware. For big endian systems
    //              ideally the peripherals should be modified to use a big endian
    //              programmer's model.
    parameter  BE = 0   )(
    // AHB interface for AHB to APB bridge
    input  wire           HCLK,
    input  wire           HRESETn,

    input  wire           HSEL,
    input  wire   [15:0]  HADDR,
    input  wire    [1:0]  HTRANS,
    input  wire           HWRITE,
    input  wire    [2:0]  HSIZE,
    input  wire    [3:0]  HPROT,
    input  wire           HREADY,
    input  wire   [31:0]  HWDATA,
    output wire           HREADYOUT,
    output wire   [31:0]  HRDATA,
    output wire           HRESP,

    input  wire           PCLK,    // Peripheral clock
    input  wire           PCLKG,   // Gate PCLK for bus interface only
    input  wire           PCLKEN,  // Clock divider for AHB to APB bridge
    input  wire           PRESETn, // APB reset

    output wire    [11:0] PADDR,
    output wire           PWRITE,
    output wire   [31:0]  PWDATA,
    output wire           PENABLE,

    output wire           APBACTIVE,

    // Peripherals
    // UART
    input  wire           uart0_rxd,
    output wire           uart0_txd,
    output wire           uart0_txen
);

// --------------------------------------------------------------------------
// Internal wires
// --------------------------------------------------------------------------
wire     [15:0]  i_paddr;
wire             i_psel;
wire             i_penable;
wire             i_pwrite;
wire     [2:0]   i_pprot;
wire     [3:0]   i_pstrb;
wire     [31:0]  i_pwdata;

// wire from APB slave mux to APB bridge
wire             i_pready_mux;
wire     [31:0]  i_prdata_mux;
wire             i_pslverr_mux;

// Peripheral signals
wire             uart0_psel;
wire     [31:0]  uart0_prdata;
wire             uart0_pready;
wire             uart0_pslverr;

wire             test_slave_psel;
wire     [31:0]  test_slave_prdata;
wire             test_slave_pready;
wire             test_slave_pslverr;

// Interrupt signals from peripherals

wire             uart0_txint;
wire             uart0_rxint;
wire             uart0_txovrint;
wire             uart0_rxovrint;
wire             uart0_combined_int;

// Synchronized interrupt signals
wire             i_uart0_txint;
wire             i_uart0_rxint;
wire             i_uart0_overflow_int;

// endian handling
wire             bigendian;
assign           bigendian = (BE!=0) ? 1'b1 : 1'b0;

wire   [31:0]    hwdata_le; // Little endian write data
wire   [31:0]    hrdata_le; // Little endian read data
wire             reg_be_swap_ctrl_en = HSEL & HTRANS[1] & HREADY & bigendian;
reg     [1:0]    reg_be_swap_ctrl; // registered byte swap control
wire    [1:0]    nxt_be_swap_ctrl; // next state of byte swap control

assign nxt_be_swap_ctrl[1] = bigendian & (HSIZE[1:0]==2'b10); // Swap upper and lower half word
assign nxt_be_swap_ctrl[0] = bigendian & (HSIZE[1:0]!=2'b00); // Swap byte within halfword

// Register byte swap control for data phase
always @(posedge HCLK or negedge HRESETn)
  begin
  if (~HRESETn)
    reg_be_swap_ctrl <= 2'b00;
  else if (reg_be_swap_ctrl_en)
    reg_be_swap_ctrl <= nxt_be_swap_ctrl;
  end

// swap byte within half word
wire  [31:0] hwdata_mux_1 = (reg_be_swap_ctrl[0] & bigendian) ?
   {HWDATA[23:16],HWDATA[31:24],HWDATA[7:0],HWDATA[15:8]}:
   {HWDATA[31:24],HWDATA[23:16],HWDATA[15:8],HWDATA[7:0]};
// swap lower and upper half word
assign       hwdata_le    = (reg_be_swap_ctrl[1] & bigendian) ?
   {hwdata_mux_1[15: 0],hwdata_mux_1[31:16]}:
   {hwdata_mux_1[31:16],hwdata_mux_1[15:0]};
// swap byte within half word
wire  [31:0] hrdata_mux_1 = (reg_be_swap_ctrl[0] & bigendian) ?
   {hrdata_le[23:16],hrdata_le[31:24],hrdata_le[ 7:0],hrdata_le[15:8]}:
   {hrdata_le[31:24],hrdata_le[23:16],hrdata_le[15:8],hrdata_le[7:0]};
// swap lower and upper half word
assign       HRDATA       = (reg_be_swap_ctrl[1] & bigendian) ?
   {hrdata_mux_1[15: 0],hrdata_mux_1[31:16]}:
   {hrdata_mux_1[31:16],hrdata_mux_1[15:0]};

// AHB to APB bus bridge
ahb_to_apb
#(.ADDRWIDTH      (16),
  .REGISTER_RDATA (1),
  .REGISTER_WDATA (0))
U_AHB_TO_APB(
  // AHB side
  .HCLK     (HCLK),
  .HRESETn  (HRESETn),
  .HSEL     (HSEL),
  .HADDR    (HADDR[15:0]),
  .HTRANS   (HTRANS),
  .HSIZE    (HSIZE),
  .HPROT    (HPROT),
  .HWRITE   (HWRITE),
  .HREADY   (HREADY),
  .HWDATA   (hwdata_le),

  .HREADYOUT(HREADYOUT), // AHB Outputs
  .HRDATA   (hrdata_le),
  .HRESP    (HRESP),

  .PADDR    (i_paddr[15:0]),
  .PSEL     (i_psel),
  .PENABLE  (i_penable),
  .PSTRB    (i_pstrb),
  .PPROT    (i_pprot),
  .PWRITE   (i_pwrite),
  .PWDATA   (i_pwdata),

  .APBACTIVE(APBACTIVE),
  .PCLKEN   (PCLKEN),     // APB clock enable signal

  .PRDATA   (i_prdata_mux),
  .PREADY   (i_pready_mux),
  .PSLVERR  (i_pslverr_mux)
  );

// APB slave multiplexer
apb_slave_mux
  #( // Parameter to determine which ports are used
  .PORT0_ENABLE  (0), // timer 0
  .PORT1_ENABLE  (0), // timer 1
  .PORT2_ENABLE  (0), // dual timer 0
  .PORT3_ENABLE  (0), // not used
  .PORT4_ENABLE  (INCLUDE_APB_UART0), // uart 0
  .PORT5_ENABLE  (0), // uart 1
  .PORT6_ENABLE  (0), // uart 2
  .PORT7_ENABLE  (0), // not used
  .PORT8_ENABLE  (0), // watchdog
  .PORT9_ENABLE  (0), // not used
  .PORT10_ENABLE (0), // not used
  .PORT11_ENABLE (INCLUDE_APB_TEST_SLAVE), // test slave for validation purpose
  .PORT12_ENABLE (0),
  .PORT13_ENABLE (0),
  .PORT14_ENABLE (0),
  .PORT15_ENABLE (0)
  )
  U_APB_SLVMUX (
  // Inputs
  .DECODE4BIT        (i_paddr[15:12]),
  .PSEL              (i_psel),
  // PSEL (output) and return status & data (inputs) for each port
  .PSEL0             (),
  .PREADY0           (),
  .PRDATA0           (),
  .PSLVERR0          (),

  .PSEL1             (),
  .PREADY1           (),
  .PRDATA1           (),
  .PSLVERR1          (),

  .PSEL2             (),
  .PREADY2           (),
  .PRDATA2           (),
  .PSLVERR2          (),

  .PSEL3             (),
  .PREADY3           (),
  .PRDATA3           (),
  .PSLVERR3          (),

  .PSEL4             (uart0_psel),
  .PREADY4           (uart0_pready),
  .PRDATA4           (uart0_prdata),
  .PSLVERR4          (uart0_pslverr),

  .PSEL5             (),
  .PREADY5           (),
  .PRDATA5           (),
  .PSLVERR5          (),

  .PSEL6             (),
  .PREADY6           (),
  .PRDATA6           (),
  .PSLVERR6          (),

  .PSEL7             (),
  .PREADY7           (),
  .PRDATA7           (),
  .PSLVERR7          (),

  .PSEL8             (),
  .PREADY8           (),
  .PRDATA8           (),
  .PSLVERR8          (),

  .PSEL9             (),
  .PREADY9           (),
  .PRDATA9           (),
  .PSLVERR9          (),

  .PSEL10            (),
  .PREADY10          (),
  .PRDATA10          (),
  .PSLVERR10         (),

  .PSEL11            (test_slave_psel),
  .PREADY11          (test_slave_pready),
  .PRDATA11          (test_slave_prdata),
  .PSLVERR11         (test_slave_pslverr),

  .PSEL12            (),
  .PREADY12          (),
  .PRDATA12          (),
  .PSLVERR12         (),

  .PSEL13            (),
  .PREADY13          (),
  .PRDATA13          (),
  .PSLVERR13         (),

  .PSEL14            (),
  .PREADY14          (),
  .PRDATA14          (),
  .PSLVERR14         (),

  .PSEL15            (),
  .PREADY15          (),
  .PRDATA15          (),
  .PSLVERR15         (),

  // Output
  .PREADY            (i_pready_mux),
  .PRDATA            (i_prdata_mux),
  .PSLVERR           (i_pslverr_mux)
  );

// -----------------------------------------------------------------
// UARTs
generate if (INCLUDE_APB_UART0 == 1) begin : gen_apb_uart_0
apb_uart U_APB_UART (
  .PCLK              (PCLK),     // Peripheral clock
  .PCLKG             (PCLKG),    // Gated PCLK for bus
  .PRESETn           (PRESETn),  // Reset

  .PSEL              (uart0_psel),     // APB interface inputs
  .PADDR             (i_paddr[11:2]),
  .PENABLE           (i_penable),
  .PWRITE            (i_pwrite),
  .PWDATA            (i_pwdata),

  .PRDATA            (uart0_prdata),   // APB interface outputs
  .PREADY            (uart0_pready),
  .PSLVERR           (uart0_pslverr),

  .ECOREVNUM         (4'h0),// Engineering-change-order revision bits

  .RXD               (uart0_rxd),      // Receive data

  .TXD               (uart0_txd),      // Transmit data
  .TXEN              (uart0_txen),     // Transmit Enabled

  .BAUDTICK          (),   // Baud rate x16 tick output (for testing)

  .TXINT             (uart0_txint),       // Transmit Interrupt
  .RXINT             (uart0_rxint),       // Receive  Interrupt
  .TXOVRINT          (uart0_txovrint),    // Transmit Overrun Interrupt
  .RXOVRINT          (uart0_rxovrint),    // Receive  Overrun Interrupt
  .UARTINT           (uart0_combined_int) // Combined Interrupt
);
end else
begin : gen_no_apb_uart
  assign uart0_prdata  = {32{1'b0}};
  assign uart0_pready  = 1'b1;
  assign uart0_pslverr = 1'b0;
  assign uart0_txd     = 1'b1;
  assign uart0_txen    = 1'b0;
  assign uart0_txint   = 1'b0;
  assign uart0_rxint   = 1'b0;
  assign uart0_txovrint = 1'b0;
  assign uart0_rxovrint = 1'b0;
  assign uart0_combined_int = 1'b0;
end endgenerate

// -----------------------------------------------------------------
// Test slave (for validation purpose)
generate if (INCLUDE_APB_TEST_SLAVE == 1) begin : gen_apb_test_slave

apb_test_slave U_APB_TEST_SLV (
  .PCLK              (PCLKG),    // use Gated PCLK for bus
  .PRESETn           (PRESETn),  // Reset

  .PSEL              (test_slave_psel),     // APB interface inputs
  .PADDR             (i_paddr[11:2]),
  .PENABLE           (i_penable),
  .PSTRB             (i_pstrb[3:0]),
  .PWRITE            (i_pwrite),
  .PWDATA            (i_pwdata),

  .PRDATA            (test_slave_prdata),   // APB interface outputs
  .PREADY            (test_slave_pready),
  .PSLVERR           (test_slave_pslverr)
);

end else
begin : gen_no_apb_test_slave
  assign test_slave_prdata  = {32{1'b0}};
  assign test_slave_pready  = 1'b1;
  assign test_slave_pslverr = 1'b0;
end endgenerate
// -----------------------------------------------------------------
// Connection to external
assign PADDR   = i_paddr[11:0];
assign PENABLE = i_penable;
assign PWRITE  = i_pwrite;
assign PWDATA  = i_pwdata;

assign uart0_overflow_int = uart0_txovrint|uart0_rxovrint;

generate if (INCLUDE_IRQ_SYNCHRONIZER == 0) begin : gen_irq_synchroniser
  // If PCLK is synchronous to HCLK, no need to have synchronizers
end else
begin : gen_no_irq_synchroniser
  // If IRQ source are asynchronous to HCLK, then we
  // need to add synchronizers to prevent metastability
  // on interrupt signals.
  irq_sync U_IRQ_SYNC0 (
    .RSTn  (HRESETn),
    .CLK   (HCLK),
    .IRQIN (uart0_txint),
    .IRQOUT(i_uart0_txint)
    );

  irq_sync U_IRQ_SYNC1 (
    .RSTn  (HRESETn),
    .CLK   (HCLK),
    .IRQIN (uart0_rxint),
    .IRQOUT(i_uart0_rxint)
    );

  irq_sync U_IRQ_SYNC2 (
    .RSTn  (HRESETn),
    .CLK   (HCLK),
    .IRQIN (uart0_overflow_int),
    .IRQOUT(i_uart0_overflow_int)
    );

end endgenerate

endmodule
