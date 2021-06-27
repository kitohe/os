#include "idt.h"
#include "interrupt_handlers.h"

void bmain()
{
    volatile int a = 0x41414141;
    idt_init();
    // just a test
    volatile int b = 0x41414141;

    while (1) {}
}
