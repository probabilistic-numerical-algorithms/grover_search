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

GROVER_FIXED_PROCESSOR_SOURCES := \
 grover_fixed_types.ads \
 grover_fixed_processor.ads \
 grover_fixed_processor.adb
SEARCH_DRIVER_SOURCES := \
 search_driver.adb $(GROVER_FIXED_PROCESSOR_SOURCES)

GNATMAKE := \
  PATH="$(WHERE_MY_PARALLEL_ADA_IS):$(PATH)" \
  LIBRARY_PATH="$(LIBRARY_PATH)" \
  gnatmake

# The -mno-rdseed is actually because I have (at the time I am writing
# this comment) no microcode patch for what was probably a bad idea in
# the first place (having the CPU generate an entropic seed). I mean,
# my intuition says one really, really ought to get initial entropy by
# throwing the kitchen sink at the computer.
CORE_COUNT := 24
OPTIMIZATIONS := \
  -mno-rdseed \
  -fomit-frame-pointer \
  -O3 \
  -mprefer-vector-width=512 \
  -ftree-vectorize -fopt-info-vec \
  -ftree-parallelize-loops=$(CORE_COUNT)

search_driver: $(SEARCH_DRIVER_SOURCES)
	$(GNATMAKE) -I$(LWT_PATH) $(@) -cargs $(OPTIMIZATIONS)
clean:: ; -rm -f search_driver

demo_entropy: $(DEMO_ENTROPY_SOURCES)
	$(GNATMAKE) $(@) -cargs -mno-rdseed -gnata -gnato1
clean:: ; -rm -f demo_entropy

clean::
	-rm -f *.{o,ali}
	-rm -f *.tmp */*.tmp
