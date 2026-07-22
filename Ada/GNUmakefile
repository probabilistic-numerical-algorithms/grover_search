#
# This is NOT a robust makefile, because at the moment I am using
# gnatmake uncarefully. You may need to run “make clean” before
# building something.
#

.DELETE_ON_ERROR:
.PHONY: clean

WHERE_MY_PARALLEL_ADA_IS := $(HOME)/src/probabilistic-numerical-algorithms/gnat2022-parallel-binary
LIBRARY_PATH := $(LIBRARY_PATH):$(WHERE_MY_PARALLEL_ADA_IS)/lib64:/usr/local/lib
PATH := $(WHERE_MY_PARALLEL_ADA_IS)/bin:$(PATH)
LWT_PATH := ../../lwt

GROVER_SOURCES := \
 grover_search.ads grover_search.adb \
 entropy.ads entropy.adb
TEST_GROVER_SOURCES := \
 test_grover.adb $(GROVER_SOURCES)
TEST_GROVER_2_SOURCES := \
 test_grover_2.adb $(GROVER_SOURCES)
DEMO_ENTROPY_SOURCES := \
 demo_entropy.adb entropy.ads entropy.adb

# The -mno-rdseed is actually because my CPU has (so far, at the time
# of this writing) no microcode fix for what was probably a bad idea
# in the first place.
CORE_COUNT := 24
OPTIMIZATIONS := \
  -mno-rdseed \
  -O3 \
  -gnat2022 -gnatX \
  -fomit-frame-pointer \
  -ftree-vectorize -fopt-info-vec \
  -ftree-parallelize-loops=$(CORE_COUNT)

test_grover: $(TEST_GROVER_SOURCES)
	gnatmake -I$(LWT_PATH) $(@) -cargs $(OPTIMIZATIONS) -largs -lgomp
clean:: ; -rm -f test_grover

test_grover_2: $(TEST_GROVER_2_SOURCES)
	gnatmake -I$(LWT_PATH) $(@) -cargs $(OPTIMIZATIONS) -largs -lgomp
clean:: ; -rm -f test_grover_2

demo_entropy: $(DEMO_ENTROPY_SOURCES)
	gnatmake $(@) -cargs -mno-rdseed -gnata -gnato1
clean:: ; -rm -f demo_entropy

example_runs/test_grover.zen5: $(TEST_GROVER_SOURCES)
	mkdir -p $(@D)
	$(MAKE) clean
	( $(MAKE) test_grover 2>&1 ) 2>&1 > $(@).tmp
	( time ./test_grover 2>&1 >> $(@).tmp ) 2> $(@).time.tmp
	cat $(@).tmp $(@).time.tmp > $(@)
	rm $(@).tmp $(@).time.tmp

clean::
	-rm -f *.{o,ali}
	-rm -f *.tmp */*.tmp
