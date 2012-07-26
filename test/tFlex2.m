MODULE tFlex2;

(*<<
3
4
12
4
5
4
5
30
4
4
5
5
6
6
>>*)

IMPORT Out;

TYPE Matrix = ARRAY OF ARRAY OF INTEGER;

PROCEDURE Foo(VAR m: Matrix);
  VAR i, j: INTEGER;
BEGIN
  Out.Int(LEN(m), 0); Out.Ln;
  Out.Int(LEN(m, 2), 0); Out.Ln;

  FOR i := 0 TO LEN(m, 1)-1 DO
    FOR j := 0 TO LEN(m, 2)-1 DO
      m[i][j] := (i+2)*(j+2)
    END
  END
END Foo;

PROCEDURE p(VAR v: ARRAY OF INTEGER);
BEGIN
  Out.Int(LEN(v), 0); Out.Ln
END p;

PROCEDURE q(VAR m: Matrix);
BEGIN
  p(m[0]); 
  Out.Int(LEN(m[0]), 0); Out.Ln
END q;

VAR mm: ARRAY 3 OF ARRAY 4 OF INTEGER;
  tt: POINTER TO Matrix;
  uu: POINTER TO ARRAY OF Matrix;

BEGIN
  Foo(mm);
  Out.Int(mm[1][2], 0); Out.Ln;

  NEW(tt, 4, 5);
  Foo(tt^);
  Out.Int(LEN(tt^), 0); Out.Ln;
  Out.Int(LEN(tt^, 2), 0); Out.Ln;
  Out.Int(tt[3][4], 0); Out.Ln;

  q(mm); q(tt^);

  NEW(uu, 4, 5, 6); q(uu[1]);
END tFlex2.

(*[[
!! SYMFILE #tFlex2 STAMP #tFlex2.%main 1
!! END STAMP
!! 
MODULE tFlex2 STAMP 0
IMPORT Out STAMP
ENDHDR

PROC tFlex2.Foo 4 5 0x00100001
! PROCEDURE Foo(VAR m: Matrix);
!   Out.Int(LEN(m), 0); Out.Ln;
CONST 0
LDLW 16
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
!   Out.Int(LEN(m, 2), 0); Out.Ln;
CONST 0
LDLW 20
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
!   FOR i := 0 TO LEN(m, 1)-1 DO
LDLW 16
DEC
STLW -12
CONST 0
STLW -4
JUMP 2
LABEL 1
!     FOR j := 0 TO LEN(m, 2)-1 DO
LDLW 20
DEC
STLW -16
CONST 0
STLW -8
JUMP 4
LABEL 3
!       m[i][j] := (i+2)*(j+2)
LDLW -4
CONST 2
PLUS
LDLW -8
CONST 2
PLUS
TIMES
LDLW 12
LDLW -4
LDLW 16
BOUND 32
LDLW 20
TIMES
LDLW -8
LDLW 20
BOUND 32
PLUS
STIW
!     FOR j := 0 TO LEN(m, 2)-1 DO
INCL -8
LABEL 4
LDLW -8
LDLW -16
JLEQ 3
!   FOR i := 0 TO LEN(m, 1)-1 DO
INCL -4
LABEL 2
LDLW -4
LDLW -12
JLEQ 1
RETURN
END

PROC tFlex2.p 0 5 0x00100001
! PROCEDURE p(VAR v: ARRAY OF INTEGER);
!   Out.Int(LEN(v), 0); Out.Ln
CONST 0
LDLW 16
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
RETURN
END

PROC tFlex2.q 0 5 0x00100001
! PROCEDURE q(VAR m: Matrix);
!   p(m[0]); 
LDLW 20
LDLW 12
CONST 0
LDLW 16
BOUND 44
LDLW 20
TIMES
INDEXW
GLOBAL tFlex2.p
CALL 2
!   Out.Int(LEN(m[0]), 0); Out.Ln
CONST 0
LDLW 20
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
RETURN
END

PROC tFlex2.%main 0 8 0
!   Foo(mm);
CONST 4
CONST 3
GLOBAL tFlex2.mm
GLOBAL tFlex2.Foo
CALL 3
!   Out.Int(mm[1][2], 0); Out.Ln;
CONST 0
GLOBAL tFlex2.mm
LDNW 24
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
!   NEW(tt, 4, 5);
CONST 5
CONST 4
CONST 2
CONST 4
CONST 0
GLOBAL tFlex2.tt
GLOBAL NEWFLEX
CALL 6
!   Foo(tt^);
LDGW tFlex2.tt
NCHECK 57
DUP 0
LDNW -4
LDNW 8
SWAP
DUP 0
LDNW -4
LDNW 4
SWAP
GLOBAL tFlex2.Foo
CALL 3
!   Out.Int(LEN(tt^), 0); Out.Ln;
CONST 0
LDGW tFlex2.tt
NCHECK 58
LDNW -4
LDNW 4
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
!   Out.Int(LEN(tt^, 2), 0); Out.Ln;
CONST 0
LDGW tFlex2.tt
NCHECK 59
LDNW -4
LDNW 8
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
!   Out.Int(tt[3][4], 0); Out.Ln;
CONST 0
LDGW tFlex2.tt
NCHECK 60
CONST 3
DUP 1
LDNW -4
LDNW 4
BOUND 60
DUP 1
LDNW -4
LDNW 8
TIMES
CONST 4
DUP 2
LDNW -4
LDNW 8
BOUND 60
PLUS
LDIW
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
!   q(mm); q(tt^);
CONST 4
CONST 3
GLOBAL tFlex2.mm
GLOBAL tFlex2.q
CALL 3
LDGW tFlex2.tt
NCHECK 62
DUP 0
LDNW -4
LDNW 8
SWAP
DUP 0
LDNW -4
LDNW 4
SWAP
GLOBAL tFlex2.q
CALL 3
!   NEW(uu, 4, 5, 6); q(uu[1]);
CONST 6
CONST 5
CONST 4
CONST 3
CONST 4
CONST 0
GLOBAL tFlex2.uu
GLOBAL NEWFLEX
CALL 7
LDGW tFlex2.uu
NCHECK 64
DUP 0
LDNW -4
LDNW 12
SWAP
DUP 0
LDNW -4
LDNW 8
SWAP
CONST 1
DUP 1
LDNW -4
LDNW 4
BOUND 64
DUP 1
LDNW -4
LDNW 8
TIMES
DUP 1
LDNW -4
LDNW 12
TIMES
INDEXW
GLOBAL tFlex2.q
CALL 3
RETURN
END

! Global variables
GLOVAR tFlex2.mm 48
GLOVAR tFlex2.tt 4
GLOVAR tFlex2.uu 4

! Pointer map
DEFINE tFlex2.%gcmap
WORD GC_BASE
WORD tFlex2.tt
WORD 0
WORD GC_BASE
WORD tFlex2.uu
WORD 0
WORD GC_END

! End of file
]]*)
