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



# Jenkins

`Jenkinsfile` in this directory is about to implement **hardware in loop** tests via two salve node (`ise-0` and `dh-01`). It contains following stages:

1. `checkout` : clone repository in **master** node and stash it for further use
2. `build`: This stage is parallel build stage which compile *kernel module* in **dh-01** node. It also generate *bitfile* in **ise-01** node. I will explain more about these nodes. In this stage some *test applications* are compiled too.
3. `deploy`: This stage deploy build artifacts (*bitfile* and *driver*) in real setup. With help of `openocd` I could program FPGA in Linux. Some scripts are developed for ease of deployment process.
4. `test`: After *bitfile* is loaded to FPGA and device driver is ready to use, test application in run to ensure that whole chain is working fine. 

## slave node `ise-01`

`ise-0` is Windows/Linux  slave (virtual) machine which is used to generate *bitfile*/*mcs* for EPCI-V1.0x FPGA. This node includes:

- Installed <u>Xilinx ISE tools</u>. I've tested HDLs with ISE-14.07 
- Installed <u>GNU make</u> utility 

Make sure Jenkins has proper access to use Xilinx ISE tools. 

## slave node `dh-01`

`dh-0` is Linux **physical** machine with PCI slot which is used to compile device driver and test *EPCI-V1.0x* board. This includes: 

- Linux headers (According to your Distro. Linux kernel version). I've tested it under Ubuntu-16.04 with kernel *4.4.0-116-generic #140*.
- `gcc` : for compiling driver and test applications
- `openocd`: for programming FPGA (check `hdl/scripts/epci-openocd.cfg`). As you know *EPCI-V1.0x* has an on board JTAG (`HS-2`) programmer which is connected to `dh-0` via USB cable 
- `sudoer` access for *jenkins* user (controlled by **master** node) to use `insmod` and `rmmod`  (check `driver/scripts/epci_load`)
- *EPCI-V1.0x* board is installed in one of PCI slot of `dh-01`. 

As you can see `dh-01` is used for build as well as test bed for *EPCI-V1.0x*. It's an **Asus G41M-E2SL** motherboard which I described in project top level `README.md` file.



