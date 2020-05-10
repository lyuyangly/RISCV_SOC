#***********************************************************************************************
#    File        : Makefile
#    Author      : Lyu Yang
#    Date        :
#    Description : Makefile for RISC-V
#***********************************************************************************************

TARGET = app_test

CROSS_COMPILE = riscv64-unknown-elf-

SRC_DIR = .
OBJ_DIR = obj
INC_DIR = -I ./
LIB_DIR = -L ./

CC = $(CROSS_COMPILE)gcc
CFLAGS =  $(INC_DIR) -c -mabi=ilp32 -march=rv32i -Wall -O1 -std=c99 -gdwarf-2 -freorder-blocks-algorithm=simple -fno-schedule-insns -fno-aggressive-loop-optimizations -fno-builtin -Wstrict-prototypes -Wno-write-strings -fno-exceptions -fno-short-enums -Wundef -falign-functions=2 -fdata-sections -ffunction-sections -fno-common

CXX = $(CROSS_COMPILE)g++
CXXFLAGS =  $(INC_DIR) -c -mabi=ilp32 -march=rv32i -Wall -O1 -std=c99 -gdwarf-2 -freorder-blocks-algorithm=simple -fno-schedule-insns -fno-aggressive-loop-optimizations -fno-builtin -Wstrict-prototypes -Wno-write-strings -fno-exceptions -fno-short-enums -Wundef -falign-functions=2 -fdata-sections -ffunction-sections -fno-common

AS = $(CROSS_COMPILE)gcc
ASFLAGS = -c -mabi=ilp32 -march=rv32i -x assembler-with-cpp -Wall -O1 -gdwarf-2 -fstack-protector -fno-common -fdata-sections -ffunction-sections

LD = $(CROSS_COMPILE)gcc
LDFLAGS = $(LIB_DIR) -mabi=ilp32 -march=rv32i -nostartfiles -Triscv.lds -Wl,-Map,$(TARGET).map

OBJCP = $(CROSS_COMPILE)objcopy
OBJCPFLAGS = -O binary -j .text -j .data -j .sdata

AR = $(CROSS_COMPILE)ar
ARFLAGS = cr

OBJDUMP = $(CROSS_COMPILE)objdump
OBJDUMPFLAG = --disassemble --syms --all-header

SIZE = $(CROSS_COMPILE)size

ASMS = $(wildcard $(SRC_DIR)/*.S)
SRCS = $(wildcard $(SRC_DIR)/*.c)

OBJS += $(ASMS:$(SRC_DIR)/%.S=$(OBJ_DIR)/%.o)
OBJS += $(SRCS:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
DEPS += $(OBJS:%.o=%.d)

# Make
all: $(TARGET).elf $(TARGET).bin $(TARGET).asm $(TARGET).mif
	$(SIZE) $(TARGET).elf

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.S
	@mkdir -p $(shell dirname $@)
	@$(AS) $(ASFLAGS) $< -o $@
	@echo AS $<

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(shell dirname $@)
	@$(CC) $(CFLAGS) -MM -MT $@ -MF $(patsubst %.o, %.d, $@) $<
	@$(CC) $(CFLAGS) $< -o $@
	@echo CC $<

-include $(DEPS)

$(TARGET).elf: $(OBJS)
	@$(LD) $(LDFLAGS) $^ -o $@

$(TARGET).asm: $(TARGET).elf
	@$(OBJDUMP) $(OBJDUMPFLAG) $(TARGET).elf > $(TARGET).asm

$(TARGET).bin: $(TARGET).elf
	@$(OBJCP) $(OBJCPFLAGS) $< $@

$(TARGET).mif: $(TARGET).bin
	@./bin2fpga/bin2fpga 4096 $< > $(TARGET).txt

clean:
	@rm -rf obj $(TARGET).elf $(TARGET).map $(TARGET).asm $(TARGET).bin

debug:
	$(CROSS_COMPILE)gdb $(TARGET).elf -x gdbinit.txt

