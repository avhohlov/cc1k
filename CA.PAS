(*
// Pseudo C compiler based on initial version of Tiny Context compiler (http://avhohlov.narod.ru/p1805en.htm)
// To compile with gcc or bcc32 replace all functions from open() to halt() with #include "C.INC"
// and change main() function return type to int
//
// Modified and reformatted for compatibility with cc1k
//
// (C) Andrei V. Khokhlov
*)

var
  Txt   : array  [ 0 .. 1023 ] of char ;
  pText : integer ;
  nText : integer ;
  nLine : integer ;

  Code  : array [ 0 .. 32767 ] of byte ;
  nCode : integer ;

  hFile : integer ;

  Heap  : array [ 0 .. 2047 ] of char ;
  pHeap : integer ;
  nHeap : integer ;

  nData : integer ;

  Name  : array [ 0 .. 127 ] of integer ;
  Cls   : array [ 0 .. 127 ] of integer ;
  Typ   : array [ 0 .. 127 ] of integer ;
  Size  : array [ 0 .. 127 ] of integer ;
  Ofs   : array [ 0 .. 127 ] of integer ;
  pName : integer ;
  nName : integer ;

  Stk   : array  [ 0 .. 31 ] of integer ;
  pStk  : integer ;

  Buff  : array  [ 0 .. 255 ] of char;
  pBuff : integer ;


function  fopen : integer ;
var
  R : integer ;
begin
  inline   ( 180 /   61 ) ;             (* asm db     0xB4 , 0x3D ;               // mov  AH, 0x3D *)
  inline   ( 176 /    0 ) ;             (* asm db     0xB0 , 0x00 ;               // mov  AL, 0 *)
  inline   ( 186 ) ;                    (* asm db     0xBA ;                      // mov  DX, &Heap *)
  inline   ( Heap ) ;
  inline   ( 131 /  194 /   62 ) ;      (* asm db     0x83 , 0xC2 , 0x3E ;        // add  DX, 62 *)
  inline   ( 205 /   33 ) ;             (* asm db     0xCD , 0x21 ;               // int  0x21 *)
  inline   ( 137 /   70 /  252 ) ;      (* asm db     0x89 , 0x46 , 0xFC ;        // mov  R , AX *)

  fopen := R ;
end ;


function  fcreate : integer ;
var
  R : integer ;
begin
  inline   ( 180 /   60 ) ;             (* asm db     0xB4 , 0x3C ;               // mov  AH, 0x3C *)
  inline   ( 185 /    0 /    0 ) ;      (* asm db     0xB9, 0x00, 0x00 ;          // mov  CX, 0 *)
  inline   ( 186 ) ;                    (* asm db     0xBA ;                      // mov  DX, &Heap *)
  inline   ( Heap ) ;
  inline   ( 131 /  194 /   66 ) ;      (* asm db     0x83 , 0xC2 , 0x42 ;        // add  DX, 66 *)
  inline   ( 205 /   33 ) ;             (* asm db     0xCD , 0x21 ;               // int  0x21 *)
  inline   ( 137 /   70 /  252 ) ;      (* asm db     0x89 , 0x46 , 0xFC ;        // mov  R , AX *)

  fcreate := R
end ;


function  fread : integer ;
var
  R : integer ;
begin
  inline   ( 180 /   63 ) ;             (* asm db     0xB4 , 0x3F ;               // mov  AH, 0x3F *)
  inline   ( 139 /   30 ) ;             (* asm db     0x8B , 0x1E ;               // mov  BX, hFile *)
  inline   ( hFile ) ;
  inline   ( 185 /    0 /    4 ) ;      (* asm db     0xB9 , 0x00 , 0x04 ;        // mov  CX, 1024 *)
  inline   ( 186 ) ;                    (* asm db     0xBA ;                      // mov  DX, &Text *)
  inline   ( Txt ) ;
  inline   ( 205 /   33 ) ;             (* asm db     0xCD , 0x21 ;               // int  0x21 *)
  inline   ( 137 /   70 /  252 ) ;      (* asm db     0x89 , 0x46 , 0xFC ;        // mov  R , AX *)

  fread := R
end ;


procedure fwrite ;
begin
  inline   ( 180 /   64 ) ;             (* asm db     0xB4 , 0x40 ;               // mov  AH, 0x40 *)
  inline   ( 139 /   30 ) ;             (* asm db     0x8B , 0x1E ;               // mov  BX, hFile *)
  inline   ( hFile ) ;
  inline   ( 139 /   14 ) ;             (* asm db     0x8B , 0x0E ;               // mov  CX, nCode *)
  inline   ( nCode ) ;
  inline   ( 186 /    6 /   28 ) ;      (* asm db     0xBA , 0x06 , 0x1C ;        // mov  DX, &Code *)
  inline   ( 186 ) ;                    (* asm db     0xBA ;                      // mov  DX, &Code *)
  inline   ( Code ) ;
  inline   ( 205 /   33 ) ;             (* asm db     0xCD , 0x21 ;               // int  0x21 *)
end ;


procedure fclose ;
begin
  inline   ( 180 /   62 ) ;             (* asm db     0xB4 , 0x3E ;               // mov  AH, 0x3E *)
  inline   ( 139 /   30 ) ;             (* asm db     0x8B , 0x1E ;               // mov  BX, hFile *)
  inline   ( hFile ) ;
  inline   ( 205 /   33 ) ;             (* asm db     0xCD , 0x21 ;               // int  0x21 *)
end ;


var
  C1 : integer ;

procedure  putchr ;
begin
  inline   ( 139 /   22  ) ;           (* asm db     0x8A , 0x16 ;               // mov  DL, Chr *)
  inline   ( C1 ) ;
  inline   ( 180 /    2 ) ;            (* asm db     0xB4 , 0x02 ;               // mov  AH, 0x02 *)
  inline   ( 205 /   33 ) ;            (* asm db     0xCD , 0x21 ;               // int  0x21 *)
end ;


procedure  halt ;
begin
  inline   ( 184 /    0 /   76 ) ;     (* asm db     0xB8 , 0x00 , 0x4C ;        // mov  AX, 0x4C00 *)
  inline   ( 205 /   33 ) ;            (* asm db     0xCD , 0x21 ;               // int  0x21 *)
end ;


procedure  Init ;
begin
  Heap [  0 ] := '0' ;
  Heap [  1 ] := '1' ;
  Heap [  2 ] := '2' ;
  Heap [  3 ] := '3' ;
  Heap [  4 ] := '4' ;
  Heap [  5 ] := '5' ;
  Heap [  6 ] := '6' ;
  Heap [  7 ] := '7' ;
  Heap [  8 ] := '8' ;
  Heap [  9 ] := '9' ;
  Heap [ 10 ] := 'A' ;
  Heap [ 11 ] := 'B' ;
  Heap [ 12 ] := 'C' ;
  Heap [ 13 ] := 'D' ;
  Heap [ 14 ] := 'E' ;
  Heap [ 15 ] := 'F' ;

  Heap [ 16 ] := 'c' ;
  Heap [ 17 ] := 'h' ;
  Heap [ 18 ] := 'a' ;
  Heap [ 19 ] := 'r' ;
  Heap [ 20 ] :=  char ( 0 ) ;

  Heap [ 21 ] := 'u' ;
  Heap [ 22 ] := 'n' ;
  Heap [ 23 ] := 's' ;
  Heap [ 24 ] := 'i' ;
  Heap [ 25 ] := 'g' ;
  Heap [ 26 ] := 'n' ;
  Heap [ 27 ] := 'e' ;
  Heap [ 28 ] := 'd' ;
  Heap [ 29 ] :=  char ( 0 ) ;

  Heap [ 30 ] := '{' ;
  Heap [ 31 ] :=  char ( 0 ) ;

  Heap [ 32 ] := 'i' ;
  Heap [ 33 ] := 'f' ;
  Heap [ 34 ] :=  char ( 0 ) ;

  Heap [ 35 ] := 'e' ;
  Heap [ 36 ] := 'l' ;
  Heap [ 37 ] := 's' ;
  Heap [ 38 ] := 'e' ;
  Heap [ 39 ] :=  char ( 0 ) ;

  Heap [ 40 ] := 'w' ;
  Heap [ 41 ] := 'h' ;
  Heap [ 42 ] := 'i' ;
  Heap [ 43 ] := 'l' ;
  Heap [ 44 ] := 'e' ;
  Heap [ 45 ] :=  char ( 0 ) ;

  Heap [ 46 ] := 'a' ;
  Heap [ 47 ] := 's' ;
  Heap [ 48 ] := 'm' ;
  Heap [ 49 ] :=  char ( 0 ) ;

  Heap [ 50 ] := 'r' ;
  Heap [ 51 ] := 'e' ;
  Heap [ 52 ] := 't' ;
  Heap [ 53 ] := 'u' ;
  Heap [ 54 ] := 'r' ;
  Heap [ 55 ] := 'n' ;
  Heap [ 56 ] :=  char ( 0 ) ;

  Heap [ 57 ] := 'm' ;
  Heap [ 58 ] := 'a' ;
  Heap [ 59 ] := 'i' ;
  Heap [ 60 ] := 'n' ;
  Heap [ 61 ] :=  char ( 0 ) ;

  Heap [ 62 ] := 'C' ;
  Heap [ 63 ] := '.' ;
  Heap [ 64 ] := 'C' ;
  Heap [ 65 ] :=  char ( 0 ) ;

  Heap [ 66 ] := 'C' ;
  Heap [ 67 ] := '.' ;
  Heap [ 68 ] := 'C' ;
  Heap [ 69 ] := 'O' ;
  Heap [ 70 ] := 'M' ;
  Heap [ 71 ] :=  char ( 0 ) ;

  nHeap := 72 ;

  Name [  0 ] :=  16 ;
  Cls  [  0 ] :=  1 ;
  Size [  0 ] :=  1 ;

  Name [  1 ] :=  21 ;
  Cls  [  1 ] :=  1 ;
  Size [  1 ] :=  2 ;

  Name [  2 ] :=  30 ;                     (* { *)
  Cls  [  2 ] :=  0 ;

  Name [  3 ] :=  32 ;                     (* if *)
  Cls  [  3 ] :=  0 ;

  Name [  4 ] :=  40 ;                     (* while *)
  Cls  [  4 ] :=  0 ;

  Name [  5 ] :=  46 ;                     (* asm *)
  Cls  [  5 ] :=  0 ;

  Name [  6 ] :=  50 ;                     (* return *)
  Cls  [  6 ] :=  0 ;

  nName := 7 ;

  pStk  := 0 ;
  nCode := 0 ;
end ;


var
  I : integer ;

procedure  Push ;
begin
  Stk [ pStk ] := I ;
  pStk := pStk + 1 ;
end ;


function  Pop : integer ;
begin
  pStk := pStk - 1 ;
  Pop := Stk [ pStk ] ;
end ;


procedure  Stop ;
begin
  pStk := 0 ;
  while ( nLine <> 0 ) do
  begin
    I := nLine mod 10 ;
    Push ;

    nLine := nLine div 10 ;
  end ;

  while ( pStk <> 0 ) do
  begin
    C1 := Pop + 48 ;
    putchr ;
  end ;

  fclose ;
  halt  ;
end ;

var
  E : integer ;
  J : integer ;
  K : integer ;
  N : integer ;

function val : integer ;
begin
  E := 10 ;
  J :=  0 ;
  if ( Buff [ 0 ] = '0' ) then
    if ( Buff [ 1 ] = 'x' ) then
    begin
      E := 16 ;
      J :=  2 ;
    end ;

  N := 0 ;
  while ( Buff [ J ]  <> char ( 0 ) ) do
  begin
    K := 0 ;
    while ( Heap [ K ]  <> Buff [ J ]  ) do
    begin
      if ( K = E ) then
        Stop ;

      K := K + 1 ;
    end ;

    N := E * N ;
    N := N + K ;
    J := J + 1 ;
  end ;

  val := N ;
end ;


function  Look : char ;
begin
  if ( pText >= nText ) then
  begin
    pText  := 0 ;
    nText  := fread ;
  end ;

  if ( pText >= nText ) then
    Look := char ( 0 )
  else
    Look := Txt [ pText ]
end ;


procedure  Next ;
begin
(* if ( pText < nText ) then
    write( Txt [pText ] ) ; *)
  pText := pText + 1 ;
end ;


procedure  Read ;
begin
  Buff [ pBuff ]  :=  Look ;
  pBuff       := pBuff + 1 ;

  Next ;
end ;


function  isalphanum : integer ;
begin
  isalphanum := 1;
  if ( 'A' <= Look  ) then
    if ( Look <=  'Z' ) then
      isalphanum := 0 ;

  if ( 'a' <= Look  ) then
    if ( Look <=  'z' ) then
      isalphanum := 0 ;

  if ( '0' <= Look  ) then
    if ( Look <=  '9' ) then
      isalphanum := 0 ;
end ;


var
  sFlag : integer ;

procedure  Scan ;
begin
  pBuff := 0 ;
  while ( pBuff = 0 ) do
  begin
    sFlag := 0 ;
    while ( sFlag = 0 ) do
    begin
      if      ( Look = char ( 9 ) ) then
        Next
      else if ( Look = char (10 ) ) then
      begin
        nLine := nLine + 1 ;
        Next
      end
      else if ( Look = char ( 13 ) ) then
        Next
      else if ( Look = char ( 32 ) ) then
        Next
      else
        sFlag := 1 ;
    end ;

    while ( isalphanum = 0 ) do
      Read ;

    if ( pBuff = 0 ) then
    begin
      Read ;

      if      ( Buff [ 0 ] = '<' ) then
      begin
        if ( Look = '='  ) then
          Read ;
      end
      else if ( Buff [ 0 ] = '!' )  then
      begin
        if ( Look = '='  ) then
          Read ;
      end
      else if ( Buff [ 0 ] = '=' ) then
      begin
        if ( Look = '='  ) then
          Read ;
      end
      else if ( Buff [ 0 ] = '>' ) then
      begin
        if ( Look = '='  ) then
          Read ;
      end
      else if ( Buff [ 0 ] = '/' ) then
      begin
        if ( Look = '/' ) then
        begin
          while ( Look  <>  char ( 10 ) ) do
          begin
            if ( Look = char ( 0 ) ) then
              Stop ;

            Next ;
          end ;

          pBuff := 0 ;
        end
      end
    end
  end ;

  Buff [ pBuff ]  :=  char ( 0 ) ;
end ;


function  Comp : integer ;
begin
  Comp  := 1;
  pBuff := 0 ;
  while ( Buff [ pBuff ] = Heap [ pHeap ] ) do
  begin
    if ( Buff [ pBuff ] = char ( 0 ) ) then
      Comp := 0 ;

    pHeap := pHeap + 1 ;
    pBuff := pBuff + 1 ;
  end
end ;


function  Find : integer ;
begin
  Find  := nName ;
  pName := 0 ;
  while ( pName < nName ) do
  begin
    pHeap := Name [ pName ] ;
    if ( Comp = 0 ) then
      Find := pName ;

    pName    := pName + 1 ;
  end
end ;


var
  C : integer ;

procedure  Emit1 ;
begin
  Code [ nCode ] := C ;
  nCode := nCode + 1 ;
end ;


procedure  Emit2 ;
begin
(* C := N mod 256 ; *)
  C := Lo ( N ) ;
  Emit1 ;
(* C := N div 256 ; *)
  C := Hi ( N ) ;
  Emit1 ;
end ;

var
  Dummy : char ;

function  Konst : integer ;
begin
  Konst := 1;
  if ( '0' <= Buff [ 0 ] ) then
    if ( Buff [ 0 ] <= '9' ) then
    begin
      N :=  val ;
      Konst := 0 ;
    end ;

  if ( Buff [ 0 ] = char ( 39 ) ) then
  begin
    N := integer ( Look ) ;

    Next ;
    Dummy := Look ;
    Next ;

    Konst := 0 ;
  end
end ;


procedure  Shlft ;
begin
  if ( Size [ Typ [ I ] ] = 2 ) then
  begin
    C := 209 ;                             (* 0xD1 // shl  BX, 1 *)
    Emit1 ;
    C := 227 ;                             (* 0xE3 *)
    Emit1 ;
  end
end ;


procedure  Call ;
begin
  Scan ;                                   (* ( *)
  Scan ;                                   (* ) *)

  C := 232 ;                               (* 0xE8 // call Ofs *)
  N := nCode + 3 ;                         (* N := ( 0xFFFF - ( ( nCode + 3 ) - Ofs [ I ] ) ) + 1 ; *)
  N := N - Ofs [ I ] ;
  N := $FFFF - N ;
  N := N + 1 ;
  Emit1 ;
  Emit2 ;
end ;


procedure  Expr ;
begin
  if      ( Konst = 0 ) then
  begin
    C := 184 ;                             (* 0xB8 // mov  AX, Val *)
    Emit1 ;
    Emit2 ;
  end
  else if ( Buff [ 0 ] = '(' ) then
  begin
    Scan ;
    Expr ;
  end
  else
  begin
    I            := Find ;
    if      ( I = nName ) then
      Stop
    else if ( Cls [ I ] = 2 ) then
    begin
      if ( Size [ I ]  <> 1 ) then
      begin
        Push ;
        Scan ;                             (* [ *)
        Scan ;
        Expr ;
        I := Pop ;

        C := 147 ;                         (* 0x93 // xchg BX, AX *)
        Emit1 ;
        Shlft   ;
      end ;

      C := 139 ;                           (* 0x8B // mov  AX,  [ ( BX +  ) Ofs ] *)
      if ( Size [ Typ [ I ] ] = 1 ) then
      begin
        C := 50 ;                          (* 0x32 // xor  AH, AH *)
        Emit1 ;
        C := 228 ;                         (* 0xE4 *)
        Emit1 ;

        C := 138 ;                         (* 0x8A // mov  AL,  [ ( BX +  ) Ofs ] *)
      end ;

      Emit1 ;

      C := 6 ;                             (* 0x06 //  [ Ofs ] *)
      if ( Size [ I ]  <> 1 ) then
        C := 135 ;                         (* 0x87 //  [ BX + Ofs ] *)

      Emit1 ;

      N := Ofs [ I ] ;
      Ofs [ I ] := nCode ;
      Emit2 ;
    end
    else if ( Cls [ I ] = 3 ) then
      Call
    else
      Stop ;
  end ;

  Scan ;
  if      ( Buff [ 0 ] = '+' ) then
    I := 1
  else if ( Buff [ 0 ] = '-' ) then
    I := 2
  else if ( Buff [ 0 ] = '*' ) then
    I := 3
  else if ( Buff [ 0 ] = '/' ) then
    I := 4
  else if ( Buff [ 0 ] = '%' ) then
    I := 5
  else
    I := 0 ;

  if ( I <> 0 ) then
  begin

  C := 80 ;                                (* 0x50 // push AX *)
  Emit1 ;

  Push  ;
  Scan  ;
  Expr  ;
  I := Pop ;

  C := 91 ;                                (* 0x5B // pop  BX *)
  Emit1 ;

  C := 147 ;                               (* 0x93 // xchg BX, AX *)
  Emit1 ;

  if      ( I = 1 ) then
  begin
    C := 3 ;                               (* 0x03 // add  AX, BX *)
    Emit1 ;
    C := 195 ;                             (* 0xC3 *)
    Emit1 ;
  end
  else if ( I = 2 ) then
  begin
    C := 43 ;                              (* 0x2B // sub  AX, BX *)
    Emit1 ;
    C := 195 ;                             (* 0xC3 *)
    Emit1 ;
  end
  else if ( I = 3 ) then
  begin
    C := 247 ;                             (* 0xF7 // mul  BX *)
    Emit1 ;
    C := 227 ;                             (* 0xE3 *)
    Emit1 ;
  end
  else
  begin
    C := 51 ;                              (* 0x33 // xor  DX, DX *)
    Emit1 ;
    C := 210 ;                             (* 0xD2 *)
    Emit1 ;

    C := 247 ;                             (* 0xF7 // div  BX *)
    Emit1 ;
    C := 243 ;                             (* 0xF3 *)
    Emit1 ;

    if ( I = 5 ) then
    begin
      C := 146 ;                           (* 0x92 // xchg DX, AX *)
      Emit1 ;
    end
  end

  end
end ;


var
  jCode : integer ;

procedure  Cond ;
begin
  Scan ;
  Expr ;

  if      ( Buff [ 0 ] = '<' ) then
  begin
    jCode := 114 ;                         (* 0x72 // jb   Ofs *)
    if ( Buff [ 1 ] = '='  ) then
      jCode := 118 ;                       (* 0x76 // jbe  Ofs *)
  end
  else if ( Buff [ 0 ] = '='  ) then
    jCode := 116                           (* 0x74 // je   Ofs *)
  else if ( Buff [ 0 ] = '!' ) then
    jCode := 117                           (* 0x75 // jne  Ofs *)
  else if ( Buff [ 0 ] = '>' ) then
  begin
    jCode := 119 ;                         (* 0x77 // ja   Ofs *)
    if ( Buff [ 1 ] = '='  ) then
      jCode := 115 ;                       (* 0x73 // jae  Ofs *)
  end
  else
    Stop ;

  C := 80 ;                                (* 0x50 // push AX *)
  Emit1 ;

  Scan ;
  Expr ;

  C := 91 ;                                (* 0x5B // pop  BX *)
  Emit1 ;

  C := 59 ;                                (* 0x3B // cmp  BX, AX *)
  Emit1 ;
  C := 216 ;                               (* 0xD8 *)
  Emit1 ;

  C := jCode ;                             (* jxx  Ofs *)
  Emit1 ;
  C := 3 ;                                 (* 0x03 *)
  Emit1 ;

  I := nCode ;
  Push ;

  C := 233 ;                               (* 0xE9 // jmp  ? *)
  Emit1 ;
  nCode := nCode + 2 ;
end ;


procedure  Patch ;
begin
  N := nCode - I ;                         (* N := ( nCode - I ) - 3 ; *)
  N := N - 3 ;

(* Code [ I + 1 ]  := N mod 256 ; *)
   Code [ I + 1 ]  := Lo ( N ) ;
(* Code [ I + 2 ]  := N div 256 ; *)
   Code [ I + 2 ]  := Hi ( N ) ;
end ;


procedure  Ctrl ;
begin
  I            :=  Find ;
  if      ( I >= nName ) then
    Stop
  else if ( I = 2 ) then                   (* { *)
  begin
    Scan ;
    Ctrl ;
    while ( Buff [ 0 ] <>  '}' ) do
      Ctrl ;

    Scan ;
  end
  else if ( I = 3 ) then                   (* if *)
  begin
    Scan ;                                 (* ( *)
    Cond ;

    Scan ;
    Ctrl ;

    pHeap := 35 ;                          (* else *)
    if ( Comp = 0 ) then
    begin
      C := 233 ;                           (* 0xE9 // jmp  ? *)
      Emit1 ;
      nCode := nCode + 2 ;

      I := Pop ;

      Patch ;

      I := nCode - 3 ;
      Push ;

      Scan ;
      Ctrl ;
    end ;

    I := Pop ;

    Patch ;
  end
  else if ( I = 4 ) then                   (* while *)
  begin
    I := nCode ;
    Push ;

    Scan ;                                 (* ( *)
    Cond ;

    Scan ;
    Ctrl ;

    I := Pop ;

    C := 233 ;                             (* 0xE9 // jmp  Ofs *)
    N := nCode + 3 ;                       (* N := ( 0xFFFF - ( ( nCode + 3 ) - Pop ) ) + 1 ; *)
    N := N - Pop ;
    N := $FFFF - N ;
    N := N + 1 ;
    Emit1 ;
    Emit2 ;

    Patch ;
  end
  else if ( I = 5 ) then                   (* asm *)
  begin
    Scan ;                                 (* db *)

    if ( Buff [ 1 ] = 'w' ) then           (* dw *)
    begin
      Scan ;                               (* offset *)
      Scan ;
      I           :=  Find ;
      if     ( I >= nName ) then
        Stop ;

      N := Ofs [ I ] ;
      Ofs [ I ] := nCode ;
      Emit2 ;

      Scan ;                               (* ; *)
    end
    else
    begin
      Buff [ 0 ]   :=  ',' ;
      while ( Buff [ 0 ] = ',' ) do
      begin
        Scan  ;
        C := val ;                         (* db   Val *)
        Emit1 ;

        Scan  ;
      end
    end ;

    Scan ;
  end
  else if ( I = 6 ) then                   (* return *)
  begin
    Scan ;
    Expr ;

    C := 195 ;                             (* 0xC3 // retn *)
    Emit1 ;

    Scan ;
  end
  else if ( Cls [ I ] = 2 ) then
  begin
    Push ;

    if ( Size [ I ]  <> 1 ) then
    begin
      Scan ;                               (* [ *)
      Scan ;
      Expr ;

      C := 80 ;                            (* 0x50 // push AX *)
      Emit1 ;
    end ;

    Scan ;                                 (* = *)
    Scan ;
    Expr ;

    I := Pop ;

    if ( Size [ I ]  <> 1 ) then
    begin
      C := 91 ;                            (* 0x5B // pop  BX *)
      Emit1 ;
      Shlft ;
    end ;

    C := 137 ;                             (* 0x89 // mov  [ ( BX + ) Ofs ] , AX *)
    if  ( Size [ Typ [ I ] ] = 1 ) then
      C := 136 ;                           (* 0x88 // mov  [ ( BX + ) Ofs ] , AL *)

    Emit1 ;

    C := 6 ;                               (* 0x06 //  [ Ofs ] *)
    if ( Size [ I ]  <> 1 ) then
      C := 135 ;                           (* 0x87 //  [ BX + Ofs ] *)

    Emit1 ;

    N := Ofs [ I ] ;
    Ofs   [ I ]  := nCode ;
    Emit2 ;

    Scan ;
  end
  else if ( Cls [ I ] = 3 ) then
  begin
    Call ;
    Scan ;
    Scan ;
  end
  else
    Stop ;
end ;

var
  J1 : integer ;

procedure  AssignOfs ;
begin
  nData := nCode +  256 ;                  (* nData := ( ( ( nCode + 256 ) + 1023 ) / 1024 ) * 1024 ; *)
  nData := nData + 1023 ;
  nData := nData div 1024 ;
  nData := nData * 1024 ;

  I := 0 ;
  while ( I < nName ) do
  begin
    if ( Cls [ I ] = 2 ) then
    begin
      J := Ofs  [ I ] ;
      while ( J <> 0 ) do
      begin
        J1 := J + 1 ;
        K  := Code [ J ]  + 256 ;
        N  := Code [ J1 ] + 256 ;          (* N := Code [ J + 1 ]  + 256 ; *)

     (* Code [ J ]  := nData mod 256 ; *)
        Code [ J ]  := Lo ( nData ) ;
     (* Code [ J1 ] := nData div 256 ; *)  (* Code [ J + 1 ]  := nData / 256 ; *)
        Code [ J1 ] := Hi ( nData );

        J := N mod 256 ;                   (* J := ( 256 * ( N % 256 ) ) + ( K % 256 ) ; *)
        J := J * 256 ;
     (* K := K div 256 ; *)
        K := K mod 256 ;
        J := J + K ;
      end ;

      N := Size [ Typ [ I ] ] * Size [ I ] ;
      while ( N mod 2 <> 0 ) do
        N := N + 1 ;

      nData := nData + N ;
    end ;

    I := I + 1 ;
  end
end ;


var
  mFlag : integer ;

procedure  Compile ;
begin
  C := 233 ;                               (* 0xE9 // jmp  ? *)
  Emit1 ;
  nCode := nCode + 2 ;

  Scan ;

  mFlag := 0 ;
  while ( mFlag = 0 ) do
  begin
    I := Find ;
    if ( I = nName ) then
      Stop ;

    if ( Cls [ I ] <> 1 ) then
      Stop ;

    Name [ nName ] := nHeap ;
    Typ  [ nName ] :=  I ;
    Ofs  [ nName ] :=  0 ;

    Scan ;
    if ( Find < nName ) then
      Stop ;

    pHeap := 57 ;                          (* main *)
    if ( Comp = 0 ) then
    begin
      N          := nCode - 3 ;
   (* Code [ 1 ] :=  N mod 256 ; *)
      Code [ 1 ] :=  Lo ( N ) ;
   (* Code [ 2 ] :=  N div 256 ; *)
      Code [ 2 ] :=  Hi ( N ) ;

      mFlag   :=  1 ;
    end ;

    pBuff := 0 ;
    while ( Buff [ pBuff ]  <> char ( 0 ) ) do
    begin
      Heap [ nHeap ] :=  Buff [ pBuff ] ;
      nHeap          := nHeap + 1 ;
      pBuff          := pBuff + 1 ;
    end ;

    Heap [ nHeap ] := char ( 0 ) ;
    nHeap          := nHeap + 1 ;

    Scan ;
    if ( Buff [ 0 ] = '(' ) then
    begin
      Cls  [ nName ] :=  3 ;
      Ofs  [ nName ] := nCode ;
      nName          := nName + 1 ;

      Scan ;                          (* void *)
      Scan ;                          (* ) *)
      Scan ;                          (* { *)
      if ( Buff [ 0 ] <>  '{' ) then
        Stop ;

      Ctrl ;

      C := 195 ;                           (* 0xC3 // retn *)
      Emit1 ;
    end
    else
    begin
      if ( mFlag <> 0 ) then
        Stop ;

      Cls  [ nName ] := 2 ;
      Size [ nName ] := 1 ;

      if ( Buff [ 0 ] = '[' ) then
      begin
        Scan ;
        Size [ nName ] := val ;
        Scan ;                             (* ] *)
        Scan ;                             (* ; *)
      end ;

      nName := nName + 1 ;

      Scan ;
    end
  end ;

  AssignOfs ;
end ;


begin
  Init ;

  hFile:= fopen ;
  pText := 0 ;
  nText := 0 ;
  nLine := 1 ;

  Compile ;

  fclose ;

  hFile := fcreate ;
  fwrite ;
  fclose ;
end .
