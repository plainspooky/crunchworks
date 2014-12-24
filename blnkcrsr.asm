;   
;   BLNKCRSR version 0
;   
;   A blinking cursor hooked in video's interruption
;   
;   Copyright 2014 Giovanni dos Reis Nunes <giovanni.nunes@gmail.com>
;
;   This program is free software; you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation; either version 2 of the License, or
;   (at your option) any later version.
;   
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;   
;   You should have received a copy of the GNU General Public License
;   along with this program; if not, write to the Free Software
;   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
;   MA 02110-1301, USA.
;   

;
;   This is a experimental code and of course that has a lot of bugs!
;   That's an idea that born in my mind during my lunch hour;
;

INCLUDE     ./library/msx1bios.asm
INCLUDE     ./library/msx1variables.asm

HTIMI:      equ 0xFD9F

PAL:        equ  5                      ; 1/10s em 50Hz
NTSC:       equ  6                      ; 1/10s em 60Hz
            
            org 0xdd00-7                ; just a suggestion
            
BINHEAD:    db 0xfe
            dw BINSTART
            dw BINSTOP+6144+768
            dw BINEXEC
            
BINSTART:
BINEXEC:    ld hl,ENABLINK              ; use USR8(0) to
            ld (USRTAB8),hl             ; enable blink
            
            ld hl,DISBLINK              ; use USR9(0) to
            ld (USRTAB9),hl             ; disable blink
            
            ret
            
DISBLINK:   ld a,0xc9                   ; 'RET'
            ld (HTIMI),a
            call CHGCLR                 ; restore original colors
            
            ret
            
ENABLINK:   ld a,(0x002b)               ; read MSX version
            bit 7,a                     ; '1' = 50Hz, '0' = 60Hz
            jr z, ENABLINK0             ; if is a NTSC/PAL-M model I jump 
            
            ld a,PAL                    ; delay value adjusted for PAL
            ld (BLNKSYNC+1),a
            
ENABLINK0:  ld de,BLNKCSR               ; the hooked routine 
            
            ld a,e                      ; 'ss' of BLNKCSR
            ld (HTIMI+1),a
            ld a,d                      ; 'tt' of BLNKCSR
            ld (HTIMI+2),a
            ld a,0xc9                   ; 'RET'
            ld (HTIMI+3),a
            
            ld a,0xcd                   ; 'CALL'
            ld (HTIMI),a
            
            ret
            
BLNKCSR:    ld a,(BLNKTIME)             ; counter value

BLNKSYNC:   cp NTSC                     ; is 6? (or is 6 in PAL?)
            jr z,BLNSCR0                ; if is equal, go to BLNSCR0
            
            inc a                       ; else, just increment A
            ld (BLNKTIME),a             ; update counter
            
            ret                         ; see you in next video interruption!
            
BLNSCR0:    ld a,(SCRMOD)               ; the actual video mode
            cp 1                        ; is SCREEN 1?
            ret nz                      ; see you in next video interruption!
            
            ld a,(BLNKCOLR)             ; get actual blink color
            ld b,0
            ld c,a                      ; and but it in C
            
            ld hl,RAINBOW               ; my "blink table"
            add hl,bc                   ; just HL+BC
            
            inc a                       ; point to the next color
            and 15                      ; 0000|XXXX
            ld (BLNKCOLR),a             ; and store for next use
            
            ld a,(FORCLR)               ; get foreground color
            add a,(hl)                  ; and add with blink color
            
            ld hl,8192+31               ; the VRAM address
            
            call WRTVRM                 ; write in VRAM

            xor a                       ; A=0
            ld (BLNKTIME),a             ; reset my counter

            ret

;
; TRS-80 Color's blinking sequence
;
RAINBOW:        db 0x10, 0x20, 0x10, 0xa0, 0x10, 0x40, 0x10, 0x60
            db 0x10, 0xf0, 0x10, 0x70, 0x10, 0xd0, 0x10, 0x90 

BLNKTIME:   db 0

BLNKCOLR:   db 0

BLNKSAVE:   db 0

BINSTOP:

;    MSX Rulez a Lot!
