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
export bsocket_starttls
export bsocket_emitdirective

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
 
 _bsocket_pollrs:
	ld	hl, -21
	call	ti._frameset
	ld	hl, _timeout_action
	xor	a, a
	ld	iy, _bs+63
	ld	de, 0
	ld	(ix - 15), de
	lea	de, ix - 2
	ld	(ix - 21), de
	lea	de, ix - 12
	ld	(ix - 18), de
	ld	(ix - 5), hl
	ld	(_bsock_timeout), a
	ld	hl, (iy)
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
.lbl_1:
	call	usb_HandleEvents
	ld	iy, (ix - 21)
	ld	de, (ix - 15)
	add	iy, de
	ld	hl, 2
	or	a, a
	sbc	hl, de
	push	hl
	push	iy
	ld	hl, _bs
	push	hl
	call	srl_Read
	push	hl
	pop	iy
	pop	hl
	pop	hl
	pop	hl
	ld	de, (ix - 15)
	add	iy, de
	lea	hl, iy
	ld	de, 2
	or	a, a
	sbc	hl, de
	jr	z, .lbl_4
	ld	a, (_bsock_timeout)
	ld	l, a
	ld	a, (_bs+62)
	and	a, 1
	bit	0, l
	jr	nz, .lbl_4
	bit	0, a
	ld	(ix - 15), iy
	jr	nz, .lbl_1
.lbl_4:
	ld	hl, (ix - 18)
	push	hl
	call	usb_StopTimer
	pop	hl
	ld	l, (ix - 2)
	ld	a, (_bs+66)
	ld	e, a
	ld	a, l
	cp	a, e
	ld	e, -1
	ld	c, 0
	ld	l, e
	jr	z, .lbl_6
	ld	l, c
.lbl_6:
	ld	a, (ix - 1)
	or	a, a
	jr	nz, .lbl_8
	ld	e, c
.lbl_8:
	ld	a, l
	and	a, e
	ld	sp, ix
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
	jr	nz, .lbl_2
	ld	hl, (ix + 6)
	dec	hl
	ld	de, 12
	push	hl
	pop	iy
	or	a, a
	sbc	hl, de
	jr	c, .lbl_3
.lbl_2:
	push	bc
	pop	hl
	ld	sp, ix
	pop	ix
	ret
.lbl_3:
	ld	hl, JTI1_0
	lea	de, iy
	add	hl, de
	add	hl, de
	add	hl, de
	ld	hl, (hl)
	jp	(hl)
.lbl_4:
	ld	hl, _bs
	push	hl
	ld	(ix - 3), bc
	call	srl_Close
	ld	bc, (ix - 3)
	pop	hl
	xor	a, a
	ld	(_bs+61), a
	inc	a
	ld	(_bsock_timeout), a
	jr	.lbl_2
.lbl_5:
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
	jp	nz, .lbl_11
	ld	hl, (_bs+58)
	jp	.lbl_12
.lbl_7:
	ld	(ix - 3), bc
	call	usb_GetRole
	ld	bc, (ix - 3)
	ld	a, (_bs+61)
	bit	4, l
	jp	nz, .lbl_2
	cp	a, 2
	jp	z, .lbl_2
	ld	hl, (ix + 9)
	ld	(_bs+58), hl
	push	hl
	call	usb_ResetDevice
	ld	bc, (ix - 3)
	pop	hl
	jp	.lbl_2
.lbl_10:
	ld	(ix - 3), bc
	ld	hl, (ix + 9)
.lbl_11:
	ld	(_bs+58), hl
.lbl_12:
	ld	iy, 9600
	ld	de, (_bs+69)
	ld	(ix - 6), de
	ld	bc, (_bs+72)
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
	jp	nz, .lbl_2
	ld	a, 2
	ld	(_bs+61), a
	jp	.lbl_2
JTI1_0:
	dl	_handle_usb_event.lbl_4
	dl	_handle_usb_event.lbl_7
	dl	_handle_usb_event.lbl_4
	dl	_handle_usb_event.lbl_10
	dl	_handle_usb_event.lbl_2
	dl	_handle_usb_event.lbl_2
	dl	_handle_usb_event.lbl_10
	dl	_handle_usb_event.lbl_4
	dl	_handle_usb_event.lbl_2
	dl	_handle_usb_event.lbl_2
	dl	_handle_usb_event.lbl_2
	dl	_handle_usb_event.lbl_5


;---------------------------------------------
; library api
;---------------------------------------------

bsocket_create:
	ld	hl, -14
	call	ti._frameset
	call	srl_GetCDCStandardDescriptors
	push	hl
	pop	de
	ld	hl, (ix + 6)
	push	hl
	pop	iy
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jp	z, .lbl_10
	ld	hl, (ix + 9)
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jp	z, .lbl_10
	ld	bc, 36106
	ld	(_bs+69), iy
	ld	(_bs+72), hl
	push	bc
	push	de
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
	jp	nz, .lbl_10
	ld	bc, _timeout_action
	ld	h, 1
	ld	l, -5
	ld	iy, 5000
	lea	de, ix - 11
	ld	(ix - 4), bc
	ld	a, h
	ld	(_bs+61), a
	ld	a, l
	ld	(_bs+66), a
	ld	l, 0
	ld	a, l
	ld	(_bs+67), a
	ld	a, h
	ld	(_bs+62), a
	ld	(_bs+63), iy
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
.lbl_4:
	call	usb_HandleEvents
	ld	a, (_bs+61)
	cp	a, 2
	jr	nz, .lbl_7
	ld	hl, 1
	push	hl
	pea	ix - 1
	ld	hl, _bs
	push	hl
	call	srl_Read
	pop	de
	pop	de
	pop	de
	ld	de, 1
	or	a, a
	sbc	hl, de
	jr	z, .lbl_12
	ld	a, (_bs+61)
.lbl_7:
	cp	a, 3
	jr	z, .lbl_13
	ld	a, (_bsock_timeout)
	ld	l, a
	ld	a, (_bs+62)
	and	a, 1
	bit	0, l
	jr	nz, .lbl_10
	bit	0, a
	jr	nz, .lbl_4
.lbl_10:
	xor	a, a
.lbl_11:
	ld	sp, ix
	pop	ix
	ret
.lbl_12:
	ld	a, 3
	ld	(_bs+61), a
.lbl_13:
	ld	hl, (ix - 14)
	push	hl
	call	usb_StopTimer
	pop	hl
	xor	a, a
	ld	(_bs+62), a
	sbc	hl, hl
	ld	(_bs+63), hl
	inc	a
	jr	.lbl_11
 
 
bsocket_connect:
	ld	hl, -6
	call	ti._frameset
	ld	iy, (ix + 6)
	ld	bc, (ix + 9)
	ld	e, 0
	ld	(ix - 2), c
	ld	(ix - 1), b
	lea	hl, iy
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jp	z, .lbl_4
	ld	l, c
	ld	h, b
	add.sis	hl, bc
	or	a, a
	sbc.sis	hl, bc
	jp	z, .lbl_4
	ld	(ix - 3), 0
	push	iy
	call	ti._strlen
	pop	de
	ld	(ix - 6), hl
	ld	hl, 1
	push	hl
	ld	hl, _bs+66
	push	hl
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, 1
	push	hl
	pea	ix - 3
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, 3
	push	hl
	pea	ix - 6
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, (ix - 6)
	push	hl
	ld	hl, (ix + 6)
	push	hl
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, 2
	push	hl
	pea	ix - 2
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	call	_bsocket_pollrs
	ld	e, a
	bit	0, e
	jr	z, .lbl_4
	ld	a, 4
	ld	(_bs+61), a
.lbl_4:
	ld	a, e
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
	ld	bc, 74
	ldir
	ret
 
bsocket_setoption:
	call	ti._frameset0
	ld	bc, (ix + 6)
	xor	a, a
	ld	de, 4
	push	bc
	pop	hl
	sbc	hl, de
	jr	nc, .lbl_10
	ld	hl, (ix + 9)
	ld	a, 1
	ld	iy, JTI5_0
	add	iy, bc
	add	iy, bc
	add	iy, bc
	ld	iy, (iy)
	jp	(iy)
.lbl_2:
	add	hl, bc
	or	a, a
	sbc	hl, bc
	jr	nz, .lbl_8
	ld	l, a
	ld	a, 0
	jr	.lbl_9
.lbl_4:
	ld	e, a
	ld	a, l
	ld	(_bs+66), a
	jr	.lbl_6
.lbl_5:
	ld	e, a
	ld	a, l
	ld	(_bs+67), a
.lbl_6:
	ld	a, e
	jr	.lbl_10
.lbl_7:
	ld	(_bs+63), hl
	jr	.lbl_10
.lbl_8:
	ld	l, a
	ld	a, 1
.lbl_9:
	ld	(_bs+62), a
	ld	a, l
.lbl_10:
	pop	ix
	ret
JTI5_0:
	dl	bsocket_setoption.lbl_2
	dl	bsocket_setoption.lbl_7
	dl	bsocket_setoption.lbl_4
	dl	bsocket_setoption.lbl_5
 
bsocket_send:
	ld	hl, -3
	call	ti._frameset
	ld	de, (ix + 9)
	or	a, a
	sbc	hl, hl
	ld	(ix - 3), de
	ld	a, (_bs+61)
	cp	a, 4
	jr	nz, .lbl_2
	ld	bc, _bs
	ld	hl, _bs+67
	ld	de, 1
	push	de
	push	hl
	push	bc
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
	pop	hl
	pop	hl
	pop	hl
	ld	hl, (ix - 3)
	push	hl
	ld	hl, (ix + 6)
	push	hl
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	de
	pop	de
	pop	de
.lbl_2:
	ld	sp, ix
	pop	ix
	ret
	
bsocket_recv:
	ld	hl, -16
	call	ti._frameset
	ld	l, 0
	ld	de, 0
	ld	a, (_bs+61)
	cp	a, 4
	jp	nz, .lbl_7
	ld	(ix - 13), de
	ld	de, _timeout_action
	ld	iy, _bs+63
	lea	bc, ix - 10
	ld	(ix - 16), bc
	ld	(ix - 3), de
	ld	a, l
	ld	(_bsock_timeout), a
	ld	hl, (iy)
	push	hl
	call	usb_MsToCycles
	pop	bc
	push	de
	push	hl
	ld	hl, (ix - 16)
	push	hl
	call	usb_StartTimerCycles
	pop	hl
	pop	hl
	pop	hl
.lbl_2:
	call	usb_HandleEvents
	ld	iy, (ix + 6)
	ld	de, (ix - 13)
	add	iy, de
	ld	hl, (ix + 9)
	or	a, a
	sbc	hl, de
	push	hl
	push	iy
	ld	hl, _bs
	push	hl
	call	srl_Read
	push	hl
	pop	iy
	pop	hl
	pop	hl
	pop	hl
	ld	de, (ix - 13)
	add	iy, de
	lea	hl, iy
	ld	de, (ix + 9)
	or	a, a
	sbc	hl, de
	ex	de, hl
	jr	z, .lbl_5
	ld	a, (_bsock_timeout)
	ld	l, a
	ld	a, (_bs+62)
	and	a, 1
	bit	0, l
	jr	nz, .lbl_6
	bit	0, a
	ld	(ix - 13), iy
	jr	nz, .lbl_2
	jr	.lbl_6
.lbl_5:
	push	hl
	pop	iy
.lbl_6:
	ld	(ix - 13), iy
	ld	hl, (ix - 16)
	push	hl
	call	usb_StopTimer
	ld	de, (ix - 13)
	pop	hl
.lbl_7:
	ex	de, hl
	ld	sp, ix
	pop	ix
	ret
 
bsocket_update:
	jp	usb_HandleEvents
 
bsocket_starttls:
	ld	hl, -1
	call	ti._frameset
	ld	de, _bs
	ld	hl, _bs+66
	ld	bc, 1
	ld	(ix - 1), c
	push	bc
	push	hl
	push	de
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, 1
	push	hl
	pea	ix - 1
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	call	_bsocket_pollrs
	inc	sp
	pop	ix
	ret
 
bsocket_emitdirective:
	ld	hl, -5
	call	ti._frameset
	ld	a, (ix + 6)
	ld	c, (ix + 9)
	ld	de, (ix + 12)
	ld	l, 0
	ld	(ix - 1), a
	ld	(ix - 2), c
	ld	(ix - 5), de
	cp	a, 2
	jr	c, .lbl_4
	ld	de, _bs
	ld	hl, _bs+66
	ld	bc, 1
	push	bc
	push	hl
	push	de
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, 1
	push	hl
	pea	ix - 1
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	hl, 3
	push	hl
	pea	ix - 5
	ld	hl, _bs
	push	hl
	call	srl_Write
	pop	hl
	pop	hl
	pop	hl
	ld	a, (ix + 9)
	or	a, a
	jr	z, .lbl_3
	ld	hl, (ix - 5)
	add	hl, bc
	or	a, a
	sbc	hl, bc
	push	hl
	pea	ix - 2
	ld	hl, _bs
	push	hl
	call	nz, srl_Write
	pop	hl
	pop	hl
	pop	hl
.lbl_3:
	call	_bsocket_pollrs
	ld	l, a
.lbl_4:
	ld	a, l
	ld	sp, ix
	pop	ix
	ret
  

_bsock_timeout:   rb	1
_bs:             	rb	75
