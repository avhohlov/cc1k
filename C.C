// Pseudo C compiler based on initial version of Tiny Context compiler (http://avhohlov.narod.ru/p1805en.htm)
// To compile with gcc or bcc32 replace all functions from open() to halt() with #include "C.INC"
// and change main() function return type to int
//
// Modified and reformatted for compatibility with cc1k
//
// (C) Andrei V. Khokhlov

char      Text  [  1024 ] ;
unsigned pText ;
unsigned nText ;
unsigned nLine ;

char      Code  [ 49152 ] ;
unsigned nCode ;

unsigned hFile ;

char      Heap  [  2048 ] ;
unsigned pHeap ;
unsigned nHeap ;

unsigned nData ;

unsigned  Name  [   128 ] ;
unsigned  Cls   [   128 ] ;
unsigned  Type  [   128 ] ;
unsigned  Size  [   128 ] ;
unsigned  Ofs   [   128 ] ;
unsigned pName ;
unsigned nName ;

unsigned  Stk   [    32 ] ;
unsigned pStk ;

char      Buff  [   256 ] ;
unsigned pBuff ;

unsigned  open ( void )
{
  asm db       180 ,   61 ;               // asm db     0xB4 , 0x3D ;               // mov  AH, 0x3D
  asm db       176 ,    0 ;               // asm db     0xB0 , 0x00 ;               // mov  AL, 0
// asm db      186 ,   72 ,  220 ;        // asm db     0xBA , 0x48 , 0xDC ;        // mov  DX, &Heap[62]
  asm db       186 ;                      // asm db     0xBA ;                      // mov  DX, &Heap
  asm dw       offset   Heap ;
  asm db       131 ,  194 ,   62 ;        // asm db     0x83 , 0xC2 , 0x3E ;        // add  DX, 62
  asm db       205 ,   33 ;               // asm db     0xCD , 0x21 ;               // int  0x21
}


unsigned  create ( void )
{
  asm db       180 ,   60 ;               // asm db     0xB4 , 0x3C ;               // mov  AH, 0x3C
  asm db       185 ,    0 ,    0 ;        // asm db     0xB9 , 0x00 , 0x00 ;        // mov  AL, 0
// asm db      186 ,   76 ,  220 ;        // asm db     0xBA , 0x4C , 0xDC ;        // mov  DX, &Heap[66]
  asm db       186 ;                      // asm db     0xBA ;                      // mov  DX, &Heap
  asm dw       offset   Heap ;
  asm db       131 ,  194 ,   66 ;        // asm db     0x83 , 0xC2 , 0x42 ;        // add  DX, 66
  asm db       205 ,   33 ;               // asm db     0xCD , 0x21 ;               // int  0x21
}


unsigned  read ( void )
{
  asm db       180 ,   63 ;               // asm db     0xB4 , 0x3F ;               // mov  AH, 0x3F
// asm db      139 ,   30 ,    8 ,  220 ; // asm db     0x8B , 0x1E , 0x08 , 0xDC ; // mov  BX, hFile
  asm db       139 ,   30 ;               // asm db     0x8B , 0x1E ;               // mov  BX, hFile         
  asm dw       offset   hFile ;
  asm db       185 ,    0 ,    4 ;        // asm db     0xB9 , 0x00 , 0x04 ;        // mov  CX, 1024
// asm db      186 ,    0 ,   24 ;        // asm db     0xBA , 0x00 , 0x18 ;        // mov  DX, &Text
  asm db       186 ;                      // asm db     0xBA ;                      // mov  DX, &Text
  asm dw       offset   Text ;
  asm db       205 ,   33 ;               // asm db     0xCD , 0x21 ;               // int  0x21
}


unsigned  write ( void )
{
  asm db       180 ,   64 ;               // asm db     0xB4 , 0x40 ;               // mov  AH, 0x40
// asm db      139 ,   30 ,    8 ,  220 ; // asm db     0x8B , 0x1E , 0x08 , 0xDC ; // mov  BX, hFile
  asm db       139 ,   30 ;               // asm db     0x8B , 0x1E ;               // mov  BX, hFile         
  asm dw       offset   hFile ;
// asm db      139 ,   14 ,    6 ,  220 ; // asm db     0x8B , 0x0E , 0x06 , 0xDC ; // mov  CX, nCode
  asm db       139 ,   14 ;               // asm db     0x8B , 0x0E ;               // mov  CX, nCode
  asm dw       offset   nCode ;
// asm db      186 ,    6 ,   28 ;        // asm db     0xBA , 0x06 , 0x1C ;        // mov  DX, &Code
  asm db       186 ;                      // asm db     0xBA ;                      // mov  DX, &Code
  asm dw       offset   Code ;
  asm db       205 ,   33 ;               // asm db     0xCD , 0x21 ;               // int  0x21
}


unsigned  close ( void )
{
  asm db       180 ,   62 ;               // asm db     0xB4 , 0x3E ;               // mov  AH, 0x3E
// asm db      139 ,   30 ,    8 ,  220 ; // asm db     0x8B , 0x1E , 0x08 , 0xDC ; // mov  BX, hFile
  asm db       139 ,   30 ;               // asm db     0x8B , 0x1E ;               // mov  BX, hFile         
  asm dw       offset   hFile ;
  asm db       205 ,   33 ;               // asm db     0xCD , 0x21 ;               // int  0x21
}


// char      Ch;                          // INFO Space omitted!
char      Chr ;

char      putchr ( void )
{
// asm db      146 ;                      // asm db     0x92 ;                      // xchg DX, AX
  asm db       139 ,   14 ;               // asm db     0x8A , 0x16 ;               // mov  DL, Chr
  asm dw       offset   Chr ;

  asm db       180 ,    2 ;               // asm db     0xB4 , 0x02 ;               // mov  AH, 0x02
  asm db       205 ,   33 ;               // asm db     0xCD , 0x21 ;               // int  0x21
}


unsigned  halt ( void )
{
  asm db       184 ,    0 ,   76 ;        // asm db     0xB8 , 0x00 , 0x4C ;        // mov  AX, 0x4C00
  asm db       205 ,   33 ;               // asm db     0xCD , 0x21 ;               // int  0x21
}


unsigned  Init ( void )
{
  Heap [  0 ] = '0' ;
  Heap [  1 ] = '1' ;
  Heap [  2 ] = '2' ;
  Heap [  3 ] = '3' ;
  Heap [  4 ] = '4' ;
  Heap [  5 ] = '5' ;
  Heap [  6 ] = '6' ;
  Heap [  7 ] = '7' ;
  Heap [  8 ] = '8' ;
  Heap [  9 ] = '9' ;
  Heap [ 10 ] = 'A' ;
  Heap [ 11 ] = 'B' ;
  Heap [ 12 ] = 'C' ;
  Heap [ 13 ] = 'D' ;
  Heap [ 14 ] = 'E' ;
  Heap [ 15 ] = 'F' ;

  Heap [ 16 ] = 'c' ;
  Heap [ 17 ] = 'h' ;
  Heap [ 18 ] = 'a' ;
  Heap [ 19 ] = 'r' ;
  Heap [ 20 ] =  0 ;

  Heap [ 21 ] = 'u' ;
  Heap [ 22 ] = 'n' ;
  Heap [ 23 ] = 's' ;
  Heap [ 24 ] = 'i' ;
  Heap [ 25 ] = 'g' ;
  Heap [ 26 ] = 'n' ;
  Heap [ 27 ] = 'e' ;
  Heap [ 28 ] = 'd' ;
  Heap [ 29 ] =  0 ;

  Heap [ 30 ] = '{' ;
  Heap [ 31 ] =  0 ;

  Heap [ 32 ] = 'i' ;
  Heap [ 33 ] = 'f' ;
  Heap [ 34 ] =  0 ;

  Heap [ 35 ] = 'e' ;
  Heap [ 36 ] = 'l' ;
  Heap [ 37 ] = 's' ;
  Heap [ 38 ] = 'e' ;
  Heap [ 39 ] =  0 ;

  Heap [ 40 ] = 'w' ;
  Heap [ 41 ] = 'h' ;
  Heap [ 42 ] = 'i' ;
  Heap [ 43 ] = 'l' ;
  Heap [ 44 ] = 'e' ;
  Heap [ 45 ] =  0 ;

  Heap [ 46 ] = 'a' ;
  Heap [ 47 ] = 's' ;
  Heap [ 48 ] = 'm' ;
  Heap [ 49 ] =  0 ;

  Heap [ 50 ] = 'r' ;
  Heap [ 51 ] = 'e' ;
  Heap [ 52 ] = 't' ;
  Heap [ 53 ] = 'u' ;
  Heap [ 54 ] = 'r' ;
  Heap [ 55 ] = 'n' ;
  Heap [ 56 ] =  0 ;

  Heap [ 57 ] = 'm' ;
  Heap [ 58 ] = 'a' ;
  Heap [ 59 ] = 'i' ;
  Heap [ 60 ] = 'n' ;
  Heap [ 61 ] =  0 ;

  Heap [ 62 ] = 'C' ;
  Heap [ 63 ] = '.' ;
  Heap [ 64 ] = 'C' ;
  Heap [ 65 ] =  0 ;

  Heap [ 66 ] = 'C' ;
  Heap [ 67 ] = '.' ;
  Heap [ 68 ] = 'C' ;
  Heap [ 69 ] = 'O' ;
  Heap [ 70 ] = 'M' ;
  Heap [ 71 ] =  0 ;

  nHeap = 72 ;

  Name [  0 ] =  16 ;
  Cls  [  0 ] =  1 ;
  Size [  0 ] =  1 ;

  Name [  1 ] =  21 ;
  Cls  [  1 ] =  1 ;
  Size [  1 ] =  2 ;

  Name [  2 ] =  30 ;                     // {
  Cls  [  2 ] =  0 ;

  Name [  3 ] =  32 ;                     // if
  Cls  [  3 ] =  0 ;

  Name [  4 ] =  40 ;                     // while
  Cls  [  4 ] =  0 ;

  Name [  5 ] =  46 ;                     // asm
  Cls  [  5 ] =  0 ;

  Name [  6 ] =  50 ;                     // return
  Cls  [  6 ] =  0 ;

  nName = 7 ;

  pStk  = 0 ;
  nCode = 0 ;
}


unsigned  I ;

unsigned  Push ( void )
{
  Stk [ pStk ] = I ;
  pStk = pStk + 1 ;
}


unsigned  Pop  ( void )
{
  pStk = pStk - 1 ;
  return Stk [ pStk ] ;
}


unsigned  Stop ( void )
{
  pStk = 0 ;
  while ( nLine != 0 )
  {
    I = nLine % 10 ;
    Push ( ) ;

    nLine = nLine / 10 ;
  }

  while ( pStk != 0 )
  {
  // Ch = Pop ( )  + 48 ;
    Chr = Pop ( )  + 48 ;
    putchr ( ) ;
  }

  close ( ) ;
  halt  ( ) ;
}


unsigned  E ;
unsigned  J ;
unsigned  K ;
unsigned  N ;

unsigned  val  ( void )
{
  E = 10 ;
  J =  0 ;
  if ( Buff [ 0 ] == '0' )
    if ( Buff [ 1 ] == 'x' )
    {
      E = 16 ;
      J =  2 ;
    }

  N = 0 ;
  while ( Buff [ J ]  != 0 )
  {
    K = 0 ;
    while ( Heap [ K ]  != Buff [ J ]  )
    {
      if ( K == E )
        Stop ( ) ;

      K = K + 1 ;
    }

 // N =  ( E * N )  + K ;
    N = E * N ;
    N = N + K ;
    J = J + 1 ;
  }

  return N ;
}


char      Look ( void )
{
  if ( pText >= nText )
  {
    pText  = 0 ;
    nText  = read ( ) ;
  }

  if ( pText >= nText )
    return 0 ;

  return   Text [ pText ] ;
}


unsigned  Next ( void )
{
  pText = pText + 1 ;
}


char      Read ( void )
{
  Buff [ pBuff ]  =  Look ( ) ;
  pBuff       = pBuff + 1 ;

  Next ( ) ;
}


unsigned  isalphanum ( void )
{
  if ( 'A' <= Look ( )  )
    if ( Look ( ) <=  'Z' )
      return 0 ;

  if ( 'a' <= Look ( )  )
    if ( Look ( ) <=  'z' )
      return 0 ;

  if ( '0' <= Look ( )  )
    if ( Look ( ) <=  '9' )
      return 0 ;

  return     1 ;
}


unsigned sFlag ;

char      Scan ( void )
{
  pBuff = 0 ;
  while ( pBuff == 0 )
  {
    sFlag = 0 ;
    while ( sFlag == 0 )
    {
      if      ( Look ( ) == 9 )
        Next ( ) ;
      else if ( Look ( ) == 10 )
      {
        nLine = nLine + 1 ;
        Next ( ) ;
      }
      else if ( Look ( ) == 13 )
        Next ( ) ;
      else if ( Look ( ) == 32 )
        Next ( ) ;
      else
        sFlag = 1 ;
    }

    while ( isalphanum ( ) == 0 )
      Read ( ) ;

    if ( pBuff == 0 )
    {
      Read ( ) ;

      if      ( Buff [ 0 ] == '<' )
      {
        if ( Look ( ) == '='  )
          Read ( ) ;
      }
      else if ( Buff [ 0 ] == '!' )
      {
        if ( Look ( ) == '='  )
          Read ( ) ;
      }
      else if ( Buff [ 0 ] == '=' )
      {
        if ( Look ( ) == '='  )
          Read ( ) ;
      }
      else if ( Buff [ 0 ] == '>' )
      {
        if ( Look ( ) == '='  )
          Read ( ) ;
      }
      else if ( Buff [ 0 ] == '/' )
      {
        if ( Look ( ) == '/' )
        {
          while ( Look ( )  !=  10 )
          {
            if ( Look ( ) == 0 )
              Stop ( ) ;

            Next ( ) ;
          }

          pBuff = 0 ;
        }
      }
    }
  }

  Buff [ pBuff ]  =  0 ;
}


unsigned  Comp ( void )
{
  pBuff = 0 ;
  while ( Buff [ pBuff ] == Heap [ pHeap ] )
  {
    if ( Buff [ pBuff ] == 0 )
      return    0 ;

    pHeap = pHeap + 1 ;
    pBuff = pBuff + 1 ;
  }

  return        1 ;
}


unsigned  Find ( void )
{
  pName = 0 ;
  while ( pName < nName )
  {
    pHeap = Name [ pName ] ;
    if ( Comp ( ) == 0 )
      return pName ;

    pName    = pName + 1 ;
  }

  return     pName ;
}


char      C ;

char      Emit1 ( void )
{
  Code [ nCode ] = C ;
  nCode = nCode + 1 ;
}


unsigned  Emit2 ( void )
{
  C = N % 256 ;
  Emit1 ( ) ;
  C = N / 256 ;
  Emit1 ( ) ;
}


unsigned  Const ( void )
{
  if ( '0' <= Buff [ 0 ] )
    if ( Buff [ 0 ] <= '9' )
    {
      N =  val ( ) ;
      return 0 ;
    }

  if ( Buff [ 0 ] == 39 )
  {
    N = Look ( ) ;

    Next ( ) ;
    Look ( ) ;
    Next ( ) ;

    return   0 ;
  }

  return     1 ;
}


unsigned  Shl  ( void )
{
  if ( Size [ Type [ I ] ] == 2 )
  {
    C = 209 ;                             // 0xD1 // shl  BX, 1
    Emit1 ( ) ;
    C = 227 ;                             // 0xE3
    Emit1 ( ) ;
  }
}


unsigned  Call ( void )
{
  Scan ( ) ;                              // (
  Scan ( ) ;                              // )

  C = 232 ;                               // 0xE8 // call Ofs
  N = nCode + 3 ;                         // N = ( 0xFFFF - ( ( nCode + 3 ) - Ofs [ I ] ) ) + 1 ;
  N = N - Ofs [ I ] ;
  N = 65535 - N ;
  N = N + 1 ;
  Emit1 ( ) ;
  Emit2 ( ) ;
}


unsigned  Expr ( void )
{
  if      ( Const ( ) == 0 )
  {
    C = 184 ;                             // 0xB8 // mov  AX, Val
    Emit1 ( ) ;
    Emit2 ( ) ;
  }
  else if ( Buff [ 0 ] == '(' )
  {
    Scan ( ) ;
    Expr ( ) ;
  }
  else
  {
    I            = Find ( ) ;
    if      ( I == nName )
      Stop ( ) ;
    else if ( Cls [ I ] == 2 )
    {
      if ( Size [ I ]  != 1 )
      {
        Push ( ) ;
        Scan ( ) ;                        //  [
        Scan ( ) ;
        Expr ( ) ;
        I = Pop ( ) ;

        C = 147 ;                         // 0x93 // xchg BX, AX
        Emit1 ( ) ;
        Shl   ( ) ;
      }

      C = 139 ;                           // 0x8B // mov  AX,  [ ( BX +  ) Ofs ]
      if ( Size [ Type [ I ] ] == 1 )
      {
        C = 50 ;                          // 0x32 // xor  AH, AH
        Emit1 ( ) ;
        C = 228 ;                         // 0xE4
        Emit1 ( ) ;

        C = 138 ;                         // 0x8A // mov  AL,  [ ( BX +  ) Ofs ]
      }

      Emit1 ( ) ;

      C = 6 ;                             // 0x06 //  [ Ofs ]
      if ( Size [ I ]  != 1 )
        C = 135 ;                         // 0x87 //  [ BX + Ofs ]

      Emit1 ( ) ;

      N = Ofs [ I ] ;
      Ofs [ I ] = nCode ;
      Emit2 ( ) ;
    }
    else if ( Cls [ I ] == 3 )
      Call ( ) ;
    else
      Stop ( ) ;
  }

  Scan ( ) ;
  if      ( Buff [ 0 ] == '+' )
    I = 1 ;
  else if ( Buff [ 0 ] == '-' )
    I = 2 ;
  else if ( Buff [ 0 ] == '*' )
    I = 3 ;
  else if ( Buff [ 0 ] == '/' )
    I = 4 ;
  else if ( Buff [ 0 ] == '%' )
    I = 5 ;
  else
    return 0 ;

  C = 80 ;                                // 0x50 // push AX
  Emit1 ( ) ;

  Push  ( ) ;
  Scan  ( ) ;
  Expr  ( ) ;
  I = Pop ( ) ;

  C = 91 ;                                // 0x5B // pop  BX
  Emit1 ( ) ;

  C = 147 ;                               // 0x93 // xchg BX, AX
  Emit1 ( ) ;

  if      ( I == 1 )
  {
    C = 3 ;                               // 0x03 // add  AX, BX
    Emit1 ( ) ;
    C = 195 ;                             // 0xC3
    Emit1 ( ) ;
  }
  else if ( I == 2 )
  {
 // C = 147 ;                             // 0x93 // xchg BX, AX
 // Emit1 ( ) ;

    C = 43 ;                              // 0x2B // sub  AX, BX
    Emit1 ( ) ;
    C = 195 ;                             // 0xC3
    Emit1 ( ) ;
  }
  else if ( I == 3 )
  {
    C = 247 ;                             // 0xF7 // mul  BX
    Emit1 ( ) ;
    C = 227 ;                             // 0xE3
    Emit1 ( ) ;
  }
  else
  {
 // C = 147 ;                             // 0x93 // xchg BX, AX
 // Emit1 ( ) ;

    C = 51 ;                              // 0x33 // xor  DX, DX
    Emit1 ( ) ;
    C = 210 ;                             // 0xD2
    Emit1 ( ) ;

    C = 247 ;                             // 0xF7 // div  BX
    Emit1 ( ) ;
    C = 243 ;                             // 0xF3
    Emit1 ( ) ;

    if ( I == 5 )
    {
      C = 146 ;                           // 0x92 // xchg DX, AX
      Emit1 ( ) ;
    }
  }
}


unsigned jCode ;

unsigned  Cond ( void )
{
  Scan ( ) ;
  Expr ( ) ;

  if      ( Buff [ 0 ] == '<' )
  {
    jCode = 114 ;                         // 0x72 // jb   Ofs
    if ( Buff [ 1 ] == '='  )
      jCode = 118 ;                       // 0x76 // jbe  Ofs
  }
  else if ( Buff [ 0 ] == '='  )
    jCode = 116 ;                         // 0x74 // je   Ofs
  else if ( Buff [ 0 ] == '!' )
    jCode = 117 ;                         // 0x75 // jne  Ofs
  else if ( Buff [ 0 ] == '>' )
  {
    jCode = 119 ;                         // 0x77 // ja   Ofs
    if ( Buff [ 1 ] == '='  )
      jCode = 115 ;                       // 0x73 // jae  Ofs
  }
  else
    Stop ( ) ;

  C = 80 ;                                // 0x50 // push AX
  Emit1 ( ) ;

  Scan ( ) ;
  Expr ( ) ;

  C = 91 ;                                // 0x5B // pop  BX
  Emit1 ( ) ;

  C = 59 ;                                // 0x3B // cmp  BX, AX
  Emit1 ( ) ;
  C = 216 ;                               // 0xD8
  Emit1 ( ) ;

  C = jCode ;                             // jxx  Ofs
  Emit1 ( ) ;
  C = 3 ;                                 // 0x03
  Emit1 ( ) ;

  I = nCode ;
  Push ( ) ;

  C = 233 ;                               // 0xE9 // jmp  ?
  Emit1 ( ) ;
  nCode = nCode + 2 ;
}


unsigned  Patch ( void )
{
  N = nCode - I ;                         // N = ( nCode - I ) - 3 ;
  N = N - 3 ;

  Code [ I + 1 ]  = N % 256 ;
  Code [ I + 2 ]  = N / 256 ;
}


unsigned  Ctrl ( void )
{
  I            =  Find ( ) ;
  if      ( I >= nName )
    Stop ( ) ;
  else if ( I == 2 )                      // {
  {
    Scan ( ) ;
    Ctrl ( ) ;
    while ( Buff [ 0 ] !=  '}' )
      Ctrl ( ) ;

    Scan ( ) ;                            // !!!
  }
  else if ( I == 3 )                      // if
  {
    Scan ( ) ;                            // (
    Cond ( ) ;

    Scan ( ) ;
    Ctrl ( ) ;

    pHeap = 35 ;                          // else
    if ( Comp ( ) == 0 )
    {
      C = 233 ;                           // 0xE9 // jmp  ?
      Emit1 ( ) ;
      nCode = nCode + 2 ;

      I = Pop ( ) ;

      Patch ( ) ;

      I = nCode - 3 ;
      Push ( ) ;

      Scan ( ) ;
      Ctrl ( ) ;
    }

    I = Pop ( ) ;

    Patch ( ) ;
  }
  else if ( I == 4 )                      // while
  {
    I = nCode ;
    Push ( ) ;

    Scan ( ) ;                            // (
    Cond ( ) ;

    Scan ( ) ;
    Ctrl ( ) ;

    I = Pop ( ) ;

    C = 233 ;                             // 0xE9 // jmp  Ofs
    N = nCode + 3 ;                       // N = ( 0xFFFF - ( ( nCode + 3 ) - Pop ( ) ) ) + 1 ;
    N = N - Pop ( ) ;
    N = 65535 - N ;
    N = N + 1 ;
    Emit1 ( ) ;
    Emit2 ( ) ;

    Patch ( ) ;
  }
  else if ( I == 5 )                      // asm
  {
    Scan ( ) ;                            // db

    if ( Buff [ 1 ] == 'w' )              // dw
    {
      Scan ( ) ;                          // offset
      Scan ( ) ;
      I           =  Find ( ) ;
      if     ( I >= nName )
        Stop ( ) ;

      N = Ofs [ I ] ;
      Ofs [ I ] = nCode ;
      Emit2 ( ) ;

      Scan ( ) ;                          // ;
    }
    else
    {
      Buff [ 0 ]   =  ',' ;
      while ( Buff [ 0 ] == ',' )
      {
        Scan  ( ) ;
        C = val ( ) ;                     // db   Val
        Emit1 ( ) ;

        Scan  ( ) ;
      }
    }

    Scan ( ) ;                            // !!!
  }
  else if ( I == 6 )                      // return
  {
    Scan ( ) ;
    Expr ( ) ;

    C = 195 ;                             // 0xC3 // retn
    Emit1 ( ) ;

    Scan ( ) ;                            // !!!
  }
  else if ( Cls [ I ] == 2 )
  {
    Push ( ) ;

    if ( Size [ I ]  != 1 )
    {
      Scan ( ) ;                          // [
      Scan ( ) ;
      Expr ( ) ;

      C = 80 ;                            // 0x50 // push AX
      Emit1 ( ) ;
    }

    Scan ( ) ;                            // =
    Scan ( ) ;
    Expr ( ) ;

    I = Pop ( ) ;

    if ( Size [ I ]  != 1 )
    {
      C = 91 ;                            // 0x5B // pop  BX
      Emit1 ( ) ;
      Shl   ( ) ;
    }

    C = 137 ;                             // 0x89 // mov  [ ( BX + ) Ofs ] , AX
    if  ( Size [ Type [ I ] ] == 1 )
      C = 136 ;                           // 0x88 // mov  [ ( BX + ) Ofs ] , AL

    Emit1 ( ) ;

    C = 6 ;                               // 0x06 //  [ Ofs ]
    if ( Size [ I ]  != 1 )
      C = 135 ;                           // 0x87 //  [ BX + Ofs ]

    Emit1 ( ) ;

    N = Ofs [ I ] ;
    Ofs   [ I ]  = nCode ;
    Emit2 ( ) ;

    Scan ( ) ;                            // !!!
  }
  else if ( Cls [ I ] == 3 )
  {
    Call ( ) ;
    Scan ( ) ;                            // ;
    Scan ( ) ;                            // !!!
  }
  else
    Stop ( ) ;
}

unsigned J1 ;

unsigned  AssignOfs ( void )
{
  nData = nCode +  256 ;                  // nData = ( ( ( nCode + 256 ) + 1023 ) / 1024 ) * 1024 ;
  nData = nData + 1023 ;
  nData = nData / 1024 ;
  nData = nData * 1024 ;

  I = 0 ;
  while ( I < nName )
  {
    if ( Cls [ I ] == 2 )
    {
      J = Ofs  [ I ] ;
      while ( J != 0 )
      {
        J1 = J + 1 ;
        K  = Code [ J ]  + 256 ;
        N  = Code [ J1 ] + 256 ;          // N = Code [ J + 1 ]  + 256 ;

        Code [ J ]  = nData % 256 ;
        Code [ J1 ] = nData / 256 ;       // Code [ J + 1 ]  = nData / 256 ;

        J = N % 256 ;                     // J = ( 256 * ( N % 256 ) ) + ( K % 256 ) ;
        J = J * 256 ;
        K = K % 256 ;
        J = J + K ;
      }

      N = Size [ Type [ I ] ] * Size [ I ] ;
      while ( N % 2 != 0 )
        N = N + 1 ;

      nData = nData + N ;
    }

    I = I + 1 ;
  }
}


unsigned mFlag ;

unsigned  Compile ( void )
{
  C = 233 ;                               // 0xE9 // jmp  ?
  Emit1 ( ) ;
  nCode = nCode + 2 ;

  Scan ( ) ;

  mFlag = 0 ;
  while ( mFlag == 0 )
  {
    I = Find ( ) ;
    if ( I == nName )
      Stop ( ) ;

    if ( Cls [ I ] != 1 )
      Stop ( ) ;

    Name [ nName ] = nHeap ;
    Type [ nName ] =  I ;
    Ofs  [ nName ] =  0 ;

    Scan ( ) ;
    if ( Find ( ) < nName )
      Stop ( ) ;

    pHeap = 57 ;                          // main
    if ( Comp ( ) == 0 )
    {
      N          = nCode - 3 ;
      Code [ 1 ] =  N %  256 ;
      Code [ 2 ] =  N /  256 ;

      mFlag   =  1 ;
    }

    pBuff = 0 ;
    while ( Buff [ pBuff ]  != 0 )
    {
      Heap [ nHeap ] =  Buff [ pBuff ] ;
      nHeap          = nHeap + 1 ;
      pBuff          = pBuff + 1 ;
    }

    Heap [ nHeap ] = 0 ;
    nHeap          = nHeap + 1 ;

    Scan ( ) ;
    if ( Buff [ 0 ] == '(' )
    {
      Cls  [ nName ] =  3 ;
      Ofs  [ nName ] = nCode ;
      nName          = nName + 1 ;

      Scan ( ) ;                          // void
      Scan ( ) ;                          // )
      Scan ( ) ;                          // {
      if ( Buff [ 0 ] !=  '{' )
        Stop ( ) ;

      Ctrl ( ) ;

      C = 195 ;                           // 0xC3 // retn
      Emit1 ( ) ;
    }
    else
    {
      if ( mFlag != 0 )
        Stop ( ) ;

      Cls  [ nName ] = 2 ;
      Size [ nName ] = 1 ;

      if ( Buff [ 0 ] == '[' )
      {
        Scan ( ) ;
        Size [ nName ] = val ( ) ;
        Scan ( ) ;                        // ]
        Scan ( ) ;                        // ;
      }

      nName = nName + 1 ;

      Scan ( ) ;
    }
  }

  AssignOfs ( ) ;
}


unsigned  main ( void )
{
  Init ( ) ;

  hFile = open ( ) ;
  pText = 0 ;
  nText = 0 ;
  nLine = 1 ;

  Compile ( ) ;

  close ( ) ;

  hFile = create ( ) ;
  write ( ) ;
  close ( ) ;
}
