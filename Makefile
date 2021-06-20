MAKE=make

all: clean boot

boot:
	cd bootloader && $(MAKE) all

clean:
	cd bootloader && $(MAKE) clean
