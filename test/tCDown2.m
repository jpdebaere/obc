MODULE tCDown2;

(* CountDown in Oberon.  From an idea by Stephen Williams;
   re-implementation in Oberon and tuning by Mike Spivey *)

IMPORT Out, Conv, Strings, Bit, GC;

CONST 
  MAX = 10;			(* Maximum number of inputs *)
  POWMAX = 1024;		(* $2^{\hbox{\sci max}}$ *)
  HSIZE = 20000;		(* Size of hash table *)

CONST				(* Operator symbols *)
  Const = 0; Plus = 1; Minus = 2; Times = 3; Divide = 4;

(* Each expression formed is recorded as a `blob'.  These blobs are
   linked together in three ways: a blob that's labelled with a binary
   operator is linked to its left and right operands in a binary tree
   structure.  Also, each blob is put in a linked list with all others
   that use the same inputs.  Finally, there is a chained hash table
   that allows us to find all blobs with a certain value. *)

TYPE blobptr = POINTER TO blob;
  blob = 
    RECORD
      op: INTEGER;		(* Operator *)
      left, right: blobptr;	(* Left and right operands *)
      val: INTEGER;		(* Value of expression *)
      used: INTEGER;		(* Bitmap of inputs used *)
      next: blobptr;		(* Next blob with same inputs *)
      hlink: blobptr;		(* Next blob in hash chain *)
    END;

(* The binary tree structure of blobs is used by |Grind|, which
   converts an expression to printed form.  The output is simplified by
   omitting brackets where they are unnecessary because of the
   priority and associativity of operators.  Thus both of the
   expressions \verb|(1+2)+3| and \verb|1+(2+3)| will be shown without
   brackets.  The hacky string constants are a way of getting round
   the lack of proper array constants in Oberon *)

CONST
  sym = "?+-*/";		(* Character symbol for each operator *)
  pri = "01122";		(* Priorities of the operators *)
  rpri = "01223";		(* Priorities for right operands *)

(* |Grind| -- convert expression to printed form *)
PROCEDURE Grind(e0: blobptr; VAR buf: ARRAY OF CHAR);
  VAR pos: INTEGER;			(* Current position in |buf| *)

  PROCEDURE Put(c: CHAR);
  BEGIN
    buf[pos] := c; pos := pos+1
  END Put;

  PROCEDURE Walk(e: blobptr; p: INTEGER);
    VAR j, kp, rp: INTEGER; cbuf: ARRAY 10 OF CHAR;
  BEGIN
    IF e.op = Const THEN
      (* A constant *)
      Conv.ConvInt(e.val, cbuf);
      j := 0;
      WHILE cbuf[j] # 0X DO Put(cbuf[j]); j := j+1 END
    ELSE
      (* A binary operator *)
      kp := ORD(pri[e.op]) - ORD('0');
      rp := ORD(rpri[e.op]) - ORD('0');
      IF kp < p THEN Put('(') END;
      Walk(e.left, kp);
      Put(' '); Put(sym[e.op]); Put(' ');
      Walk(e.right, rp);
      IF kp < p THEN Put(')') END
    END
  END Walk;

BEGIN
  pos := 0;
  Walk(e0, 1);
  Put(0X)
END Grind;

(* Sets of input numbers are represented by bitmaps, i.e. integers in
   the range $[0\ddot2^N)$ in which the one bits indicate which
   numbers are present.  The array entry |pool[s]| shows all the expressions
   that have been created using the set of inputs |s|. *)

VAR pool: ARRAY POWMAX OF blobptr;

(* For each possible value |val|, we keep track of all the expressions
   with value |val| that have been created: they are kept in a linked
   list starting at |htable[val MOD HSIZE]|, together (of course) with
   others that hash to the same bucket.  We've chosen |HSIZE| large
   enough that such collisions will rarely happen. 
   The purpose of this hash table is to make it easy to avoid creating
   a `useless' expression if another with the same value already
   exists and uses no inputs that the new one would not use.  This
   speeds up the search immensely. *)

VAR htable: POINTER TO ARRAY HSIZE OF blobptr;

(* As we generate expressions, we keep track of the best answer seen
   so far: an expression that comes closest to the
   target, and of the expressions that are that close, the one that is
   the shortest when printed. *)

VAR
  target: INTEGER;		(* The target number *)
  temp, best: ARRAY 80 OF CHAR;	(* Latest expression, and best found so far *)
  bestval, bestdist: INTEGER;	(* Value and distance of |best| from |target| *)

(* |Add| -- create a new expression if it is not useless *)
PROCEDURE Add(op: INTEGER; p, q: blobptr; val, used: INTEGER);
  VAR dist: INTEGER; r: blobptr;
BEGIN
  (* Return immediately if useless *)
  r := htable[val MOD HSIZE];
  WHILE r # NIL DO
    IF (r.val = val) & (Bit.And(r.used, Bit.Not(used)) = 0) THEN
      RETURN
    END;
    r := r.hlink
  END;

  (* Create the expression and add it to |pool| and |htable| *)
  NEW(r);
  r.op := op; r.left := p; r.right := q; r.val := val; r.used := used;
  r.next := pool[used]; pool[used] := r;
  r.hlink := htable[val MOD HSIZE]; htable[val MOD HSIZE] := r;

  (* See if the new expression comes near the target *)
  dist := ABS(val - target);
  IF dist <= bestdist THEN
    (* At least as close as before *)
    Grind(r, temp);
    IF (dist < bestdist) 
        OR (Strings.Length(temp) < Strings.Length(best)) THEN
      (* Actually closer, or anyway shorter *)
      bestval := val; bestdist := dist;
      COPY(temp, best)
    END
  END
END Add;

(* The |Combine| procedure combines the contents of |pool[r]| with the
contents of |pool[s]| using every possible operator.  The results are
entered into the pool for the set union of |r| and |s|.
To speed the search, we do not allow expressions of the form $E_1+E_2$
where the value of $E_1$ is smaller than the value of $E_2$; the
equivalent expression $E_2+E_1$ renders this one useless anyway *)

(* |Combine| -- combine each expression in |pool[r]| with each in |pool[s]| *)
PROCEDURE Combine(r, s: INTEGER);
  VAR p, q: blobptr; used: INTEGER;
BEGIN
  used := Bit.Or(r, s);
  p := pool[r];
  WHILE p # NIL DO
    q := pool[s];
    WHILE q # NIL DO
      IF p.val >= q.val THEN
	Add(Plus, p, q, p.val+q.val, used);
	IF p.val > q.val THEN Add(Minus, p, q, p.val-q.val, used) END;
	Add(Times, p, q, p.val*q.val, used);
	IF (q.val > 0) & (p.val MOD q.val = 0) THEN
	  Add(Divide, p, q, p.val DIV q.val, used)
        END
      END;
      q := q.next
    END;
    p := p.next
  END
END Combine;

(* The search algorithm works by starting with just the input numbers,
and successively forming all expressions
using 2, 3,~\dots input numbers.
Each expression with $i$ inputs can be obtained by combining two
expressions that use $j$ and $k$ inputs, where $j+k=i$, and the two
expressions use disjoint sets of inputs.  Since the expressions are
divided into pools according to the set of inputs they use, at the |i|'th
stage we must combine each pool |r| with each pool |s| such that
|ones[r]+ones[s]=i| and |r| and |s| are disjoint. *)

(* |Search| -- search for all ways to reach the target. *)
PROCEDURE Search(n: INTEGER; draw: ARRAY OF INTEGER);
  VAR 
    i, r, s, t: INTEGER;
    ones: ARRAY POWMAX OF INTEGER; (* |ones[i]| is no. of 1 bits in |i|. *)
BEGIN
  (* Set up the table in |ones|.  For each |i|, we should have
     $"ones"[2^i..2^{i+1}) = "ones"[0..2^i) + 1$. *)
  ones[0] := 0; t := 1;
  FOR i := 0 TO n-1 DO
    FOR r := 0 TO t-1 DO ones[t+r] := ones[r]+1 END;
    t := 2*t
  END;

  (* Empty the hash table and pools *)
  FOR i := 0 TO HSIZE-1 DO htable[i] := NIL END;
  FOR r := 0 TO t-1 DO pool[r] := NIL END;

  (* Plant the original numbers as seeds, and set $t = 2^n$. *)
  t := 1;
  FOR i := 0 TO n-1 DO
    Add(Const, NIL, NIL, draw[i], t);
    t := 2*t
  END;

  (* Combine using up to |n-1| operations. *)
  bestdist := 100000;
  FOR i := 2 TO n DO 
    (* Combine all disjoint pairs of pools that use a total of |i| inputs *)
    FOR r := 1 TO t-1 DO
      FOR s := 1 TO t-1 DO
	IF (ones[r] + ones[s] = i) & (Bit.And(r, s) = 0) THEN
	  Combine(r, s)
        END
      END
    END
  END
END Search;

(*
(* |RandChoice| -- randomly choose six numbers *)
PROCEDURE RandChoice(VAR draw: ARRAY OF INTEGER);
  VAR i, j: INTEGER;
BEGIN
  (* We want 5 numbers from 1, 1, 2, 2, ..., 10, 10, with each number equally 
     likely to be chosen. The laws of conditional probablility show how to do 
     it: at each stage, we must select |(5-j)| numbers from the |(20-i)| that 
     remain, so the first of them is selected with that probability. *)
  FOR i := 0 TO 19 DO
    (* Choose |i/2+1| with probability |(5-j)/(20-i)| *)
    IF Random.Roll(20-i) < 5-j THEN
      draw[j] := i DIV 2 + 1; j := j+1
    END
  END;
  draw[5] := 25 * (Random.Roll(4) + 1);
  target := 101 + Random.Roll(899)
END RandChoice;
*)

(* |Main| -- main program *)
PROCEDURE Main;
  VAR 
    i, n: INTEGER; 
    (* buf: ARRAY 20 OF CHAR; *)
    draw: ARRAY MAX OF INTEGER;
BEGIN
  n := 6;
  draw[0] := 100; draw[1] := 4; draw[2] := 25; 
  draw[3] := 50; draw[4] := 2; draw[5] := 8; 
  target := 999;

(*
  IF Args.argc = 1 THEN
    (* Random problem *)
    Random.Randomize;
    n := 6;
    RandChoice(draw);
  ELSIF (Args.argc >= 3) & (Args.argc < MAX+1) THEN
    (* Problem specified on command line *)
    n := Args.argc-2;
    FOR i := 0 TO n-1 DO
      Args.GetArg(i+1, buf);
      draw[i] := Conv.IntVal(buf)
    END;
    Args.GetArg(Args.argc-1, buf);
    target := Conv.IntVal(buf);
  ELSE
    Out.String("usage: countdown [x1 x2 ... xn target]");
    Out.Ln;
    HALT(1)
  END;
*)

  (* Print input numbers (ascending if we chose them). *)
  Out.String("To make "); Out.Int(target, 0); Out.String(" from");
  FOR i := 0 TO n-1 DO Out.Char(' '); Out.Int(draw[i], 0) END;
  Out.Char(':'); Out.Ln;

  (* Find the best solution *)
  Search(n, draw);

  (* Print it. *)
  Out.Ln; Out.String("  "); Out.String(best); 
  Out.String(" = "); Out.Int(bestval, 0);   
  IF bestdist > 0 THEN 
    Out.String(" (off by "); Out.Int(bestdist, 0); Out.Char(')')
  END;
  Out.Ln; Out.Ln
END Main;

BEGIN
  GC.Debug("gs");
  NEW(htable);
  Main;
  htable := NIL;
  GC.Collect;
  Out.Ln
END tCDown2.

(*<<
To make 999 from 100 4 25 50 2 8:

  (50 - (100 + 4) / 8) * (25 + 2) = 999

[gc[ex]]
>>*)

(*[[
!! SYMFILE #tCDown2 STAMP #tCDown2.%main 1
!! END STAMP
!! 
MODULE tCDown2 STAMP 0
IMPORT Out STAMP
IMPORT Conv STAMP
IMPORT Strings STAMP
IMPORT Bit STAMP
IMPORT GC STAMP
ENDHDR

PROC tCDown2.%11.Put 1 5 0
!   PROCEDURE Put(c: CHAR);
SAVELINK
!     buf[pos] := c; pos := pos+1
LDLC 12
LDEW 16
LDEW -4
LDEW 20
BOUND 53
STIC
LDEW -4
INC
STEW -4
RETURN
END

PROC tCDown2.%12.Walk 7 5 0x00100001
!   PROCEDURE Walk(e: blobptr; p: INTEGER);
SAVELINK
!     IF e.op = Const THEN
LDLW 12
NCHECK 59
LOADW
JNEQZ 14
!       Conv.ConvInt(e.val, cbuf);
CONST 10
LOCAL -26
LDLW 12
NCHECK 61
LDNW 12
GLOBAL Conv.ConvInt
CALL 3
!       j := 0;
CONST 0
STLW -8
JUMP 16
LABEL 15
LOCAL -26
LDLW -8
CONST 10
BOUND 63
LDIC
ALIGNC
LDLW -4
LINK
GLOBAL tCDown2.%11.Put
CALL 1
INCL -8
LABEL 16
!       WHILE cbuf[j] # 0X DO Put(cbuf[j]); j := j+1 END
LOCAL -26
LDLW -8
CONST 10
BOUND 63
LDIC
JNEQZ 15
RETURN
LABEL 14
!       kp := ORD(pri[e.op]) - ORD('0');
GLOBAL tCDown2.%2
LDLW 12
NCHECK 66
LOADW
CONST 6
BOUND 66
LDIC
CONST 48
MINUS
STLW -12
!       rp := ORD(rpri[e.op]) - ORD('0');
GLOBAL tCDown2.%3
LDLW 12
NCHECK 67
LOADW
CONST 6
BOUND 67
LDIC
CONST 48
MINUS
STLW -16
!       IF kp < p THEN Put('(') END;
LDLW -12
LDLW 16
JGEQ 18
CONST 40
ALIGNC
LDLW -4
LINK
GLOBAL tCDown2.%11.Put
CALL 1
LABEL 18
!       Walk(e.left, kp);
LDLW -12
LDLW 12
NCHECK 69
LDNW 4
LDLW -4
LINK
GLOBAL tCDown2.%12.Walk
CALL 2
!       Put(' '); Put(sym[e.op]); Put(' ');
CONST 32
ALIGNC
LDLW -4
LINK
GLOBAL tCDown2.%11.Put
CALL 1
GLOBAL tCDown2.%1
LDLW 12
NCHECK 70
LOADW
CONST 6
BOUND 70
LDIC
ALIGNC
LDLW -4
LINK
GLOBAL tCDown2.%11.Put
CALL 1
CONST 32
ALIGNC
LDLW -4
LINK
GLOBAL tCDown2.%11.Put
CALL 1
!       Walk(e.right, rp);
LDLW -16
LDLW 12
NCHECK 71
LDNW 8
LDLW -4
LINK
GLOBAL tCDown2.%12.Walk
CALL 2
!       IF kp < p THEN Put(')') END
LDLW -12
LDLW 16
JGEQ 20
CONST 41
ALIGNC
LDLW -4
LINK
GLOBAL tCDown2.%11.Put
CALL 1
LABEL 20
RETURN
END

PROC tCDown2.Grind 1 5 0x00300001
! PROCEDURE Grind(e0: blobptr; VAR buf: ARRAY OF CHAR);
!   pos := 0;
CONST 0
STLW -4
!   Walk(e0, 1);
CONST 1
LDLW 12
LOCAL 0
LINK
GLOBAL tCDown2.%12.Walk
CALL 2
!   Put(0X)
CONST 0
ALIGNC
LOCAL 0
LINK
GLOBAL tCDown2.%11.Put
CALL 1
RETURN
END

PROC tCDown2.Add 2 5 0x00608001
! PROCEDURE Add(op: INTEGER; p, q: blobptr; val, used: INTEGER);
!   r := htable[val MOD HSIZE];
LDGW tCDown2.htable
NCHECK 116
LDLW 24
CONST 20000
MOD
CONST 20000
BOUND 116
LDIW
STLW -8
JUMP 22
LABEL 21
!     IF (r.val = val) & (Bit.And(r.used, Bit.Not(used)) = 0) THEN
LDLW -8
NCHECK 118
LDNW 12
LDLW 24
JNEQ 24
LDLW 28
GLOBAL Bit.Not
CALLW 1
LDLW -8
NCHECK 118
LDNW 16
GLOBAL Bit.And
CALLW 2
JNEQZ 24
!       RETURN
RETURN
LABEL 24
!     r := r.hlink
LDLW -8
NCHECK 121
LDNW 24
STLW -8
LABEL 22
!   WHILE r # NIL DO
LDLW -8
JNEQZ 21
!   NEW(r);
CONST 28
GLOBAL tCDown2.blob
LOCAL -8
GLOBAL NEW
CALL 3
!   r.op := op; r.left := p; r.right := q; r.val := val; r.used := used;
LDLW 12
LDLW -8
NCHECK 126
STOREW
LDLW 16
LDLW -8
NCHECK 126
STNW 4
LDLW 20
LDLW -8
NCHECK 126
STNW 8
LDLW 24
LDLW -8
NCHECK 126
STNW 12
LDLW 28
LDLW -8
NCHECK 126
STNW 16
!   r.next := pool[used]; pool[used] := r;
GLOBAL tCDown2.pool
LDLW 28
CONST 1024
BOUND 127
LDIW
LDLW -8
NCHECK 127
STNW 20
LDLW -8
GLOBAL tCDown2.pool
LDLW 28
CONST 1024
BOUND 127
STIW
!   r.hlink := htable[val MOD HSIZE]; htable[val MOD HSIZE] := r;
LDGW tCDown2.htable
NCHECK 128
LDLW 24
CONST 20000
MOD
CONST 20000
BOUND 128
LDIW
LDLW -8
NCHECK 128
STNW 24
LDLW -8
LDGW tCDown2.htable
NCHECK 128
LDLW 24
CONST 20000
MOD
CONST 20000
BOUND 128
STIW
!   dist := ABS(val - target);
LDLW 24
LDGW tCDown2.target
MINUS
GLOBAL ABSINT
CALLW 1
STLW -4
!   IF dist <= bestdist THEN
LDLW -4
LDGW tCDown2.bestdist
JGT 26
!     Grind(r, temp);
CONST 80
GLOBAL tCDown2.temp
LDLW -8
GLOBAL tCDown2.Grind
CALL 3
!     IF (dist < bestdist) 
LDLW -4
LDGW tCDown2.bestdist
JLT 29
!         OR (Strings.Length(temp) < Strings.Length(best)) THEN
CONST 80
GLOBAL tCDown2.temp
GLOBAL Strings.Length
CALLW 2
CONST 80
GLOBAL tCDown2.best
GLOBAL Strings.Length
CALLW 2
JGEQ 26
LABEL 29
!       bestval := val; bestdist := dist;
LDLW 24
STGW tCDown2.bestval
LDLW -4
STGW tCDown2.bestdist
!       COPY(temp, best)
CONST 80
GLOBAL tCDown2.best
CONST 80
GLOBAL tCDown2.temp
GLOBAL COPY
CALL 4
LABEL 26
RETURN
END

PROC tCDown2.Combine 3 6 0x00018001
! PROCEDURE Combine(r, s: INTEGER);
!   used := Bit.Or(r, s);
LDLW 16
LDLW 12
GLOBAL Bit.Or
CALLW 2
STLW -12
!   p := pool[r];
GLOBAL tCDown2.pool
LDLW 12
CONST 1024
BOUND 156
LDIW
STLW -4
JUMP 31
LABEL 30
!     q := pool[s];
GLOBAL tCDown2.pool
LDLW 16
CONST 1024
BOUND 158
LDIW
STLW -8
JUMP 33
LABEL 32
!       IF p.val >= q.val THEN
LDLW -4
NCHECK 160
LDNW 12
LDLW -8
NCHECK 160
LDNW 12
JLT 35
! 	Add(Plus, p, q, p.val+q.val, used);
LDLW -12
LDLW -4
NCHECK 161
LDNW 12
LDLW -8
NCHECK 161
LDNW 12
PLUS
LDLW -8
LDLW -4
CONST 1
GLOBAL tCDown2.Add
CALL 5
! 	IF p.val > q.val THEN Add(Minus, p, q, p.val-q.val, used) END;
LDLW -4
NCHECK 162
LDNW 12
LDLW -8
NCHECK 162
LDNW 12
JLEQ 37
LDLW -12
LDLW -4
NCHECK 162
LDNW 12
LDLW -8
NCHECK 162
LDNW 12
MINUS
LDLW -8
LDLW -4
CONST 2
GLOBAL tCDown2.Add
CALL 5
LABEL 37
! 	Add(Times, p, q, p.val*q.val, used);
LDLW -12
LDLW -4
NCHECK 163
LDNW 12
LDLW -8
NCHECK 163
LDNW 12
TIMES
LDLW -8
LDLW -4
CONST 3
GLOBAL tCDown2.Add
CALL 5
! 	IF (q.val > 0) & (p.val MOD q.val = 0) THEN
LDLW -8
NCHECK 164
LDNW 12
JLEQZ 35
LDLW -4
NCHECK 164
LDNW 12
LDLW -8
NCHECK 164
LDNW 12
ZCHECK 164
MOD
JNEQZ 35
! 	  Add(Divide, p, q, p.val DIV q.val, used)
LDLW -12
LDLW -4
NCHECK 165
LDNW 12
LDLW -8
NCHECK 165
LDNW 12
ZCHECK 165
DIV
LDLW -8
LDLW -4
CONST 4
GLOBAL tCDown2.Add
CALL 5
LABEL 35
!       q := q.next
LDLW -8
NCHECK 168
LDNW 20
STLW -8
LABEL 33
!     WHILE q # NIL DO
LDLW -8
JNEQZ 32
!     p := p.next
LDLW -4
NCHECK 170
LDNW 20
STLW -4
LABEL 31
!   WHILE p # NIL DO
LDLW -4
JNEQZ 30
RETURN
END

PROC tCDown2.Search 1035 6 0
! PROCEDURE Search(n: INTEGER; draw: ARRAY OF INTEGER);
LOCAL 16
LDLW 20
CONST 4
TIMES
FLEXCOPY
!   ones[0] := 0; t := 1;
CONST 0
STLW -4112
CONST 1
STLW -16
!   FOR i := 0 TO n-1 DO
LDLW 12
DEC
STLW -4116
CONST 0
STLW -4
JUMP 41
LABEL 40
!     FOR r := 0 TO t-1 DO ones[t+r] := ones[r]+1 END;
LDLW -16
DEC
STLW -4120
CONST 0
STLW -8
JUMP 43
LABEL 42
LOCAL -4112
LDLW -8
CONST 1024
BOUND 194
LDIW
INC
LOCAL -4112
LDLW -16
LDLW -8
PLUS
CONST 1024
BOUND 194
STIW
INCL -8
LABEL 43
LDLW -8
LDLW -4120
JLEQ 42
!     t := 2*t
LDLW -16
CONST 2
TIMES
STLW -16
!   FOR i := 0 TO n-1 DO
INCL -4
LABEL 41
LDLW -4
LDLW -4116
JLEQ 40
!   FOR i := 0 TO HSIZE-1 DO htable[i] := NIL END;
CONST 0
STLW -4
JUMP 45
LABEL 44
CONST 0
LDGW tCDown2.htable
NCHECK 199
LDLW -4
CONST 20000
BOUND 199
STIW
INCL -4
LABEL 45
LDLW -4
CONST 19999
JLEQ 44
!   FOR r := 0 TO t-1 DO pool[r] := NIL END;
LDLW -16
DEC
STLW -4124
CONST 0
STLW -8
JUMP 47
LABEL 46
CONST 0
GLOBAL tCDown2.pool
LDLW -8
CONST 1024
BOUND 200
STIW
INCL -8
LABEL 47
LDLW -8
LDLW -4124
JLEQ 46
!   t := 1;
CONST 1
STLW -16
!   FOR i := 0 TO n-1 DO
LDLW 12
DEC
STLW -4128
CONST 0
STLW -4
JUMP 49
LABEL 48
!     Add(Const, NIL, NIL, draw[i], t);
LDLW -16
LDLW 16
LDLW -4
LDLW 20
BOUND 205
LDIW
CONST 0
CONST 0
CONST 0
GLOBAL tCDown2.Add
CALL 5
!     t := 2*t
LDLW -16
CONST 2
TIMES
STLW -16
!   FOR i := 0 TO n-1 DO
INCL -4
LABEL 49
LDLW -4
LDLW -4128
JLEQ 48
!   bestdist := 100000;
CONST 100000
STGW tCDown2.bestdist
!   FOR i := 2 TO n DO 
LDLW 12
STLW -4132
CONST 2
STLW -4
JUMP 51
LABEL 50
!     FOR r := 1 TO t-1 DO
LDLW -16
DEC
STLW -4136
CONST 1
STLW -8
JUMP 53
LABEL 52
!       FOR s := 1 TO t-1 DO
LDLW -16
DEC
STLW -4140
CONST 1
STLW -12
JUMP 55
LABEL 54
! 	IF (ones[r] + ones[s] = i) & (Bit.And(r, s) = 0) THEN
LOCAL -4112
LDLW -8
CONST 1024
BOUND 215
LDIW
LOCAL -4112
LDLW -12
CONST 1024
BOUND 215
LDIW
PLUS
LDLW -4
JNEQ 57
LDLW -12
LDLW -8
GLOBAL Bit.And
CALLW 2
JNEQZ 57
! 	  Combine(r, s)
LDLW -12
LDLW -8
GLOBAL tCDown2.Combine
CALL 2
LABEL 57
!       FOR s := 1 TO t-1 DO
INCL -12
LABEL 55
LDLW -12
LDLW -4140
JLEQ 54
!     FOR r := 1 TO t-1 DO
INCL -8
LABEL 53
LDLW -8
LDLW -4136
JLEQ 52
!   FOR i := 2 TO n DO 
INCL -4
LABEL 51
LDLW -4
LDLW -4132
JLEQ 50
RETURN
END

PROC tCDown2.Main 13 6 0
! PROCEDURE Main;
!   n := 6;
CONST 6
STLW -8
!   draw[0] := 100; draw[1] := 4; draw[2] := 25; 
CONST 100
STLW -48
CONST 4
STLW -44
CONST 25
STLW -40
!   draw[3] := 50; draw[4] := 2; draw[5] := 8; 
CONST 50
STLW -36
CONST 2
STLW -32
CONST 8
STLW -28
!   target := 999;
CONST 999
STGW tCDown2.target
!   Out.String("To make "); Out.Int(target, 0); Out.String(" from");
CONST 9
GLOBAL tCDown2.%4
GLOBAL Out.String
CALL 2
CONST 0
LDGW tCDown2.target
GLOBAL Out.Int
CALL 2
CONST 6
GLOBAL tCDown2.%5
GLOBAL Out.String
CALL 2
!   FOR i := 0 TO n-1 DO Out.Char(' '); Out.Int(draw[i], 0) END;
LDLW -8
DEC
STLW -52
CONST 0
STLW -4
JUMP 59
LABEL 58
CONST 32
ALIGNC
GLOBAL Out.Char
CALL 1
CONST 0
LOCAL -48
LDLW -4
CONST 10
BOUND 279
LDIW
GLOBAL Out.Int
CALL 2
INCL -4
LABEL 59
LDLW -4
LDLW -52
JLEQ 58
!   Out.Char(':'); Out.Ln;
CONST 58
ALIGNC
GLOBAL Out.Char
CALL 1
GLOBAL Out.Ln
CALL 0
!   Search(n, draw);
CONST 10
LOCAL -48
LDLW -8
GLOBAL tCDown2.Search
CALL 3
!   Out.Ln; Out.String("  "); Out.String(best); 
GLOBAL Out.Ln
CALL 0
CONST 3
GLOBAL tCDown2.%6
GLOBAL Out.String
CALL 2
CONST 80
GLOBAL tCDown2.best
GLOBAL Out.String
CALL 2
!   Out.String(" = "); Out.Int(bestval, 0);   
CONST 4
GLOBAL tCDown2.%7
GLOBAL Out.String
CALL 2
CONST 0
LDGW tCDown2.bestval
GLOBAL Out.Int
CALL 2
!   IF bestdist > 0 THEN 
LDGW tCDown2.bestdist
JLEQZ 61
!     Out.String(" (off by "); Out.Int(bestdist, 0); Out.Char(')')
CONST 10
GLOBAL tCDown2.%8
GLOBAL Out.String
CALL 2
CONST 0
LDGW tCDown2.bestdist
GLOBAL Out.Int
CALL 2
CONST 41
ALIGNC
GLOBAL Out.Char
CALL 1
LABEL 61
!   Out.Ln; Out.Ln
GLOBAL Out.Ln
CALL 0
GLOBAL Out.Ln
CALL 0
RETURN
END

PROC tCDown2.%main 0 6 0
!   GC.Debug("gs");
CONST 3
GLOBAL tCDown2.%9
GLOBAL GC.Debug
CALL 2
!   NEW(htable);
CONST 80000
GLOBAL tCDown2.%10
GLOBAL tCDown2.htable
GLOBAL NEW
CALL 3
!   Main;
GLOBAL tCDown2.Main
CALL 0
!   htable := NIL;
CONST 0
STGW tCDown2.htable
!   GC.Collect;
GLOBAL GC.Collect
CALL 0
!   Out.Ln
GLOBAL Out.Ln
CALL 0
RETURN
END

! Global variables
GLOVAR tCDown2.pool 4096
GLOVAR tCDown2.htable 4
GLOVAR tCDown2.target 4
GLOVAR tCDown2.temp 80
GLOVAR tCDown2.best 80
GLOVAR tCDown2.bestval 4
GLOVAR tCDown2.bestdist 4

! Pointer map
DEFINE tCDown2.%gcmap
WORD GC_BASE
WORD tCDown2.pool
WORD GC_BLOCK
WORD 0
WORD 1024
WORD GC_BASE
WORD tCDown2.htable
WORD 0
WORD GC_END

! String "?+-*/"
DEFINE tCDown2.%1
STRING 3F2B2D2A2F00

! String "01122"
DEFINE tCDown2.%2
STRING 303131323200

! String "01223"
DEFINE tCDown2.%3
STRING 303132323300

! String "To make "
DEFINE tCDown2.%4
STRING 546F206D616B652000

! String " from"
DEFINE tCDown2.%5
STRING 2066726F6D00

! String "  "
DEFINE tCDown2.%6
STRING 202000

! String " = "
DEFINE tCDown2.%7
STRING 203D2000

! String " (off by "
DEFINE tCDown2.%8
STRING 20286F66662062792000

! String "gs"
DEFINE tCDown2.%9
STRING 677300

! Descriptor for blob
DEFINE tCDown2.blob
WORD 0x000000cd
WORD 0
WORD tCDown2.blob.%anc

DEFINE tCDown2.blob.%anc
WORD tCDown2.blob

! Descriptor for *anon*
DEFINE tCDown2.%10
WORD tCDown2.%10.%map

! Pointer maps
DEFINE tCDown2.%10.%map
WORD GC_BLOCK
WORD 0
WORD 20000
WORD GC_END

! End of file
]]*)

$Id: tCDown2.m 1678 2011-03-15 20:27:21Z mike $
