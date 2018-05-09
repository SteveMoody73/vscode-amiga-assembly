;********************************************************************************************
;* Title:  p.S
;********************************************************************************************
;* Author: Paul Raingeard de la Bl�ti�re
;*
;* Description: Mise en place d'une d�mo en suivant les vid�os de Photon / scoopex
;*
;*
;* Include Files: hw.i : registres de base de l'amiga
;*
;* Assembler:  ASM-One V1.20
;*
;* Revision History:
;* Rev #     Date      Who     Comments
;* -----  -----------  ------  --------------------------------------------
;*  1.0    10-Apr-18   PRB     Premi�re release
;********************************************************************************************
	SECTION MyDemo,CODE
	JUMPPTR start

	INCDIR    src:Include/
	INCLUDE "hw.i"

;******************************************************************	
;* Constantes
;******************************************************************	
COPPER_WAIT     equ		$FFFE
W				equ		320
H 				equ		256
BPLSIZE			equ		(W*H)/8 ; 1 plans de bits en octets

LOGOW			equ		192					; padding � 1 word 12*16 = 192 / 11*16 = 172 < 178
LOGOH			equ		67
LOGOMARGIN		equ		(W-LOGOW)/2
LOGOBPL			equ		LOGOW/8
LOGOBWIDTH 		equ		LOGOBPL*3
LOGOSTARTV		equ		$4c
******************************************************************	

start
OSOff	movem.l	d0-a6,-(sp)
		move.l	4.w,a6			; execbase - le .w permet de ne garde qu'un octe pour l'adresse - diminution de taille de la commande
		clr.l	d0				; les registres sont des long - il faut les nettoyer avec un .l
		move.l	#GfxName,a1		; nom de la librairie
		jsr		-408(a6)			; oldopenlibrary()
		move.l	d0,a1			; r�cup�ration de l'adresse de chargement de la lib
		move.l	38(a1),CopperSave; pointeur du Copper originel
		jsr		-414(a6)			; closelibrary()

		lea		$dff000, a6			; adresse de base

		move.w	INTENAR(a6),INTENARSave; Copie de la valeur des interruptions 
		move.w	DMACONR(a6),DMACONSave; sauvegarde du dmacon 

		move.w	#$138, d0			; wait for eoframe param�tre pour la routine de WaitRaster - position � attendre
		bsr.w	WaitRaster			; Appel de la routine wait raster - bsr = jmp, mais pour des adresses moins distantes
		move.w	#$7fff,INTENA(a6)	; d�sactivation de toutes les interruptions bits : valeur + masque sur 7b
		move.w	#$7fff,INTREQ(a6)	;disable all bits in INTREQ
		move.w	#$7fff,INTREQ(a6)	;disable all bits in INTREQ
		move.w	#$7fff,DMACON(a6)	;disable all bits in DMACON
		move.w	#$87e0,DMACON(a6)	; Activation classique pour d�mo

	;--- Boucle principale
		bsr		Init
		move.l	#Copper, COP1LC(A6) ; Mise en place de la Copperlist
		bsr		Main
	;---------------------

exit
OSOn	move.w	#$7fff,DMACON(a6)			;disable all bits in DMACON
		or.w	#$8200,(DMACONSave)			; Iversion du masque de bits pour l'activation
		move.w	(DMACONSave),DMACON(a6)		; Remise des indormations sauvegard�es
		move.l	(CopperSave),COP1LC(a6)		; r�adressage de la Copperlist
		or		#$c000,(INTENARSave)		; Inversion du masque d'activation sur la partie de valeur ? associer
		move	(INTENARSave),INTENA(a6)	; r�activation des interruptions
		movem.l	(sp)+,d0-a6
		clr d0								; code retour du programme
		rts									; fin de programme retour � AmigaOs
	
;******************************************************************
;* Routines
;******************************************************************

;******************************************************************
;* Main - Fonction principale
;*  Fonction principale du traitement
;*
;* I/O: None
;******************************************************************
Main
			movem.l	d0-a6,-(sp)
			move	#LOGOSTARTV-6,d7	; position y
			moveq	#-1,d6				; incr�ment

.resetct	move	#LOGOH+6,d2			; dur�e d'un cycle
			neg		d6
.loop		move.w 	#$02a, d0			; wait for eoframe param�tre pour la routine de WaitRaster - position � attendre
			bsr.w 	WaitRaster			; Appel de la routine wait raster - bsr = jmp, mais pour des adresses moins distantes

			add.b	#1,Spr+1			; d�placement du sprite
			
			add		d6,d7				; Ajout de l'incr�ment
			dbf		d2,.continue		; teste si on est a zero, sinon d�cr�mente et pat dans watiras1
			jmp		.resetct			; le compteur d2 est arriv� ? -1

.continue	move.l	#WaitRas1,a0
			move	d7,d0
			moveq	#6-1,d1
.lsetpost	move.b	d0,(a0)
			add.w	#1,d0
			add.w	#8,a0
			dbf		d1,.lsetpost
	
.chkmouse	btst	#6,$bfe001
			bne.b	.loop

			movem.l (sp)+,d0-a6
			rts

;******************************************************************
;* Init - Initialisation des �l�ments graphiques
;*
;* I/O: None
;******************************************************************
Init
	; --- sauvegarde des registres
			movem.l	d0-a6,-(sp)
	; --- mise � "blanc" du fond d'ecran
			lea		Screen, a0
			move.w	#BPLSIZE-1,d0
.l			move.b 	#$f0,(a0)+
			dbf		d0,.l
		;--- mise en place de son adresse dans la Copperlist
			lea CopBp2,a0
			move.l #Screen,d1
			swap d1
			move.w d1,2(a0)
			swap d1
			move.w d1,6(a0)

	;--- Initialisation des adresses des sprites
		;--- sprites smiley
			lea		CopSpr, a0
			move.l	#Spr,d1
			swap	d1
			move.w	d1,2(a0)
			swap	d1
			move.w	d1,6(a0)
		;--- Null sprites
			addq	#8,a0		; passage � l'adressage de sprite suivant
			move.l	#NullSpr,d1
			move	#7-1,d0
.lnspr		swap	d1
			move.w	d1,2(a0)
			swap	d1
			move.w	d1,6(a0)
			addq	#8,a0		; add quick
			dbf		d0,.lnspr

	;--- Initialisation des adresses des bitmap
			lea		CopBp1, a0
			move.l	#Logo, d1
			move	#3-1,d0
.lbp		swap	d1
			move.w	d1,2(a0)
			swap	d1
			move.w	d1,6(a0)
			addq	#8,a0		; add quick
			add		#LOGOBPL,d1
			dbf	d0,.lbp

	;---  Retour de routine
			movem.l (sp)+,d0-a6
			rts

;******************************************************************
;* WaitRaster - wait for rasterline d0.w.
;*
;* I/O: Modifies d0-d2/a0
;* Calling Convention:
;*		move.w 	#$02a, d0			; wait for eoframe param�tre pour la routine de WaitRaster - position � attendre
;*		bsr.w 	WaitRaster			; Appel de la routine wait raster - bsr = jmp, mais pour des adresses moins distantes
;******************************************************************
WaitRaster
		movem.l d0-a6,-(sp)
		move.l	#$1ff00,d2
		lsl.l	#8,d0
		and.l	d2,d0
		lea		$dff004,a0
.wr		move.l	(a0),d1
		and.l	d2,d1
		cmp.l	d1,d0
		bne.s	.wr
		
		movem.l (sp)+,d0-a6
		rts

;******************************************************************
;* DATA
;******************************************************************

;******************************************************************
;* GfxName : Nom de la librairie graphique
;******************************************************************
GfxName 
	dc.b "graphics.library",0

	EVEN

;******************************************************************
;* Sauvegarde de registres
;******************************************************************
DMACONSave:
	dcb.w 1
CopperSave:
	dcb.l 1
INTENARSave:
	dcb.w 1

	SECTION MyDemoData,DATA_C
Spr:
	dc.b $95,$40,$a5,$00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000011111000000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0110011111001100,%0001100000110000
	dc.w %1110011111001110,%0001100000110000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0010000000001000
	dc.w %1111111111111110,%0001100000110000
	dc.w %0111111111111100,%0000011111000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w 0,0

NullSpr:
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0

Copper:
	dc.w $1fc,0				;slow fetch mode for AGA compatibility : ? garder en d�but de Copperlist
	dc.w BPLCON0,$0200			; 1200 : activation des sprites - 1 = BPLCON0
	; -- d�finition de la zone d'affichage
	dc.b 0,DIWSTRT,LOGOSTARTV,$81		; Display window start (upper left vert-horiz position)
	dc.b 0,DIWSTOP,$2c,$c1      ; Display window stop (lower right vert.-horiz. position)
	dc.w DDFSTRT,$38+LOGOMARGIN/2		; Display bitplane data fetch start (horiz. position) - attention � la forme du calcul : pas d'espaces
	dc.w DDFSTOP,$d0-LOGOMARGIN/2		; Display bitplane data fetch stop (horiz. position)     
	dc.w BPL1MOD,LOGOBWIDTH-LOGOBPL		; Dimension � sauter : 2*LOGOBPL
	dc.w BPL2MOD,LOGOBWIDTH-LOGOBPL
	dc.w BPLCON1,$0

	; couleurs pour le sprite
	dc.w COLOR17, $ff0		;couleur sprite commence � 17
	dc.w COLOR18, $00f
	dc.w COLOR19, $f00

CopSpr:
	dc.w SPR0PTH,0
	dc.w SPR0PTL,0
	dc.w SPR1PTH,0
	dc.w SPR1PTL,0
	dc.w SPR2PTH,0
	dc.w SPR2PTL,0
	dc.w SPR3PTH,0
	dc.w SPR3PTL,0
	dc.w SPR4PTH,0
	dc.w SPR4PTL,0
	dc.w SPR5PTH,0
	dc.w SPR5PTL,0
	dc.w SPR6PTH,0
	dc.w SPR6PTL,0
	dc.w SPR7PTH,0
	dc.w SPR7PTL,0

CopBp1:
	dc.w BPL1PTH,0
	dc.w BPL1PTL,0
	dc.w BPL2PTH,0
	dc.w BPL2PTL,0
	dc.w BPL3PTH,0
	dc.w BPL3PTL,0

	dc.w  BPLCON0,$3200

	; -- bordure haute
	dc.w COLOR00,$349			; mise ? jour de la couleur de fond dff180
	; la ligne du haut est ? $2b - en x elle va de $07 ? $df
	dc.w $2b07,COPPER_WAIT		; COPPER_WAIT est le masque pour commande attendre
	dc.w COLOR00,$56c			; mise ? jour de la couleur de fond dff180
	dc.w $2c07,COPPER_WAIT		; COPPER_WAIT est le masque pour commande attendre
	; -- couleur du centre
	;dc.w COLOR00,$113			; mise ? jour de la couleur de fond dff180
	; couleurs pour le logo
	dc.w COLOR00,$0667,COLOR01,$0ddd,COLOR02,$0833,COLOR03,$0334
	dc.w COLOR04,$0a88,COLOR05,$099a,COLOR06,$0556,COLOR07,$0633


WaitRas1:
	dc.w $8007,COPPER_WAIT
	dc.w COLOR00,$055
WaitRas2:
	dc.w $8107,COPPER_WAIT
	dc.w COLOR00,$0aa
WaitRas3:
	dc.w $8207,COPPER_WAIT
	dc.w COLOR00,$0ff
WaitRas4:
	dc.w $8307,COPPER_WAIT
	dc.w COLOR00,$0aa
WaitRas5:
	dc.w $8407,COPPER_WAIT
	dc.w COLOR00,$055
WaitRas6:
	dc.w $8507,COPPER_WAIT
	dc.w COLOR00,$667

	dc.w $9507,COPPER_WAIT
CopBp2:
	dc.w BPL1PTH,0
	dc.w BPL1PTL,0
	dc.w DDFSTRT,$38		; Display bitplane data fetch start (horiz. position) - attention � la forme du calcul : pas d'espaces
	dc.w DDFSTOP,$d0		; Display bitplane data fetch stop (horiz. position)     
	dc.w BPL1MOD,0
	dc.w BPL2MOD,0
	dc.w BPLCON0,$1200


	; -- bordure basse
	dc.w $ffdf,COPPER_WAIT		; demande pour d�passer le NTSC, on est en PAL
	; l'adressage recommence ? 0 ici - on calcule des d�calages ? partir de 0
	dc.w $2c07,COPPER_WAIT		; 2c = 40 lignes soit : 240 en y
	dc.w COLOR00,$56c
	dc.w $2d07,COPPER_WAIT		; 2d - une ligne apr?s
	dc.w COLOR00,$349			; bordure jusqu'en bas : 256 en y

	; -- Commande de fin de liste
	dc.l COPPER_HALT		; fin de liste - adresse en dehors de la zone autoris�e

Logo:
	INCBIN "src:sky.178x67x3.raw"
LogoEnd:
Blank:
	dcb.w LOGOBWIDTH*6,0	; Taille ligne en octets * 3 bitplan * 6 lignes
BlankEnd:


	SECTION MyDemoBSS,BSS_C		; allocation au runtime
Screen:
	ds.b BPLSIZE
