#
#    simple Makefile to mem_bt.c
#

CC=gcc
CFLAGS=-I.
DEPS = 
_OBJ = mem_bt.o
TARGET = mem_bt
ODIR = build

OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))

$(ODIR)/%.o: %.c $(DEPS)
	@mkdir -p $(ODIR)
	@$(CC) -c -o $@ $< $(CFLAGS)

$(ODIR)/$(TARGET): $(OBJ)
	@$(CC) -o $@ $^ $(CFLAGS)

clean:
	@rm -rf $(ODIR)
