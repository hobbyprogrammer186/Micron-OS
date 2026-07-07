# MicronOS
Optimized OS For Old Computers

## Features
- Zero Heap Allocation
- Optimized For Old Computers
- Small Kernel
- Can Properly Intracted From Hardware Without Drivers By Communicating With BIOS

## Implemented Components
[ - ] Bootloader

[ - ] Scheduler

[ x ] Memory Manager
- [ X ] Memory Allocation/Dealloation
- [ - ] Memory Defragment/Alignment
- [ - ] Swap Memory (Virtual RAM)

[ * ] VGA/VBE
- [ * ] Resulation Changing
- [ - ] Drawing Graphics

[ - ] Executeable File Support

[ - ] Basic Apps/Games And Desktop Envirornment

### Meanings:

`*`: Incomplete Implemention.

`-`: Not Beginned Of Implemention

`X`: Completed Implemention

## Contribute
Build:
```bash
make -j$(nproc)
```
Linting (Catching Build Error Clearly):
```bash
make LINT=1
```