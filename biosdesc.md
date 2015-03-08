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
IBM PC-compatibles, up to XT-clones consist of the following hardware that is exposed to the programmer, in (rough) order of increasing complexity. In general, the datasheets along with the provided Base Port I/O addresses are sufficient for understanding how the PC's components (onboard *and* external) interact with each other. Topics which are not provided in official datasheets and/or require examining circuit schematics are discussed in subsequent sections. Base Port I/O addresses are listed in parentheses:
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

On PC-class and XT-class machines, other hardware, including a 8284 Clock Generator and 8288 Bus Controller, exist on the mainboard, but are not exposed to the programmer.

###8088 CPU
To expand later.

The IBM PC CPU is an Intel 8088 processor running in maximum mode. Consequently, the 8259 PIC (multiplexes interrupt sources for the single INT input) and 8237 DMAC are supported. The sources for NMI include parity error, handled using TTL glue logic and a TTL parity generator, and I/O channel check from the ISA bus. The address and data buses are buffered using TTL chips.

###8237 DMA Controller
When the IBM PC was designed, requests for DMA were exposed to expansion cards via pins on the ISA bus. The designers decided that hardware should make requests for DMA using an active high signal, and that the DMA controller should acknowledge DMA requests using an active low signal. Normal (uncompressed) timing is used, and mem-to-mem is disabled.

###8253 PIT
Channel 0 of the PIT attaches to the highest-priority interrupt- IR0- of the PIC. This consequently means that the system timer ISR is INT 0x08 (see next section). A square wave (PIT mode 3) is emitted from channel 0, though a pulse (PIT mode 2) should work just as well in practice (PIC is edge-triggered).
Channel 1 feeds into an inverter, which in turn feeds into DREQ0 of the DMAC. A pulse is emitted from channel 1 (PIT mode 2).
Channel 2 attaches to the speaker gate, and emits a square wave (PIT mode 3).

###8259 PIC
The PIC reserves interrupts 0x08-0x0F of the 8088 for external hardware events. This from what I can tell, is a design mistake; the 8086 Family User's Manual explicitly states that interrupts 0x0-0x1F are reserved for Intel's use. They were used in the 286 and above for what would become protected mode. This causes some pain in 5170/AT-clones and above, as the PIC's base address must be relocated.

The PIC's input pins that hardware use to request attention are called Interrupt Requests (IRs). The "IRQ" abbreviation seems to be specific to software descriptions of the interrupt system ([discussion](http://www.vintage-computer.com/vcforum/showthread.php?45214-8259-End-of-Interrupt-Behavior&p=347031#post347031)). The designers of the PC decided to make the ISA bus edge-triggered (low-to-high).

Default interrupts, as described in the PIC datasheet, are also known as "spurious interrupts".

###DMA Page Registers
The 8237 DMA Controller only has enough address lines for a 64kB system. The DMA page registers provide the remaining 4 address bits in an IBM PC system, one for each channel except channel 0. DMA channel 0 handles DRAM Refresh by assertion of 8253 PIT's channel 1 output (see BIOS description for more detail). Consequently, mem-to-mem xfers are not useful. The page register itself is a TTL 4x4 register file.

|Port|Function|
|-----|:-----|
|0x80|Extra storage (Diagnostic Output for POST cards)|
|0x81|DMA channel 2 A16-19|
|0x82|DMA channel 3 A16-19|
|0x83|DMA channel 1 A16-19|

###PPI Ports
Many hardware functions that require only one or two data/control lines are exposed via the PPI. PPI Ports A and C are inputs while B is an output. The following lists a table of I/O from the PPI- copied/modified in presentation from IBM 5150 Technical Reference Manual. Note: **For sense switches, OFF is seen as 1, ON is seen as 0 from the CPU's point-of-view! All references to sense switches are from CPU's POV.**

The PPI is replaced with an 8042 in AT-systems and above, which provides an interface to the same hardware for compatibility.

|PPI Port|Function|Criteria|
|----|:---|----|
|PA0-7|Keyboard Keycode|PB7 == 0|
|PA0|Boot to BASIC (0) or from floppy (1)|PB7 == 1|
|PA1|Reserved|PB7 == 1|
|PA2-3|Number of EXTRA mainboard memory banks (0-3)|PB7 == 1|
|PA4-5|No video (0)/40x25 CGA (1)/80x25 CGA (2)/80x25 Monochrome (3)|PB7 == 1|
|PA6-7|Number of floppy disk drives (1-4)|PB7 == 1|
|PB0|Timer channel 2 gate disable (0)/enable (1)|N/A|
|PB1|PC speaker data disable (0)/enable (1)|N/A|
|PB2|Read I/O channel memory size (0)/512kB bias (1)|N/A|
|PB3|Casette motor off (1)/on (0)|N/A|
|PB4|Enable (0)/disable (1) RAM parity check gate|N/A|
|PB5|Enable (0)/disable (1) I/O channel check gate|N/A|
|PB6|Hold keyboard clock low (0)/Nothing (1)|N/A|
|PB7|Enable keyboard (0)/enable sense switches (1)|N/A|
|PC0|I/O memory count 512kB bias|PB2 == 0|
|PC1-3|Nothing?|PB2 == 0|
|PC0-3|I/O memory count in 32kB increments (0-15)|PB2 == 1|
|PC4|Casette data in|N/A|
|PC5|Timer channel 2 out (PC speaker data)|N/A|
|PC6|I/O channel check gate out|N/A|
|PC7|RAM parity check gate out|N/A|

Notes:
* PA2-3: Always 3 on 64kB-256kB boards.
* PA4-5: 0 can also be interpreted as: Expansion video card's BIOS provides video support routines and hardware init.
* PB0: Timer channel 2's output can be disabled by a gate input on the PIT (PIT has 3 timers; channels 0-2). Likewise, PB6-7 provide gates to prevent the propogation of I/O channel and parity errors (see next section).
* PB1: Timer channel 2's output is the PC speaker data, which is routed through a PC speaker enable gate.
* PB7: 1 clears keyboard shift register as well.

###Gates
Some PC control logic can be prevented from reaching its destination by asserting a wire which feeds into a logic gate (AND/OR) shared with the control logic. Asserting this wire inhibits the value of the other (control) data line from reaching the output out the logic gate by keeping the gate's output de-asserted. At least five gates are provided that the programmer can maniplulate:
* NMI gate: Prevent NMIs from reaching the CPU completely.
* PIT provides gates for each channel. Only channel 2's gate is accesible to the programmer via PPI.
* Speaker data gate can silence the speaker, regardless of PIT channel 2 output and gate.
* I/O channel check: Prevent expansion card errors from reaching the PPI Port C or NMI pin on the CPU.
* Parity check: Prevent parity errors from reaching the PPI Port C or NMI pin on the CPU.

###Sense Switches
For the first set of sense switches, near the center of the board, SW1-8 correspond to PA0-7. For the second set of sense switches, near the power supply, SW1-4 correspond to PC0-3. PC0 also reads SW5 of the second set of sense switches, when PB2 is deasserted. The relevant functions are documented in the PPI ports table.

Total system memory installed in kB, as set by the sense switches, is determined by the following formula (reminder that assertion of switches is OFF position): 
```
Mem in kb = (SW2-5)*512 + (SW2-1 to SW2-4)*32 + (SW1-3 to SW1-4)*16
``` 
Because BIOS checks mainboard RAM first, SW1-3 and SW1-4 should be asserted (set to OFF position) before any of SW2-1 to SW2-5 are asserted. 

###Keyboard
Page 4-4 of the 1984 Technical Reference Manual contains an error. PCLK (14MHz or so) should *not* be connected to the keyboard clock. The keyboard clock should be connected to the input of LS175. PCLK presumably just adds a delay relative to the keyboard data line when being clocked into a shift register.

If I had a desktop computer, I'd likely be using a modern clone of the Model F keyboard with USB- or even a real one that converts scancodes to AT/PS/2 protocol! I already [built a converter before](http://www.vintage-computer.com/vcforum/showthread.php?15907-AT-to-XT-Keyboard-Converter&p=306127#post306127). Sadly, since doing this project, I lost most of my information.

IMHO, what actually happens in the XT keyboard protocol, although simple, is not extensively documented, compared to the more-complx AT protocol. An XT protocol decoder can be built with 3 TTL chips: 
* 74LS322 shift register for the data itself 
* 74LS74 that controls when to trigger interrupts and inhibit shift register input
* 74LS07 for buffering data lines which can control the open-collector keyboard clock and data

The keyboard clocks in a data byte byte by first pulling its clock line low and data line high. Both lines open-collector, meaning either side can pull the line from high to low to say "I need to tell you something". The keyboard then releases the clock high, which causes the shift register to accept the input high data. The next 8 bits, which can be a combination of 0 and 1, are clocked in on the rising edge in the same manner. After the last bit is clocked, the PC pulls the data line low and triggers an interrupt (IRQ 1).

To be continued.

##Expansion Card Hardware
Expansion cards are likely to provide the following hardware (*that BIOS is likely to initialize if found*) as well:
* 6845 CRT Controller (0x3D4-5 Color, 0x3B4-5 Mono)
* MM58167 RTC (0x240, 0x300, 0x340- Found by trial and error)
* TTL Glue logic for Color and Mono adapter configuration (0x3D4-0x3DF Color, 0x3B4-0x3BF Mono)
* TTL Glue logic for Line Printer Terminal (LPT) (0x3BC, 0x378, 0x278, ?)
* TTL Glue logic for Game Control Adapter (0x201)
* 16550 UART for Serial Communications (COM) (0x3F8, 0x2F8, 0x3E8, 0x238)
* 765 Floppy Disk Controller (0x3F2 Glue logic, 0x3F4-0x3F5 Controller)
* VGA VLSI chip (BIOS is provided by controller- PC BIOS simply needs to jump to setup routine)
* Xebec-standard XT hard disk controller (BIOS is provided by controller- PC BIOS simply needs to jump to setup routine)
* Ethernet card (BIOS is provided by card- PC BIOS simply needs to jump to setup routine)

Most hardware is exposed through x86 port-mapped I/O ports. Memory-mapped I/O is reserved for BIOS ROM chips, extra memory and the frame buffer.

The minimum external hardware configuration so that the BIOS doesn't complain (at least IBM's) appears to be Floppy and Video Card.

The following sections describe programming and hardware considerations for expansion cards. The topics discussed here all have circuit schematics, from which most of this information is derived. Most of these expansion cards use TTL latches/registers to implement I/O ports, which feed into/out of other parts of the expansion card circuitry. These latches can (and do) affect operation of other main control logic components, such as the CRT Controller's input clock speed being determined by the CGA mode control register. These are interactions between hardware components (beyond address decoding) that cannot necessarily be inferred *just* from the datasheets for the relevant hardware and TTL chips.
###MDA Card
To be written. Use the CRT parmeters and schematic given in [this document][MDA].
[MDA]: http://www.minuszerodegrees.net/oa/OA%20-%20IBM%20Monochrome%20Display%20and%20Printer%20Adapter.pdf

###CGA Card
To be written. Use the CRT parmeters and schematic given in [this document][CGA].
[CGA]: http://www.minuszerodegrees.net/oa/OA%20-%20IBM%20Color%20Graphics%20Monitor%20Adapter%20(CGA).pdf

###Floppy Controller
To be written. The FDC is arguably the most difficult part of the IBM PC to understand, as it requires knowledge about how data is stored on a floppy drive, as well as workarounds required (clock recovery via PLL) due to physical limitations of floppy media (data density) of sampling data (bit slip). The actual format of floppy data doesn't help matters either. See [MFM](http://en.wikipedia.org/wiki/Modified_Frequency_Modulation), and [here](https://archive.org/details/bitsavers_necdatashe79_1461697). Commit information on the A1 sync mark to memory :). It keeps throwing me off.

##LPT
To be written. See [this document][MDA] for schematic.

###Game Port
To be written. See [this document][GP] for schematic.
[GP]: http://www.minuszerodegrees.net/oa/OA%20-%20IBM%20Game%20Control%20Adapter.pdf

##Software Workarounds and Incompatibilities
TODO: Find a better name for this section! Discuss clone timings and incompatibilities.

Software timing loops are necessary, at least in the early stages of the BIOS, including floppy access The following loop delays approximately 0.412 seconds at 4.77 MHz. ([discussion](http://www.vintage-computer.com/vcforum/showthread.php?45197-IO-Delays-on-8088-class-computers&p=346963#post346963)):
```
	 MOV CX, 0
F11: LOOP F11
```

A more reliable method of delay may be to read an unused I/O port (where wait-states will be added Port 0x80 (POST cards) or port 0x4F ([source](http://www.sat.dundee.ac.uk/psc/pctim003.txt)) seem to be good candidates. Perhaps reading channel 0 of the PIT can work as well.


#Address Space Description of 5150 BIOS
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

##General Division of BIOS (Increasing Addresses)
Accoding to IBM 5150 Technical Reference Manual:
* POST (NMI Vector embedded)
* Bootstrap
* IO Support
* System Configuration Analysis
* Casette (Not documented here- I have no way to test a casette, and Int 0x15 in clones is used for auxilary support routines)
* Graphics Mode Character ROM
* Time Of Day
* Print Screen

The BIOS, in effect:
1. Checks the hardware.
2. Installs ISRs for a variety of interrupts (both hardware-triggered and software-invoked).
3. Provides an mechanism for manipulating I/O devices and getting system information by abstracting hardware details.
4. Initiates loading of another OS.

##BIOS Data Area
TODO: Add other locations, and mark where each location was introduced and from what source(s) I got it.

The BIOS uses 256 bytes from linear address 0x00400 to 0x004FF to store its parameters and data. The following locations are used in the IBM PC 5150 BIOS as described by the IBM 5150 Technical Reference Manual.

###COM/LPT Base Addresses, Equipment Word, Memory Size
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x00400|COM 1 address|2|
|0x00402|COM 2 address|2|
|0x00404|COM 3 address|2|
|0x00406|COM 4 address|2|
|0x00408|LPT 1 address|2|
|0x0040A|LPT 2 address|2|
|0x0040C|LPT 3 address|2|
|0x0040E|LPT 4 address|2|
|0x00410|Equipment word|2|
|0x00412|Manufacturing test|1|
|0x00413|Total memory size|2|
|0x00415|I/O channel memory size|2|

* According to "System BIOS for IBM PC/XT/AT Computers and Compatibles", the equipment word consists of the following fields:

|Bits|Function|
|----|:--------|
|15-14| Number of LPT ports|
|13-12| Reserved|
|11-9| Number of COM ports|
|8| Reserved|
|7-6| Number of disk drives|
|5-4| Other (0)/40x25 CGA (1)/80x25 CGA (2)/Monochrome (3) video mode|
|3| Reserved|
|2| Pointing device|
|1| Coprocessor installed|
|0| Diskette boot enabled|

* The Manufacturing test flag can be used to input a program into the PC using a microcontroller attached to the keyboard port. At least one person uses this to create an XT server.
* Memory sizes are in kB.

###Keyboard
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x00417|Keyboard status|2|
|0x00419|Keypad entry|1|
|0x0041A|Keyboard buffer head|2|
|0x0041C|Keyboard buffer tail|2|
|0x0041E|Keyboard ring buffer|2*16|

* The Keyboard status word is accessed as two bytes. The meaning of each bit is as follows. The 3 LSB do not appear to have meaning in the 5150:

|Bits|Function|
|----|:--------|
|15|Insert state is inactive (0)/active (1)|
|14|Caps lock state is inactive (0)/active (1)|
|13|Num lock state is inactive (0)/active (1)|
|12|Scroll lock state is inactive (0)/active (1)|
|11|Alt key is not depressed (0)/depressed (1)|
|10|Ctrl key is not depressed (0)/depressed (1)|
|9|Left shift key is not depressed (0)/depressed (1)|
|8|Right shift key is not depressed (0)/depressed (1)|
|7|Insert key is not depressed (0)/depressed (1)|
|6|Caps lock key is not depressed (0)/depressed (1)|
|5|Num lock key is not depressed (0)/depressed (1)|
|4|Scroll lock key is not depressed (0)/depressed (1)| 
|3|Hold state is inactive(0)/active (1)|

* TODO: Discuss keyboard key mappings to states (i.e. Hold state triggered by Pause/Break key) and keypad entry.
* If head == tail in the ring buffer, the buffer is empty. Because of this, only 15 words are usable. Each buffer entry stores the ASCII equivalent of the scancode, and then the scancode itself.

###Floppy
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x0043E|Seek status|1|
|0x0043F|Motor status|1|
|0x00440|Motor count|1|
|0x00441|Disk status|1|
|0x00442|NEC controller status|1*7|

* Seek status bits 0-3 represent whether drives 0-3 require calibration on the next seek command. A 0 for the corresponding drive bit indicates that recalibration is required. The BIOS uses the top 4 bits for internal housekeeping. In the 5150 BIOS, only the MSB bit is used. **The MSB indicates that IR 6, which connects to the floppy drive, has been serviced. It is up to INT 0x0E (8 + 6 = 0x0E) to set the MSB of 0x0043E.**
* Motor status bits 0-3 represent whether drives 0-3's motors are running. Bit 7 is used to indicate that the current 765 command to be sent is a write, and that a delay for motor spin-up is required before sending the command.
* TODO: Discuss floppy cable twists and how they prevent multiple motors from running simultaneously.
* Motor count is the count in system ticks before floppy motor shuts off.
* The meaning of various bits in the Disk status byte is as follows (0 represents no errors):

|Bits|Function|
|----|:--------|
|7|Timeout for diskette operation|
|6|Seek error|
|5|Controller failure|
|4|CRC error from diskette read|
|3|Dma overrun (1)/DMA 64kb Boundary exceeded (1 **and** Bit 0 == 1)|
|2|Record not found|
|0-1|Invalid 765 command (1)/Bad address mark (2)/Write protected disk (3)|
* Many conditions cause "Controller failure to be returned". See BIOS description.
* TODO: Figure out why it's called DMA "overrun".
* 765 FDC returns up to 7 bytes as status of command execution.

###Video
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x00449|CRT mode|1|
|0x0044A|CRTC number columns|2|
|0x0044C|Video card buffer size|2|
|0x0044E|Video card buffer start|2|
|0x00450|Cursor position|2*8|
|0x00460|Cursor mode|2|
|0x00462|Active page|1|
|0x00463|CRTC address|2|
|0x00465|Video card mode register mirror|1|
|0x00466|CRT palette|1|

###Casette
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x00467|Casette edge count|2|
|0x00469|Casette CRC register mirror|1|
|0x0046B|Casette last input value|1|

###Timer
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x0046C|Timer count|4|
|0x00470|24-hour overflow for timer|1|

* The timer count is accessed as two words in 5150 BIOS.


###System
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x00471|Break flag|1|
|0x00472|Reset flag|2|

* The reset flag is given the value 0x1234 to tell the BIOS to do a warm reset.

###Fixed disk
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x00474|Fixed disk data area|4|

* In 5150/5160 systems and respective clones, the hard disk controller is expected to provide int 0x13 subroutines. Like on 5170 systems and clones, however, the register set is possibly standardized.

###LPT/COM Timeouts
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x00478|LPT 1 timeout|1|
|0x00479|LPT 2 timeout|1|
|0x0047A|LPT 3 timeout|1|
|0x0047B|LPT 4 timeout|1|
|0x0047C|COM 1 timeout|1|
|0x0047D|COM 2 timeout|1|
|0x0047E|COM 3 timeout|1|
|0x0047F|COM 4 timeout|1|

###Extra Keyboard Data
|Address (Linear)|Function|Size (Bytes)|
|----|:---|---|
|0x00480|Keyboard ring buffer start|2|
|0x00482|Keyboard ring buffer end|2|

* The above variables describe the beginning and end addresses for the keyboard ring buffer. This is in contrast to the current head and tail.


##Entry Point Table
IBM BIOSes, including clones, tend to reserve specific addresses as entry points into its interrupt service routines. The following is a list of such entry points that should be kept for compatibility with software which jumps directly into BIOS. This includes certain Option ROMs and early-PC software which thought it was a good idea to bypass the ```INT``` instruction to save a few cycles.

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
|0xFF065|INT 10 Entry Point|
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
|0xFFFF5|"MM/DD/YY"|
|0xFFFFE|System Model 0xFC|

Sometimes the Interrupt Vectors can also be found after the Dummy Interrupt Handler, but this is not universal (for example, the COMPAQ Portable BIOS does not do this).

##BIOS Video Modes
To be written.

#5150 BIOS Verbal Description
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
* Test Channel 1 of PIT by waiting for a single tick (?). Halt if takes too long (use software-timed loop).
* Test Channel 1 of PIT by waiting for a single period (cnt wraps to 0). Halt if takes too long (use software-timed loop).
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


6845 CRT Controller parameters are stored in the following order:
* 40x25 CGA
* 80x25 CGA
* Graphics CGA
* 80x25 Monochrome (HiRes only- LoRes clock is not implemented on board)

#Clone Features
##Turbo Button
To be written. A good starting point is PB2 on the PPI on clones that don't provide a second switch.

#Thanks
* Ray, aka modem7, from [The Vintage Computer Forums](vintage-computer.com), for giving me permission to link to his [website](http://minuszerodegrees.net) and diagrams, and performing various hardware tests and software analysis over the years.

