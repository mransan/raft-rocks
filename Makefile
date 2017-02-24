LIB_NAME=raft-rocks

LIB_FILES+=raft_rocks

LIB_DEPS=raft,ocaml-protoc,ocplib-endian

ifneq ($(LIB_DEPS),)
	LIB_DEPS:=-pkgs $(LIB_DEPS)
endif

OBJ_FILE    = $(CURDIR)/stubs/raft_rocks_stubs.o

OCB_INC     = -X stubs -I src -I tests

OCB_FLAGS   = -use-ocamlfind $(LIB_DEPS) 

OCB_LDFLAGS = -lflags $(OBJ_FILE)
OCB_LDFLAGS+= -lflags "-cclib -lrocksdb "
OCB_LDFLAGS+= -lflags "-cclib -lbz2 -cclib -lz -cclib -lzstd -cclib -lsnappy"
OCB_LDFLAGS+= -lflags "-cclib -lstdc++ -cclib -lpthread"

OCB         = ocamlbuild $(OCB_INC) $(OCB_FLAGS)

.PHONY: clib

test: tests/log_test.ml $(OBJ_FILE)
	$(OCB) $(OCB_LDFLAGS) log_test.native
	export OCAMLRUNPARAM="b" && ./log_test.native 

%.o: %.cpp
	g++ -fPIC -DIPC --std=c++11 -I `ocamlc -where` -c $< -o $@

doc:
	$(OCB) src/$(LIB_NAME).docdir/index.html

gen:
	ocaml-protoc -ml_out src src/raft_rocks.proto

clean:
	rm -f stubs/*.o
	$(OCB) -clean

include Makefile.opamlib
