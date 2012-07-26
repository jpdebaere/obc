MODULE tBigLocal;

IMPORT Out;

TYPE Vec = ARRAY 100000 OF INTEGER;

PROCEDURE Q(VAR a: Vec);
BEGIN
  a[50000] := 3;
END Q;

PROCEDURE P;
  VAR dummy: Vec; x: INTEGER;
BEGIN
  Q(dummy); x := 4;
  Out.Int(x, 0); Out.Ln;
  Out.Int(dummy[50000], 0); Out.Ln
END P;

BEGIN
  P
END tBigLocal.

(*<<
4
3
>>*)

(*[[
!! SYMFILE #tBigLocal STAMP #tBigLocal.%main 1
!! END STAMP
!! 
MODULE tBigLocal STAMP 0
IMPORT Out STAMP
ENDHDR

PROC tBigLocal.Q 0 4 0x00100001
! PROCEDURE Q(VAR a: Vec);
!   a[50000] := 3;
CONST 3
LDLW 12
CONST 200000
PLUSA
STOREW
RETURN
END

PROC tBigLocal.P 100001 4 0
! PROCEDURE P;
!   Q(dummy); x := 4;
LOCAL 0
CONST -400000
PLUSA
GLOBAL tBigLocal.Q
CALL 1
CONST 4
LOCAL 0
CONST -400004
PLUSA
STOREW
!   Out.Int(x, 0); Out.Ln;
CONST 0
LOCAL 0
CONST -400004
PLUSA
LOADW
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
!   Out.Int(dummy[50000], 0); Out.Ln
CONST 0
LOCAL 0
CONST -200000
PLUSA
LOADW
GLOBAL Out.Int
CALL 2
GLOBAL Out.Ln
CALL 0
RETURN
END

PROC tBigLocal.%main 0 4 0
!   P
GLOBAL tBigLocal.P
CALL 0
RETURN
END

! End of file
]]*)