# 编译逻辑
# *.bpf.c: CLANG生成eBPF目标文件*.bpf.o(在build_bpf文件夹中)
# *.bpf.o 通过bpftool生成skeleton header, 即sberf.skel.h(在build_bpf文件夹中)
# *.c: include上一步生成的skeleton header, 通过cc生成常规.o文件(在build文件夹中)
# 最后通过cc, 将所有常规.o文件链接，生成sberf可执行文件
# bpf.c --> bpf.o --> skel.h
#                       \_ .c -> .o
#                                 \_ sberf


ifeq ($(DEBUG), 1)
	Q =
	msg =
else
	Q = @
	msg = @printf '	%-8s %s%s\n' "$(1)" "$(2)" "$(if $(3), $(3))";
endif

SBERF := sberf
CFLAGS ?= -g -O2 -Werror -Wall -std=c11
# source code @ ./src
SRCDIR := src
# object file @ ./build
OUTPUT ?= build
BPFOUT := build_bpf
BPFTOOL := bpftool
CLANG ?= clang
BPF_LIB := libbpf.a

ARCH ?= $(shell uname -m | sed 's/x86_64/x86/' \
| sed 's/arm.*/arm/' \
| sed 's/aarch64/arm64/' \
| sed 's/ppc64le/powerpc/' \
| sed 's/mips.*/mips/' \
| sed 's/riscv64/riscv/' \
| sed 's/loongarch64/loongarch/')

VMLINUX ?= foo
LIBBPF ?= foo

# 所有目标.o文件
OBJS := sberf.o
SKEL := $(patsubst %.o, %.skel.h,$(OBJS))
OBJS_BUILT := $(addprefix $(OUTPUT)/,$(OBJS))
# bpf.c is condensed into SKEL_BUILT
SKEL_BUILT := $(addprefix $(BPFOUT)/,$(SKEL))

# include搜索目录
INCLUDE := /usr/include

# bpf.o object (Clang generates *.tmp.bpf.o, which is used to generate *.bpf.o)
$(BPFOUT)/%.bpf.o: $(SRCDIR)/%.bpf.c $(wildcard $(SRCDIR)/%.h) | $(BPFOUT)
	$(call msg,BPF,$@)
	$(Q)$(CLANG) -g -O2 -target bpf -D__TARGET_ARCH_$(ARCH) \
		-c $(filter $(SRCDIR)/%.bpf.c,$^) -o $(patsubst %.bpf.o,%.tmp.bpf.o,$@)
	$(Q)$(BPFTOOL) gen object $@ $(patsubst %.bpf.o,%.tmp.bpf.o,$@)
	rm -rf $(patsubst %.bpf.o,%.tmp.bpf.o,$@)

# skeleton header
$(BPFOUT)/%.skel.h: $(BPFOUT)/%.bpf.o | $(BPFOUT)
	$(call msg,SKEL,$@)
	$(Q)$(BPFTOOL) gen skeleton $< > $@

# object file for normal .c file, not the bpf.c file.(specified in OBJS variable)
$(OUTPUT)/%.o: $(SRCDIR)/%.c $(wildcard $(SRCDIR)/%.h) $(SKEL_BUILT) | $(OUTPUT) $(BPFOUT)
	$(call msg,CC,$@)
	$(Q)$(CC) $(CFLAGS) -I$(BPFOUT) -I$(INCLUDE) -c $(filter %.c,$^) -o $@

# sberf executable
sberf: $(OBJS_BUILT)
	$(call msg,CC,$@)
	$(Q)$(CC) $(CFLAGS) $(OBJS_BUILT) -l:$(BPF_LIB) -lelf -lz -o $@ 

all: $(SBERF)

# all obj file will be stored in build directory
$(OUTPUT):
	$(call msg,MKDIR,$@)
	$(Q)mkdir -p $@

$(BPFOUT):
	$(call msg,MKDIR,$@)
	$(Q)mkdir -p $@

clean-all:
	$(call msg,CLEANALL)
	$(Q)rm -rf $(OUTPUT) $(SBERF) $(TEST)

clean:
	$(call msg,CLEAN)
	$(Q)rm -rf $(BPFOUT) $(OUTPUT) $(SBERF)

# tests
TEST := sberf_test
TESTDIR = test
TEST_FILE := test.c

test: $(TEST)

# one liner or one filer
$(TEST): $(TESTDIR)/$(TEST_FILE)
	$(call msg,CC,$@)
	$(Q)$(CC) $(CFLAGS) $(TESTDIR)/$(TEST_FILE) -o $(TEST)
