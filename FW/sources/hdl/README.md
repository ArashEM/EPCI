# Introduction

HDL part of project can be found here. File hierarchy is and folder content is described below

- `components`: containing all HDL components of project
- `configs`: includes Makefile configuration files and other configuration files
- `constraints`: UCF and other constraint fils
- `packages`: All required packages for VHDL files to be synthesized 
- `build`: build artifacts like **mcs** file can be found here

# Architecture

EPCI implements only `BAR0` with **64KB** of  non-prefetchable memory space. Here is result of `lspci` command in G41 board

```bash
root@G41MES2L:/home/me# lspci -xxxvv -s 03:01.0
03:01.0 DPIO module: Xilinx Corporation Xilinx 6 Designs (Xilinx IP) (rev 02)
        Subsystem: Xilinx Corporation Xilinx 6 Designs (Xilinx IP)
        Control: I/O- Mem+ BusMaster- SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx-
        Status: Cap- 66MHz- UDF- FastB2B- ParErr- DEVSEL=medium >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
        Interrupt: pin A routed to IRQ 11
        Region 0: Memory at e1500000 (32-bit, non-prefetchable) [size=64K]
00: ee 10 00 06 02 00 00 02 02 00 00 11 00 00 00 00
10: 00 00 50 e1 00 00 00 00 00 00 00 00 00 00 00 00
20: 00 00 00 00 00 00 00 00 00 00 00 00 ee 10 00 06
30: 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00

```

## Memory map

Internal memory map of EPCI firmware is described in following table. All offsets are according to `BAR0` address.

| offset   | size (B) | description                                                  |
| -------- | -------- | ------------------------------------------------------------ |
| `0x0000` | `0x8000` | **32KB** of SRAM. can be used for Read/Write test operation. byte, word and dword access is implemented. |
| `0x8010` | `0x10`   | Register map for **LEDs** controller. Details of register is listed below |



##  LED controller 

`EPCI-V1.00` hardware had 3 LEDs. each LED has it's own controller with 32 bit control registers.

| offset | size (B) | description                                           |
| ------ | -------- | ----------------------------------------------------- |
| `0x0`  | `0x1`    | (x,x,x,x,x,x,x, `on/off`). Control LEDx on/off status |
| `0x1`  | `0x1`    | For future used                                       |
| `0x2`  | `0x02`   | PWM value                                             |

For more information check `hdl/components/LED.vhd` 

