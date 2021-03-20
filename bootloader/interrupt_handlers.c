#include "interrupt_handlers.h"

void irq0_handler()
{
    eoi();
}
 
void irq1_handler()
{
    eoi();
}
 
void irq2_handler()
{
    eoi();
}
 
void irq3_handler()
{
    eoi();
}
 
void irq4_handler()
{
    eoi();
}
 
void irq5_handler()
{
    eoi();
}
 
void irq6_handler()
{
    eoi();
}
 
void irq7_handler()
{
    eoi();
}
 
void irq8_handler()
{
    outb(0xA0, 0x20);
    eoi();        
}
 
void irq9_handler()
{
    outb(0xA0, 0x20);
    eoi();
}
 
void irq10_handler()
{
    outb(0xA0, 0x20);
    eoi();
}
 
void irq11_handler()
{
    outb(0xA0, 0x20);
    eoi();
}
 
void irq12_handler()
{
    outb(0xA0, 0x20);
    eoi();
}
 
void irq13_handler()
{
    outb(0xA0, 0x20);
    eoi();
}
 
void irq14_handler()
{
    outb(0xA0, 0x20);
    eoi();
}
 
void irq15_handler()
{
    outb(0xA0, 0x20);
    eoi();
}
