      ; Simplified asm port of Pseudo C compiler (https://sourceforge.net/projects/pseudo-c-compiler)
      ; To compile initial C version it must be modified:
      ; 1. All words and symbols must be separated by spaces
      ;    For example, Init(); statement must be replaced
      ;    with Init<space>(<space>)<space>;
      ; 2. All hexadecimal constants must be repaced
      ;    with the same decimal constants
      ; 3. May be need to change data offset (dsz initial value)
      ;
      ; (C) Andrei V. Khokhlov

        org    256             ; 0x100

        cld

      ; mov    AX ,    16640   ; INFO Depend on compiled program code size - see C.C/AssignOfs()
      ; mov    AX ,    6144    ; FIXME Error - code and data overlap
        mov    AX ,    7168
        mov    DI ,    dsz
      ; mov  [ DI ] ,  AX
        stosw

        mov    AX ,    1
        mov    DI ,    lno
      ; mov  [ DI ] ,  AX      ; Line = 1
        stosw

        sub    AX ,    AX
        mov    DI ,    nText
      ; mov  [ DI ] ,  AX
        stosw                  ; [nText] = 0

        mov    DI ,    pText
      ; mov  [ DI ] ,  AX
        stosw                  ; [pText] = 0

      ; mov    AH ,    61      ; 0x3D ; Open file
      ; mov    AL ,    0
        mov    AX ,    15616
        mov    DX ,    src
        int    33              ; 0x21

        jnc    start
        jmp    halt

start :
    ; ; mov  [ hnd ] , AX
      ; mov    DI ,    hnd
    ; ; mov  [ DI ] ,  AX
      ; stosw
        mov    BX ,    AX      ; File handle
         
        mov    BP ,    dict    ; nDict
        mov    DI ,    code    ; nCode

        mov    AL ,    233     ; jmp
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

        call   find_name
        cmp    SI ,    BP
        jae    new_name
        jmp    halt

new_name :
        call   get_tok         ; Semicolon / square bracket / round bracket

        pop    DX              ; Name
        mov  [ BP ] ,  DX
        inc    BP
        inc    BP

        pop    AX              ; Size
        mov  [ BP ] ,  AX
        inc    BP
        inc    BP

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
        mov    SI ,    dsz
        mov    DX ,  [ SI ]

        mov  [ BP ] ,  DX      ; Data offset
        inc    BP
        inc    BP

        mov    CX ,    AX
        and    CX ,    1
        je     align_2
        inc    AX

align_2 :
        add    DX ,    AX
        mov  [ SI ] ,  DX

        call   get_tok

        jmp    compile

compile_fn :
        push   DX              ; Name
        push   DI              ; Code offset

        mov  [ BP ] ,  DI      ; Code offset
        inc    BP
        inc    BP

      ; call   get_tok         ; void
      ; call   get_tok         ; Round bracket (closing)
        call   get_tok_2
        call   get_tok
        cmp    CX ,    75      ; Curly bracket (opening)
        je     process_stmt
        jmp    halt

process_stmt :
        call   stmt            ; Next token available

        mov    AL ,    195     ; retn
        stosb

        pop    AX              ; Code Offset
        pop    DX              ; Name
        cmp    DX ,    996     ; main
        je     compile_end
        jmp    compile

compile_end :
        mov    SI ,    code
        inc    SI
        mov    CX ,    SI
        inc    CX
        inc    CX
        sub    AX ,    CX
        mov  [ SI ] ,  AX

        mov    AH ,    62      ; 0x3E ; Close file
    ; ; mov    BX ,  [ hnd ]
      ; mov    SI ,    hnd
      ; mov    BX ,  [ SI ]
        int    33              ; 0x21

        mov    AH ,    60      ; 0x3C ; Create file
        mov    CX ,    0
        mov    DX ,    dst
        int    33              ; 0x21

      ; jnc    write
      ; jmp    halt

write:
        mov    BX ,    AX      ; File handle

        mov    AH ,    64      ; 0x40 ; Write file
        mov    CX ,    DI
        mov    DX ,    code
        sub    CX ,    DX
        int    33              ; 0x21

        mov    AH ,    62      ; 0x3E ; Close file
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

        jmp    get_tok

do_if :
        cmp    CX ,    624     ; if
        jne    do_while

        call   cond

        push   SI              ; bypass jmp ofs

        call   get_tok
        call   stmt

        cmp    CX ,    59723   ; else
        jne    no_else

        mov    AL ,    233     ; jmp
        stosb
        mov    DX ,    DI
        stosw                  ; Reserved for ofs

        pop    SI

        call   patch

        push   DX

        call   get_tok
        call   stmt

no_else :
        pop    SI

        call   patch

      ; call   get_tok         ; INFO Error

        retn

do_while :
        cmp    CX ,    51457   ; while
        jne    do_asm

        push   DI              ; while ofs

        call   cond

        push   SI              ; bypass jmp ofs

        call   get_tok
        call   stmt

        pop    SI
        pop    DX              ; while ofs

        mov    AL ,    233     ; jmp
        stosb
        sub    DX ,    DI
        dec    DX
        dec    DX
        mov    AX ,    DX
        stosw

        call   patch

      ; call   get_tok         ; INFO Error

        retn

do_asm :
        cmp    CX ,    5631    ; asm
        jne    do_return
        call   get_tok         ; db/dw
        cmp    CX ,    591     ; dw
        jne    do_db

        call   get_tok_2       ; offset Name
        call   find_and_load   ; AX = Ofs
        stosw

      ; jmp    get_tok_2       ; INFO Error - find_and_load calls get_tok once
      ; call   get_tok

      ; retn

        jmp    get_tok

do_db :
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

        jmp    get_tok

do_return :
        cmp    CX ,    62198   ; return
        jne    do_assign

        call   get_tok
        call   expr

        mov    AL ,    195     ; retn
        stosb

        jmp    get_tok

do_assign :
        call   find_and_load

        cmp    CX ,    65528   ; Round bracket (opening)
        jne    store_to_var

        call   call_fn

        jmp    get_tok

store_to_var :
        push   AX              ; Ofs

        cmp    CX ,    43      ; Square bracket (opening)
        jne    store_to_simple_var

        push   DX              ; Size

        call   get_tok         ; INFO Omitted
        call   expr

        mov    AL ,    80      ; 0x50 push AX
        stosb

      ; call   get_tok         ; =
      ; call   get_tok
        call   get_tok_2
        call   expr

      ; mov    AX ,    88      ; 0x58 pop  SI ; INFO Error
        mov    AL ,    91      ; 0x5B pop  SI
        stosb

        pop    DX

        cmp    DX ,    1
        je     no_shift_1
        mov    AX ,    58321   ; 0xE3D1 shl  BX, 1
        stosw

no_shift_1 :
        mov    CX ,    135     ; 0x87 [SI+Ofs]

        jmp    store_any

store_to_simple_var :
        push   DX

        call   get_tok
        call   expr

        pop    DX

        mov    CX ,    6       ; [Ofs]

store_any :
        mov    AL ,    136     ; 0x88
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
      ; mov    AX ,    SI
        pop    AX              ; Ofs
        stosw

        jmp    get_tok


patch :
        mov    AX ,    DI
        sub    AX ,    SI
        dec    AX
        dec    AX
        mov  [ SI ] ,  AX

        retn

                               ; If/While Condition
cond :
      ; call   get_tok         ; Round bracket (opening)
      ; call   get_tok
        call   get_tok_2
        call   expr            ; CX = < , <= , ...

        push   CX

        mov    AL ,    80      ; 0x50 push AX
        stosb

        call   get_tok
        call   expr            ; CX = )

      ; mov    AX ,    88      ; 0x58 pop  SI ; INFO Error
        mov    AL ,    91      ; 0x5B pop  SI
        stosb

        pop    CX

        mov    SI ,    cond_tab

cond_loop :
      ; mov    AX ,  [ SI ]
        lodsw
        or     AX ,    AX
        jne    cmp_cond_op
        jmp    halt

cmp_cond_op :
        cmp    AX ,    CX
        je     do_cond

      ; add    SI ,    4
        lodsw

        jmp    cond_loop

do_cond :
        mov    AX ,    55355   ; 0xD83B  cmp  BX, AX
      ; stosb                  ; INFO Error
        stosw

      ; inc    SI
      ; inc    SI
      ; mov    AX ,  [ SI ]    ; Opcode
        lodsw
        stosw

        mov    AL ,    233     ; jmp
        stosb
        mov    SI ,    DI
        stosw                  ; Reserved for ofs

        retn

                               ; Expression
expr :
        call   operand

        mov    SI ,    oper_tab

oper_loop :
        lodsw
        or     AX ,    AX
        jne    cmp_oper
        retn

cmp_oper :
        cmp    AX ,    CX
        je     do_oper

        lodsw

      ; jmp    cond_loop       ; INFO Error
        jmp    oper_loop

do_oper :
        mov    AL ,    80      ; 0x50 push AX
        stosb

        push   CX              ; Operator
        push   SI

        call   get_tok
        call   operand         ; CX = next token value

        pop    SI
        pop    DX              ; Operator

        mov    AL ,    91      ; 0x5B pop  BX
        stosb

        mov    AL ,    147     ; 0x93 xchg AX, BX
        stosb

        lodsw                  ; Opcode

        cmp    AX ,    62455   ; 0xF3F7 div  BX
        jne    not_div_mod
        push   AX
        mov    AX ,    53811   ; 0xD233 xor  DX, DX
        stosw
        pop    AX

not_div_mod :
        stosw

        cmp    DX ,    65525   ; %
        jne    no_xchg
        mov    AL ,    146     ; 0x92 xchg AX, DX
        stosb

no_xchg :
        retn

                               ; Operand
operand :
      ; cmp    AL ,    57      ; 9
        cmp    AX ,    57
        ja     var_or_fn

        mov    AL ,    184     ; 0xB8 mov  AX, Val
        stosb
        mov    AX ,    CX
        stosw

      ; call   get_tok         ; TODO jmp  get_token

      ; retn

        jmp    get_tok

var_or_fn :
        call   find_and_load

        cmp    CX ,    65528   ; Round bracket (opening)
        jne    load_var

        jmp    call_fn

load_var :
        push   AX              ; Ofs
        push   CX              ; INFO Omitted

        cmp    CX ,    43      ; Square bracket (opening)
        mov    CX ,    6       ; mod-reg-r/m = [Ofs]
        jne    load_var_1

        pop    CX              ; Discard next token

      ; push   AX
        push   DX

        call   get_tok         ; INFO Omitted
        call   operand
        call   get_tok         ; INFO Omitted

        mov    AL ,    147     ; 0x93 xchg AX, BX
        stosb

        pop    DX              ; Size
      ; pop    SI              ; Ofs

        push   CX

        cmp    DX ,    1
      ; jne    no_shift_2      ; INFO Error
        je     no_shift_2
        mov    AX ,    58321   ; 0xE3D1 shl  BX, 1
        stosw                  ; INFO Omitted

no_shift_2 :
        mov    CX ,    135     ; 0x87 ; mod-reg-r/m = [BX+Ofs]

load_var_1 :
        mov    AL ,    139     ; 0x8B
      ; cmp    SI ,    1       ; INFO Error
        cmp    DX ,    1
        jne    load_var_2
        mov    AX ,    58418   ; 0xE432 xor AH, AH
        stosw
        mov    AL ,    138     ; 0x8A

load_var_2 :
        stosb

        mov    AX ,    CX      ; mod-reg-r/m
      ; stosw                  ; INFO Error
        stosb

        pop    CX

      ; mov    AX ,    SI      ; Ofs
        pop    AX              ; Ofs
        stosw

      ; call   get_tok         ; INFO Error

      ; pop    CX              ; INFO Omitted

        retn


call_fn :
        mov    SI ,    AX      ; Ofs in AX only

        mov    AL ,    232     ; 0xE8 call
        stosb

        sub    SI ,    DI
        dec    SI
        dec    SI
        mov    AX ,    SI
        stosw

      ; call   get_tok         ; Round bracket (closing)
      ; call   get_tok         ; Semicolon / bracket / operator
      ; call   get_tok_2

      ; retn

        jmp    get_tok_2


find_and_load :
        call   find_name
        cmp    SI ,    BP
        jb     load_size_ofs
        jmp    halt

load_size_ofs :
        push   SI
        call   get_tok
        pop    SI

      ; inc    SI
      ; inc    SI
      ; mov    DX ,  [ SI ]    ; Size
        lodsw
        mov    DX ,    AX

      ; inc    SI
      ; inc    SI
      ; mov    SI ,  [ SI ]    ; Ofs
        lodsw

        retn


find_name :
        mov    SI ,    dict

find_name_loop :
        cmp    SI ,    BP
        jb     compare
        retn

compare :
      ; mov    DX ,  [ SI ]
        lodsw
      ; cmp    DX ,    CX
        cmp    AX ,    CX
        jne    next_name

        retn

next_name :
      ; add    SI ,    6
        lodsw
        lodsw

        jmp    find_name_loop


get_tok_2 :
        call   get_tok

                               ; AL = First Char or 0
                               ; CX = Hash Code
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
        mov    SI ,    lno
        mov    DX ,  [ SI ]
        inc    DX
      ; add    DX ,    1
      ; mov  [ lno ] , DX
        mov  [ SI ] ,  DX
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
        cmp    AX ,    37      ; %
        jne    chk_char

        mov    CX ,    65525   ; 37 - 48
        retn

chk_char :
        cmp    AX ,    39      ; Char
        jne    tok_next

        push   AX
        call   getc
        push   AX
        call   getc            ; '
        pop    CX
        pop    AX

        retn

tok_next :
        push   AX              ; First Char

tok_loop :
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
        ja     tok_loop

        pop    AX              ; First Char

        cmp    AX ,    47      ; /
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
        mov    SI ,     nText

      ; mov    AX ,   [ SI ]
        lodsw

        mov    SI ,     pText
        mov    DX ,   [ SI ]
        cmp    DX ,     AX
        jb     ready

      ; push   BX

        mov    AH ,     63     ; 0x3F ; Read file
      ; mov    BX ,     hnd
      ; mov    BX ,   [ BX ]
        mov    CX ,     1024
        mov    DX ,     text
        int    33              ; 0x21

      ; pop    BX

                               ; TODO   Check CF

        mov    SI ,     nText
        mov  [ SI ] ,   AX

        sub    DX ,     DX
        cmp    DX ,     AX
        jae    set_ptext

ready :
        mov    SI ,     text
        add    SI ,     DX
        sub    AX ,     AX     ; FIXME
      ; mov    AL ,   [ SI ]
        lodsb
        inc    DX

set_ptext :
        mov    SI ,     pText
        mov  [ SI ] ,   DX

      ; push   AX
      ; mov    DX ,     AX
      ; call   putc
      ; pop    AX

        retn


halt :
        call   newln

        mov    SI ,     lno
        mov    DX ,   [ SI ]
        call   info

        mov    AX ,     19456  ; 0x4C00
        int    33              ; 0x21

newln :
      ; mov    DX ,     13
        mov    DL ,     13
        call   putc
      ; mov    DX ,     10
        mov    DL ,     10
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
        mov    AH ,     2
      ; mov    AX ,     512    ; AH = 2
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
      ; dw     0               ; INFO Unnecessary

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
      ; dw     0               ; INFO Unnecessary

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
      ; rw     1

text :
        rb     1024

nText :
        rw     1

pText :
        rw     1

dsz :
        rw     1               ; Data size

lno :                          ; Line number
        rw     1
                               ; Hash Code
                               ; Size (char = 1 / word = 2)
                               ; Ofs
dict :
        rw     3072            ; 6 * 512

code :
        rb     6912
