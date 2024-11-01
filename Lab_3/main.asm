.model small
.stack 100h
.data
	prad_pran db 'Autorius: Pijus Zlatkus. Programa iskviecia zingsninio rezimo pertraukimo INT 1 apdorojimo procedura, atpazistancia komanda SUB reg~r/m.', 13, 10, '$'
	pran_zingsn db 'Zingsninio rezimo pertraukimas! $'
	enteris db 13, 10, '$'
	
	pran_sub db 'SUB $', 13, '$'
	pran_ds db 'ds:$', 13, '$'
	
	registrai db 'axcxdxbxalcldlblahchdhbhspbpsidi$'
	poslinkiai db 'bx+sibx+dibp+sibp+disi   di   bp   bx   $'
	
	baitas_1 db ?
	baitas_2 db ?
	baitas_3 db ?
	baitas_4 db ?
	
	bitas_d db ?
	bitas_w db ?
	bitai_mod db ?
	bitai_reg db ?
	bitai_rm db ?
	
	regAX dw ?
	regBX dw ?
	regCX dw ?
	regDX dw ?
	regSP dw ?
	regBP dw ?
	regSI dw ?
	regDI dw ?
	regES dw ?
	regDS dw ?
.code
    Pradzia:
	MOV	ax, @data
	MOV	ds, ax
	
	MOV ah, 9
	MOV dx, offset prad_pran
	INT 21h

	MOV	ax, 0
	MOV	es, ax
	
	PUSH es:[4]
	PUSH es:[6]
	
	MOV	word ptr es:[4], offset pertraukimas
	MOV	es:[6], cs

	PUSHF
	PUSHF
	POP ax
	OR ax, 0100h
	PUSH ax
	POPF
	
	NOP	
	SUB bx, 1h
	INC ax
	SUB dl, ah
	SUB bx, dx
	mov bx, 10h
	mov si, 100h
	SUB [bx+si+2], bx
	SUB al, 22h
	INC bx
	
	POPF
	POP	es:[6]
	POP	es:[4]

	MOV	ah, 4Ch
	MOV	al, 0
	INT	21h

PROC pertraukimas
	MOV regAX, ax				
	MOV regBX, bx
	MOV regCX, cx
	MOV regDX, dx
	MOV regSP, sp
	MOV regBP, bp
	MOV regSI, si
	MOV regDI, di
	MOV regES, es
	MOV regDS, ds
	
	MOV	ax, @data
	MOV	ds, ax
	
	POP si
	POP di
	PUSH di
	PUSH si
	
	MOV ax, cs:[si]		;Išimame pirmąjį baitą, esantį grįžimo adresu
	MOV bx, cs:[si+2]
	
	MOV baitas_1, al
	MOV baitas_2, ah
	MOV baitas_3, bl
	MOV baitas_4, bh
	
	AND al, 0FCh
	CMP al, 28h
	JNE baigti_pertraukima1
	
	MOV al, baitas_1
	AND al, 2h
	MOV bitas_d, al
	
	MOV al, baitas_1
	AND al, 1h
	MOV bitas_w, al
	
	MOV al, baitas_2
	AND al, 0C0h
	MOV bitai_mod, al
	
	MOV al, baitas_2
	AND al, 38h
	MOV bitai_reg, al
	
	MOV al, baitas_2
	AND al, 7h
	MOV bitai_rm, al
	
	;Spausdinam pranesima apie zingsnini pertraukima
	MOV ah, 9
	MOV dx, offset enteris
	INT 21h
	
	MOV ah, 9
	MOV dx, offset pran_zingsn
	INT 21h
	
	;Spausdinam adresa
	MOV ax, di
	CALL spausdinti_zodi
	
	MOV ah, 2
	MOV dl, ':'
	INT 21h
	
	MOV ax, si
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	
	JMP ignoruoti
	baigti_pertraukima1:
	JMP baigti_pertraukima
	ignoruoti:
	
	;sesioliktainis masininis kodas
	MOV ah, baitas_1
	MOV al, baitas_2
	CALL spausdinti_zodi
	
	CMP bitai_mod, 0
	JE ar_poslinkis
	
	CMP bitai_mod, 40h
	JE poslinkis_baitas
	
	CMP bitai_mod, 80h
	JE poslinkis_zodis
	JMP praleisti_poslinki
	
	ar_poslinkis:
	CMP bitai_rm, 6
	JE poslinkis_zodis
	JMP praleisti_poslinki
	
	poslinkis_baitas:
	MOV al, baitas_3
	CALL spausdinti_tarpa
	CALL spausdinti_baita
	JMP praleisti_poslinki
	
	poslinkis_zodis:
	MOV al, baitas_3
	MOV ah, baitas_4
	CALL spausdinti_tarpa
	CALL spausdinti_zodi
	
	praleisti_poslinki:
	CALL spausdinti_tarpa
	
	;Spausdinam komandos asemblerini uzrasa
	MOV ah, 9
	MOV dx, offset pran_sub
	INT 21h
	
	CMP bitas_d, 2h
	JNE ne_i_reg
	
	CMP bitas_w, 1h
	JNE ne_zodis1
	
	MOV cx, 0
	CALL spausdinti_registra_vyr
	MOV ah, 2
	MOV dl, ','
	INT 21h
	CALL spausdinti_tarpa
	
	MOV cx, 0
	CALL tikrinti_mod
	
	MOV ah, 9
	MOV dx, offset enteris
	INT 21h
	
	CALL spausdinti_operandu_reiksmes
	MOV ah, 9
	MOV dx, offset enteris
	INT 21h
	
	JMP baigti_pertraukima
	
	ne_zodis1:
	MOV cx, 0
	CALL spausdinti_registra_jaun
	MOV ah, 2
	MOV dl, ','
	INT 21h
	CALL spausdinti_tarpa
	
	MOV cx, 0
	CALL tikrinti_mod
	
	MOV ah, 9
	MOV dx, offset enteris
	INT 21h
	
	CALL spausdinti_operandu_reiksmes
	MOV ah, 9
	MOV dx, offset enteris
	INT 21h
	
	JMP baigti_pertraukima
	
	
	;------------------------------------------
	ne_i_reg:
	CMP bitas_w, 1h
	JNE ne_zodis2
	
	MOV cx, 0
	CALL tikrinti_mod
	MOV ah, 2
	MOV dl, ','
	INT 21h
	CALL spausdinti_tarpa
	
	MOV cx, 0
	CALL spausdinti_registra_vyr
	
	MOV ah, 9
	MOV dx, offset enteris
	INT 21h
	
	CALL spausdinti_operandu_reiksmes
	MOV ah, 9
	MOV dx, offset enteris
	INT 21h
	
	JMP baigti_pertraukima
	
	ne_zodis2:
	MOV cx, 0
	CALL tikrinti_mod
	MOV ah, 2
	MOV dl, ','
	INT 21h
	CALL spausdinti_tarpa
	
	MOV cx, 0
	CALL spausdinti_registra_jaun
	
	MOV ah, 9
	MOV dx, offset enteris
	INT 21h
	
	CALL spausdinti_operandu_reiksmes
	MOV ah, 9
	MOV dx, offset enteris
	INT 21h
	
baigti_pertraukima:
	MOV ax, regAX	
	MOV bx, regBX
	MOV cx, regCX
	MOV dx, regDX
	MOV sp, regSP
	MOV bp, regBP
	MOV si, regSI
	MOV di, regDI
	MOV es, regES
	MOV ds, regDS
IRET

spausdinti_operandu_reiksmes:
	CMP bitas_d, 2h
	JNE ne_reg
	CMP bitas_w, 1
	JNE ne_w_1
	
	MOV cx, 0
	CALL spausdinti_registra_vyr
	MOV ah, 2
	MOV dl, '='
	INT 21h
	
	CALL spausdinti_registro_vyr_reiksme
	CALL spausdinti_tarpa
	MOV ah, 2
	MOV dl, ';'
	INT 21h
	CALL spausdinti_tarpa
	CALL spausdinti_mod_su_reiksme
	RET
	
	ne_w_1:
	MOV cx, 0
	CALL spausdinti_registra_jaun
	MOV ah, 2
	MOV dl, '='
	INT 21h
	
	CALL spausdinti_registro_jaun_reiksme
	CALL spausdinti_tarpa
	MOV ah, 2
	MOV dl, ';'
	INT 21h
	CALL spausdinti_tarpa
	CALL spausdinti_mod_su_reiksme
	RET

	;---------------------------------
	ne_reg:
	CMP bitas_w, 1
	JNE ne_w_2
	
	CALL spausdinti_mod_su_reiksme
	MOV ah, 2
	MOV dl, ';'
	INT 21h
	CALL spausdinti_tarpa
	
	MOV cx, 0
	CALL spausdinti_registra_vyr
	MOV ah, 2
	MOV dl, '='
	INT 21h
	CALL spausdinti_registro_vyr_reiksme
	RET
	
	ne_w_2:
	
	CALL spausdinti_mod_su_reiksme
	MOV ah, 2
	MOV dl, ';'
	INT 21h
	CALL spausdinti_tarpa
	
	MOV cx, 0
	CALL spausdinti_registra_jaun
	MOV ah, 2
	MOV dl, '='
	INT 21h
	CALL spausdinti_registro_jaun_reiksme
	RET

spausdinti_registro_vyr_reiksme:
	CMP cx, 1
	JE jei_reg_ax
	CMP cx, 2
	JE jei_reg_cx
	CMP cx, 3
	JE jei_reg_dx
	CMP cx, 4
	JE jei_reg_bx
	CMP cx, 5
	JE jei_reg_sp
	CMP cx, 6
	JE jei_reg_bp
	CMP cx, 7
	JE jei_reg_si
	CMP cx, 8
	JE jei_reg_di
	
	jei_reg_ax:
	MOV ax, regAX
	CALL spausdinti_zodi
	RET
	
	jei_reg_cx:
	MOV ax, regCX
	CALL spausdinti_zodi
	RET
	
	jei_reg_dx:
	MOV ax, regDX
	CALL spausdinti_zodi
	RET
	
	jei_reg_bx:
	MOV ax, regBX
	CALL spausdinti_zodi
	RET
	
	jei_reg_sp:
	MOV ax, regSP
	CALL spausdinti_zodi
	RET
	
	jei_reg_bp:
	MOV ax, regBP
	CALL spausdinti_zodi
	RET
	
	jei_reg_si:
	MOV ax, regSI
	CALL spausdinti_zodi
	RET
	
	jei_reg_di:
	MOV ax, regDI
	CALL spausdinti_zodi
	RET
	
RET

spausdinti_registro_jaun_reiksme:
	CMP cx, 1
	JE jei_reg_al
	CMP cx, 2
	JE jei_reg_cl
	CMP cx, 3
	JE jei_reg_dl
	CMP cx, 4
	JE jei_reg_bl
	CMP cx, 5
	JE jei_reg_ah
	CMP cx, 6
	JE jei_reg_ch
	CMP cx, 7
	JE jei_reg_dh
	CMP cx, 8
	JE jei_reg_bh
	
	jei_reg_al:
	MOV ax, regAX
	CALL spausdinti_baita
	RET
	
	jei_reg_cl:
	MOV ax, regCX
	CALL spausdinti_baita
	RET
	
	jei_reg_dl:
	MOV ax, regDX
	CALL spausdinti_baita
	RET
	
	jei_reg_bl:
	MOV ax, regBX
	CALL spausdinti_baita
	RET
	
	jei_reg_ah:
	MOV ax, regAX
	SHR ax, 8
	CALL spausdinti_baita
	RET
	
	jei_reg_ch:
	MOV ax, regCX
	SHR ax, 8
	CALL spausdinti_baita
	RET
	
	jei_reg_dh:
	MOV ax, regDX
	SHR ax, 8
	CALL spausdinti_baita
	RET
	
	jei_reg_bh:
	MOV ax, regBX
	SHR ax, 8
	CALL spausdinti_baita
	RET

spausdinti_mod_su_reiksme:
	CMP bitai_mod, 0C0h
	JE jei_mod_11
	CMP bitai_mod, 80h
	JE jei_mod_10
	CMP bitai_mod, 40h
	JE jei_mod_01
	CMP bitai_mod, 0
	JE jei_mod_00
	
	jei_mod_11:
	MOV cx, 1
	CMP bitas_w, 1
	JNE jei_ne_w_1
	CALL spausdinti_registra_vyr
	MOV ah, 2
	MOV dl, '='
	INT 21h
	CALL spausdinti_registro_vyr_reiksme
	RET
	
	jei_ne_w_1:
	CALL spausdinti_registra_jaun
	MOV ah, 2
	MOV dl, '='
	INT 21h
	CALL spausdinti_registro_jaun_reiksme
	RET
	
	jei_mod_10:
	MOV bx, cx
	CALL spausdinti_adresa
	CALL spausdinti_tarpa
	RET
	
	jei_mod_01:
	MOV bx, cx
	CALL spausdinti_adresa
	CALL spausdinti_tarpa
	RET
	
	jei_mod_00:
	CMP bitai_rm, 6h
	JNE jei_ne_110
	
	MOV ah, 9
	MOV dx, offset pran_ds
	INT 21h
	MOV ah, 2
	MOV dl, '['
	INT 21h
	MOV al, baitas_3
	MOV ah, baitas_4
	CALL spausdinti_zodi
	MOV ah, 2
	MOV dl, ']'
	INT 21h
	MOV ah, 2
	MOV dl, '='
	INT 21h
	
	MOV bl, baitas_3
	MOV bh, baitas_4
	MOV ax, ds:[bx]
	CMP bitas_w, 1
	JNE jei_ne_w_2
	CALL spausdinti_zodi
	RET
	jei_ne_w_2:
	CALL spausdinti_baita
	RET
	
	jei_ne_110:
	MOV bx, cx
	CALL spausdinti_adresa
	CALL spausdinti_tarpa
	RET
	
RET

spausdinti_adresa:
	CMP bitai_rm, 0
	JE sum_000
	CMP bitai_rm, 1
	JE sum_001
	CMP bitai_rm, 2
	JE sm_010
	CMP bitai_rm, 3
	JE sm_011
	CMP bitai_rm, 4
	JE sm_100
	CMP bitai_rm, 5
	JE sm_101
	CMP bitai_rm, 6
	JE sm_110
	CMP bitai_rm, 7
	JE sm_111

	sum_000:
	MOV ax, regBX
	MOV cx, ax
	MOV ax, regSI
	ADD cx, ax
	
	MOV bx, 35
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regBX
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	
	MOV bx, 20
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regSI
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	JMP sum_psl
	
	JMP ignoruoti1
	sm_010:
	JMP sum_010
	sm_011:
	JMP sum_011
	sm_100:
	JMP sum_100
	sm_101:
	JMP sum_101
	sm_110:
	JMP sum_110
	sm_111:
	JMP sum_111
	ignoruoti1:
	
	sum_001:
	MOV ax, regBX
	MOV cx, ax
	MOV ax, regDI
	ADD cx, ax
	
	MOV bx, 35
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regBX
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	
	MOV bx, 25
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regDI
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	JMP sum_psl
	
	sum_010:
	MOV ax, regBP
	MOV cx, ax
	MOV ax, regSI
	ADD cx, ax
	
	MOV bx, 30
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regBP
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	
	MOV bx, 20
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regSI
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	JMP sum_psl
	
	sum_011:
	MOV ax, regBP
	MOV cx, ax
	MOV ax, regDI
	ADD cx, ax
	
	MOV bx, 30
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regBP
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	
	MOV bx, 25
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regDI
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	JMP sum_psl
	
	sum_100:
	MOV ax, regSI
	MOV cx, ax
	
	MOV bx, 20
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regSI
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	JMP sum_psl
	
	sum_101:
	MOV ax, regDI
	MOV cx, ax
	
	MOV bx, 25
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regDI
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	JMP sum_psl
	
	sum_110:
	MOV ax, regBP
	MOV cx, ax
	
	MOV bx, 30
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regBP
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	JMP sum_psl
	
	sum_111:
	MOV ax, regBX
	MOV cx, ax
	
	MOV bx, 35
	CALL spausdinti_poslinki
	MOV ah, 2
	MOV dl, '='
	INT 21h
	MOV ax, regBX
	CALL spausdinti_zodi
	CALL spausdinti_tarpa
	
	sum_psl:
	CALL tikrinti_mod
	MOV ah, 2
	MOV dl, '='
	INT 21h

	CMP bitai_mod, 80h
	JE zodzio_psl
	CMP bitai_mod, 40h
	JE baito_psl
	CMP bitai_mod, 0
	JE be_psl
	
	zodzio_psl:
	MOV bl, baitas_3
	MOV bh, baitas_4
	ADD cx, bx
	MOV bx, cx
	
	MOV ax, ds:[bx]
	CMP bitas_w, 1
	JNE jei_ne_w_3
	CALL spausdinti_zodi
	RET
	jei_ne_w_3:
	CALL spausdinti_baita
	RET
	
	baito_psl:
	MOV bl, baitas_3
	MOV bh, 0
	ADD cx, bx
	MOV bx, cx
	
	MOV ax, ds:[bx]
	CMP bitas_w, 1
	JNE jei_ne_w_4
	CALL spausdinti_zodi
	RET
	jei_ne_w_4:
	CALL spausdinti_baita
	RET
	
	be_psl:
	MOV bx, cx
	
	MOV ax, ds:[bx]
	CMP bitas_w, 1
	JNE jei_ne_w_5
	CALL spausdinti_zodi
	RET
	jei_ne_w_5:
	CALL spausdinti_baita
	RET
	CALL spausdinti_zodi
	RET
	
tikrinti_mod:
	CMP bitai_mod, 0C0h
	JE mod_11
	CMP bitai_mod, 80h
	JE mod_10
	CMP bitai_mod, 40h
	JE mod_01
	CMP bitai_mod, 0
	JE mod_00
	
	mod_11:
	MOV cx, 1
	CMP bitas_w, 1
	JNE ne_w
	CALL spausdinti_registra_vyr
	RET
	
	ne_w:
	CALL spausdinti_registra_jaun
	RET
	
	mod_10:
	MOV ah, 2
	MOV dl, '['
	INT 21h
	CALL spausdinti_rm
	MOV ah, 2
	MOV dl, '+'
	INT 21h
	MOV al, baitas_3
	MOV ah, baitas_4
	CALL spausdinti_zodi
	MOV ah, 2
	MOV dl, ']'
	INT 21h
	RET
	
	mod_01:
	MOV ah, 2
	MOV dl, '['
	INT 21h
	CALL spausdinti_rm
	MOV ah, 2
	MOV dl, '+'
	INT 21h
	MOV al, baitas_3
	CALL spausdinti_baita
	MOV ah, 2
	MOV dl, ']'
	INT 21h
	RET
	
	mod_00:
	CMP bitai_rm, 6h
	JNE mod_ne_110
	
	MOV ah, 9
	MOV dx, offset pran_ds
	INT 21h
	MOV ah, 2
	MOV dl, '['
	INT 21h
	MOV al, baitas_3
	MOV ah, baitas_4
	CALL spausdinti_zodi
	MOV ah, 2
	MOV dl, ']'
	INT 21h
	RET
	
	mod_ne_110:
	MOV ah, 2
	MOV dl, '['
	INT 21h
	CALL spausdinti_rm
	MOV ah, 2
	MOV dl, ']'
	INT 21h
	RET

spausdinti_registra_vyr:
	CMP cx, 1 
	JNE praleisti1
	
	MOV ax, 0
	MOV bx, 0
	
	MOV al, byte ptr bitai_reg
	MOV bx, offset bitai_reg
	PUSH ax
	PUSH bx
	MOV al, byte ptr bitai_rm
	PUSH ax
	SHL al, 3
	MOV word ptr [bx], ax
	
	praleisti1:
	CMP bitai_reg, 0
	JE reg_ax
	CMP bitai_reg, 8h
	JE reg_cx
	CMP bitai_reg, 10h
	JE reg_dx
	CMP bitai_reg, 18h
	JE reg_bx
	CMP bitai_reg, 20h
	JE jmp1
	CMP bitai_reg, 28h
	JE jmp2
	CMP bitai_reg, 30h
	JE jmp3
	CMP bitai_reg, 38h
	JE jmp4
	
	reg_ax:
	PUSH bx
	MOV bx, 0
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 1
	JNE baigti1
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_cx:
	PUSH bx
	MOV bx, 2
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 2
	JNE baigti1
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	jmp1:
	JMP reg_sp
	jmp2:
	JMP reg_bp
	jmp3:
	JMP reg_si
	jmp4:
	JMP reg_di
	
	reg_dx:
	PUSH bx
	MOV bx, 4
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 3
	JNE baigti1
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	baigti1:
	RET
	
	reg_bx:
	PUSH bx
	MOV bx, 6
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 4
	JNE baigti1
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_sp:
	PUSH bx
	MOV bx, 24
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 5
	JNE baigti1
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_bp:
	PUSH bx
	MOV bx, 26
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 6
	JNE baigti1
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_si:
	PUSH bx
	MOV bx, 28
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 7
	JNE baigti1
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_di:
	PUSH bx
	MOV bx, 30
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 8
	JNE baigti1
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
spausdinti_registra_jaun:
	CMP cx, 1 
	JNE praleisti2
	
	MOV ax, 0
	MOV bx, 0
	
	MOV al, byte ptr bitai_reg
	MOV bx, offset bitai_reg
	PUSH ax
	PUSH bx
	MOV al, byte ptr bitai_rm
	PUSH ax
	SHL al, 3
	MOV word ptr [bx], ax
	
	praleisti2:
	CMP bitai_reg, 0
	JE reg_al
	CMP bitai_reg, 8h
	JE reg_cl
	CMP bitai_reg, 10h
	JE reg_dl
	CMP bitai_reg, 18h
	JE reg_bl
	CMP bitai_reg, 20h
	JE jmp5
	CMP bitai_reg, 28h
	JE jmp6
	CMP bitai_reg, 30h
	JE jmp7
	CMP bitai_reg, 38h
	JE jmp8
	
	reg_al:
	PUSH bx
	MOV bx, 8
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 1
	JNE baigti2
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_cl:
	PUSH bx
	MOV bx, 10
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 2
	JNE baigti2
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	jmp5:
	JMP reg_ah
	jmp6:
	JMP reg_ch
	jmp7:
	JMP reg_dh
	jmp8:
	JMP reg_bh
	
	reg_dl:
	PUSH bx
	MOV bx, 12
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 3
	JNE baigti2
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	baigti2:
	RET
	
	reg_bl:
	PUSH bx
	MOV bx, 14
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 4
	JNE baigti2
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_ah:
	PUSH bx
	MOV bx, 16
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 5
	JNE baigti2
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_ch:
	PUSH bx
	MOV bx, 18
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 6
	JNE baigti2
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_dh:
	PUSH bx
	MOV bx, 20
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 7
	JNE baigti2
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
	reg_bh:
	PUSH bx
	MOV bx, 22
	CALL spausdinti_registra
	POP bx
	CMP cx, 1
	MOV cx, 8
	JNE baigti2
	MOV bx, offset bitai_rm
	POP ax
	MOV byte ptr [bx], al
	POP bx
	POP ax
	MOV byte ptr [bx], al
	RET
	
spausdinti_rm:
	mov ax, 5
	MOV bx, 0
	MOV bl, bitai_rm
	MUL bl
	MOV bx, ax
	
	CALL spausdinti_poslinki
	RET

spausdinti_registra:
	PUSH bx
	
	MOV dl, offset [registrai+bx]
	MOV ah, 2
	INT 21h
	INC bx
	MOV dl, offset [registrai+bx]
	MOV ah, 2
	INT 21h
	
	POP bx
RET

spausdinti_poslinki:
	PUSH bx
	PUSH cx
	CMP bx, 19
	JA po_du
	MOV cx, 5
	JMP ciklas
	po_du:
	MOV cx, 2
	
	ciklas:
	MOV dl, offset [poslinkiai+bx]
	MOV ah, 2
	INT 21h
	INC bx
	LOOP ciklas
	POP cx
	POP bx
	RET
	
spausdinti_zodi:
	PUSH ax
	PUSH dx

	PUSH ax
	MOV al, ah
	CALL spausdinti_baita
	
	POP ax
	CALL spausdinti_baita
	
	POP dx
	POP ax
RET

spausdinti_baita:
	PUSH ax
	PUSH dx
	PUSH cx
	
	PUSH ax
	MOV cl, 4
	SHR al, cl
	CALL spausdinti_sesioliktaini_skaiciu
	POP ax
	CALL spausdinti_sesioliktaini_skaiciu
	
	POP cx
	POP dx
	POP ax
RET

spausdinti_sesioliktaini_skaiciu:
	AND al, 0Fh
	CMP al, 9
	JBE jei_ne_raide
	
	SUB al, 10
	ADD al, 41h
	MOV dl, al
	MOV ah, 2;
	INT 21h
	JMP baigti_spausdinti
	
	
	jei_ne_raide:
	MOV dl, al
	ADD dl, 30h
	MOV ah, 2
	INT 21h
	
	baigti_spausdinti:
RET

spausdinti_tarpa:
	PUSH ax
	PUSH dx
	
	MOV ah, 2
	MOV dl, ' '
	INT 21h
	
	POP dx
	POP ax
RET

pertraukimas ENDP

END Pradzia