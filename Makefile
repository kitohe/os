MAKE=make

all: boot

boot:
	cd bootloader && $(MAKE) all

clean:
	cd bootloader && $(MAKE) clean
