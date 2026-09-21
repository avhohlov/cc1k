      ; Simplified asm version of Pseudo C compiler (https://sourceforge.net/projects/pseudo-c-compiler)
      ; To compile initial C version it must be modified:
      ; 1. All words and symbols must be separated by spaces
      ;    For example, Init(); statement must be replaced
      ;    with Init<space>(<space>)<space>;
      ; 2. All hexadecimal constants must be repaced
      ;    with the same decimal constants
      ; 3. May be need to change data offset (dsz initial value)
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

                               ; Compiling
      ; mov    AX ,    16640   ; INFO Depend on compiled program code size - see C.C/AssignOfs()
        mov    AX ,    6144
        mov    BX ,    dsz
        mov  [ BX ] ,  AX
        mov    AX ,    1
        mov    BX ,    lno
        mov  [ BX ] ,  AX      ; Line = 1
        mov    SI ,    dict    ; nDict
        mov    DI ,    code    ; nCode

        cld

        mov    AX ,    233     ; jmp
        stosb
        stosw                  ; Reserved for ofs

        call   get_tok         ; Type

compile :
        or     CX ,    CX
        jne    chk_type
        jmp    halt

chk_type :
        mov    AX ,    1
        cmp    CX ,    57156   ; char
        je     char_type
        inc    AX              ; int  / word

char_type :
        push   AX
        call   get_tok         ; Name
        push   CX

        call   get_tok         ; Semicolon / square bracket / round bracket

        pop    DX              ; Name
        mov  [ SI ] ,  DX
        inc    SI
        inc    SI

        pop    AX              ; Size
        mov  [ SI ] ,  AX
        inc    SI
        inc    SI

        cmp    CX ,    65528   ; Round bracket (opening)
        jne    add_var
        jmp    compile_fn

add_var :
        cmp    CX ,    43      ; Square bracket (opening)
        jne    simple_var
        push   AX              ; Size
        call   get_tok         ; Array size
        pop    AX

        mul    CX              ; AX = Array Size

        push   AX
      ; call   get_tok         ; Square bracket (closing)
      ; call   get_tok         ; Semicolon INFO Error - omitted
        call   get_tok_2
        pop    AX

simple_var :
        mov    BX ,    dsz
        mov    DX ,  [ BX ]

        mov  [ SI ] ,  DX      ; Data offset
        inc    SI
        inc    SI

        mov    CX ,    AX
        and    CX ,    1
        je     align_2
        inc    AX

align_2 :
        add    DX ,    AX
        mov  [ BX ] ,  DX

        call   get_tok

        jmp    compile

compile_fn :
        push   DX              ; Name
        push   DI              ; Code offset

        mov  [ SI ] ,  DI      ; Code offset
        inc    SI
        inc    SI

      ; call   get_tok         ; Round bracket (closing)
      ; call   get_tok         ; void
      ; call   get_tok
        call   get_tok_3
      ; cmp    CX ,    75      ; Curly bracket (opening)
      ; je     process_stmt
      ; jmp    halt

process_stmt :
        call   stmt            ; Next token available

        mov    AX ,    195     ; retn
        stosb

        pop    AX              ; Code Offset
        pop    DX              ; Name
        cmp    DX ,    996     ; main
        je     compile_end
        jmp    compile

compile_end :
        mov    BX ,    code
        inc    BX
        mov    CX ,    BX
        inc    CX
        inc    CX
        sub    AX ,    CX
        mov  [ BX ] ,  AX

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
      ; mov    BX ,    hnd
      ; mov  [ BX ] ,  AX
        mov    BX ,    AX

      ; mov    AH ,    64      ; 0x40
        mov    AX ,    16384
      ; mov    BX ,  [ hnd ]   ; TODO   mov    BX ,  pred AX
      ; mov    BX ,    hnd
      ; mov    BX ,  [ BX ]
        mov    CX ,    DI
        mov    DX ,    code
        sub    CX ,    DX
        int    33              ; 0x21

      ; mov    AH ,    62      ; 0x3E
        mov    AX ,    15872
      ; mov    BX ,  [ hnd ]
      ; mov    BX ,    hnd
      ; mov    BX ,  [ BX ]
        int    33              ; 0x21

        retn

                               ; Statement
stmt :
        cmp    CX ,    75      ; Curly bracket (opening)
        jne    do_if

        call   get_tok
        jmp    chk_blk_end

do_stmt :
        call   stmt

chk_blk_end :
        cmp    CX ,    77      ; Curly bracket (closing)
        jne    do_stmt

      ; call   get_tok

      ; retn

        jmp    get_tok

do_if :
        cmp    CX ,    624     ; if
        jne    do_while

        call   cond

        push   BX              ; bypass jmp ofs

        call   get_tok
        call   stmt

        cmp    CX ,    59723   ; else
        jne    no_else

        mov    AX ,    233     ; jmp
        stosb
        mov    DX ,    DI
        stosw                  ; Reserved for ofs

        pop    BX

      ; mov    AX ,    DI
      ; sub    AX ,    BX
      ; dec    AX
      ; dec    AX
      ; mov  [ BX ] ,  AX

        call   patch

        push   DX

        call   get_tok
        call   stmt

no_else :
        pop    BX

      ; mov    AX ,    DI
      ; sub    AX ,    BX
      ; dec    AX
      ; dec    AX
      ; mov  [ BX ] ,  AX

        call   patch

      ; call   get_tok         ; INFO Error

        retn

do_while :
        cmp    CX ,    51457   ; while
        jne    do_asm

        push   DI              ; while ofs

        call   cond

        push   BX              ; bypass jmp ofs

        call   get_tok
        call   stmt

        pop    BX
        pop    DX              ; while ofs

        mov    AX ,    233     ; jmp
        stosb
        sub    DX ,    DI
        dec    DX
        dec    DX
        mov    AX ,    DX
        stosw

      ; mov    AX ,    DI
      ; sub    AX ,    BX
      ; dec    AX
      ; dec    AX
      ; mov  [ BX ] ,  AX

        call   patch

      ; call   get_tok         ; INFO Error

        retn

do_asm :
        cmp    CX ,    5631    ; asm
        jne    do_return
        call   get_tok         ; db

        mov    CX ,    65532   ; ,
        jmp    comma_cmp

asm_loop :
        call   get_tok
        mov    AX ,    CX
        stosb

        call   get_tok

comma_cmp :
        cmp    CX ,    65532
        je     asm_loop

      ; call   get_tok

      ; retn

        jmp    get_tok

do_return :
        cmp    CX ,    62198   ; return
        jne    do_assign

        call   get_tok
        call   expr

        mov    AX ,    195     ; retn
        stosb

      ; call   get_tok

      ; retn

        jmp    get_tok

do_assign :
        call   find_name

      ; push   BX
      ; call   get_tok
      ; pop    BX

      ; inc    BX
      ; inc    BX
      ; mov    DX ,  [ BX ]    ; Size

      ; inc    BX
      ; inc    BX
      ; mov    BX ,  [ BX ]    ; Ofs

        cmp    CX ,    65528   ; Round bracket (opening)
        jne    store_to_var

      ; mov    AX ,    232     ; 0xE8 call
      ; stosb

      ; sub    BX ,    DI
      ; dec    BX
      ; dec    BX
      ; mov    AX ,    BX
      ; stosw

      ; call   get_tok         ; Round bracket (closing)
      ; call   get_tok         ; Semicolon

        call   call_fn
      ; call   get_tok

      ; retn

        jmp    get_tok

store_to_var :
        cmp    CX ,    43      ; Square bracket (opening)
        jne    store_to_simple_var

        push   BX
        push   DX

        call   get_tok         ; INFO Omitted
        call   expr

      ; pop    DX
      ; pop    BX

        mov    AX ,    80      ; 0x50 push AX
        stosb

      ; push   BX              ; TODO Extra push/pop
      ; push   DX

      ; call   get_tok         ; =
      ; call   get_tok
        call   get_tok_2
        call   expr

        pop    DX
        pop    BX

      ; mov    AX ,    88      ; 0x58 pop  BX ; INFO Error
        mov    AX ,    91      ; 0x5B pop  BX
        stosb

        cmp    DX ,    1
        je     no_shift_1
        mov    AX ,    58321   ; 0xE3D1 shl  BX, 1
        stosw

no_shift_1 :
        mov    CX ,    135     ; 0x87 [BX+Ofs]

        jmp    store_any

store_to_simple_var :
        push   BX
        push   DX

        call   get_tok
        call   expr

        pop    DX
        pop    BX

        mov    CX ,    6       ; [Ofs]

store_any :
        mov    AX ,    136     ; 0x88
        cmp    DX ,    1
        je     store_to_any_2
        inc    AX

store_to_any_2 :
      ; stosw                  ; INFO Error
        stosb

        mov    AX ,    CX      ; mod-reg-rm
      ; stosw                  ; INFO Error
        stosb

      ; mov    AX ,    DX      ; INFO Error
        mov    AX ,    BX
        stosw

      ; call   get_tok

      ; retn

        jmp    get_tok


patch :
        mov    AX ,    DI
        sub    AX ,    BX
        dec    AX
        dec    AX
        mov  [ BX ] ,  AX

        retn

                               ; If/While Condition
cond :
      ; call   get_tok         ; Round bracket (opening)
      ; call   get_tok
        call   get_tok_2
        call   expr            ; CX = < , <= , ...

        push   CX

        mov    AX ,    80      ; 0x50 push AX
        stosb

        call   get_tok
        call   expr            ; CX = )

      ; mov    AX ,    88      ; 0x58 pop  BX ; INFO Error
        mov    AX ,    91      ; 0x5B pop  BX
        stosb

        pop    CX

        mov    BX ,    cond_tab

cond_loop :
        mov    AX ,  [ BX ]
        or     AX ,    AX
        jne    cmp_cond_op
        jmp    halt

cmp_cond_op :
        cmp    AX ,    CX
        je     do_cond

        add    BX ,    4

        jmp    cond_loop

do_cond :
        mov    AX ,    55355   ; 0xD83B  cmp  BX, AX
      ; stosb                  ; INFO Error
        stosw

        inc    BX
        inc    BX
        mov    AX ,  [ BX ]    ; Opcode
        stosw

        mov    AX ,    233     ; jmp
        stosb
        mov    BX ,    DI
        stosw                  ; Reserved for ofs

        retn

                               ; Expression
expr :
        call   operand

        mov    BX ,    oper_tab

oper_loop :
        mov    AX ,  [ BX ]
        or     AX ,    AX
        jne    cmp_oper
        retn

cmp_oper :
        cmp    AX ,    CX
        je     do_oper

        add    BX ,    4

      ; jmp    cond_loop       ; INFO Error
        jmp    oper_loop

do_oper :
        mov    AX ,    80     ; 0x50 push AX
        stosb

        push   BX

        call   get_tok
        call   operand

        pop    BX

        push   CX              ; INFO Omitted

        mov    AX ,    91      ; 0x5B pop  BX
        stosb

        mov    CX ,  [ BX ]    ; Oper

        inc    BX
        inc    BX
        mov    DX ,  [ BX ]    ; Opcode

        mov    AX ,    147     ; 0x93 xchg AX, BX
        stosb

        mov    AX ,    53811   ; 0xD233 xor  DX, DX
        cmp    DX ,    62455   ; 0xF3F7 div  BX
        jne    not_div_mod
        stosw

not_div_mod :
        mov    AX ,    DX
        stosw

        cmp    CX ,    65525   ; %
        jne    no_xchg
        mov    AX ,    146     ; 0x92 xchg AX, DX
        stosb

no_xchg :
        pop   CX               ; INFO Omitted

        retn

                               ; Operand
operand :
        mov    BX ,    nf
        mov    AX ,  [ BX ]
        or     AX ,    AX
        je     var_or_fn

        mov    AX ,    184     ; 0xB8 mov  AX, Val
        stosb
        mov    AX ,    CX
        stosw

      ; call   get_tok         ; TODO jmp  get_token

      ; retn

        jmp    get_tok

var_or_fn :
        call   find_name

      ; push   BX
      ; call   get_tok
      ; pop    BX

      ; inc    BX
      ; inc    BX
      ; mov    DX ,  [ BX ]    ; Size

      ; inc    BX
      ; inc    BX
      ; mov    BX ,  [ BX ]    ; Ofs

        cmp    CX ,    65528   ; Round bracket (opening)
        jne    load_var

      ; mov    AX ,    232     ; 0xE8 call
      ; stosb

      ; sub    BX ,    DI
      ; dec    BX
      ; dec    BX
      ; mov    AX ,    BX
      ; stosw

      ; call   get_tok         ; Round bracket (closing) ; INFO Omitted
      ; call   get_tok

      ; retn

        jmp    call_fn

load_var :
        push   CX              ; INFO Omitted

        cmp    CX ,    43      ; Square bracket (opening)
        mov    CX ,    6       ; [Ofs]
        jne    load_var_1

        push   BX
        push   DX

        call   get_tok         ; INFO Omitted
        call   operand
        call   get_tok         ; INFO Omitted

        pop    DX
        pop    BX

        pop    AX              ; FIXME Check and improve
        push   CX

        mov    AX ,    147     ; 0x93 xchg AX, BX
        stosb

        cmp    DX ,    1
      ; jne    no_shift_2      ; INFO Error
        je     no_shift_2
        mov    AX ,    58321   ; 0xE3D1 shl  BX, 1
        stosw                  ; INFO Omitted

no_shift_2 :
        mov    CX ,    135     ; 0x87 [BX+Ofs]

load_var_1 :
      ; cmp    BX ,    1       ; INFO Error
        cmp    DX ,    1
        jne    word_value
        mov    AX ,    58418   ; 0xE432 xor AH, AH
        stosw

word_value :
        mov    AX ,    138     ; 0x8A
        cmp    DX ,    1
      ; jne    load_var_2      ; INFO Error
        je     load_var_2
        inc    AX

load_var_2 :
        stosb

        mov    AX ,    CX      ; mod-reg-rm
      ; stosw                  ; INFO Error
        stosb

        mov    AX ,    BX      ; Ofs
        stosw

      ; call   get_tok         ; INFO Error

        pop    CX              ; INFO Omitted

        retn


call_fn :
        mov    AX ,    232     ; 0xE8 call
        stosb

        sub    BX ,    DI
        dec    BX
        dec    BX
        mov    AX ,    BX
        stosw

      ; call   get_tok         ; Round bracket (closing)
      ; call   get_tok         ; Semicolon / bracket / operator
      ; call   get_tok_2

      ; retn

        jmp    get_tok_2


find_name :
        mov    BX ,    dict

find_name_loop :
        cmp    BX ,    SI
        jb     compare
        jmp    halt

compare :
        mov    DX ,  [ BX ]
        cmp    DX ,    CX
        jne    next_name

        push   BX
        call   get_tok
        pop    BX

        inc    BX
        inc    BX
        mov    DX ,  [ BX ]    ; Size

        inc    BX
        inc    BX
        mov    BX ,  [ BX ]    ; Ofs

        retn

next_name :
        add    BX ,    6

        jmp    find_name_loop


get_tok_3 :
        call   get_tok

get_tok_2 :
        call   get_tok

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
      ; mov    DX ,    1
        inc    DX

ident :
        mov    BX ,    nf
        mov  [ BX ] ,  DX

        cmp    AX ,    37      ; %
        jne    chk_char

        mov    CX ,    65525   ; 37 - 48
        retn

chk_char :
        cmp    AX ,    39      ; Char
        jne    tok_next

      ; inc    DX
        mov    DX ,    1
        mov  [ BX ] ,  DX      ; TODO Improve

        call   getc
        push   AX
        call   getc            ; '
        pop    CX

        retn

tok_next :
      ; mov    BX ,    AX      ; INFO Error
        push   AX              ; Pred char

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

        pop    DX              ; Pred char

      ; cmp    AL ,    32
        cmp    AX ,    32
        ja     tok_next

        mov    AX ,    BX

        mov    BX ,    nf
        mov    BX ,  [ BX ]
        or     BX ,    BX
        je     chk_rem
        retn

chk_rem :
        cmp    CX ,    65525   ; INFO Conflict // with %
        je     remark
        retn

remark :
        call   getc

        or     AX ,    AX
        jne    not_eof
        jmp    get_tok

not_eof :
        cmp    AX ,    10
        jne    remark

        jmp    eol

not_lf :
        jmp    get_tok


getc :
      ; mov    AH ,     63     ; 0x3F
        mov    AX ,     16128
      ; mov    BX ,   [ hnd ]
        mov    BX ,     hnd
        mov    BX ,   [ BX ]
        mov    CX ,     1
        mov    DX ,     buf
        int    33              ; 0x21

                               ; TODO   Check CF

        or     AX ,     AX
        je     eof
      ; mov    AL ,   [ buf]
        mov    BX ,     buf
        mov    AL ,   [ BX ]

      ; push   AX
      ; mov    DX ,     AX
      ; call   putc
      ; pop    AX

eof :
        retn


halt :
        call   newln

        mov    BX ,     lno
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


oper_tab :
        dw     65531           ; +
        dw     49923           ; 0xC303

        dw     65533           ; -
        dw     49963           ; 0xC32B

        dw     65530           ; *
        dw     58359           ; 0xE3F7

        dw     65535           ; /
        dw     62455           ; 0xF3F7

        dw     65525           ; %
        dw     62455           ; 0xF3F7

        dw     0
        dw     0

cond_tab :
        dw     12              ; <
        dw     882

        dw     133             ; <=
        dw     886

        dw     143             ; ==
        dw     884

      ; dw     65339           ; != ; INFO Error
        dw     65399           ; !=
        dw     885

        dw     153             ; >=
        dw     883

        dw     14              ; >
        dw     887

        dw     0
        dw     0

src :
        db     67              ; C.C
        db     46
        db     67
        db     0

dst :
        db     67              ; C.COM
        db     46
        db     67
        db     79
        db     77
        db     0

hnd :
        rw     1

buf :
        rw     1               ; TODO rb?

dsz :
        rw     1               ; Data size

lno :                          ; Line number
        rw     1

nf :                           ; Number flag
        rw     1

                               ; Hash Code
                               ; Size (char = 1 / word = 2)
                               ; Ofs
dict :
        rw     3072            ; 6 * 512

code :
        rb     8192
