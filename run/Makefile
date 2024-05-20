SRCS=$(wildcard ../src/*.sv)
TOP_MODULE=vga_tb

HY220_SIMULATOR?=vivado
HY220_TOOLS_DIR?=~hy220/tools
include $(HY220_TOOLS_DIR)/common/Makefile.include

check:
	@./compare_ref.sh
