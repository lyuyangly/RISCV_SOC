//##################################################################################################
//  Project     : RISC-V SOPC
//  Author      : Lyu Yang
//  Date        : 2020-05-10
//  Description : RISC-V SOPC
//##################################################################################################
`timescale 1ns / 1ns
module riscv_sopc (
    input                   clk         ,
    input                   rst_n       ,
    input                   uart_rxd    ,
    output                  uart_txd    ,
    output  [3:0]           pio
);

// Clock and Reset
wire            rst_sync;

// System Bus
wire            ihbusreq;
wire            ihgrant;
wire    [31:0]  ihaddr;
wire    [1:0]   ihtrans;
wire    [2:0]   ihsize;
wire    [2:0]   ihburst;
wire    [3:0]   ihprot;
wire            ihwrite;
wire    [31:0]  ihwdata;
wire            ihmasterlock;
wire            dhbusreq;
wire            dhgrant;
wire    [31:0]  dhaddr;
wire    [1:0]   dhtrans;
wire    [2:0]   dhsize;
wire    [2:0]   dhburst;
wire    [3:0]   dhprot;
wire            dhwrite;
wire    [31:0]  dhwdata;
wire            dhmasterlock;
wire    [31:0]  mhrdata;
wire            mhready;
wire    [1:0]   mhresp;

wire    [31:0]  shaddr;
wire    [1:0]   shtrans;
wire    [2:0]   shsize;
wire    [2:0]   shburst;
wire    [3:0]   shprot;
wire            shwrite;
wire    [31:0]  shwdata;
wire            shready;

wire            ram_hsel;
wire    [31:0]  ram_hrdata;
wire            ram_hready;
wire    [1:0]   ram_hresp;

wire            pio_hsel;
wire    [31:0]  pio_hrdata;
wire            pio_hready;
wire            pio_hresp;
wire    [31:0]  gpio;

// APB Subsystem AHB Interface
wire            apbsys_hsel;
wire    [31:0]  apbsys_hrdata;
wire            apbsys_hready;
wire            apbsys_hresp;

// RST SYNC
rst_sync U_RST_SYNC (
    .clk                    (clk                ),
    .arst_i                 (rst_n              ),
    .srst_o                 (rst_sync           )
);

// RISC-V CPU
riscv_top U_RISCV (
    .hclk                   (clk                ),
    .hreset_n               (rst_sync           ),
    .ihbusreq               (ihbusreq           ),
    .ihgrant                (ihgrant            ),
    .ihaddr                 (ihaddr             ),
    .ihtrans                (ihtrans            ),
    .ihsize                 (ihsize             ),
    .ihburst                (ihburst            ),
    .ihprot                 (ihprot             ),
    .ihwrite                (ihwrite            ),
    .ihwdata                (ihwdata            ),
    .ihmasterlock           (ihmasterlock       ),
    .ihready                (mhready            ),
    .ihrdata                (mhrdata            ),
    .ihresp                 (mhresp             ),
    .dhbusreq               (dhbusreq           ),
    .dhgrant                (dhgrant            ),
    .dhaddr                 (dhaddr             ),
    .dhtrans                (dhtrans            ),
    .dhsize                 (dhsize             ),
    .dhburst                (dhburst            ),
    .dhprot                 (dhprot             ),
    .dhwrite                (dhwrite            ),
    .dhwdata                (dhwdata            ),
    .dhmasterlock           (dhmasterlock       ),
    .dhready                (mhready            ),
    .dhrdata                (mhrdata            ),
    .dhresp                 (mhresp             ),
    .ext_nmi                (1'b0               ),
    .ext_tint               (1'b0               ),
    .ext_sint               (1'b0               ),
    .ext_int                (4'h0               ),
    .dbg_stall              (1'b0               ),
    .dbg_strb               (1'b0               ),
    .dbg_we                 (1'b0               ),
    .dbg_addr               (16'h0              ),
    .dbg_dati               (32'h0              ),
    .dbg_dato               (),
    .dbg_ack                (),
    .dbg_bp                 ()
);

// AHB Interconnect
amba_ahb_m2s4 U_AHB_MATRIX (
    .HCLK                   (clk                ),
    .HRESETn                (rst_sync           ),
    .REMAP                  (1'b0               ),
    .M0_HBUSREQ             (ihbusreq           ),
    .M0_HGRANT              (ihgrant            ),
    .M0_HTRANS              (ihtrans            ),
    .M0_HBURST              (ihburst            ),
    .M0_HSIZE               (ihsize             ),
    .M0_HWRITE              (ihwrite            ),
    .M0_HPROT               (ihprot             ),
    .M0_HLOCK               (ihmasterlock       ),
    .M0_HADDR               (ihaddr             ),
    .M0_HWDATA              (ihwdata            ),
    .M1_HBUSREQ             (dhbusreq           ),
    .M1_HGRANT              (dhgrant            ),
    .M1_HTRANS              (dhtrans            ),
    .M1_HBURST              (dhburst            ),
    .M1_HSIZE               (dhsize             ),
    .M1_HWRITE              (dhwrite            ),
    .M1_HPROT               (dhprot             ),
    .M1_HLOCK               (dhmasterlock       ),
    .M1_HADDR               (dhaddr             ),
    .M1_HWDATA              (dhwdata            ),
    .M_HRDATA               (mhrdata            ),
    .M_HREADY               (mhready            ),
    .M_HRESP                (mhresp             ),
    .S_HTRANS               (shtrans            ),
    .S_HBURST               (shburst            ),
    .S_HSIZE                (shsize             ),
    .S_HWRITE               (shwrite            ),
    .S_HPROT                (shprot             ),
    .S_HMASTER              (                   ),
    .S_HMASTLOCK            (                   ),
    .S_HADDR                (shaddr             ),
    .S_HWDATA               (shwdata            ),
    .S_HREADY               (shready            ),
    .S0_HSEL                (ram_hsel           ),
    .S0_HREADY              (ram_hready         ),
    .S0_HRESP               (ram_hresp          ),
    .S0_HSPLIT              (16'h0              ),
    .S0_HRDATA              (ram_hrdata         ),
    .S1_HSEL                (pio_hsel           ),
    .S1_HREADY              (pio_hready         ),
    .S1_HRESP               ({1'b0,pio_hresp}   ),
    .S1_HSPLIT              (16'h0              ),
    .S1_HRDATA              (pio_hrdata         ),
    .S2_HSEL                (                   ),
    .S2_HREADY              (1'b1               ),
    .S2_HRESP               (2'b00              ),
    .S2_HSPLIT              (16'h0              ),
    .S2_HRDATA              (32'h0              ),
    .S3_HSEL                (apbsys_hsel        ),
    .S3_HREADY              (apbsys_hready      ),
    .S3_HRESP               ({1'b0,apbsys_hresp}),
    .S3_HSPLIT              (16'h0              ),
    .S3_HRDATA              (apbsys_hrdata      )
);

// RAM For CPU
ahb_ram U_RAM (
    .hclk                   (clk                ),
    .hreset_n               (rst_sync           ),
    .hsel                   (ram_hsel           ),
    .htrans                 (shtrans            ),
    .hwrite                 (shwrite            ),
    .haddr                  (shaddr             ),
    .hsize                  (shsize             ),
    .hready_in              (shready            ),
    .hwdata                 (shwdata            ),
    .hready_out             (ram_hready         ),
    .hrdata                 (ram_hrdata         ),
    .hresp                  (ram_hresp          )
);

// Simple PIO
apb_pio U_PIO (
    .HCLK                   (clk                ),
    .HRESETn                (rst_sync           ),
    .HSEL                   (pio_hsel           ),
    .HADDR                  (shaddr             ),
    .HTRANS                 (shtrans            ),
    .HSIZE                  (shsize             ),
    .HPROT                  (shprot             ),
    .HWRITE                 (shwrite            ),
    .HREADY                 (shready            ),
    .HWDATA                 (shwdata            ),
    .HREADYOUT              (pio_hready         ),
    .HRDATA                 (pio_hrdata         ),
    .HRESP                  (pio_hresp          ),
    .GPIO                   (gpio               )
);

assign pio = gpio[3:0];

// APB Subsystem for UART
apb_subsystem #(
    .INCLUDE_IRQ_SYNCHRONIZER(1),
    .INCLUDE_APB_TEST_SLAVE  (1),
    .INCLUDE_APB_UART0       (1),
    .BE                      (0) ) U_APB_SUBSYS (
    .HCLK                   (clk                ),
    .HRESETn                (rst_sync           ),
    .HSEL                   (apbsys_hsel        ),
    .HADDR                  (shaddr[15:0]       ),
    .HTRANS                 (shtrans            ),
    .HWRITE                 (shwrite            ),
    .HSIZE                  (shsize             ),
    .HPROT                  (shprot             ),
    .HREADY                 (shready            ),
    .HWDATA                 (shwdata            ),
    .HREADYOUT              (apbsys_hready      ),
    .HRDATA                 (apbsys_hrdata      ),
    .HRESP                  (apbsys_hresp       ),
    // APB clock and reset
    .PCLK                   (clk                ),
    .PCLKG                  (clk                ),
    .PCLKEN                 (1'b1               ),
    .PRESETn                (rst_sync           ),
    // APB extension ports
    .PADDR                  (                   ),
    .PWRITE                 (                   ),
    .PWDATA                 (                   ),
    .PENABLE                (                   ),
    // Status Output for clock gating
    .APBACTIVE              (                   ),
    // UART
    .uart0_rxd              (uart_rxd           ),
    .uart0_txd              (uart_txd           ),
    .uart0_txen             (                   )
);

// PS SUBSYS
`ifdef SYNTHESIS
PS7SYS U_PS7();
`endif

endmodule
