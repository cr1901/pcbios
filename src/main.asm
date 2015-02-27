;General BIOS macros
%macro post_err 1
	mov al, %1
	jmp err_hlt
%endmacro


;Helper macro for higher-speed boards. Right now it resolves to nothing.
%if 0 ;TURBO_CLONE_{FIXED, ADJUST}
	%macro delay 0
		jmp %%delay
	%%delay:
	%endmacro
%else
	%define delay
%endif

;Generate a jump table with the following inputs:
;%1 becomes a label to the table: %1_tab
;%2 becomes is appended to the base_name to create a (near) jump table entry. The name 
;is that of a label elsewhere in the translation unit.
;%3 is the number of jump_table entries
%macro jump_table 3 ;Base name, entry prefix, number entries
%1_tab:
	%assign n 0h
	%rep %3
		dw %1_%2 %+ n
		%assign n n+1h
	%endrep
%endmacro

%macro int_table 2
	jump_table int %+ %1, sub, %2	
%endmacro


;General defines
%define crlf 0x0D, 0x0A
%define lin2seg(_x) (_x >> 4) ;Use segments 0x0, 0x1000, 0x2000, etc
%define lin2off(_x) (_x & 0x0FFFF)
%xdefine bit(_x, _offset) _x << _offset

;IO defines
;Onboard hardware
%define DMAC_base 0
struc DMA_8237
.baseaddr0 resb 0
.curraddr0 resb 1
.basewc0 resb 0
.currwc0 resb 1
.baseaddr1 resb 0
.curraddr1 resb 1
.basewc1 resb 0
.currwc1 resb 1
.baseaddr2 resb 0
.curraddr2 resb 1
.basewc2 resb 0
.currwc2 resb 1
.baseaddr3 resb 0
.curraddr3 resb 1
.basewc3 resb 0
.currwc3 resb 1
.status resb 0
.cmd resb 1
.request resb 1
.msksngl resb 1
.mode resb 1
.clearff resb 1
.temp resb 0
.mclr resb 1
.mskclr resb 1
.mskall resb 1
endstruc
%define DMAC(_x) DMAC_base + DMA_8237. %+ _x

%define PIC_base 0x20
struc PIC_8259
.icw1 resb 0
.ocw2 resb 0
.ocw3 resb 1
.icw2 resb 0
.icw3 resb 0
.icw4 resb 0
.ocw1 resb 0
endstruc
%define PIC(_x) PIC_base + PIC_8259. %+ _x

%define PIT_base 0x40
struc PIT_8253
.count0 resb 1 ;Writes start value to count down to 0 before event trigger, reads current count.
.count1 resb 1
.count2 resb 1
.ctrl resb 1
endstruc
%define PIT(_x) PIT_base + PIT_8253. %+ _x

%define PPI_base 0x60
struc PPI_8255
.porta resb 1 ;Keycode/switches
.portb resb 1 ;Gates and other control logic
.portc resb 1 ;Mem switches/mainboard status
.ctrl resb 1
endstruc
%define PPI(_x) PPI_base + PIT_8255. %+ _x

%define PAGE_base 0x80
struc PAGE_regs
.POST resb 1
.chan2 resb 1
.chan3 resb 1
.chan1 resb 1
endstruc
%define PAGE(_x) PAGE_base + PAGE_regs. %+ _x

%define NMI_gate 0xA0

;External hardware (including expansion cards)
%define COM1_base 0x3F8
%define COM2_base 0x2F8
%define COM3_base 0x3E8
%define COM4_base 0x2E8
;struc COM_8250
;endstruc


%define MDA_base 0x3B4
struc MDA_reg
.idx6845 resb 1
.data6845 resb 1
resb 2
.ctrl resb 1
resb 1
.status resb 1
endstruc
%define MDA(_x) MDA_base + MDA_reg. %+ _x

%define CGA_base 0x3D4
struc CGA_reg
.idx6845 resb 1
.data6845 resb 1
resb 2
.modectl resb 1
.colorsel resb 1
.status resb 1
endstruc
%define CGA(_x) CGA_base + CGA_reg. %+ _x

struc CRTC_6845
.htotal resb 1
.hdisp resb 1
.hsyncpos resb 1
.hsyncwid resb 1
.vtotal resb 1
.vadjust resb 1
.vdisp resb 1
.vsyncpos resb 1
.interlace resb 1
.maxline resb 1
.cursbeg resb 1
.cursend resb 1
.startadh resb 1
.startadl resb 1
.cursh resb 1
.cursl resb 1
.lpenh resb 1
.lpenl resb 1
endstruc
%define CRTC(_x) CRTC_6845. %+ _x

%define LPT1_base 0x3BC
%define LPT2_base 0x378
%define LPT3_base 0x278
struc LPT_reg
.data resb 1
.status resb 1
.ctrl resb 1
endstruc
%define LPT1(_x) LPT1_base + LPT_reg. %+ _x
%define LPT2(_x) LPT2_base + LPT_reg. %+ _x
%define LPT3(_x) LPT3_base + LPT_reg. %+ _x


;BDA defintions
struc bios_data_area
.com1addr resw 1
.com2addr resw 1
.com3addr resw 1
.com4addr resw 1
.lpt1addr resw 1
.lpt2addr resw 1
.lpt3addr resw 1
.lpt4addr resw 1
.equipword resw 1

endstruc
%define BDA(_x) bios_data_area. %+ _x

;Equipment word format (according to Phoenix BIOS book):
;15-14- Number of LPT ports
;13-12- Reserved
;11-9- Number of COM ports
;8- Reserved
;7-6- Numbr of disk drives
;5-4- Other (0)/40x25 CGA (1)/80x25 CGA (2)/Monochrome (3) video mode
;3- Reserved
;2- Pointing device
;1- Coprocessor installed
;0- Diskette boot enabled

;section .bss
;org 0x400
;resb bios_data_area_size


;Entry point management defines
%define ibm_compat_offset 0xFE000 ;The original BIOS started here

;Essentially, pad until the entry point is reached. Will error out if exceeded.
%macro ibm_entry 1
	times %1-($-$$)-ibm_compat_offset db 0xFF
%endmacro

%define post_entry     ibm_entry 0xFE05B ;POST Entry Point
%define NMI_entry      ibm_entry 0xFE2C3 ;NMI Entry Point
%define HDDparam_entry ibm_entry 0xFE401 ;HDD Parameter Table
%define int19h_entry   ibm_entry 0xFE6F2 ;INT 19 Entry Point
%define cfgdata_entry  ibm_entry 0xFE6F5 ;Configuration Data Table
%define baud_entry     ibm_entry 0xFE729 ;Baud Rate Generator Table
%define int14h_entry   ibm_entry 0xFE739 ;INT 14 Entry Point
%define int16h_entry   ibm_entry 0xFE82E ;INT 16 Entry Point
%define int09h_entry   ibm_entry 0xFE987 ;INT 09 Entry Point
%define int13h_entry   ibm_entry 0xFEC59 ;INT 13 Floppy Entry Point
%define int0eh_entry   ibm_entry 0xFEF57 ;INT 0E Entry Point
%define FDCparam_entry ibm_entry 0xFEFC7 ;Floppy Disk Controller Parameter Table
%define int17h_entry   ibm_entry 0xFEFD2 ;INT 17
%define int10h_entry   ibm_entry 0xFF065 ;INT Video
%define int1dh_entry   ibm_entry 0xFF0A4 ;MDA and CGA Video Parameter Table INT 1D
%define int12h_entry   ibm_entry 0xFF841 ;INT 12 Entry Point
%define int11h_entry   ibm_entry 0xFF84D ;INT 11 Entry Point
%define int15h_entry   ibm_entry 0xFF859 ;INT 15 Entry Point
%define gfxchar_entry  ibm_entry 0xFFA6E ;Low 128 character of graphic video font
%define int1ah_entry   ibm_entry 0xFFE6E ;INT 1A Entry Point
%define int08h_entry   ibm_entry 0xFFEA5 ;INT 08 Entry Point
%define dummyint_entry ibm_entry 0xFFF53 ;Dummy Interrupt Handler
%define int05h_entry   ibm_entry 0xFFF54 ;INT 05 Print Screen Entry Point
%define reset_entry    ibm_entry 0xFFFF0 ;Power-On Entry Point
%define ROMdate_entry  ibm_entry 0xFFFF5 ;ROM Date in ASCII “MM/DD/YY” for 8 characters
%define sysmodel_entry ibm_entry 0xFFFFE ;System Model 0xFC 

;Just place the table of interrupt vectors somewhere in the code.
;%macro int_table 0

;%endmacro

;BIOS code begins here
section .text ;Not necessary, but this is where the real code starts
org ibm_compat_offset ;Where the assembler thinks the code starts relative to CPU
;org 0xE0000

banner:	db '5150-class IBM PC BIOS', crlf
	db '(c) 2013-15 William D. Jones', crlf, 0x00

post_entry
;Will need to think this one through.
;Simple CMP won't work b/c unused flag positions are undefined.
;fl_chk:
;	mov ah, 0b11010101 ;Check if AX and FLAGS work
;	mov ah, al
;	sahf
;	lahf
;	cmp ah, al
;	jne .bad_fl
;	xor ah, ah
;	sahf
;	lahf
;	test a
;.bad_fl:
	
	;jc fl_okay

;If we got here, we know AX and FLAGS retain values.
;cpu_chk:
;	mov ax, 0xAA55
;.invert:
;	mov dx, ax
;	mov ds, dx
;	mov cx, ds
;	mov es, cx 
;	mov bx, es
;	mov ss, bx
;	mov si, ss
;	mov di, si
;	mov sp, di
;	mov bp, sp
;	xor ax, bp
;	jne .bad_gp
;	cmp bp, 0x55AA
;	je .gp_okay
;	mov ax, 0x55AA
;	jmp .invert
;.bad_gp:
;	post_err 0
;.gp_okay:
;	post_err 1
;	;jc fltest
	
	;jnc

	
init_refresh:
;First we need to initialize PIT channel 1, which feeds into DREQ0 on DMAC after
;some glue logic which can be ignored here.
;Although 8253 datasheet explicitly says all registers are undefined on power-on,
;it appears to be legal to load just the LSB of the counter. Load both bytes just in case.
	mov al, 0x74 ;Channel 1 select, Load word (LSB, then MSB), Mode 2, binary counter
	out PIT(ctrl), al
	mov al, 0x12 ;0x1234DD/18 = approx 66KHz, or 128 rows every 2ms, 256 every 4ms, etc.
	out PIT(count1), al
	xor al, al
	out PIT(count1), al

;Then we need to initialize DMA controller channel 0. (AL already 0- how convenient)
	out DMAC(mclr), al ;Put 8237 in known state.
	delay
	out DMAC(cmd), al ;Command register is indeed zero! 
	;Active-high REQ, active-low ACK, late-write signal (see timing 
	;diagrams), no compressed timing, chan 0 is not used for mem-to-mem 
	;xfers.
	delay
	out DMAC(baseaddr0), al
	delay ;For higher clock speeds- may need a delay so DMA controller
	;can respond properly (i.e. "recovery time" between accesses)
%if 0 ;POST_CARD_REFRESH_COMPAT
	mov al, 0x1
%endif	
	out DMAC(baseaddr0), al
	mov al, 0xFF
	out DMAC(basewc0), al ;Will xfer 65536 bytes incrementing before reload
	delay
%if 0 ;POST_CARD_REFRESH_COMPAT
	mov al, 0x1
%endif
	
	out DMAC(basewc0), al
	mov al, 0x58 ;Channel 0 is DRAM refresh- PIT output of channel 1 
	;connected to it. Single mode, increment, auto enable, read xfer.
	out DMAC(mode), al
	;Set the other channels to a known state (single mode, increment, 
	;NO auto enable, verify, channels 1-3)
	mov cx, 3
	mov al, 0x41
.other_dma:
	out DMAC(mode), al
	inc al ;Next channel
	loop .other_dma

;If we got here, all is okay. Enable DRAM Refresh!
	mov al, 0x0E ;Mask all but Ch. 0
	out DMAC(mskall), al
	;hlt
	
;Quick check first 1kB RAM, if verified, we can set up a stack and use subroutines.
;quick_chk_1k:
;;One time setup
;	xor bx, bx
;	mov ds, bx
;	mov es, bx
;	mov ax, 0xAA55
;	mov bp, ax
;
;;Pass I and II setup	
;	cld
;	xor si, si
;	xor di, di
;	mov cx, 0x200
;	rep stosw
;	mov cx, 0x200
;	sub si, 2 ;Perhaps use space-saving add later?
;	sub di, 2
;	std
;.read_next:
;	lodsw
;	cmp ax, bp
;	loope .read_next
;	;jne .bad_1k
	
	
	

set_stack:
	xor ax, ax
	mov ss, ax
	mov sp, 0x400 ;0x300-0x3FF becomes stack- SP points to "last used".
	
	;If CGA/MDA 6845 CRTCs exist, initialize them now using the tables
	;provided by INT 0x1D and the switch settings.
	
video_BIOS_init:
	;call near rom_chksum
	mov ax, 0xC000
	mov ds, ax
	;mov ax, word [0]
	;cmp ax, 0xAA55
	;jne .no_video_ROM
	;xor ah, ah
	;mov al, byte [2] ;If option ROM, get number of 512 byte pages
	;mov cl, 9
	;shl ax, cl ;Convert to bytes
	;mov cx, ax
	;xor si, si
	;call near rom_chksum ;verify checksum
	;jnz .bad_video_ROM
	call far [ds:3] ;Jump into option ROM and wait for return
	jmp .done
	
.bad_video_ROM:	
	
.no_video_ROM:
.done:
	hlt

;Video card needs to provide its own refresh circuitry


;Helper subroutines (entered by call)/repeatedly-used blocks of code (entered by jmp)
beep_err:
err_hlt:
	out PAGE(POST), al
	hlt
	

;
;Assumes: ES/DS: set to segment to check
;CX- Number of words (16-bits) to check
;AX- Test pattern
;Return- CX=0 AND CF=0, no error. CF=1 Parity, CX=nonzero failing bit position
;Trashes- AX, BX, CX, DX, DI, SI, BP
mem_chk:
.again:
	mov dx, cx ;Save copy of count
	mov bx, ax ;Save copy of test pattern
	xor si, si
	xor di, di 
.write_pattern:
	cld
	rep stosw
	mov cx, dx ;Get the count back
.chk_next:
	lodsw
	cmp bx, ax ;Check that pattern read was correct
	loope .chk_next 
	test cx, 0xFFFF ;If CX is nonzero
	jne .find_bad_bits
	
.find_bad_bits:


;Assumes: DS: set to segment to check
;SI: Offset to start checking
;CX- number of bytes to check
;Return- AH=Sum of all bytes. ZF=1, no error.
rom_chksum:
	xor ax, ax
.next_byte:
	lodsb
	add ah, al
	loop .next_byte
	retn
	;mov 
	


NMI_entry
	post_err 3
	
HDDparam_entry
	db 0
int19h_entry
cfgdata_entry
baud_entry
int14h_entry
int16h_entry
int09h_entry
int13h_entry
	mov bl, ah
	xor bh, bh
	

int0eh_entry
FDCparam_entry
int17h_entry
int10h_entry
	;cmp ah, 
	jg .bad_id
	mov bl, ah
	xor bh, bh
	shl bl, 1 ;Double bl
	mov cx, [cs:int10h_tab + bx]
	jmp cx
.bad_id:
	iret
	
jump_table int10h, sub, 16
;There isn't much space between here and int1dh_entry...
	
int1dh_entry
;Table entries include:
;Htotal, Hdisplayed, Hsync_pos, Hsync_width, Vtotal, Vtotal_adjust
;Vdisplayed, Vsync_pos, Interlace, Maxsl, Cursor_star, Cursor_end
;Start_addr (word), Cursor (word)
cga_params_4025:
db 0x38, 0x28, 0x2D, 0x0A, 0x1F, 0x06
db 0x19, 0x1C, 0x02, 0x07, 0x06, 0x07
dw 0x0, 0x0

cga_params_8025:
db 0x71, 0x50, 0x5A, 0x0A, 0x1F, 0x06
db 0x19, 0x1C, 0x02, 0x07, 0x06, 0x07
dw 0x0, 0x0

cga_params_gfx:
db 0x38, 0x28, 0x2D, 0x0A, 0x7F, 0x06
db 0x64, 0x70, 0x02, 0x01, 0x06, 0x07
dw 0x0, 0x0

mda_params:
db 0x61, 0x50, 0x52, 0x0F, 0x19, 0x06
db 0x19, 0x19, 0x02, 0x0D, 0x0B, 0x0C
dw 0x0, 0x0


int10h_sub0:
int10h_sub1:

;Set cursor position
int10h_sub2:
	mov bx, dx
	mov dx, CGA(idx6845)
	mov al, CRTC(cursl)
	out dx, al
	;Somehow convert BX to a character position.
	
	mov dx, CGA(data6845)
	in al, dx
	mov bl, al
	mov dx, CGA(idx6845)
	mov al, CRTC(cursh)
	out dx, al
	mov dx, CGA(data6845)
	in al, dx
	mov bh, al
	
	
	;mov al, 
	;times 200 nop
int10h_sub3:

int10h_sub4:

int10h_sub5:
int10h_sub6:
int10h_sub7:
int10h_sub8:
int10h_sub9:
int10h_sub10:
int10h_sub11:
int10h_sub12:
int10h_sub13:
int10h_sub14:
int10h_sub15:




int12h_entry
int11h_entry
int15h_entry

gfxchar_entry
%ifdef GFX_ROM
	%incbin GFX_ROM
%endif

int1ah_entry
int08h_entry
dummyint_entry
	iret

int05h_entry

reset_entry
;jmp far 0xF000:E05B
db `\xEA\x5B\xE0\x00\xF0`, DATE_STAMP, 'CR', 0



