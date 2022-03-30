PIC_LD=ld
LDVERSION= $(shell $(PIC_LD) -v | grep -q 2.30 ;echo $$?)
ifeq ($(LDVERSION), 0)
     LD_NORELAX_FLAG= --no-relax
endif

ARCHIVE_OBJS=
ARCHIVE_OBJS += _836487_archive_1.so
_836487_archive_1.so : archive.1/_836487_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//../syn_simv.daidir//_836487_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../syn_simv.daidir//_836487_archive_1.so $@


ARCHIVE_OBJS += _prev_archive_1.so
_prev_archive_1.so : archive.1/_prev_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//../syn_simv.daidir//_prev_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../syn_simv.daidir//_prev_archive_1.so $@



VCS_CU_ARC0 =_cuarc0.so

VCS_CU_ARC_OBJS0 =objs/amcQw_d.o 


O0_OBJS =

$(O0_OBJS) : %.o: %.c
	$(CC_CG) $(CFLAGS_O0) -c -o $@ $<


%.o: %.c
	$(CC_CG) $(CFLAGS_CG) -c -o $@ $<

$(VCS_CU_ARC0) : $(VCS_CU_ARC_OBJS0)
	$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//../syn_simv.daidir//$(VCS_CU_ARC0) $(VCS_CU_ARC_OBJS0)
	rm -f $(VCS_CU_ARC0)
	@ln -sf .//../syn_simv.daidir//$(VCS_CU_ARC0) $(VCS_CU_ARC0)

CU_UDP_OBJS = \
objs/udps/hUcmi.o objs/udps/PjGxs.o objs/udps/MzHq6.o objs/udps/guAtk.o objs/udps/aKVa7.o  \
objs/udps/F8ezs.o objs/udps/GLrQJ.o objs/udps/dKp3B.o 

CU_LVL_OBJS = \
SIM_l.o 

MAIN_OBJS = \


CU_OBJS = $(MAIN_OBJS) $(ARCHIVE_OBJS) $(VCS_CU_ARC0) $(CU_UDP_OBJS) $(CU_LVL_OBJS)

