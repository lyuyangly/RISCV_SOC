//##################################################################################################
//  Project     : RISC-V
//  Author      : Lyu Yang
//  Date        : 2020-05-10
//  Description : RISC-V PKG
//##################################################################################################
package riscv_pkg;

// AHB BIU Type Define
    typedef enum logic [2:0] {
         BYTE  = 3'b000,
         HWORD = 3'b001,
         WORD  = 3'b010,
         DWORD = 3'b011,
         QWORD = 3'b100,
         UNDEF_SIZE = 3'bxxx
    } biu_size_t;

    typedef enum logic [2:0] {
         SINGLE  = 3'b000,
         INCR    = 3'b001,
         WRAP4   = 3'b010,
         INCR4   = 3'b011,
         WRAP8   = 3'b100,
         INCR8   = 3'b101,
         WRAP16  = 3'b110,
         INCR16  = 3'b111,
         UNDEF_BURST = 3'bxxx
    } biu_type_t;

// Debug Unit
    parameter DBG_ADDR_SIZE = 16; // 16bit Debug Addresses
    parameter DU_ADDR_SIZE  = 12; // 12bit internal address bus

    parameter MAX_BREAKPOINTS = 8;

    /*
     * Debug Unit Memory Map
     *
     * addr_bits  Description
     * ------------------------------
     * 15-12      Debug bank
     * 11- 0      Address inside bank

     * Bank0      Control & Status
     * Bank1      GPRs
     * Bank2      CSRs
     * Bank3-15   reserved
     */
    parameter [15:12] DBG_INTERNAL = 4'h0,
                      DBG_GPRS     = 4'h1,
                      DBG_CSRS     = 4'h2;

    /*
     * Control registers
     * 0 00 00 ctrl
     * 0 00 01
     * 0 00 10 ie
     * 0 00 11 cause
     *  reserved
     *
     * 1 0000 BP0 Ctrl
     * 1 0001 BP0 Data
     * 1 0010 BP1 Ctrl
     * 1 0011 BP1 Data
     * ...
     * 1 1110 BP7 Ctrl
     * 1 1111 BP7 Data
     */
    parameter [4:0] DBG_CTRL    = 'h00, //debug control
                    DBG_HIT     = 'h01, //debug HIT register
                    DBG_IE      = 'h02, //debug interrupt enable (which exception halts the CPU?)
                    DBG_CAUSE   = 'h03, //debug cause (which exception halted the CPU?)
                    DBG_BPCTRL0 = 'h10, //hardware breakpoint0 control
                    DBG_BPDATA0 = 'h11, //hardware breakpoint0 data
                    DBG_BPCTRL1 = 'h12, //hardware breakpoint1 control
                    DBG_BPDATA1 = 'h13, //hardware breakpoint1 data
                    DBG_BPCTRL2 = 'h14, //hardware breakpoint2 control
                    DBG_BPDATA2 = 'h15, //hardware breakpoint2 data
                    DBG_BPCTRL3 = 'h16, //hardware breakpoint3 control
                    DBG_BPDATA3 = 'h17, //hardware breakpoint3 data
                    DBG_BPCTRL4 = 'h18, //hardware breakpoint4 control
                    DBG_BPDATA4 = 'h19, //hardware breakpoint4 data
                    DBG_BPCTRL5 = 'h1a, //hardware breakpoint5 control
                    DBG_BPDATA5 = 'h1b, //hardware breakpoint5 data
                    DBG_BPCTRL6 = 'h1c, //hardware breakpoint6 control
                    DBG_BPDATA6 = 'h1d, //hardware breakpoint6 data
                    DBG_BPCTRL7 = 'h1e, //hardware breakpoint7 control
                    DBG_BPDATA7 = 'h1f; //hardware breakpoint7 data


    //Debug codes
    parameter        DEBUG_SINGLE_STEP_TRACE  = 0,
                     DEBUG_BRANCH_TRACE       = 1;

    parameter        BP_CTRL_IMP         = 0,
                     BP_CTRL_ENA         = 1,
                     BP_CTRL_CC_FETCH    = 3'h0,
                     BP_CTRL_CC_LD_ADR   = 3'h1,
                     BP_CTRL_CC_ST_ADR   = 3'h2,
                     BP_CTRL_CC_LDST_ADR = 3'h3;

    /*
     * addr         Key  Description
     * --------------------------------------------
     * 0x000-0x01f  GPR  General Purpose Registers
     * 0x100-0x11f  FPR  Floating Point Registers
     * 0x200        PC   Program Counter
     * 0x201        PPC  Previous Program Counter
     */
    parameter [11:0] DBG_GPR = 12'b0000_000?_????,
                     DBG_FPR = 12'b0001_000?_????,
                     DBG_NPC = 12'h200,
                     DBG_PPC = 12'h201;

    // OP Code
    parameter [31:0] INSTR_NOP = 'h13;

    /*
     * Opcodes
     */
    parameter [ 6:2] OPC_LOAD     = 5'b00_000,
                     OPC_LOAD_FP  = 5'b00_001,
                     OPC_MISC_MEM = 5'b00_011,
                     OPC_OP_IMM   = 5'b00_100,
                     OPC_AUIPC    = 5'b00_101,
                     OPC_OP_IMM32 = 5'b00_110,
                     OPC_STORE    = 5'b01_000,
                     OPC_STORE_FP = 5'b01_001,
                     OPC_AMO      = 5'b01_011,
                     OPC_OP       = 5'b01_100,
                     OPC_LUI      = 5'b01_101,
                     OPC_OP32     = 5'b01_110,
                     OPC_MADD     = 5'b10_000,
                     OPC_MSUB     = 5'b10_001,
                     OPC_NMSUB    = 5'b10_010,
                     OPC_NMADD    = 5'b10_011,
                     OPC_OP_FP    = 5'b10_100,
                     OPC_BRANCH   = 5'b11_000,
                     OPC_JALR     = 5'b11_001,
                     OPC_JAL      = 5'b11_011,
                     OPC_SYSTEM   = 5'b11_100;

    /*
     * RV32/RV64 Base instructions
     */
    //                            f7       f3 opcode
    parameter [14:0] LUI    = 15'b???????_???_01101,
                     AUIPC  = 15'b???????_???_00101,
                     JAL    = 15'b???????_???_11011,
                     JALR   = 15'b???????_000_11001,
                     BEQ    = 15'b???????_000_11000,
                     BNE    = 15'b???????_001_11000,
                     BLT    = 15'b???????_100_11000,
                     BGE    = 15'b???????_101_11000,
                     BLTU   = 15'b???????_110_11000,
                     BGEU   = 15'b???????_111_11000,
                     LB     = 15'b???????_000_00000,
                     LH     = 15'b???????_001_00000,
                     LW     = 15'b???????_010_00000,
                     LBU    = 15'b???????_100_00000,
                     LHU    = 15'b???????_101_00000,
                     LWU    = 15'b???????_110_00000,
                     LD     = 15'b???????_011_00000,
                     SB     = 15'b???????_000_01000,
                     SH     = 15'b???????_001_01000,
                     SW     = 15'b???????_010_01000,
                     SD     = 15'b???????_011_01000,
                     ADDI   = 15'b???????_000_00100,
                     ADDIW  = 15'b???????_000_00110,
                     ADD    = 15'b0000000_000_01100,
                     ADDW   = 15'b0000000_000_01110,
                     SUB    = 15'b0100000_000_01100,
                     SUBW   = 15'b0100000_000_01110,
                     XORI   = 15'b???????_100_00100,
                     XOR    = 15'b0000000_100_01100,
                     ORI    = 15'b???????_110_00100,
                     OR     = 15'b0000000_110_01100,
                     ANDI   = 15'b???????_111_00100,
                     AND    = 15'b0000000_111_01100,
                     SLLI   = 15'b000000?_001_00100,
                     SLLIW  = 15'b0000000_001_00110,
                     SLL    = 15'b0000000_001_01100,
                     SLLW   = 15'b0000000_001_01110,
                     SLTI   = 15'b???????_010_00100,
                     SLT    = 15'b0000000_010_01100,
                     SLTU   = 15'b0000000_011_01100,
                     SLTIU  = 15'b???????_011_00100,
                     SRLI   = 15'b000000?_101_00100,
                     SRLIW  = 15'b0000000_101_00110,
                     SRL    = 15'b0000000_101_01100,
                     SRLW   = 15'b0000000_101_01110,
                     SRAI   = 15'b010000?_101_00100,
                     SRAIW  = 15'b0100000_101_00110,
                     SRA    = 15'b0100000_101_01100,
                     SRAW   = 15'b0100000_101_01110,

                     //pseudo instructions
                     SYSTEM = 15'b???????_000_11100, //excludes RDxxx instructions
                     MISCMEM= 15'b???????_???_00011;


    /*
     * SYSTEM/MISC_MEM opcodes
     */
    parameter [31:0] FENCE      = 32'b0000????????_00000_000_00000_0001111,
                     SFENCE_VM  = 32'b000100000100_?????_000_00000_1110011,
                     FENCE_I    = 32'b000000000000_00000_001_00000_0001111,
                     ECALL      = 32'b000000000000_00000_000_00000_1110011,
                     EBREAK     = 32'b000000000001_00000_000_00000_1110011,
                     MRET       = 32'b001100000010_00000_000_00000_1110011,
                     HRET       = 32'b001000000010_00000_000_00000_1110011,
                     SRET       = 32'b000100000010_00000_000_00000_1110011,
                     URET       = 32'b000000000010_00000_000_00000_1110011,
//                     MRTS       = 32'b001100000101_00000_000_00000_1110011,
//                     MRTH       = 32'b001100000110_00000_000_00000_1110011,
//                     HRTS       = 32'b001000000101_00000_000_00000_1110011,
                     WFI        = 32'b000100000101_00000_000_00000_1110011;

    //                                f7      f3  opcode
    parameter [14:0] CSRRW      = 15'b???????_001_11100,
                     CSRRS      = 15'b???????_010_11100,
                     CSRRC      = 15'b???????_011_11100,
                     CSRRWI     = 15'b???????_101_11100,
                     CSRRSI     = 15'b???????_110_11100,
                     CSRRCI     = 15'b???????_111_11100;


    /*
     * RV32/RV64 A-Extensions instructions
     */
    //                            f7       f3 opcode
    parameter [14:0] LRW      = 15'b00010??_010_01011,
                     SCW      = 15'b00011??_010_01011,
                     AMOSWAPW = 15'b00001??_010_01011,
                     AMOADDW  = 15'b00000??_010_01011,
                     AMOXORW  = 15'b00100??_010_01011,
                     AMOANDW  = 15'b01100??_010_01011,
                     AMOORW   = 15'b01000??_010_01011,
                     AMOMINW  = 15'b10000??_010_01011,
                     AMOMAXW  = 15'b10100??_010_01011,
                     AMOMINUW = 15'b11000??_010_01011,
                     AMOMAXUW = 15'b11100??_010_01011;

    parameter [14:0] LRD      = 15'b00010??_011_01011,
                     SCD      = 15'b00011??_011_01011,
                     AMOSWAPD = 15'b00001??_011_01011,
                     AMOADDD  = 15'b00000??_011_01011,
                     AMOXORD  = 15'b00100??_011_01011,
                     AMOANDD  = 15'b01100??_011_01011,
                     AMOORD   = 15'b01000??_011_01011,
                     AMOMIND  = 15'b10000??_011_01011,
                     AMOMAXD  = 15'b10100??_011_01011,
                     AMOMINUD = 15'b11000??_011_01011,
                     AMOMAXUD = 15'b11100??_011_01011;

    /*
     * RV32/RV64 M-Extensions instructions
     */
    //                            f7       f3 opcode
    parameter [14:0] MUL    = 15'b0000001_000_01100,
                     MULH   = 15'b0000001_001_01100,
                     MULW   = 15'b0000001_000_01110,
                     MULHSU = 15'b0000001_010_01100,
                     MULHU  = 15'b0000001_011_01100,
                     DIV    = 15'b0000001_100_01100,
                     DIVW   = 15'b0000001_100_01110,
                     DIVU   = 15'b0000001_101_01100,
                     DIVUW  = 15'b0000001_101_01110,
                     REM    = 15'b0000001_110_01100,
                     REMW   = 15'b0000001_110_01110,
                     REMU   = 15'b0000001_111_01100,
                     REMUW  = 15'b0000001_111_01110;
// Thread State
    /*
     *  Per Supervisor Spec draft 1.10
     *
     */

    //MCPUID mapping
    typedef struct packed {
      logic z,y,x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a;
    } misa_extensions_struct;

    typedef struct packed {
      logic [ 1:0] base;
      misa_extensions_struct extensions;
    } misa_struct;


    typedef struct packed {
      logic [ 7:0] bank;
      logic [ 6:0] offset;
    } mvendorid_struct;


    //MSTATUS mapping
    typedef struct packed {
      logic       sd;
      logic [1:0] sxl,                 //S-Mode XLEN
                  uxl;                 //U-Mode XLEN
//    logic [4:0] vm;                  //virtualisation management
      logic       tsr,
                  tw,
                  tvm,
                  mxr,
                  sum,
                  mprv;                //memory privilege

      logic [1:0] xs;                  //user extension status
      logic [1:0] fs;                  //floating point status

      logic [1:0] mpp, hpp;            //previous privilege levels
      logic       spp;                 //supervisor previous privilege level
      logic       mpie,hpie,spie,upie; //previous interrupt enable bits
      logic       mie, hie, sie, uie;  //interrupt enable bits (per privilege level)
    } mstatus_struct;

    typedef struct packed {
      logic meip, heip, seip, ueip, mtip, htip, stip, utip, msip, hsip, ssip,usip;
    } mip_struct;

    typedef struct packed {
      logic meie, heie, seie, ueie, mtie, htie, stie, utie, msie, hsie, ssie, usie;
    } mie_struct;

    //PMP-CFG register
    typedef enum logic [1:0] {
      OFF   = 2'd0,
      TOR   = 2'd1,
      NA4   = 2'd2,
      NAPOT = 2'd3
    } pmpcfg_a_t;

    typedef struct packed {
      logic       l;
      logic [1:0] reserved;
      pmpcfg_a_t  a;
      logic       x,
                  w,
                  r;
    } pmpcfg_t;

    localparam PMPCFG_MASK = 8'h9F;

    // Timer
    typedef struct packed {
      logic [31:0] h,l;
    } timer_struct; //mtime, htime, stime

    //user FCR mapping
    typedef struct packed {
      logic [2:0] rm;
      logic [4:0] flags;
    } fcsr_struct;

    //CSR mapping
    parameter [11:0] //User
                     //User Trap Setup
                     USTATUS       = 'h000,
                     UIE           = 'h004,
                     UTVEC         = 'h005,
                     //User Trap Handling
                     USCRATCH      = 'h040,
                     UEPC          = 'h041,
                     UCAUSE        = 'h042,
//                   UBADADDR      = 'h043,
                     UTVAL         = 'h043,
                     UIP           = 'h044,
                     //User Floating-Point CSRs
                     FFLAGS        = 'h001,
                     FRM           = 'h002,
                     FCSR          = 'h003,
                     //User Counters/Timers
                     CYCLE         = 'hC00,
                     TIME          = 'hC01,
                     INSTRET       = 'hC02,
                     HPMCOUNTER3   = 'hC03, //until HPMCOUNTER31='hC1F
                     CYCLEH        = 'hC80,
                     TIMEH         = 'hC81,
                     INSTRETH      = 'hC82,
                     HPMCOUNTER3H  = 'hC83, //until HPMCONTER31='hC9F

                     //Supervisor
                     //Supervisor Trap Setup
                     SSTATUS       = 'h100,
                     SEDELEG       = 'h102,
                     SIDELEG       = 'h103,
                     SIE           = 'h104,
                     STVEC         = 'h105,
                     SCOUNTEREN    = 'h106,
                     //Supervisor Trap Handling
                     SSCRATCH      = 'h140,
                     SEPC          = 'h141,
                     SCAUSE        = 'h142,
                     STVAL         = 'h143,
                     SIP           = 'h144,
                     //Supervisor Protection and Translation
                     SATP          = 'h180,
/*
                     //Hypervisor
                     //Hypervisor trap setup
                     HSTATUS       = 'h200,
                     HEDELEG       = 'h202,
                     HIDELEG       = 'h203,
                     HIE           = 'h204,
                     HTVEC         = 'h205,
                     //Hypervisor Trap Handling
                     HSCRATCH      = 'h240,
                     HEPC          = 'h241,
                     HCAUSE        = 'h242,
                     HTVAL         = 'h243,
                     HIP           = 'h244,
*/

                     //Machine
                     //Machine Information
                     MVENDORID     = 'hF11,
                     MARCHID       = 'hF12,
                     MIMPID        = 'hF13,
                     MHARTID       = 'hF14,
                     //Machine Trap Setup
                     MSTATUS       = 'h300,
                     MISA          = 'h301,
                     MEDELEG       = 'h302,
                     MIDELEG       = 'h303,
                     MIE           = 'h304,
                     MNMIVEC       = 'h7C0, //ROALOGIC NMI Vector
                     MTVEC         = 'h305,
                     MCOUNTEREN    = 'h306,
                     //Machine Trap Handling
                     MSCRATCH      = 'h340,
                     MEPC          = 'h341,
                     MCAUSE        = 'h342,
                     MTVAL         = 'h343,
                     MIP           = 'h344,
                     //Machine Protection and Translation
                     PMPCFG0       = 'h3A0,
                     PMPCFG1       = 'h3A1, //RV32 only
                     PMPCFG2       = 'h3A2,
                     PMPCFG3       = 'h3A3, //RV32 only
                     PMPADDR0      = 'h3B0,
                     PMPADDR1      = 'h3B1,
                     PMPADDR2      = 'h3B2,
                     PMPADDR3      = 'h3B3,
                     PMPADDR4      = 'h3B4,
                     PMPADDR5      = 'h3B5,
                     PMPADDR6      = 'h3B6,
                     PMPADDR7      = 'h3B7,
                     PMPADDR8      = 'h3B8,
                     PMPADDR9      = 'h3B9,
                     PMPADDR10     = 'h3BA,
                     PMPADDR11     = 'h3BB,
                     PMPADDR12     = 'h3BC,
                     PMPADDR13     = 'h3BD,
                     PMPADDR14     = 'h3BE,
                     PMPADDR15     = 'h3BF,

                     //Machine Counters/Timers
                     MCYCLE        = 'hB00,
                     MINSTRET      = 'hB02,
                     MHPMCOUNTER3  = 'hB03, //until MHPMCOUNTER31='hB1F
                     MCYCLEH       = 'hB80,
                     MINSTRETH     = 'hB82,
                     MHPMCOUNTER3H = 'hB83, //until MHPMCOUNTER31H='hB9F
                     //Machine Counter Setup
                     MHPEVENT3     = 'h323,   //until MHPEVENT31 = 'h33f

                     //Debug
                     TSELECT       = 'h7A0,
                     TDATA1        = 'h7A1,
                     TDATA2        = 'h7A2,
                     TDATA3        = 'h7A3,
                     DCSR          = 'h7B0,
                     DPC           = 'h7B1,
                     DSCRATCH      = 'h7B2;

    //MXL mapping
    parameter [ 1:0] RV32I  = 2'b01,
                     RV32E  = 2'b01,
                     RV64I  = 2'b10,
                     RV128I = 2'b11;


    //Privilege levels
    parameter [ 1:0] PRV_M = 2'b11,
                     PRV_H = 2'b10,
                     PRV_S = 2'b01,
                     PRV_U = 2'b00;

    //Virtualisation
    parameter [ 3:0] VM_MBARE = 4'd0,
                     VM_SV32  = 4'd1,
                     VM_SV39  = 4'd8,
                     VM_SV48  = 4'd9,
                     VM_SV57  = 4'd10,
                     VM_SV64  = 4'd11;

    //MIE MIP
    parameter        MEI = 11,
                     HEI = 10,
                     SEI = 9,
                     UEI = 8,
                     MTI = 7,
                     HTI = 6,
                     STI = 5,
                     UTI = 4,
                     MSI = 3,
                     HSI = 2,
                     SSI = 1,
                     USI = 0;

    //Performance counters
    parameter        CY = 0,
                     TM = 1,
                     IR = 2;




    //Exception causes
    parameter        EXCEPTION_SIZE                 = 16;

    parameter        CAUSE_MISALIGNED_INSTRUCTION   = 0,
                     CAUSE_INSTRUCTION_ACCESS_FAULT = 1,
                     CAUSE_ILLEGAL_INSTRUCTION      = 2,
                     CAUSE_BREAKPOINT               = 3,
                     CAUSE_MISALIGNED_LOAD          = 4,
                     CAUSE_LOAD_ACCESS_FAULT        = 5,
                     CAUSE_MISALIGNED_STORE         = 6,
                     CAUSE_STORE_ACCESS_FAULT       = 7,
                     CAUSE_UMODE_ECALL              = 8,
                     CAUSE_SMODE_ECALL              = 9,
                     CAUSE_HMODE_ECALL              = 10,
                     CAUSE_MMODE_ECALL              = 11,
                     CAUSE_INSTRUCTION_PAGE_FAULT   = 12,
                     CAUSE_LOAD_PAGE_FAULT          = 13,
                     CAUSE_STORE_PAGE_FAULT         = 15;

    parameter        CAUSE_USINT                    = 0,
                     CAUSE_SSINT                    = 1,
                     CAUSE_HSINT                    = 2,
                     CAUSE_MSINT                    = 3,
                     CAUSE_UTINT                    = 4,
                     CAUSE_STINT                    = 5,
                     CAUSE_HTINT                    = 6,
                     CAUSE_MTINT                    = 7,
                     CAUSE_UEINT                    = 8,
                     CAUSE_SEINT                    = 9,
                     CAUSE_HEINT                    = 10,
                     CAUSE_MEINT                    = 11;

endpackage
