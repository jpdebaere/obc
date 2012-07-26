#
# jitgen.tcl
# 
# This file is part of the Oxford Oberon-2 compiler
# Copyright (c) 2006 J. M. Spivey
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $Id: jitgen.tcl 1646 2010-12-15 11:39:11Z mike $
#

# This workaround is needed with TCL 8.4.2 if output goes to an emacs
# compilation buffer.
fconfigure stdout -translation lf
fconfigure stderr -translation lf

if {[llength $argv] != 2} {
    puts stderr "usage: jitgen input.iset decode.c"
    exit 1
}

set srcdir [file dirname $argv0]
source "$srcdir/util.tcl"
source "$srcdir/iparse.tcl"

if {[file exists "config.tcl"]} {source "config.tcl"}

lsplit $argv infile jfile


# GENERATE DECODING TABLE

proc gen_decode {name} {
    global ncodes opcode instrs expand
    
    set f [open $name "w"]
    
    puts $f "/* Decoding table -- generated by jitgen.tcl */"
    puts $f ""
		
    puts $f "#include \"obx.h\""
    puts $f "#include \"decode.h\""
    puts $f "#include \"keiko.h\""
    puts $f ""

    puts $f "struct inst instrs\[\] = {"
    puts $f "     { \"ILLEGAL\", { 0 } },"
    foreach inst $instrs {
	set m {}
	if {[info exists expand($inst)]} {
	    foreach x $expand($inst) {
		if {[regexp {^(.*) \$a$} $x _ y]} {
		    lappend m "I_$y|IARG"
		} elseif {[regexp {^(.*) (-?[0-9]*)$} $x _ y z]} {
		    lappend m "I_$y|ICON" $z
		} else {
		    lappend m "I_$x"
		}
	    }
	}
	lappend m 0
	puts $f "     { \"$inst\", { [join $m ", "] } },"
    }
    puts $f "};"
    puts $f ""

    puts $f "struct decode decode\[\] = {"
    for {set i 0} {$i < $ncodes} {incr i} {
	with $opcode($i) {op inst patt arg len} {
	    puts $f "     { I_$inst, \"$patt\", $arg, $len },"
	}
    }
    puts $f "};"
    
    close $f
}


# MAIN PROGRAM

readfile $infile

if {$status != 0} {exit $status}

gen_decode $jfile

exit $status
