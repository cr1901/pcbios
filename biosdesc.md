IBM PC BIOS Verbal Description- Chinese Wall Approach
======
Turn on word wrap in your editor if you have it! I'll run this through ```fold``` later.

This document describes the operation of the IBM PC Basic Input Output System (BIOS) in sufficient
detail such that a hobbyist could reimplement their own version, should they so desire. This document is divided into two sections: One that describes the hardware the BIOS will touch, and then a verbal description of a PC-class BIOS. The BIOS described here is the October 1982 version of the IBM 5150 BIOS. The IBM 5160 BIOS is similar.

IBM 5150 (PC), PC clones, IBM 5160 (XT), and XT-class clones are rather similar in design and circuitry, with the possibility of clone boards supporting more features than the hardware of the IBM motherboards permit. Such features include a turbo switch (switch CPU speed), and the ability to from boot secondary floppy diskette. Differences between the IBM 5150 and 5160 include:
* Extra I/O expansion slots on 5160 (7.5- see 5160 diagram for pictoral explation of the 8th slot. It is not currently known why the 8th slot is placed in this location).
* Lack of cassette port on 5160.
* Location of the 8259 PIC relative to the CPU between [5150](http://www.minuszerodegrees.net/5150/misc/5150_address_bus.jpg) and [5160](http://www.minuszerodegrees.net/5160/misc/5160_address_bus.jpg).
* Address-decoding logic permits installing 640kB RAM on the mainboard of the latter with a small mod.

TLDR: With few modifications, the BIOS described in this document should be directly implementable on PCs of *all* the above classes.

#IBM PC Hardware Brief
##Onboard Hardware
IBM PC-compatibles, up to XT-clones consist of the following hardware that is exposed to the programmer, in (rough) order of increasing complexity. Base Port I/O addresses are listed in parentheses:
* NMI Gate (0xA0)
* Sense Switches (0x60-0x62) (Two sets on PC and PC-clones only)
* RAM Parity Check Gate (0x61-0x62)
* IO Channel Check Gate (0x61-0x62)
* Keyboard SIPO Shift Register (0x60-0x61)
* PC Speaker (0x61)
* DMA Page Register (0x80-0x83)
* 8255 PPI (Programmable Peripheral Interface) (0x60)
* 8253 PIT (Precision Interval Timer) (0x40)
* 8259 PIC (Programmable Interrupt Controller) (0x20)
* 8237 DMA Controller (0x00)
* 8087 Floating Point Coprocessor

Many functions that require only one or two data/control lines are exposed via the PPI. PPI Ports A and C are inputs while B is an output. The following lists a table of I/O- copied from IBM 5150 Technical Reference Manual. Note: **For sense switches, OFF is seen as 1, ON is seen as 0 from the CPU's point-of-view! All references to sense switches are from CPU's POV.**

###PPI Ports
|PPI Port|Function|Criteria|
|----|:---|----|
|PA0-7|Keyboard Keycode|PB7 == 0|
|PA0|<ul style="display:inline"><li>0 Boot to BASIC</li><li>1- Boot from floppy</li><ul>|PB7 == 1|
|PA1|Reserved|PB7 == 1|
|PA2-3|Number of EXTRA mainboard memory banks (0-3)*|PB7 == 1|
|PA4-5|<ul style="display:inline"><li>0- Expansion card provides Video BIOS**</li><li>1- 40x25 CGA</li><li>2- 80x25 CGA</li><li>3- 80x25 Monochrome</li><ul>|PB7 == 1|
|PA6-7|Number of floppy disk drives (1-4)|PB7 == 1|

|PB0|I/O memory count 512kB bias|N/A|
|PB1|Nothing?|N/A|
|PB2|I/O memory count in 32kB increments (0-15)|N/A|
|PB4|Casette Data In|N/A|
|PB5|Timer Channel 2 Out (PC speaker data)|N/A|
|PB6|I/O Channel Check Gate|N/A|
|PB7|RAM Parity Check Gate|N/A|


|PC0|I/O memory count 512kB bias|PB2 == 0|
|PC1-3|Nothing?|PB2 == 0|
|PC0-3|I/O memory count in 32kB increments (0-15)|PB2 == 1|
|PC4|Casette Data In|N/A|
|PC5|Timer Channel 2 Out (PC speaker data)|N/A|
|PC6|I/O Channel Check Gate|N/A|
|PC7|RAM Parity Check Gate|N/A|

###Sense Switches
For the first set of sense switches, near the center of the board, SW1-8 correspond to PA0-7. For the second set of sense switches, near the power supply, SW1-4 correspond to PC0-3. PC0 also reads SW5 of the second set of sense switches, when PB2 is deasserted. The relevant functions are documented in the PPI ports table.

Total system memory installed in kB, as set by the sense switches, is determined by the following formula: (SW2-5)*512 + (SW2-1 to SW2-4)*32 + (SW1-3 to SW1-4)*16. Because the BIOS checks mainboard RAM first, SW1-3 and SW1-4 should be asserted (set to OFF position) before any of SW2-1 to SW2-5 are asserted. 

*Always 3 on 64kB-256kB boards.

The PPI is replaced with an 8042 in AT-systems and above, which provides an interface to the same hardware for compatibility.

Other hardware, including a 8284 Clock Generator and 8288 Bus Controller, exist on the board, but are not exposed to the programmer.

##Expansion Card Hardware
Expansion cards are likely to provide the following hardware (*that BIOS is likely to initialize if found*) as well:
* 6845 CRT Controller (0x3D4-5 Color, 0x3B4-5 Mono)
* MM58167 RTC (0x240, 0x300, 0x340- Found by trial and error)
* TTL Glue logic for Color and Mono adapter configuration (0x3D4-0x3DF Color, 0x3B4-0x3BF Mono)
* TTL Glue logic for Line Printer Terminal (LPT) (0x3BC, 0x378, 0x278, ?)
* 16550 UART for Serial Communications (COM) (0x3F8, 0x2F8, 0x3E8, 0x238)
* 765 Floppy Disk Controller (0x3F2 Glue logic, 0x3F4-0x3F5 Controller)
* VGA VLSI chip (BIOS is provided by controller- PC BIOS simply needs to jump to setup routine)
* Xebec-standard XT hard disk controller (BIOS is provided by controller- PC BIOS simply needs to jump to setup routine)
* Ethernet card (BIOS is provided by card- PC BIOS simply needs to jump to setup routine)

Most hardware is exposed through x86 port-mapped I/O ports. Memory-mapped I/O is reserved for BIOS ROM chips, extra memory and the frame buffer.

The minimum external hardware configuration so that the BIOS doesn't complain (at least IBM's) appears to be Floppy and Video Card.

##Software Workarounds and Incompatibilities
TODO: Find a better name for this section!

Software timing loops are necessary, at least in the early stages of the BIOS, including floppy access The following loop delays approximately 0.412 seconds at 4.77 MHz. ([discussion](http://www.vintage-computer.com/vcforum/showthread.php?45197-IO-Delays-on-8088-class-computers&p=346963#post346963)):
```
	 MOV CX, 0
F11: LOOP F11
```

A more reliable method of delay may be to read an unused I/O port (where wait-states will be added Port 0x80 (POST cards) or port 0x4F ([source](http://www.sat.dundee.ac.uk/psc/pctim003.txt)) seem to be good candidates. Perhaps reading channel 0 of the PIT can work as well.

Discuss: Clone timings and incompatibilities.

#Address Space of 5150 BIOS
|Address (Linear)|Description |
|---------------|-----|
|0x00000-0x002FF|Interrupt Vectors|
|0x00300-0x003FF|BIOS Stack|
|0x00400-0x004FF|BIOS Data Area|
|0x00500-0x03FFF|Minimum RAM on PC|
|0x07C00-0x07FFF|Boostrap/IPL Entry Point|
|0x08000-0x9FFFF|Usable RAM (if available)|
|0xA0000-0xDFFFF|Reserved for I/O Expansion|
|0xE0000-0xEFFFF|Reserved|
|0xF0000-0xF3FFF|BIOS Program (Later 5160)|
|0xF4000-0xF5FFF|Option ROM U28 (5150 only)|
|0xF6000-0xFDFFF|ROM BASIC (5150, 5160, some clones)|
|0xFE000-0xFFFFF|ROM BIOS + IBM Entry Points|

#General Division of BIOS (Increasing Addresses)
Accoding to IBM 5150 Technical Reference Manual:
* POST (NMI Vector embedded)
* Bootstrap
* IO Support
* System Configuration Analysis
* Casette (Not documented here, as Int 0x15 in clones is used for auxilary support routines)
* Graphics Mode Character ROM
* Time Of Day
* Print Screen

The BIOS, in effect:
1. Checks the hardware.
2. Installs ISRs for a variety of interrupts (both hardware-triggered and software-invoked).
3. Provides an mechanism for manipulating I/O devices and getting system information by abstracting hardware details.
4. Initiates loading of another OS.

IBM BIOSes, including clones, tend to reserve specific addresses as entry points into its interrupt service routines. The following is a list of such entry points that should be kept for compatibility with software which jumps directly into BIOS. This includes certain Option ROMs and early-PC software which thought it was a good idea to bypass the ```INT``` instruction to save a few cycles.

##Entry Point Table
Sources: 
* [EFI Compatibility Support Module Specification](http://www.intel.com/content/dam/doc/reference-guide/efi-compatibility-support-module-specification-v096.pdf)
* System BIOS for IBM PC/XT/AT Computers and Compatibles (Phoenix Technologies Ltd.)
  
|Address (Linear)|Description|
|-------|--------------------|
|0xFE05B|POST Entry Point|
|0xFE2C3|NMI Entry Point|
|0xFE401|HDD Parameter Table|
|0xFE6F2|INT 19 Entry Point|
|0xFE6F5|Configuration Data Table|
|0xFE729|Baud Rate Generator Table|
|0xFE739|INT 14 Entry Point|
|0xFE82E|INT 16 Entry Point|
|0xFE987|INT 09 Entry Point|
|0xFEC59|INT 13 Entry Point|
|0xFEF57|INT 0E Entry Point|
|0xFEFC7|FDC Parameter Table|
|0xFEFD2|INT 17 Entry Point|
|0xFF065|INT Video|
|0xFF0A4|INT 1D Video Parameter Table|
|0xFF841|INT 12 Entry Point|
|0xFF84D|INT 11 Entry Point|
|0xFF859|INT 15 Entry Point|
|0xFFA6E|Graphic Video Font (128 ch.)|
|0xFFE6E|INT 1A Entry Point|
|0xFFEA5|INT 08 Entry Point|
|0xFFF53|Dummy Interrupt Handler|
|0xFFF54|INT 05 Entry Point|
|0xFFFF0|Power-On Entry Point|
|0xFFFF5|b MM/DD/YYb |
|0xFFFFE|System Model 0xFC|

Sometimes the Interrupt Vectors can also be found after the Dummy Interrupt Handler, but this is not universal (for example, the COMPAQ Portable BIOS does not do this).

##BIOS Memory Map
|Address (Linear)|Description |
|---------------|-----|
|0x00000-0x002FF|Interrupt Vectors|
|0x00300-0x003FF|BIOS Stack|
|0x00400-0x004FF|BIOS Data Area|
|0x00500-0x03FFF|Minimum RAM on PC|
|0x07C00-0x07FFF|Boostrap/IPL Entry Point|
|0x08000-0x9FFFF|Usable RAM (if available)|
|0xA0000-0xDFFFF|Reserved for I/O Expansion|
|0xE0000-0xEFFFF|Reserved|
|0xF0000-0xF3FFF|BIOS Program (Later 5160)|
|0xF4000-0xF5FFF|Option ROM U28 (5150 only)|
|0xF6000-0xFDFFF|ROM BASIC (5150, 5160, some clones)|
|0xFE000-0xFFFFF|ROM BIOS + IBM Entry Points|

#5150 BIOS Description
##Bootstrap
###Banner
```
DB '1501476 COPR. IBM 1981' ; COPYRIGHT NOTICE
```
The position of 'IBM' may be significant for some software which attempts BIOS vendor detection.

###Storage Test
I find the code hard to read. For brevity, here's an effectively equivalent result:
* For each test pattern: 0xAA, 0x55, 0xFF, 0x01 (tests parity), 0x00
 * Write a 16kB (or user loaded value) block with the test pattern. Read value back and compare.
 * Fail if error reading value back or parity check (in this case, parity check is specifically at the end).
 * If all test patterns pass, success.
* Return information re: success, parity check, and bad read.

####An attempt to dissect ```STGTST:```
* Two entry points- the proc itself and the ability to choose the number of bytes to test.
* Assumes ES and DS point to the memory segment being tested.
* Zero flag = 0 is storage error. AL = 0 on parity check. 
* The read value is XORed with expected value otherwise. This is to detect bad bits (recall that XOR is "one or the other but not both").

```
STGTST:
```
* Load CX with 0x4000 (16kb)

```
STGTST_CNT:
```
* Clear Direction Flag
* Assume CX is properly loaded. Save CX into BX.
* Move 0xAAAA into AX (AL- value to write/read from mem. AH- Compare against)
* Move 0xFF55 into DX (Both bytes are additional test patterns)
* Point DI to the beginning, and write first test pattern.

```
C3:
```
* Point to the last byte just written with DI, set Direction Flag backwards. (Almost verbatim comment)

```
C4:
```
* Copy DI to SI, and load counter CX with copy of original count in BX.

```
C5: 
```
* Compare written data in memory, written into AL, to AH. Jump to C7 on error (XOR AL, AH).
* Get new value to write into AL FROM DL and write new data to memory.
* Loop C5 until CX reaches zero (i.e. until all relevant memory locations filled).
* If AH was zero, this is the end of all memory tests. Jump to C6X.
* Else, copy AL (which holds what was just written to mem) to AH, which will be compared against. * Then EXCHANGE DH and DL.
* If AH is not zero, jump to C6
* Otherwise, move AH to DL and jump to C3 (this implies that the memory will be zeroed... after already being zeroed.)

```
C6:
```
* Clear Direction Flag
* If end of backwards pass (DI + 1 points to 0), jump to C4
* Otherwise Load DX with 0x0001 (remaining two patterns), jump to C3

```
C6X:
```
* Check if a parity error occured, clear zero flag if so. Move 0x00 to AL.

```
C7:
```
* Clear direction flag and return.

####In essence:
* AH: Current Test patten to verify
* AL: Actual read data, data to write.
* DL: Current test pattern to write.
* DH: Next test pattern to write.

Contents or registers are at the END of the check/write loop. Before AH<=AL and DX swap.
* Pass 0f: Write 0xAA. AX = 0xAAAA
* Pass 0b: Check 0xAA, write 0x55. AX=0xAA55 DX=0xFF55
* Pass 1f: Check 0x55, write 0xFF. Reload DX with 0x0001. AX=0x55FF DX=0x55FF
* Pass 1b: Check 0xFF, write 0x01. AX=0xFF01 DX=0x0001
* Pass 2f: Check 0x01, write 0x00. Load DL with 0. AX=0x0100 DX=0x0100
* Pass 2b: Check 0x00, write 0x00. AX=0x0000 DX=0x0000

This subroutine is actually placed before the BIOS Entry Point but after banner.

###CPU Test (BIOS Entry Point)
* Test that the flags register bits retains values (bit set/bit clear) using LAHF/SAHF- AF and OF don't have a corresponding Jump on Condition Code. Halt on error.
* Test all other registers by "walking (moving value between)" all registers for 0xFFFF and 0x0000. Halt on error.

###ROS Checksum Test I
* Disable NMI gate (at 0xA0) 
* Enable page reg (at 0x83)- why? This step seems to not be useful
* Set up PPI- A,C-Input, B-Output (at 0x63, value 0x99)
* Disable Color/Mono gfx devices, enable HiRes Mono (I believe LoRes clock was never soldered to Mono ISA card)
* Disable Parity Check, Gate Sense Switches, Cassette Motor
* Do a simple 8-bit checksum on the BIOS ROM module (8kb). Halt on error.

###Pre-DMA Refresh Tests
* Disable DMA controller
* PIT input frequency is 0x1234DD = 1193181 Hz.
* Test Channel 1 of PIT by waiting for a single tick (?). Halt if takes too long.
* Test Channel 1 of PIT by waiting for a single period (cnt wraps to 0). Halt if takes too long.
* Set up Channel 1 divisor for DMA refresh (0x1234DD/18- around 66KHz, or at least 128 rows every 2 ms: 1/128 * (1/500) = 64kHz).
* For DRAM rows, the convention is 2^n * (128) rows every 2^(n + 1) ms, where n >= 0.
 * A 64kb chunk of memory accesses every second is sufficient, since rows get refreshed repeatedly as the address increments. A memory access to 0x0000 and 0x0100, for instance, refresh the same row for 128-row RAM. A memory access to 0x0000 and 0x0200 refresh the same row for 256-row RAM. Rinse and repeat.
* Test Address and Count Registers of DMA controller by writing and reading a pattern back (0xFF, 0x00). Halt on error.

###Init DMA Refresh
* Set up DMA Cannel 0 for single, read xfer, autoinit, incrementing, and 64kB chunk (0x58) (65536 is to support various DRAM row counts).
* Enable DMA controller (0x00 to command register) and enable channel 0.
* Set up DMA channels 1 to 3 to a known state (single, verify xfer, no autoinit, incrementing). 
 * The 8237 datasheet recommends this in case bad things (TM) happen.

###First 16k Check
* Set DS/ES to 0 (in this case, MOV ES, BX/MOV DS, BX works b/c BX held 0 previously)
* Enable expansion box (write 0x01 to 0x213).
* Check Data Area for whether this is a warm reset or not (0x1234).
* Jump to Storage Test Subroutine. Halt on error.

###Get RAM Size
```
517 CLD ;Needed?
```
* Read sense switches (PORT_A) to determine the number of banks of RAM on the motherboard.
* Zero out this RAM. Ensure reset flag in Data Area is preserved. This does not work quite as intended on 64k/256k boards due to assuming 16kB RAM chips. IBM says that these switches should both be off on 64k/256k boards.


GFX Tables are stored in the following order:
* 40x25 CGA
* 80x25 CGA
* Graphics CGA
* 80x25 Monochrome (HiRes only- LoRes clock is not implemented on board)

#Clone Features
##Turbo Button
To be written. A good starting point is PB2 on the PPI on clones that don't provide a second switch.

#Thanks
* Ray, aka modem7, from [The Vintage Computer Forums](vintage-computer.com), for giving me permission to link to his [website](http://minuszerodegrees.net) and diagrams, and performing various hardware tests and software analysis over the years.

