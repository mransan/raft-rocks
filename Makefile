LIB_NAME=raft-rocks

LIB_FILES+=raft_rocks

LIB_DEPS=raft,rocks,ocaml-protoc

## Generic library makefile ##

ifneq ($(LIB_DEPS),)
	LIB_DEPS:=-pkgs $(LIB_DEPS)
endif

OCB_INC   = -X stubs -I src -I tests
OCB_FLAGS = -use-ocamlfind $(LIB_DEPS) 
OCB       = ocamlbuild $(OCB_INC) $(OCB_FLAGS)

##

.PHONY: clib

test: $(PWD)/stubs/raft_rocks_stubs.o
	$(OCB) -lflag $(PWD)/stubs/raft_rocks_stubs.o\
				 -lflags "-cclib -lrocksdb "\
				 -lflags "-cclib -lbz2 -cclib -lz -cclib -lzstd -cclib -lsnappy"\
				 -lflags "-cclib -lstdc++ -cclib -lpthread"\
				 test.native
	export OCAMLRUNPARAM="b" && ./test.native 

%.o: %.cpp
	g++ -fPIC -DIPC --std=c++11 -I `ocamlc -where` -c $< -o $@

doc:
	$(OCB) src/$(LIB_NAME).docdir/index.html

gen:
	ocaml-protoc -ml_out src src/raft.proto

clean:
	rm -f stubs/*.o
	$(OCB) -clean

include Makefile.opamlib