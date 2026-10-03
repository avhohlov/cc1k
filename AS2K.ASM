      ; Simplified 8086/88 assembler.
      ; May compile itself and CC1K.ASM
      ;
      ; Source file name      A.ASM
      ; Destination file name A.COM
      ;
      ; (C) Andrei V. Khokhlov

        org    256             ; 0x100

      ; mov    AH ,    61      ; 0x3D
      ; mov    AL ,    0
        mov    AX ,    15616
        mov    DX ,    src
        int    33              ; 0x21

                               ; TODO   Check CF

      ; mov  [ hnd ] , AX
        mov    BX ,    hnd
        mov  [ BX ] ,  AX

        sub    AX ,    AX
        mov    BX ,    nText
        mov  [ BX ] ,  AX
        mov    BX ,    pText
        mov  [ BX ] ,  AX

                               ; Assembling
        mov    AX ,    1
        mov    BX ,    lno
        mov  [ BX ] ,  AX      ; Line = 1
        mov    SI ,    lbl
        mov    BP ,    ref
        mov    DI ,    code

        cld

asm :
        mov    BX ,    csz
        mov  [ BX ] ,  DI

asm_1 :
        call   get_tok
        or     CX ,    CX
        jne    process
        jmp    asm_end

process :
        call   find_inst
        inc    BX
        inc    BX
      ; add    BX ,    2
        mov    DX ,  [ BX ]    ; Class
        or     DX ,    DX
        je     process_lbl
        jmp    process_inst

process_lbl :
        push   CX
        call   get_tok         ; colon
        pop    CX

        sub    AX ,    AX
        call   find_lbl

      ; jmp    asm
        jmp    asm_1

process_inst :
      ; add    BX ,    2
        inc    BX
        inc    BX
        mov    AX ,  [ BX ]    ; Opcodes

process_10 :
        cmp    DX ,    10
        jne    process_15
        jmp    process_2_op

process_15 :

process_20 :
        cmp    DX ,    20
        jne    process_25
        jmp    process_mul

process_25 :
        cmp    DX ,    25
        jne    process_30
        jmp    process_inc

process_30 :
        cmp    DX ,    30
        jne    process_35
        jmp    process_push

process_35 :
        cmp    DX ,    35
        jne    process_40
        jmp    process_int

process_40 :
        cmp    DX ,    40
        jne    process_45
        jmp    process_ret

process_45 :
        cmp    DX ,    45
        jne    process_50
        jmp    process_jmp

process_50 :
        cmp    DX ,    50
        jne    process_55
        jmp    process_jxx

process_55 :
        cmp    DX ,    55
        jne    process_60
        jmp    process_no_op

process_60 :
        cmp    DX ,    60
        jne    process_65
        jmp    process_db

process_65 :
        cmp    DX ,    65
        jne    process_70
        jmp    process_dw

process_70 :
        cmp    DX ,    70
        jne    process_75
        jmp    process_rb

process_75 :
        cmp    DX ,    75
        jne    process_80
        jmp    process_rw

process_80 :
        cmp    DX ,    80
        jne    not_implemented
        jmp    process_org

not_implemented :
        jmp    halt

asm_end :
        mov    BX ,    ref

ref_loop :
        cmp    BX ,    BP
        jae    ref_end

        push   BX

        mov    BX ,  [ BX ]
        mov    DX ,  [ BX ]    ; Lbl Ofs
        cmp    DX ,    65535
        jne    patch

        call   newln

        inc    BX
        inc    BX
        mov    DX ,  [ BX ]
        call   info

        jmp    halt

patch :
        pop    BX

      ; add    BX ,    2       ; [ BX ] = IP
        inc    BX
        inc    BX

        mov    SI ,  [ BX ]    ; Code Ofs
      ; mov    AL ,  [ SI ]
      ; cmp    AL ,    1
        mov    AX ,  [ SI ]
        and    AX ,    7
        cmp    AX ,    1
        jne    patch_word

        mov    AX ,    DX
        sub    AX ,    SI
      ; sub    AX ,    1       ; TODO Check distance
        dec    AX

        mov  [ SI ] ,  AL

        jmp    patch_done

patch_word :
      ; cmp    AL ,    2
        cmp    AX ,    2
        jne    patch_abs

        mov    AX ,    DX
        sub    AX ,    SI
      ; sub    AX ,    2
        dec    AX
        dec    AX

        mov  [ SI ] ,  AX

        jmp    patch_done

patch_abs :
        mov    AX ,    DX
        mov    CX ,    code
        sub    AX ,    CX
        add    AX ,    256

        mov  [ SI ] ,  AX

patch_done :
      ; add    BX ,    2       ; [ BX ] = Ref List
        inc    BX
        inc    BX

        jmp    ref_loop

ref_end :
      ; mov    AH ,    62      ; 0x3E
        mov    AX ,    15872
      ; mov    BX ,  [ hnd ]
        mov    BX ,    hnd
        mov    BX ,  [ BX ]
        int    33              ; 0x21

      ; mov    AH ,    60      ; 0x3C
        mov    AX ,    15360
        mov    CX ,    0
        mov    DX ,    dst
        int    33              ; 0x21

                               ; TODO   Check CF

      ; mov  [ hnd ] , AX
        mov    BX ,    hnd
        mov  [ BX ] ,  AX

        mov    BX ,    csz
        mov    CX ,  [ BX ]

      ; mov    AH ,    64      ; 0x40
        mov    AX ,    16384
      ; mov    BX ,  [ hnd ]   ; TODO   mov    BX ,  pred AX
        mov    BX ,    hnd
        mov    BX ,  [ BX ]
      ; mov    CX ,    DI
        mov    DX ,    code
        sub    CX ,    DX
        int    33              ; 0x21

      ; mov    AH ,    62      ; 0x3E
        mov    AX ,    15872
      ; mov    BX ,  [ hnd ]
        mov    BX ,    hnd
        mov    BX ,  [ BX ]
        int    33              ; 0x21

        retn


process_2_op :
        push   AX              ; Opcodes

        call   get_tok
        cmp    CX ,   43       ; [
        je     store_1
        jmp    load_1

store_1 :
        call   get_tok
        call   find_reg
        mov    AX ,  [ BX ]
        or     AX ,    AX
        jne    chk_dst_ix_1
        jmp    halt

chk_dst_ix_1 :
      ; add    BX ,    2
        inc    BX
        inc    BX
        mov    AX ,  [ BX ]    ; Reg
        cmp    AX ,    32768   ; Byte reg?
        jb     chk_dst_ix_2
        jmp    halt

chk_dst_ix_2 :
        cmp    AX ,    16384   ; Index reg?
        jae    store_2
        jmp    halt

store_2 :
        push   AX

        call   get_tok         ; ]
        call   get_tok         ; ,
        call   get_tok

        call   find_reg
        mov    AX ,  [ BX ]
        or     AX ,    AX
        jne    store_3
        jmp    halt

store_3 :
      ; add    BX ,    2
        inc    BX
        inc    BX
        mov    DX ,  [ BX ]    ; Src

        pop    CX              ; Index reg
        pop    AX              ; Opcodes
        cmp    DX ,    32768
        jae    byte_opr_1
        or     AX ,    1

byte_opr_1 :
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        and    DX ,    7
        add    DX ,    DX
        add    DX ,    DX
        add    DX ,    DX

        mov    AX ,    CX
        mov    AL ,    AH
        and    AX ,    7

        push   AX

        cmp    AX ,    6
        jne    not_bp
        mov    AX ,    70       ; 0x46 = 01-000-110

not_bp :
        or     AX ,    DX

      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        pop    AX

        cmp    AX ,    6
        jne    not_bp_2
        sub    AX ,    AX
        stosb                   ; Zero ofs

not_bp_2 :
        jmp    asm

load_1 :
      ; call   get_tok         ; INFO Error
        call   find_reg

        mov    AX ,  [ BX ]
        or     AX ,    AX
        jne    load_2_mod      ; TODO HashCode(load_2) = 0
        jmp    halt

load_2_mod :
      ; add    BX ,    2
        inc    BX
        inc    BX
        mov    AX ,  [ BX ]    ; Dst

        push   AX

        call   get_tok         ; comma
        call   get_tok         ; Src

        mov    BX ,    nf
        mov    DX ,  [ BX ]
        or     DX ,    DX
        je     chk_ind
        jmp    load_num_1

chk_ind :
        cmp    CX ,    43      ; [
        jne    chk_src_reg
        jmp    load_mem_1

chk_src_reg :
        call   find_reg
        mov    AX ,  [ BX ]
        or     AX ,    AX
        je     chk_lbl
        jmp    copy_reg_1

chk_lbl :
        mov    AX ,    1
        call   find_lbl        ; [ BX ] = Ofs or 65535

        pop    DX              ; Dst
        pop    AX              ; Opcodes

        cmp    DX ,   32768
        jb     imm_to_wreg_1
        jmp    halt

imm_to_wreg_1 :
        cmp    AX ,    136     ; mov
        jne    not_mov_0

        mov    AX ,    184     ; 0xB8
        add    AX ,    DX      ; Reg

        stosb

        mov    AX ,    4       ; Absolute ofs
        jmp    add_ref

not_mov_0 :
        mov    AL ,    AH
        and    AX ,    255

        push   BX

        mov    BX ,    reg_imm
        add    BX ,    AX
        or     AX ,    AX
        mov    AX ,  [ BX ]

        jne    not_mov_1       ; TODO Check
        inc    AX

not_mov_1 :
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        mov    AL ,    AH
        or     AX ,    DX

      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        pop    BX

        mov    AX ,    4       ; Absolute ofs
        jmp    add_ref

load_num_1 :
        pop    DX              ; Dst
        pop    AX              ; Opcodes
      ; mov    AL ,    AH      ; Error

        cmp    AX ,    136     ; mov
        jne    not_mov

        mov    AX ,    176     ; 0xB0
        add    AX ,    DX      ; Reg

        cmp    DX ,    32768
        jb     load_word

        stosb

        mov    AX ,    CX
        stosb

        jmp asm

load_word :
        add    AX ,    8       ; W = 1

        stosb

        mov    AX ,    CX
        stosw

        jmp asm

not_mov :
        cmp    DX ,    32768
        jb     imm_to_wreg_2
        jmp    halt            ; INFO Omitted

imm_to_wreg_2 :
        mov    AL ,    AH
        and    AX ,    255

        or     DX ,    DX
        jne    not_acc

        mov    BX ,    acc_imm
        add    BX ,    AX
        mov    AX ,  [ BX ]

        or     AX ,    1
        stosb

        mov    AX ,    CX
        stosw

        jmp    asm

not_acc :
        mov    BX ,    reg_imm
        add    BX ,    AX
        mov    AX ,  [ BX ]

        cmp    CX ,    127
        jbe    byte_imm

        cmp    CX ,    65408   ; TODO Check
        jb     word_imm_2
      ; mov    BX ,    65535
      ; sub    BX ,    CX
      ; mov    CX ,    255
      ; sub    CX ,    BX

byte_imm :
        add    AX ,    2       ; S:W = 1:1
        stosb

        mov    AL ,    AH
        or     AX ,    DX
        stosb

        mov    AX ,    CX
        stosb

        jmp    asm

word_imm_2 :
        stosb

        mov    AL ,    AH
        or     AX ,    DX
        stosb

        mov    AX ,    CX
        stosw

        jmp    asm

load_mem_1 :
        call   get_tok
        call   find_reg
        mov    AX ,  [ BX ]
        or     AX ,    AX
        jne    chk_src_ix_1
        jmp    halt

chk_src_ix_1 :
      ; add    BX ,    2
        inc    BX
        inc    BX
        mov    CX ,  [ BX ]    ; Reg
        cmp    CX ,    32768   ; Byte reg?
        jb     chk_src_ix_2
        jmp    halt

chk_src_ix_2 :
        cmp    CX ,    16384   ; Index reg?
        jae    load_3
        jmp    halt

load_3 :
        pop    DX              ; Dst
        pop    AX              ; Opcodes

        or     AX ,    2       ; To Reg

        cmp    DX ,    32768
        jae    byte_opr_3
        or     AX ,   1        ; Word

byte_opr_3 :
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        and    DX ,    7
        add    DX ,    DX
        add    DX ,    DX
        add    DX ,    DX

        mov    AX ,    CX
        mov    AL ,    AH      ; Index Code
        and    AX ,    7

        push   AX

        cmp    AX ,    6
        jne    not_bp_3
        mov    AX ,    70

not_bp_3 :
        or     AX ,    DX

      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        pop    AX

        cmp    AX ,    6
        jne    not_bp_4
        sub    AX ,    AX
        stosb

not_bp_4 :

        call   get_tok         ; ]

        jmp    asm

copy_reg_1 :
        pop    DX              ; Dst
        pop    AX              ; Opcodes

      ; add    BX ,    2
        inc    BX
        inc    BX
        mov    CX ,  [ BX ]    ; Src

        or     AX ,    2       ; TODO Swap Dst and Src?

        cmp    DX ,    32768
        jae    byte_opr_4
        or     AX ,    1

byte_opr_4 :
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        and    DX ,    7
        add    DX ,    DX
        add    DX ,    DX
        add    DX ,    DX

        mov    AX ,    192     ; MOD = 11
        or     AX ,    DX
        and    CX ,    7
        or     AX ,    CX

      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        jmp    asm


process_mul :
        push   AX              ; Opcodes

        call   get_tok
        call   find_reg
        mov    DX ,  [ BX ]
        or     DX ,    DX
        jne    mul_byte_reg
        jmp    halt

mul_byte_reg :
        pop    AX

      ; add    BX ,    2
        inc    BX
        inc    BX
        mov    DX ,  [ BX ]    ; Reg
        cmp    DX ,    32768   ; Byte reg?
        jae    mul_byte_1
        or     AX ,    1       ; Word

mul_byte_1 :
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        mov    AL ,    AH
        or     AX ,    DX

      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        jmp    asm


process_inc :
        push   AX

        call   get_tok
        call   find_reg
        mov    AX ,  [ BX ]
        or     AX ,    AX
        jne    chk_inc_reg
        jmp    halt

chk_inc_reg :
      ; add    BX ,    2
        inc    BX
        inc    BX
        mov    CX ,  [ BX ]    ; TODO Check byte reg

        pop    AX

        and    CX ,    7
        or     AX ,    CX

      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        jmp    asm


process_push :
        push   AX

        call   get_tok
        call   find_reg
        mov    AX ,  [ BX ]
        or     AX ,    AX
        jne    chk_push_reg
        jmp    halt

chk_push_reg :
      ; add    BX ,    2
        inc    BX
        inc    BX

        mov    CX ,  [ BX ]    ; TODO Check word reg

        pop    AX

        and    CX ,    7
        or     AX ,    CX

      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        jmp    asm


process_int :
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        call   get_tok

        mov    AX ,    CX
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        jmp    asm


process_ret :
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        jmp    asm


process_jmp :
        push   AX
        call   get_tok
        pop    AX

        cmp    AX ,    233     ; jmp
        jne    jmp_near
        cmp    CX ,    12132   ; short
        jne    jmp_near

        mov    AX ,    235     ; 0xEB
        stosb

        call   get_tok

        mov    AX ,    1       ; TODO AL?
        call   find_lbl        ; [ BX ] = Ofs or 65535

        mov    DX ,  [ BX ]
        cmp    DX ,    65535
        jne    set_jmp_len_10
        mov    AX ,    1       ; Byte ref
        jmp    add_ref

set_jmp_len_10 :
        mov    AX ,    DI
        inc    AX
        sub    DX ,    AX
        mov    AX ,    DX
        stosb

        jmp    asm

jmp_near :
        stosb

        mov    AX ,    1       ; TODO AL?
        call   find_lbl        ; [ BX ] = Ofs or 65535

        mov    DX ,  [ BX ]
        cmp    DX ,    65535
        jne    set_jmp_len
        mov    AX ,    2       ; Word ref
        jmp    add_ref

set_jmp_len :
        mov    AX ,    DI
      ; add    AX ,    2
        inc    AX
        inc    AX
        sub    DX ,    AX
      ; mov  [ DI ] ,  DX
    ; ; add    DI ,    2
      ; inc    DI
      ; inc    DI
        mov    AX ,    DX
        stosw

        jmp    asm


process_jxx :
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        call   get_tok
        mov    AX ,    1       ; TODO AL?
        call   find_lbl        ; [ BX ] = Ofs or 65535

        mov    DX ,  [ BX ]
        cmp    DX ,    65535
        jne    set_jmp_len_1
        mov    AX ,    1       ; Byte ref
        jmp    add_ref

set_jmp_len_1 :
        mov    AX ,    DI
      ; add    AX ,    1
        inc    AX
        sub    DX ,    AX
        mov    AX ,    DX      ; TODO Check distance
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    2       ; INFO Error
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        jmp    asm


process_no_op :
      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
        stosb

        jmp    asm


process_db :
        call   get_tok
      ; mov  [ DI ] ,  CX
      ; inc    DI
    ; ; add    DI ,    1
        mov    AX ,    CX
        stosb

        jmp    asm


process_dw :
        call   get_tok
      ; mov  [ DI ] ,  CX
      ; inc    DI
      ; inc    DI
    ; ; add    DI ,    2
        mov    AX ,    CX
        stosw

        jmp    asm


process_rb :
        call   get_tok

        sub    AX ,    AX

rb_loop :
        or     CX ,    CX
        je     rb_exit

      ; mov  [ DI ] ,  AL
      ; inc    DI
    ; ; add    DI ,    1
        stosb

        dec    CX
      ; sub    CX ,    1

        jmp    rb_loop

rb_exit :
        jmp    asm_1


process_rw :
        call   get_tok

        sub    AX ,    AX

rw_loop :
        or     CX ,    CX
        je     rb_exit

      ; mov  [ DI ] ,  AX
    ; ; add    DI ,    2
      ; inc    DI
      ; inc    DI
        stosw

        dec    CX
      ; sub    CX ,    1

        jmp    rw_loop

rw_exit :
        jmp    asm_1


process_org :
        call   get_tok         ; Ignore

        jmp    asm

                               ; AX : 1 - byte / 2 - word / 4 - word abs
add_ref :
        mov    DX ,    DI

        cmp    AX ,    1
        jne    add_word

      ; mov  [ DI ] ,  AL
    ; ; add    DI ,    1
      ; inc    DI
      ; stowb                  ; TODO Error
        stosb

        jmp    add_ref_impl

add_word :
      ; mov  [ DI ] ,  AX
    ; ; add    DI ,    2
      ; inc    DI
      ; inc    DI
        stosw

add_ref_impl :
        mov  [ BP ] ,  BX
        inc    BP
        inc    BP

        mov  [ BP ] ,  DX
        inc    BP
        inc    BP

        jmp    asm


find_inst :
        mov    BX ,    inst

find_inst_loop :
        mov    DX ,  [ BX ]
        or     DX ,    DX
        jne    inst_cmp

        retn

inst_cmp :
        cmp    DX ,    CX
        jne    next_inst

        retn

next_inst :
        add    BX ,    6
        jmp    find_inst_loop


find_reg  :
        mov    BX ,    regs

find_reg_loop :
        mov    DX ,  [ BX ]
        or     DX ,    DX
        jne    reg_cmp

        retn

reg_cmp :
        cmp    DX ,    CX
        jne    next_reg

        retn

next_reg :
        add    BX ,    4
        jmp    find_reg_loop


                               ; AX = 0 - set ofs / AX = 1 - add if not found
                               ; return [ BX ] = Ofs
find_lbl :
        mov    BX ,    lbl

find_lbl_loop :
        cmp    BX ,    SI
        jae    add_lbl

        mov    DX ,  [ BX ]
        cmp    DX ,    CX
        jne    next_lbl

        inc    BX
        inc    BX
      ; add    BX ,    2

        or     AX ,    AX      ; TODO AL?
        jne    ret_lbl

        mov    DX ,  [ BX ]    ; Ofs
        cmp    DX ,  65535
        je     set_ofs
        jmp    halt

set_ofs :
        mov    DX ,    DI
        mov  [ BX ] ,  DX

        retn

next_lbl :
        add    BX ,    6
        jmp    find_lbl_loop

add_lbl :
        mov  [ SI ] ,  CX      ; Hash Code
      ; add    SI ,    2
        inc    SI
        inc    SI

        push   SI              ; Return value

        mov    DX ,    DI
        or     AX ,    AX
        je     set_lbl_ofs

        cmp    CX ,    43      ; [
        jne    chk_inst_collision
        jmp    halt

chk_inst_collision :
        call   find_inst
      ; add    BX ,    2
        inc    BX
        inc    BX
        mov    DX ,  [ BX ]    ; Class
        or     DX ,    DX
        je     chk_regs_collision
      ; mov    DX ,    73      ; I
      ; call   putc
        jmp    halt

chk_regs_collision :
        call   find_reg
        mov    DX ,  [ BX ]
        or     DX ,    DX
        je     set_fwd_flag
      ; mov    DX ,    82      ; R
      ; call   putc
        jmp    halt

set_fwd_flag :
        mov    DX ,    65535

set_lbl_ofs :
        mov  [ SI ] ,  DX      ; Ofs or 65535
      ; add    SI ,    2
        inc    SI
        inc    SI

        mov    BX ,    lno
        mov    DX ,  [ BX ]
        mov  [ SI ] ,  DX
      ; add    SI ,    2
        inc    SI
        inc    SI

        pop    BX

ret_lbl :
        retn


get_tok :
        call   getc
        sub    CX ,    CX      ; Hash Code
        or     AL ,    AL
        jne    getc_ok

        retn

getc_ok :
      ; cmp    AL ,    10
        cmp    AX ,    10      ; AH = 0
        jne    not_eol

eol :
      ; mov    DX ,  [ lno ]
        mov    BX ,    lno
        mov    DX ,  [ BX ]
        inc    DX
      ; add    DX ,    1
      ; mov  [ lno ] , DX
        mov  [ BX ] ,  DX
not_eol :

      ; cmp    AL ,    32
        cmp    AX ,    32
        jbe    get_tok

        sub    DX ,    DX
      ; cmp    AL ,    48
        cmp    AX ,    48
        jb     ident
      ; cmp    AL ,    57
        cmp    AX ,    57
        ja     ident
        mov    DX ,    1
ident :

        mov    BX ,    nf
        mov  [ BX ] ,  DX

tok_next :
      ; xchg   AX ,    CX      ; TODO Implement?
      ; mov    DX ,    AX
      ; mov    AX ,    CX
      ; mov    CX ,    DX
        db     145             ; xchg AX, CX

        mov    DX ,    10
        mul    DX
        sub    CX ,    48
        add    CX ,    AX

        push   CX
        call   getc
        pop    CX
      ; cmp    AL ,    32
        cmp    AX ,    32
        ja     tok_next

        mov    BX ,    nf
        mov    BX ,  [ BX ]
        or     BX ,    BX
        je     chk_semi
        retn

chk_semi :                     ; INFO nf check required!
        cmp    CX ,    11      ; Semicolon
      ; mov    DX ,    CX
      ; add    DX ,    1
      ; cmp    DX ,    12
        je     remark
        retn

remark :
        call   getc

        or     AX ,    AX
        jne    not_eof
        jmp    get_tok

not_eof :
    ; ; cmp    AL ,    10
        cmp    AX ,    10
      ; ja     remark
        jne    remark

        jmp    eol

      ; jne    not_lf
    ; ; mov    DX ,  [ lno ]
      ; mov    BX ,    lno
      ; mov    DX ,  [ BX ]
      ; inc    DX
    ; ; add    DX ,    1
    ; ; mov  [ lno ] , DX
      ; mov  [ BX ] ,  DX

not_lf :
        jmp    get_tok


getc :
        mov    BX ,     nText
        mov    AX ,   [ BX ]
        mov    BX ,     pText
        mov    BX ,   [ BX ]
        cmp    BX ,     AX
        jb     ready

      ; mov    AH ,     63     ; 0x3F
        mov    AX ,     16128
        mov    BX ,     hnd
        mov    BX ,   [ BX ]
        mov    CX ,     1024
        mov    DX ,     text
        int    33              ; 0x21

                               ; TODO   Check CF

        mov    BX ,     nText
        mov  [ BX ] ,   AX
        sub    CX ,     CX
        mov    BX ,     pText
        mov    DX ,     BX
        mov  [ BX ] ,   CX
        mov    BX ,     CX

        cmp    BX ,     AX
        jb     ready
        retn                   ; AX = 0

ready :
        mov    DX ,     BX
        add    BX ,     text
        sub    AX ,     AX     ; FIXME
        mov    AL ,   [ BX ]
        inc    DX
        mov    BX ,     pText
        mov  [ BX ] ,   DX

        push   AX
        mov    DX ,     AX
        call   putc
        pop    AX

        retn


halt :
        call   newln

        mov    BX ,     lno
      ; mov    CX ,   [ BX ]   ; FIXME Remove dup function
      ; call   info_ini
        mov    DX ,   [ BX ]
        call   info

        mov    AX ,     19456  ; 0x4C00
        int    33              ; 0x21

newln :
        mov    DX ,     13
        call   putc
        mov    DX ,     10
        call   putc

        retn


                               ; CX - number to print
info_ini :
      ; cmp    CX ,     10
      ; jb     ini_put_char

      ; mov    AX ,     CX
      ; sub    DX ,     DX
      ; mov    CX ,     10
      ; div    CX
      ; mov    CX ,     AX

      ; push   DX
      ; call   info_ini
      ; pop    CX

ini_put_char :
      ; mov    DX ,     CX
      ; add    DX ,     48

      ; call   putc

      ; retn

                               ; DX - number to print
info :
        mov    AX ,     DX
        sub    DX ,     DX
        mov    CX ,     10
        div    CX
        or     AX ,     AX
        je     put_char

        push   DX
        mov    DX ,     AX
        call   info
        pop    DX

put_char :
        add    DX ,     48
        call   putc

        retn


putc :                         ; DL = char
        mov    AX ,     512    ; AH = 2
        int    33

        retn


src :
        db     65              ; A.ASM
        db     46
        db     65
        db     83
        db     77
        db     0

dst :
        db     65              ; A.COM
        db     46
        db     67
        db     79
        db     77
        db     0

                               ;      Classes
                               ; 10 - 2-op (mov, add, ...)
                               ; 15 - 2-op (shl, shr, ...)
                               ; 20 - 1-op (mul, div, ...)
                               ; 25 - 1-op (inc, dec)
                               ; 30 - 1-op (push, pop)
                               ; 35 - int
                               ; 40 - ret
                               ; 45 - jmp/call
                               ; 50 - jxx
                               ; 55 - no-op
                               ; 60 - db
                               ; 65 - dw
                               ; 70 - rb
                               ; 75 - rw
                               ; 80 - org
                               ;  0 - guard

                               ; Instructions
                               ; Hash Code
                               ; Class
                               ; Opcodes

inst :
        dw     6800            ; mov
        dw     10
        dw     136             ; 0x0088

        dw     5472            ; add
        dw     10
        dw     512             ; 0x0200

        dw     7440            ; sub
        dw     10
        dw     1064            ; 0x0428

        dw     5774            ; cmp
        dw     10
        dw     1592            ; 0x0638

        dw     696             ; or
        dw     10
      ; dw     1544            ; 0x0808 ; Error
        dw     2056            ; 0x0808

        dw     5572            ; and
        dw     10
      ; dw     2080            ; 0x0A20 ; Error
        dw     2592            ; 0x0A20

        dw     6850            ; mul
        dw     20
        dw     57590           ; 0xE0F6

        dw     5840            ; div
        dw     20
        dw     61686           ; 0xF0F6

        dw     6371            ; inc
        dw     25
        dw     64              ; 0x0040

        dw     5781            ; dec
        dw     25
        dw     72              ; 0x0048

        dw     6090            ; push
        dw     30
        dw     80              ; 0x0050

        dw     7094            ; pop
        dw     30
        dw     88              ; 0x0058

        dw     6388            ; int
        dw     35
        dw     205             ; 0x00CD

        dw     6506            ; retn
        dw     40
        dw     195             ; 0x00C3

        dw     6474            ; jmp
        dw     45
        dw     233             ; 0x00E9

        dw     56560           ; call
        dw     45
        dw     232             ; 0x00E8

      ; dw     64807           ; jmps
      ; dw     50
      ; dw     235             ; 0x00EB

        dw     630             ; jb
        dw     50
        dw     114             ; 0x0072

        dw     631             ; jc
        dw     50
        dw     114             ; 0x0072

        dw     6353            ; jbe
        dw     50
        dw     118             ; 0x0076

        dw     633             ; je
        dw     50
        dw     116             ; 0x0074

        dw     6473            ; jne
        dw     50
        dw     117             ; 0x0075

        dw     6343            ; jae
        dw     50
        dw     115             ; 0x0073

        dw     6471            ; jnc
        dw     50
        dw     115             ; 0x0073

        dw     629             ; ja
        dw     50
        dw     119             ; 0x0077

        dw     5752            ; cld
        dw     55
        dw     252             ; 0x00FC

        dw     13560           ; lodsb
        dw     55
        dw     172             ; 0x00AC

        dw     13581           ; lodsw
        dw     55
        dw     173             ; 0x00AD

        dw     24124           ; stosb
        dw     55
        dw     170             ; 0x00AA

        dw     24145           ; stosw
        dw     55
        dw     171             ; 0x00AB

        dw     570             ; db
        dw     60
        dw     0

        dw     591             ; dw
        dw     65
        dw     0

        dw     710             ; rb
        dw     70
        dw     0

        dw     731             ; rw
        dw     75
        dw     0

        dw     7015            ; org
        dw     80
        dw     0

        dw     0               ; Guard
        dw     0
        dw     0

                               ; Patch for reg-imm
reg_imm :
      ; dw     49351           ; 0xC0C7 ; mov
        dw     49350           ; 0xC0C6 ; mov
        dw     49281           ; 0xC081 ; add
        dw     59521           ; 0xE881 ; sub
        dw     63617           ; 0xF881 ; cmp
        dw     51329           ; 0xC881 ; or
        dw     57473           ; 0xE081 ; and

                               ; Patch for acc-imm
acc_imm :
        dw     0               ; 0x0000 ; mov
        dw     4               ; 0x0004 ; add
        dw     44              ; 0x002C ; sub
        dw     60              ; 0x003C ; cmp
        dw     12              ; 0x000C ; or
        dw     36              ; 0x0024 ; and

                               ; Registers
                               ; Hash Code
                               ; Code

regs :
        dw     210             ; AX
        dw     0

        dw     220             ; BX
        dw     18179           ; 0x4703

        dw     230             ; CX
        dw     1

        dw     240             ; DX
        dw     2

        dw     212             ; BP
        dw     17925           ; 0x4605

        dw     375             ; SI
        dw     17414           ; 0x4406

        dw     225             ; DI
        dw     17671           ; 0x4507

        dw     198             ; AL
        dw     32768           ; 0x8000

        dw     194             ; AH
        dw     32772           ; 0x8004

        dw     228             ; DL
        dw     32770           ; 0x8002

        dw     0               ; Guard
        dw     0

hnd :
        rw     1

text :
        rb     1024

nText :
        rw     1

pText :
        rw     1

lno :                          ; Line number
        rw     1

nf :                           ; Number flag
        rw     1

csz :                          ; Code size
        rw     1

                               ; Hash Code
                               ; Ofs
                               ; Line no
lbl :
        rw     6144            ; 6 * 1024

                               ; Lbl
                               ; IP
ref :
        rw     4096            ; 4 * 1024


code :
        rb     8192
