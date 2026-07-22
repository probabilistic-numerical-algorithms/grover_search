.DELETE_ON_ERROR:

LIBRARY_PATH := $(LIBRARY_PATH):/usr/local/lib
PATH := $(HOME)/src/probabilistic-numerical-algorithms/gnat2022-parallel-binary/bin:$(PATH)
LWT_PATH := ../../lwt

GROVER_SOURCES := \
 grover_search.ads grover_search.adb \
 entropy.ads entropy.adb
TEST_GROVER_SOURCES := \
 test_grover.adb $(GROVER_SOURCES)

test_grover: $(TEST_GROVER_SOURCES)
	gnatmake -I$(LWT_PATH) -gnat2022 -gnatX $(@) \
	  -cargs -O3 -mno-rdseed -ftree-vectorize -fopt-info-vec -llwt

example_runs/test_grover.zen5: $(TEST_GROVER_SOURCES)
	mkdir -p $(@D)
	$(MAKE) clean
	( $(MAKE) test_grover 2>&1 ) 2>&1 > $(@).tmp
	( time ./test_grover 2>&1 >> $(@).tmp ) 2> $(@).time.tmp
	cat $(@).tmp $(@).time.tmp > $(@)
	rm $(@).tmp $(@).time.tmp

.PHONY: clean
clean::
	-rm -f *.{o,ali}
	-rm -f *.tmp */*.tmp
	-rm -f test_grover
