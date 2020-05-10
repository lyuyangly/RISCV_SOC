# Makefile For VCS

export PRJ_PATH=$(shell pwd)/..

all:
	@echo "VCS Verification ENV"

verdi:
	@verdi -sverilog riscv_sopc_tb.sv -f ../rtl/filelist/filelist.lst -top riscv_sopc_tb &

cmp:
	@vcs -LDFLAGS -Wl,--no-as-needed -debug_pp +lint=TFIPC-L +lint=PCWM -P ${NOVAS_HOME}/share/PLI/VCS/LINUX/novas.tab ${NOVAS_HOME}/share/PLI/VCS/LINUX/pli.a -sverilog riscv_sopc_tb.sv -f ../rtl/filelist/filelist.lst -top riscv_sopc_tb -l vcs.log

run:
	@./simv -l simv.log

dve:
	@dve -vpd wave.vpd &

clean:
	@rm -rf ucli.key csrc simv simv.daidir vcs.log simv.log DVEfiles wave.fsdb novas_dump.log verdiLog nWaveLog

