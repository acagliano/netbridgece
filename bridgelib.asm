;------------------------------------------
include '../include/library.inc'
include '../include/include_library.inc'
;------------------------------------------

library BRDGLIB, 0


;---------------------------------------------
; dependencies
;---------------------------------------------
include_library '../usbdrvce/usbdrvce.asm'
include_library '../srldrvce/srldrvce.asm'

;---------------------------------------------
; api declarations
;---------------------------------------------

export bsocket_create
export bsocket_connect
export bsocket_close
export bsocket_setoption
export bsocket_send
export bsocket_recv
export bsocket_update
export bsocket_sendpacket

;---------------------------------------------
; callbacks
;---------------------------------------------

_timeout_action:
	call	ti._frameset0
	ld	a, 1
	or	a, a
	sbc	hl, hl
	ld	(_bsock_timeout), a
	pop	ix
	ret

_handle_usb_event:
	ld	hl, -6
	call	ti._frameset
	ld	bc, (ix + 6)
	ld	de, (ix + 9)
	ld	hl, (ix + 12)
	push	hl
	push	de
	push	bc
	call	srl_UsbEventCallback
	push	hl
	pop	bc
	pop	hl
	pop	hl
	pop	hl
	push	bc
	pop	hl
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jp	nz, .lbl_14
	ld	hl, (ix + 6)
	dec	hl
	ld	de, 12
	push	hl
	pop	iy
	or	a, a
	sbc	hl, de
	jp	nc, .lbl_14
	ld	hl, JTI1_0
	lea	de, iy
	add	hl, de
	add	hl, de
	add	hl, de
	ld	hl, (hl)
	jp	(hl)
.lbl_3:
	ld	hl, _bs
	push	hl
	ld	(ix - 3), bc
	call	srl_Close
	ld	bc, (ix - 3)
	pop	hl
	xor	a, a
	jp	.lbl_13
.lbl_4:
	ld	(ix - 3), bc
	ld	hl, 0
	ld	de, 8
	push	de
	push	hl
	push	hl
	call	usb_FindDevice
	pop	de
	pop	de
	pop	de
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jp	nz, .lbl_10
	ld	hl, (_bs+58)
	jp	.lbl_11
.lbl_6:
	ld	(ix - 3), bc
	call	usb_GetRole
	ld	bc, (ix - 3)
	ld	a, (_bs+64)
	bit	4, l
	jr	nz, .lbl_14
	cp	a, 2
	jr	z, .lbl_14
	ld	hl, (ix + 9)
	ld	(_bs+58), hl
	push	hl
	call	usb_ResetDevice
	ld	bc, (ix - 3)
	pop	hl
	jr	.lbl_14
.lbl_9:
	ld	(ix - 3), bc
	ld	hl, (ix + 9)
.lbl_10:
	ld	(_bs+58), hl
.lbl_11:
	ld	iy, 9600
	ld	de, (_bs+73)
	ld	(ix - 6), de
	ld	bc, (_bs+76)
	push	iy
	ld	de, -1
	push	de
	push	bc
	ld	de, (ix - 6)
	push	de
	push	hl
	ld	hl, _bs
	push	hl
	call	srl_Open
	pop	de
	pop	de
	pop	de
	pop	de
	pop	de
	pop	de
	add	hl, bc
	or	a, a
	sbc	hl, bc
	ld	bc, (ix - 3)
	jr	nz, .lbl_14
	ld	a, 2
.lbl_13:
	ld	(_bs+64), a
.lbl_14:
	push	bc
	pop	hl
	ld	sp, ix
	pop	ix
	ret
JTI1_0:
	dl	_handle_usb_event.lbl_3
	dl	_handle_usb_event.lbl_6
	dl	_handle_usb_event.lbl_3
	dl	_handle_usb_event.lbl_9
	dl	_handle_usb_event.lbl_14
	dl	_handle_usb_event.lbl_14
	dl	_handle_usb_event.lbl_9
	dl	_handle_usb_event.lbl_3
	dl	_handle_usb_event.lbl_14
	dl	_handle_usb_event.lbl_14
	dl	_handle_usb_event.lbl_14
	dl	_handle_usb_event.lbl_4


;---------------------------------------------
; library api
;---------------------------------------------

bsocket_create:
	ld	hl, -14
	call	ti._frameset
	call	srl_GetCDCStandardDescriptors
	ld	de, (ix + 6)
	ld	(_bs+73), de
	ld	de, (ix + 9)
	ld	(_bs+76), de
	ld	de, 36106
	push	de
	push	hl
	ld	hl, 0
	push	hl
	ld	hl, _handle_usb_event
	push	hl
	call	usb_Init
	pop	de
	pop	de
	pop	de
	pop	de
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jp	nz, .lbl_9
	ld	bc, _timeout_action
	ld	h, 1
	ld	l, -5
	ld	iy, 5000
	lea	de, ix - 11
	ld	(ix - 4), bc
	ld	a, h
	ld	(_bs+64), a
	ld	a, l
	ld	(_bs+70), a
	ld	l, 0
	ld	a, l
	ld	(_bs+71), a
	ld	a, h
	ld	(_bs+65), a
	ld	(_bs+66), iy
	ld	a, l
	ld	(_bsock_timeout), a
	ld	hl, 14
	push	hl
	ld	hl, 5118976
	push	hl
	ld	(ix - 14), de
	push	de
	call	usb_StartTimerCycles
	pop	hl
	pop	hl
	pop	hl
.lbl_2:
	call	usb_HandleEvents
	ld	a, (_bs+64)
	cp	a, 2
	jr	nz, .lbl_6
	ld	hl, 1
	push	hl
	pea	ix - 1
	ld	hl, _bs
	push	hl
	call	srl_Read
	pop	de
	pop	de
	pop	de
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jr	z, .lbl_5
	ld	a, (_bs+70)
	ld	l, a
	ld	a, (ix - 1)
	cp	a, l
	jr	z, .lbl_10
.lbl_5:
	ld	a, (_bs+64)
.lbl_6:
	cp	a, 3
	jr	z, .lbl_11
	ld	a, (_bsock_timeout)
	ld	l, a
	ld	a, (_bs+65)
	and	a, 1
	bit	0, l
	jr	nz, .lbl_9
	bit	0, a
	jr	nz, .lbl_2
.lbl_9:
	xor	a, a
	jr	.lbl_12
.lbl_10:
	ld	a, 3
	ld	(_bs+64), a
.lbl_11:
	ld	hl, (ix - 14)
	push	hl
	call	usb_StopTimer
	pop	hl
	ld	hl, usb_HandleEvents
	ld	(_bs+61), hl
	xor	a, a
	ld	(_bs+65), a
	sbc	hl, hl
	ld	(_bs+66), hl
	inc	a
	ld	(_bs+69), a
.lbl_12:
	ld	sp, ix
	pop	ix
	ret
 
 
bsocket_connect:
	ld	hl, -9
	call	ti._frameset
	ld	hl, (ix + 6)
	push	hl
	call	ti._strlen
	ld	(ix - 3), hl
	pop	de
	push	hl
	pop	de
	inc	de
	push	hl
	pop	iy
	ld	bc, 4
	add	iy, bc
	lea	bc, iy
	ld	(ix - 6), bc
	ld	hl, 0
	add	hl, sp
	or	a, a
	sbc	hl, bc
	push	hl
	pop	iy
	ld	(ix - 9), iy
	ld	sp, iy
	push	de
	ld	hl, (ix + 6)
	push	hl
	push	iy
	call	ti._memcpy
	pop	hl
	pop	hl
	pop	hl
	ld	bc, (ix - 9)
	push	bc
	pop	iy
	ld	de, (ix - 3)
	add	iy, de
	or	a, a
	sbc	hl, hl
	ld	l, (iy + 1)
	ld	de, (ix + 9)
	ld	(hl), de
	ld	hl, (ix - 6)
	push	hl
	push	bc
	sbc	hl, hl
	push	hl
	call	bsocket_emitdirective
	ld	sp, ix
	pop	ix
	ret
  
bsocket_close:
	ld	hl, _bs
	push	hl
	call	srl_Close
	pop	hl
	call	usb_Cleanup
	xor	a, a
	ld	(_bs), a
	ld	hl, _bs
	push	hl
	pop	de
	inc	de
	ld	bc, 78
	ldir
	ret
 
bsocket_setoption:
	call	ti._frameset0
	ld	bc, (ix + 6)
	xor	a, a
	ld	de, 5
	push	bc
	pop	hl
	sbc	hl, de
	jr	nc, .lbl_14
	ld	hl, (ix + 9)
	ld	a, 1
	ld	iy, JTI6_0
	add	iy, bc
	add	iy, bc
	add	iy, bc
	ld	iy, (iy)
	jp	(iy)
.lbl_2:
	ld	e, a
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jr	nz, .lbl_11
	ld	a, 0
	jr	.lbl_12
.lbl_4:
	ld	e, a
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jr	nz, .lbl_9
	ld	a, 0
	jr	.lbl_10
.lbl_6:
	ld	e, a
	ld	a, l
	ld	(_bs+70), a
	jr	.lbl_13
.lbl_7:
	ld	e, a
	ld	a, l
	ld	(_bs+71), a
	jr	.lbl_13
.lbl_8:
	ld	(_bs+66), hl
	jr	.lbl_14
.lbl_9:
	ld	a, 1
.lbl_10:
	ld	(_bs+69), a
	jr	.lbl_13
.lbl_11:
	ld	a, 1
.lbl_12:
	ld	(_bs+65), a
.lbl_13:
	ld	a, e
.lbl_14:
	pop	ix
	ret
JTI6_0:
	dl	bsocket_setoption.lbl_2
	dl	bsocket_setoption.lbl_8
	dl	bsocket_setoption.lbl_4
	dl	bsocket_setoption.lbl_6
	dl	bsocket_setoption.lbl_7
 
bsocket_send:
	call	ti._frameset0
	ld	bc, _bs
	ld	hl, _bs+71
	ld	de, 1
	push	de
	push	hl
	push	bc
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, (ix + 9)
	push	hl
	ld	hl, (ix + 6)
	push	hl
	ld	hl, _bs
	push	hl
	call	srl_Write
	ld	sp, ix
	pop	ix
	ret

bsocket_recv:
	ld	hl, -13
	call	ti._frameset
	ld	de, _timeout_action
	xor	a, a
	ld	hl, _bs+66
	lea	bc, ix - 10
	ld	(ix - 13), bc
	ld	(ix - 3), de
	ld	(_bsock_timeout), a
	ld	hl, (hl)
	push	hl
	call	usb_MsToCycles
	pop	bc
	push	de
	push	hl
	ld	hl, (ix - 13)
	push	hl
	call	usb_StartTimerCycles
	pop	hl
	pop	hl
	pop	hl
	call	usb_HandleEvents
	ld	hl, (ix + 9)
	push	hl
	ld	hl, (ix + 6)
	push	hl
	ld	hl, _bs
	push	hl
	call	srl_Read
	pop	hl
	pop	hl
	pop	hl
	ld	hl, (ix + 9)
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jr	nz, .lbl_2
.lbl_1:
	ld	hl, (ix - 13)
	push	hl
	call	usb_StopTimer
	pop	hl
	or	a, a
	sbc	hl, hl
	ld	sp, ix
	pop	ix
	ret
.lbl_2:
	ld	a, (_bsock_timeout)
	ld	l, a
	ld	a, (_bs+65)
	and	a, 1
	bit	0, l
	jr	nz, .lbl_1
	bit	0, a
	jr	z, .lbl_1
	call	usb_HandleEvents
	ld	hl, (ix + 9)
	push	hl
	ld	hl, (ix + 6)
	push	hl
	ld	hl, _bs
	push	hl
	call	srl_Read
	pop	hl
	pop	hl
	pop	hl
	jr	.lbl_2
 
bsocket_emitdirective:
	ld	hl, -21
	call	ti._frameset
	ld	de, (ix + 12)
	ld	iy, _bs
	ld	bc, 2
	lea	hl, ix - 13
	ld	(ix - 18), hl
	lea	hl, ix - 15
	ld	(ix - 3), de
	ld	a, (_bs+70)
	ld	(ix - 15), a
	ld	a, (ix + 6)
	ld	(ix - 14), a
	push	bc
	ld	(ix - 21), hl
	push	hl
	push	iy
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, 3
	push	hl
	pea	ix - 3
	ld	hl, _bs
	push	hl
	call	srl_Write
	ld	de, (ix + 9)
	pop	hl
	pop	hl
	pop	hl
	push	de
	pop	hl
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jr	z, .lbl_2
	ld	hl, (ix - 3)
	add	hl, bc
	or	a, a
	sbc	hl, bc
	push	hl
	push	de
	ld	hl, _bs
	push	hl
	call	nz, srl_Write
	pop	hl
	pop	hl
	pop	hl
.lbl_2:
	ld	hl, _timeout_action
	ld	(ix - 6), hl
	xor	a, a
	ld	(_bsock_timeout), a
	ld	hl, _bs+66
	ld	hl, (hl)
	push	hl
	call	usb_MsToCycles
	pop	bc
	push	de
	push	hl
	ld	hl, (ix - 18)
	push	hl
	call	usb_StartTimerCycles
	pop	hl
	pop	hl
	pop	hl
.lbl_3:
	call	usb_HandleEvents
	ld	hl, 2
	push	hl
	ld	hl, (ix - 21)
	push	hl
	ld	hl, _bs
	push	hl
	call	srl_Read
	pop	hl
	pop	hl
	pop	hl
	ld	a, (_bsock_timeout)
	ld	l, a
	ld	a, (_bs+65)
	and	a, 1
	bit	0, l
	jr	nz, .lbl_5
	bit	0, a
	jr	nz, .lbl_3
.lbl_5:
	ld	hl, (ix - 18)
	push	hl
	call	usb_StopTimer
	pop	hl
	ld	l, (ix - 15)
	ld	a, (_bs+70)
	ld	e, a
	ld	a, l
	cp	a, e
	ld	e, -1
	ld	c, 0
	ld	l, e
	jr	z, .lbl_7
	ld	l, c
.lbl_7:
	ld	a, (ix - 14)
	or	a, a
	jr	nz, .lbl_9
	ld	e, c
.lbl_9:
	ld	a, l
	and	a, e
	ld	sp, ix
	pop	ix
	ret
  
bsocket_sendpacket:
	ld	hl, -15
	call	ti._frameset
	ld	hl, (ix + 6)
	ld	de, 0
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jp	z, .lbl_13
	ld	bc, _bs
	ld	iy, 1
	lea	hl, ix + 9
	ld	(ix - 12), hl
	ld	(ix - 3), hl
	ld	(ix - 6), de
	push	iy
	ld	hl, _bs+71
	push	hl
	push	bc
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	a, (_bs+69)
	bit	0, a
	jr	nz, .lbl_4
	ld	de, 1
	ld	bc, (ix + 6)
	push	bc
	pop	hl
	or	a, a
	sbc	hl, de
	call	pe, ti._setflag
	jp	p, .lbl_11
	ld	bc, 0
	jp	.lbl_11
.lbl_4:
	ld	iy, (ix - 3)
	ld	de, 1
	ld	bc, (ix + 6)
	push	bc
	pop	hl
	or	a, a
	sbc	hl, de
	call	pe, ti._setflag
	jp	p, .lbl_6
	ld	bc, 0
.lbl_6:
	lea	iy, iy + 6
	push	bc
	pop	hl
	ld	de, 0
	ld	(ix - 9), bc
.lbl_7:
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jr	z, .lbl_9
	lea	bc, iy
	ld	(ix - 3), bc
	ld	bc, (iy - 3)
	ld	(ix - 15), iy
	push	de
	pop	iy
	add	iy, bc
	lea	de, iy
	ld	iy, (ix - 15)
	lea	iy, iy + 6
	dec	hl
	ld	bc, (ix - 9)
	jr	.lbl_7
.lbl_9:
	ld	(ix - 6), de
	ld	hl, 3
	push	hl
	pea	ix - 6
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, (ix - 12)
	ld	(ix - 3), hl
	or	a, a
	sbc	hl, hl
	ld	(ix - 6), hl
	ld	bc, (ix - 9)
	jr	.lbl_11
.lbl_10:
	ld	iy, (ix - 3)
	lea	hl, iy + 3
	ld	(ix - 3), hl
	ld	hl, (iy)
	lea	de, iy + 6
	ld	(ix - 3), de
	ld	de, (iy + 3)
	push	de
	push	hl
	ld	hl, _bs
	push	hl
	ld	(ix - 9), bc
	call	srl_Write
	ld	bc, (ix - 9)
	push	hl
	pop	de
	pop	hl
	pop	hl
	pop	hl
	ld	hl, (ix - 6)
	add	hl, de
	ld	(ix - 6), hl
	dec	bc
.lbl_11:
	push	bc
	pop	hl
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jr	nz, .lbl_10
	ld	de, (ix - 6)
.lbl_13:
	ex	de, hl
	ld	sp, ix
	pop	ix
	ret
 
bsocket_update:
	ld	hl, (_bs+61)
	jp	(hl)
  

_bsock_timeout:   rb	1
_bs:             	rb	79
