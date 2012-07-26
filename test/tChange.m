MODULE tChange;

IMPORT Out;

CONST N = 10; M = 1000000000;

TYPE bignum = ARRAY N OF INTEGER;

PROCEDURE Normalize(VAR a: bignum);
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO N-2 DO
    a[i+1] := a[i+1] + a[i] DIV M;
    a[i] := a[i] MOD M
  END
END Normalize;

PROCEDURE Set(VAR a: bignum; x: INTEGER);
  VAR i: INTEGER;
BEGIN
  a[0] := x;
  FOR i := 1 TO N-1 DO a[i] := 0 END;
  Normalize(a)
END Set;

PROCEDURE Add(VAR a1: bignum; a2: bignum);
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO N-1 DO a1[i] := a1[i] + a2[i] END;
  Normalize(a1)
END Add;

PROCEDURE PrintPiece(x: INTEGER);
  VAR m: INTEGER;
BEGIN
  m := M;
  WHILE m > 1 DO
    m := m DIV 10;
    Out.Int(x DIV m, 0);
    x := x MOD m
  END
END PrintPiece;

PROCEDURE Print(VAR a: bignum);
  VAR i: INTEGER;
BEGIN
  i := N-1;
  WHILE (i > 0) & (a[i] = 0) DO i := i-1 END;
  Out.Int(a[i], 0); i := i-1;
  WHILE i >= 0 DO PrintPiece(a[i]); i := i-1 END
END Print;

PROCEDURE Pay(goal: INTEGER; coin: ARRAY OF INTEGER; VAR ans: bignum);
  VAR 
    n, k, c: INTEGER;
    ways: POINTER TO ARRAY OF bignum;
BEGIN
  NEW(ways, goal+1);
  Set(ways[0], 1);
  FOR n := 1 TO goal DO Set(ways[n], 0) END;

  FOR k := 0 TO LEN(coin)-1 DO
    c := coin[k];
    FOR n := c TO goal DO
      Add(ways[n], ways[n-c])
    END
  END;

  ans := ways[goal]
END Pay;

VAR 
  goal: INTEGER;
  ans: bignum;
  coin: ARRAY 7 OF INTEGER;

BEGIN
  goal := 10000;
  coin[0] := 1; coin[1] := 2; coin[2] := 5; coin[3] := 10;
  coin[4] := 20; coin[5] := 50; coin[6] := 100;
  Pay(goal, coin, ans);
  Print(ans); Out.Ln
END tChange.

(*<<
146885286371151
>>*)

(*[[
!! SYMFILE #tChange STAMP #tChange.%main 1
!! END STAMP
!! 
MODULE tChange STAMP 0
IMPORT Out STAMP
ENDHDR

PROC tChange.Normalize 1 4 0x00100001
! PROCEDURE Normalize(VAR a: bignum);
!   FOR i := 0 TO N-2 DO
CONST 0
STLW -4
JUMP 2
LABEL 1
!     a[i+1] := a[i+1] + a[i] DIV M;
LDLW 12
LDLW -4
INC
CONST 10
BOUND 13
LDIW
LDLW 12
LDLW -4
CONST 10
BOUND 13
LDIW
CONST 1000000000
DIV
PLUS
LDLW 12
LDLW -4
INC
CONST 10
BOUND 13
STIW
!     a[i] := a[i] MOD M
LDLW 12
LDLW -4
CONST 10
BOUND 14
LDIW
CONST 1000000000
MOD
LDLW 12
LDLW -4
CONST 10
BOUND 14
STIW
!   FOR i := 0 TO N-2 DO
INCL -4
LABEL 2
LDLW -4
CONST 8
JLEQ 1
RETURN
END

PROC tChange.Set 1 4 0x00100001
! PROCEDURE Set(VAR a: bignum; x: INTEGER);
!   a[0] := x;
LDLW 16
LDLW 12
STOREW
!   FOR i := 1 TO N-1 DO a[i] := 0 END;
CONST 1
STLW -4
JUMP 4
LABEL 3
CONST 0
LDLW 12
LDLW -4
CONST 10
BOUND 22
STIW
INCL -4
LABEL 4
LDLW -4
CONST 9
JLEQ 3
!   Normalize(a)
LDLW 12
GLOBAL tChange.Normalize
CALL 1
RETURN
END

PROC tChange.Add 11 4 0x00100001
! PROCEDURE Add(VAR a1: bignum; a2: bignum);
LOCAL -44
LDLW 16
CONST 40
FIXCOPY
!   FOR i := 0 TO N-1 DO a1[i] := a1[i] + a2[i] END;
CONST 0
STLW -4
JUMP 6
LABEL 5
LDLW 12
LDLW -4
CONST 10
BOUND 29
LDIW
LOCAL -44
LDLW -4
CONST 10
BOUND 29
LDIW
PLUS
LDLW 12
LDLW -4
CONST 10
BOUND 29
STIW
INCL -4
LABEL 6
LDLW -4
CONST 9
JLEQ 5
!   Normalize(a1)
LDLW 12
GLOBAL tChange.Normalize
CALL 1
RETURN
END

PROC tChange.PrintPiece 1 4 0
! PROCEDURE PrintPiece(x: INTEGER);
!   m := M;
CONST 1000000000
STLW -4
JUMP 8
LABEL 7
!     m := m DIV 10;
LDLW -4
CONST 10
DIV
STLW -4
!     Out.Int(x DIV m, 0);
CONST 0
LDLW 12
LDLW -4
ZCHECK 39
DIV
GLOBAL Out.Int
CALL 2
!     x := x MOD m
LDLW 12
LDLW -4
ZCHECK 40
MOD
STLW 12
LABEL 8
!   WHILE m > 1 DO
LDLW -4
CONST 1
JGT 7
RETURN
END

PROC tChange.Print 1 4 0x00100001
! PROCEDURE Print(VAR a: bignum);
!   i := N-1;
CONST 9
STLW -4
JUMP 10
LABEL 9
DECL -4
LABEL 10
!   WHILE (i > 0) & (a[i] = 0) DO i := i-1 END;
LDLW -4
JLEQZ 11
LDLW 12
LDLW -4
CONST 10
BOUND 48
LDIW
JEQZ 9
LABEL 11
!   Out.Int(a[i], 0); i := i-1;
CONST 0
LDLW 12
LDLW -4
CONST 10
BOUND 49
LDIW
GLOBAL Out.Int
CALL 2
DECL -4
JUMP 13
LABEL 12
LDLW 12
LDLW -4
CONST 10
BOUND 50
LDIW
GLOBAL tChange.PrintPiece
CALL 1
DECL -4
LABEL 13
!   WHILE i >= 0 DO PrintPiece(a[i]); i := i-1 END
LDLW -4
JGEQZ 12
RETURN
END

PROC tChange.Pay 7 6 0x00802001
! PROCEDURE Pay(goal: INTEGER; coin: ARRAY OF INTEGER; VAR ans: bignum);
LOCAL 16
LDLW 20
CONST 4
TIMES
FLEXCOPY
!   NEW(ways, goal+1);
LDLW 12
INC
CONST 1
CONST 40
CONST 0
LOCAL -16
GLOBAL NEWFLEX
CALL 5
!   Set(ways[0], 1);
CONST 1
LDLW -16
NCHECK 59
CONST 0
DUP 1
LDNW -4
LDNW 4
BOUND 59
CONST 40
TIMES
PLUSA
GLOBAL tChange.Set
CALL 2
!   FOR n := 1 TO goal DO Set(ways[n], 0) END;
LDLW 12
STLW -20
CONST 1
STLW -4
JUMP 15
LABEL 14
CONST 0
LDLW -16
NCHECK 60
LDLW -4
DUP 1
LDNW -4
LDNW 4
BOUND 60
CONST 40
TIMES
PLUSA
GLOBAL tChange.Set
CALL 2
INCL -4
LABEL 15
LDLW -4
LDLW -20
JLEQ 14
!   FOR k := 0 TO LEN(coin)-1 DO
LDLW 20
DEC
STLW -24
CONST 0
STLW -8
JUMP 17
LABEL 16
!     c := coin[k];
LDLW 16
LDLW -8
LDLW 20
BOUND 63
LDIW
STLW -12
!     FOR n := c TO goal DO
LDLW 12
STLW -28
LDLW -12
STLW -4
JUMP 19
LABEL 18
!       Add(ways[n], ways[n-c])
LDLW -16
NCHECK 65
LDLW -4
LDLW -12
MINUS
DUP 1
LDNW -4
LDNW 4
BOUND 65
CONST 40
TIMES
PLUSA
LDLW -16
NCHECK 65
LDLW -4
DUP 1
LDNW -4
LDNW 4
BOUND 65
CONST 40
TIMES
PLUSA
GLOBAL tChange.Add
CALL 2
!     FOR n := c TO goal DO
INCL -4
LABEL 19
LDLW -4
LDLW -28
JLEQ 18
!   FOR k := 0 TO LEN(coin)-1 DO
INCL -8
LABEL 17
LDLW -8
LDLW -24
JLEQ 16
!   ans := ways[goal]
LDLW 24
LDLW -16
NCHECK 69
LDLW 12
DUP 1
LDNW -4
LDNW 4
BOUND 69
CONST 40
TIMES
PLUSA
CONST 40
FIXCOPY
RETURN
END

PROC tChange.%main 0 6 0
!   goal := 10000;
CONST 10000
STGW tChange.goal
!   coin[0] := 1; coin[1] := 2; coin[2] := 5; coin[3] := 10;
CONST 1
STGW tChange.coin
CONST 2
GLOBAL tChange.coin
STNW 4
CONST 5
GLOBAL tChange.coin
STNW 8
CONST 10
GLOBAL tChange.coin
STNW 12
!   coin[4] := 20; coin[5] := 50; coin[6] := 100;
CONST 20
GLOBAL tChange.coin
STNW 16
CONST 50
GLOBAL tChange.coin
STNW 20
CONST 100
GLOBAL tChange.coin
STNW 24
!   Pay(goal, coin, ans);
GLOBAL tChange.ans
CONST 7
GLOBAL tChange.coin
LDGW tChange.goal
GLOBAL tChange.Pay
CALL 4
!   Print(ans); Out.Ln
GLOBAL tChange.ans
GLOBAL tChange.Print
CALL 1
GLOBAL Out.Ln
CALL 0
RETURN
END

! Global variables
GLOVAR tChange.goal 4
GLOVAR tChange.ans 40
GLOVAR tChange.coin 28

! End of file
]]*)
