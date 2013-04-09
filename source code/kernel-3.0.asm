;*************100498G*********Senaratne H.H.*************
;*****************start of the kernel code***************
[org 0x000]
[bits 16]

[SEGMENT .text]

;START #####################################################
    	mov ax, 0x0100			;location where kernel is loaded
    	mov ds, ax
	mov es, ax
    
	cli
    	mov ss, ax				;stack segment
    	mov sp, 0xFFFF			;stack pointer at 64k limit
    	sti

    	push dx
    	push es
    	xor ax, ax
    	mov es, ax
    	cli
    	mov word [es:0x21*4], _int0x21	; setup interrupt service
    	mov [es:0x21*4+2], cs
    	sti
    	pop es
    	pop dx
	
	call _display_endl
    	mov si, strWelcomeMsg   ; load message
    	mov al, 0x01            ; request sub-service 0x01
    	int 0x21
	
	call _display_endl
	call _display_endl

	mov si, strHelp; load help message
	mov al, 0x01
	int 0x21	

	call _shell				; call the shell
    
    	int 0x19                ; reboot
;END #######################################################

_int0x21:
    	_int0x21_ser0x01:       ;service 0x01
    		cmp al, 0x01            ;see if service 0x01 wanted
    		jne _int0x21_end        ;goto next check (now it is end)
    
	_int0x21_ser0x01_start:
    		lodsb                   ; load next character
    		or  al, al              ; test for NUL character
    		jz  _int0x21_ser0x01_end
    		mov ah, 0x0E            ; BIOS teletype
    		mov bh, 0x00            ; display page 0
    		mov bl, 0x07            ; text attribute
    		int 0x10                ; invoke BIOS
    		jmp _int0x21_ser0x01_start
    	_int0x21_ser0x01_end:
    		jmp _int0x21_end

    	_int0x21_end:
    		iret

_shell:
	_shell_begin:
	;move to next line
	call _display_endl

	;display prompt
	call _display_prompt

	;get user command
	call _get_command
	
	;split command into components
	call _split_cmd

	;check command & perform action

	; empty command
	_cmd_none:		
	mov si, strCmd0
	cmp BYTE [si], 0x00
	jne	_cmd_ver		;next command
	jmp _cmd_done
	
	; display version
	_cmd_ver:		
	mov si, strCmd0
	mov di, cmdVer
	mov cx, 4
	repe	cmpsb
	jne	_cmd_help		;next command	
	
	call _display_endl
	mov si, strOsName		;display version
	mov al, 0x01
    int 0x21
	call _display_space
	mov si, txtVersion		;display version
	mov al, 0x01
    int 0x21
	call _display_space

	mov si, strMajorVer		
	mov al, 0x01
    int 0x21
	mov si, strMinorVer
	mov al, 0x01
    int 0x21
	call _display_endl
	jmp _cmd_done

	
	_cmd_help:			;help command
	mov si, strCmd0
	mov di, cmdHelp
	mov cx, 5		
	repe cmpsb
	jne _cmd_hw  ;next command
	
	call _help
	jmp _cmd_done

	_cmd_hw:			;commannd to get hardware info
	mov si, strCmd0
	mov di, cmdHW
	mov cx, 3		
	repe cmpsb
	jne _cmd_exit  ;next command
	
	call _hw
	jmp _cmd_done
	

	; exit shell
	_cmd_exit:		
	mov si, strCmd0
	mov di, cmdExit
	mov cx, 5
	repe	cmpsb
	jne	_cmd_unknown		;next command

	je _shell_end			;exit from shell

	_cmd_unknown:
	call _display_endl

	mov si, msgUnknownCmd		;unknown command
	mov al, 0x01
    int 0x21

	_cmd_done:

	jmp _shell_begin
	
	_shell_end:
	ret

	
;************Available Commands**************
_help:
	call _display_endl
	mov si, strCommands
	mov al, 0x01
	int 0x21
	call _display_endl
	mov si, strVer
	mov al, 0x01
	int 0x21
	call _display_endl
	mov si, strHW
	mov al, 0x01
	int 0x21
	call _display_endl
	mov si, strExit
	mov al, 0x01
	int 0x21
	call _display_endl
		
	ret
;**************Hardware Info*******************
_hw:
	call _display_endl
	mov si, strHardware
	mov al, 0x01
	int 0x21
	call _display_endl

	call _cpu_details
	call _mouse_details
	call _keyboard_details
	call _memory_details
	call _hardDrive_details
	call _diskette_details	
	call _serial_details
	call _parallel_details
	call _bios_details

	call _display_endl		
	ret

;***************CPU details***********************
_cpu_details:
	call _display_endl	;cpu vender
	mov si, strVendor
	mov al, 0x01
	int 0x21

	mov eax, 0x00
	cpuid
	mov [strCPUID], ebx
	mov [strCPUID+4], edx
	mov [strCPUID+8], ecx

	mov si, strCPUID
	mov al, 0x01
	int 0x21

	call _display_endl	;cpu type
	mov si, strCpuType
	mov al, 0x01
	int 0x21
	
	mov eax, 0x80000002
	cpuid
	mov [strBrand],eax
	mov [strBrand+4],ebx
	mov [strBrand+8],ecx
	mov [strBrand+12],edx

	mov eax, 0x80000003
	cpuid
	mov [strBrand+16],eax
	mov [strBrand+20],ebx
	mov [strBrand+24],ecx
	mov [strBrand+28],edx

	mov eax, 0x80000004
	cpuid
	mov [strBrand+32],eax
	mov [strBrand+36],ebx
	mov [strBrand+40],ecx
	mov [strBrand+44],edx

	mov si, strBrand
	mov al, 0x01
	int 0x21
	
	ret

;****************Mouse Details****************
_mouse_details:
     	call _display_endl
	xor ax, ax
    	int 0x11
     	and ax, 0x04 		;bit 2
     	shr ax, 2 
     	cmp ax, 0x01         
     	je endmouse              
     	mov si, strnomouse	;if no mouse
     	mov al, 0x01
	int 0x21
     	jmp end1
    	endmouse:		;if detected
     	mov si, strismouse
     	mov al, 0x01
	int 0x21
    	end1:
	ret

;**************Keyboard details**************
_keyboard_details:
     	call _display_endl
	xor ah,ah
	mov ah,0xf2
     	int 0x16
	cmp al,0x00
	je _none
	mov si, strPC	;if 9-bit PC keyboard 
     	mov al, 0x01
	int 0x21
     	jmp _end2

	_none:
	cmp al,0x01
	je _AT
    	mov si, strnokey ;if no keyboard detected
     	mov al, 0x01
	int 0x21
	jmp _end2
	
	_AT:
	mov si, strAT 	;if 11-bit AT keyboard
     	mov al, 0x01
	int 0x21
	jmp _end2

    	_end2:
	ret

;****************memory details**********************
_memory_details:
	call _display_endl	
	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor dx,dx	
	mov ax, 0xe801
	int 0x15		
	jc _error		; if CF is set on an error
	cmp ah, 0x86		; check for unsupported function
	je _error
	cmp ah, 0x80		; check for invalid command
	je _error
	mov si, strmem
	mov al, 0x01
	int 0x21
	cmp cx, 0x0000		;if cx=0
	je _cx_zero
	jmp _mem_cal
	
	_cx_zero:		;solve cx conflict
	mov cx,ax		
	mov dx,bx		

	_mem_cal:
	shr dx, 4		;divide dx by 2^4
	shr cx, 10		;divide cx by 2^10 
	add cx,dx		;get the total 
	mov dx, cx
	call _hex2dec		;convert hex to decimal
	mov si, strMB
	mov al, 0x01
	int 0x21
	jmp _memdone

	_error:			;error message
	mov si, strMemErr
	mov al, 0x01
	int 0x21
	
	_memdone:
	ret

;******************Hard drive details*****************
_hardDrive_details:
	call _display_endl
	mov si, strHardDrive
	mov al, 0x01
	int 0x21
	mov ax, 0x0040
	push es
	mov es,ax
	mov al,[es:0x0075]	; read 40:75 offset
	add al, 48			
	pop es
	mov ah, 0x0e
	int 0x10
	ret

;***************Diskette details*********************
_diskette_details:
	call _display_endl
	mov si, strDiskette
	mov al, 0x01
	int 0x21
	xor ax, ax
	int 0x11
	and ax,0x01
	cmp ax,0x01	
	je _is_floppy
	mov ah, 0x0e	;if no floppy print 0
    	mov al, '0'
    	int 0x10
    	ret	

	_is_floppy:	;if floppy is installed
	and ax, 0xc0	;bit 6 and 7
	shr ax, 6
	add ax, 49	;convert to ascii (+1)
	mov ah, 0x0e
	int 0x10
	ret

;*************Serial details********************
_serial_details:
	call _display_endl
	
	mov si, strSerial
	mov al, 0x01
	int 0x21
		
	xor ax, ax
	int 0x11
	and ax, 0xe00	;bits 9-11
	shr ax, 9
	add ax, 48	;converts to ascii
	mov ah, 0x0e
	int 0x10
	ret 

;*************Parallel details******************
_parallel_details:
	call _display_endl
	
	mov si, strParallel
	mov al, 0x01
	int 0x21
		
	xor ax, ax
	int 0x11
	and ax, 0xc000	;bits 14 and 15
	shr ax, 14
	add ax, 48	;converts to ascii
	mov ah, 0x0e	
	int 0x10
	ret 	

;*************Bios details******************	
_bios_details:
	call _display_endl
	mov si, strBios
	mov al, 0x01
	int 0x21
	push es
	mov ax, 0xf000	;BIOS release date
	mov es, ax	;      is in F000:FFF5
	mov si, 0xfff5
	mov bl,8

	_loop:		;loop to print
	mov al, [es:si]
	mov ah, 0x0e
	int 0x10
	inc si
	dec bl
	cmp bl, 0
	jne _loop
	
	pop es
	ret

;==============Other functions=================

_hex2dec:
	push ax
	push bx
	push cx
	push si
	mov ax,dx                
	mov si,10               
	xor cx,cx             

	_non_zero:
	xor dx,dx              
	div si                 
	push dx               
	inc cx                 
	or ax,ax                
	jne _non_zero            

	_write_digits:
	pop dx                 
	add dl,48              
	mov al, dl
	mov ah, 0x0e
	int 0x10
	loop _write_digits


	pop si
	pop cx
	pop bx
	pop ax
	ret


_get_command:
	;initiate count
	mov BYTE [cmdChrCnt], 0x00
	mov di, strUserCmd

	_get_cmd_start:
	mov ah, 0x10		;get character
	int 0x16

	cmp al, 0x00		;check if extended key
	je _extended_key
	cmp al, 0xE0		;check if new extended key
	je _extended_key

	cmp al, 0x08		;check if backspace pressed
	je _backspace_key

	cmp al, 0x0D		;check if Enter pressed
	je _enter_key

	mov bh, [cmdMaxLen]		;check if maxlen reached
	mov bl, [cmdChrCnt]
	cmp bh, bl
	je	_get_cmd_start

	;add char to buffer, display it and start again
	mov [di], al			;add char to buffer
	inc di					;increment buffer pointer
	inc BYTE [cmdChrCnt]	;inc count

	mov ah, 0x0E			;display character
	mov bl, 0x07
	int 0x10
	jmp	_get_cmd_start

	_extended_key:			;extended key - do nothing now
	jmp _get_cmd_start

	_backspace_key:
	mov bh, 0x00			;check if count = 0
	mov bl, [cmdChrCnt]
	cmp bh, bl
	je	_get_cmd_start		;yes, do nothing
	
	dec BYTE [cmdChrCnt]	;dec count
	dec di

	;check if beginning of line
	mov	ah, 0x03		;read cursor position
	mov bh, 0x00
	int 0x10

	cmp dl, 0x00
	jne	_move_back
	dec dh
	mov dl, 79
	mov ah, 0x02
	int 0x10

	mov ah, 0x09		; display without moving cursor
	mov al, ' '
    mov bh, 0x00
    mov bl, 0x07
	mov cx, 1			; times to display
    int 0x10
	jmp _get_cmd_start

	_move_back:
	mov ah, 0x0E		; BIOS teletype acts on backspace!
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
	mov ah, 0x09		; display without moving cursor
	mov al, ' '
    mov bh, 0x00
    mov bl, 0x07
	mov cx, 1			; times to display
    int 0x10
	jmp _get_cmd_start

	_enter_key:
	mov BYTE [di], 0x00
	ret

_split_cmd:
	;adjust si/di
	mov si, strUserCmd
	;mov di, strCmd0

	;move blanks
	_split_mb0_start:
	cmp BYTE [si], 0x20
	je _split_mb0_nb
	jmp _split_mb0_end

	_split_mb0_nb:
	inc si
	jmp _split_mb0_start

	_split_mb0_end:
	mov di, strCmd0

	_split_1_start:			;get first string
	cmp BYTE [si], 0x20
	je _split_1_end
	cmp BYTE [si], 0x00
	je _split_1_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_1_start

	_split_1_end:
	mov BYTE [di], 0x00

	;move blanks
	_split_mb1_start:
	cmp BYTE [si], 0x20
	je _split_mb1_nb
	jmp _split_mb1_end

	_split_mb1_nb:
	inc si
	jmp _split_mb1_start

	_split_mb1_end:
	mov di, strCmd1

	_split_2_start:			;get second string
	cmp BYTE [si], 0x20
	je _split_2_end
	cmp BYTE [si], 0x00
	je _split_2_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_2_start

	_split_2_end:
	mov BYTE [di], 0x00

	;move blanks
	_split_mb2_start:
	cmp BYTE [si], 0x20
	je _split_mb2_nb
	jmp _split_mb2_end

	_split_mb2_nb:
	inc si
	jmp _split_mb2_start

	_split_mb2_end:
	mov di, strCmd2

	_split_3_start:			;get third string
	cmp BYTE [si], 0x20
	je _split_3_end
	cmp BYTE [si], 0x00
	je _split_3_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_3_start

	_split_3_end:
	mov BYTE [di], 0x00

	;move blanks
	_split_mb3_start:
	cmp BYTE [si], 0x20
	je _split_mb3_nb
	jmp _split_mb3_end

	_split_mb3_nb:
	inc si
	jmp _split_mb3_start

	_split_mb3_end:
	mov di, strCmd3

	_split_4_start:			;get fourth string
	cmp BYTE [si], 0x20
	je _split_4_end
	cmp BYTE [si], 0x00
	je _split_4_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_4_start

	_split_4_end:
	mov BYTE [di], 0x00

	;move blanks
	_split_mb4_start:
	cmp BYTE [si], 0x20
	je _split_mb4_nb
	jmp _split_mb4_end

	_split_mb4_nb:
	inc si
	jmp _split_mb4_start

	_split_mb4_end:
	mov di, strCmd4

	_split_5_start:			;get last string
	cmp BYTE [si], 0x20
	je _split_5_end
	cmp BYTE [si], 0x00
	je _split_5_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_5_start

	_split_5_end:
	mov BYTE [di], 0x00

	ret

_display_space:
	mov ah, 0x0E                            ; BIOS teletype
	mov al, 0x20
    mov bh, 0x00                            ; display page 0
    mov bl, 0x07                            ; text attribute
    int 0x10                                ; invoke BIOS
	ret

_display_endl:
	mov ah, 0x0E		; BIOS teletype acts on newline!
    mov al, 0x0D
	mov bh, 0x00
    mov bl, 0x07
    int 0x10
	mov ah, 0x0E		; BIOS teletype acts on linefeed!
    mov al, 0x0A
	mov bh, 0x00
    mov bl, 0x07
    int 0x10
	ret

_display_prompt:
	mov si, strPrompt
	mov al, 0x01
	int 0x21
	ret

;===================Data========================

[SEGMENT .data]
    strWelcomeMsg   db  "Welcome to JOSH Ver 0.01 with added features by Hashini Senaratne", 0x00
	strHelp			db	"Type 'help' to get the list of shell commands",0x00
	strVer			db	"ver    -to display version",0x00
	strHW			db	"hw     -to display hardware information",0x00
	strExit			db	"exit   -to reboot",0x00
	strCommands		db	"Available Commands are...",0x00
	strHardware		db	"Hardware Information...",0x00
	strPrompt		db	"JOSH>>", 0x00
	cmdMaxLen		db	255			;maximum length of commands

	strOsName		db	"JOSH", 0x00	;OS details
	strMajorVer		db	"0", 0x00
	strMinorVer		db	".03", 0x00

	strVendor		db	"CPU vendor                  : ",0x00	;hardware details
	strCpuType		db	"CPU type                    : ",0x00
	strnomouse		db	"Mouse details (PS)          : No mouse detected",0x00
	strismouse		db	"Mouse details (PS)          : Mouse is installed",0x00
	strmem			db	"RAM size                    : ",0x00
	strMB			db	"MB",0x00
	strMemErr		db	"Memory Reading error occured",0x00
	strnokey		db	"Keyboard details            : No keyboard detected",0x00
	strPC			db	"Keyboard details            : 9-bit PC keyboard is in use",0x00
	strAT			db	"Keyboard details            : 11-bit AT keyboard is in use",0x00
	strEng 			db	"(English)",0x00
	strJap 			db	"(Japan)",0x00
	strHardDrive		db	"Installed hard drives       : ",0x00
	strDiskette		db	"Detecked Diskettes          : ",0x00
	strSerial		db	"Detecked Serial Ports       : ",0x00
	strParallel		db	"Detecked Parallel Ports     : ",0x00
	strBios 		db 	"Bios released               : ",0x00

	cmdVer			db	"ver", 0x00		; internal commands
	cmdExit			db	"exit", 0x00
	cmdHelp			db	"help", 0x00
	cmdHW			db	"hw", 0x00

	txtVersion		db	"version", 0x00	;messages and other strings
	msgUnknownCmd		db	"Unknown command or bad file name!", 0x00

[SEGMENT .bss]
	strUserCmd	resb	256		;buffer for user commands
	cmdChrCnt	resb	1		;count of characters
	strCmd0		resb	256		;buffers for the command components
	strCmd1		resb	256
	strCmd2		resb	256
	strCmd3		resb	256
	strCmd4		resb	256
	strBrand	resb	256
	strCPUID	resb	16		;string variable
	strRAM		resb	256

;********************end of the kernel code********************
