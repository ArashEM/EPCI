INCLUDE=inc
SOURCE=src
TARGET=epci
OUTPUT=build

SOURCES=$(wildcard $(SOURCE)/*.c)

# Depends on bin/include bin/*.c and bin/Makefile
all: $(subst $(SOURCE),$(OUTPUT),$(SOURCES)) $(OUTPUT)/Makefile
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD)/$(OUTPUT) modules

# Create a symlink from src to bin
$(OUTPUT)/%: $(SOURCE)/%
	@ln -s ../$< $@

# Generate a Makefile with the needed obj-m and mymodule-objs set
$(OUTPUT)/Makefile:
	@echo "obj-m += $(TARGET).o\nEXTRA_CFLAGS=-I$(PWD)/$(INCLUDE)\n$(TARGET)-objs := $(subst $(TARGET).o,, $(subst .c,.o,$(subst $(SOURCE)/,,$(SOURCES))))" > $@

clean:
	@rm -rf $(OUTPUT)
	@mkdir $(OUTPUT)

