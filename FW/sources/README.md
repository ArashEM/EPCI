# Introduction

This folder contains EPCI project firmwares. Which include HDLs for FPGA and C code for Linux device driver.

- `hdl` includes all HDL files to build **BIT** for EPCI-V1.0X board
- `driver` include all C files to build **.ko** file which is EPCI-V1.0X Linux driver

## Synthesis prerequisites 

To build (synthesis / Implement) HDL files, you need:

- Installed <u>Xilinx ISE tools</u>. I've tested HDLs with ISE-14.07 
- Installed <u>GNU make</u> utility 

Then

```bash
git clone https://github.com/ArashEM/EPCI.git
cd EPCI/FW/sources/hdl/
make mcs
```

You can find programming files in `build/epci_fpga.bit` , `build/epci_fpga.mcs`

## Compile prerequisites

To compile EPCI Linux driver, you need:

- Linux headers (According to your Distro. Linux kernel version). I've tested it under Ubuntu-16.04 with kernel *4.4.0-116-generic #140*.
- `gcc`

Then

```bash
git clone https://github.com/ArashEM/EPCI.git
cd EPCI/FW/sources/driver/
make 
```

You can find kernel module in `build/epci.ko`

# How to change

Synthesizing HDLs is based on [ISE-Makefile](https://github.com/duskwuff/Xilinx-ISE-Makefile.git)  project with a little modifications. 

First of all, check `configs/project.cfg` file which include all HDLs and synthesis options. You do not need to make any changes in `Makefile`. 

Kernel module build is traditional Linux Kbuild system. For more information you can check [lkmpg](https://www.tldp.org/LDP/lkmpg/2.6/lkmpg.pdf). 











