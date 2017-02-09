#!/usr/bin/tclsh
#

proc EchoAccept {sock addr port} {
  global echo
#	puts "sock: $sock  addr: $addr  port: $port"
  set echo(addr,$sock) [list $addr $port]
  fileevent $sock readable [list Echo $sock]
}

proc InitStyleContent { dcontent wallColor winColor doorColor } {
	upvar $dcontent content

	append content "<html>"
	append content "<head>"
	append content "<meta http-equiv=\"refresh\" content=\"5\">"
	append content "<style>"
	append content "hwall {"
	append content "    position: absolute;"
	append content "    height: 0px;"
	append content "    border: 6px solid $wallColor;"
	append content "}"
	append content "vwall {"
	append content "    position: absolute;"
	append content "    width: 0px;"
	append content "    border: 6px solid $wallColor;"
	append content "}"
	append content "hwin {"
	append content "    position: absolute;"
	append content "    height: 0px;"
	append content "    border: 3px solid $winColor;"
	append content "}"
	append content "vwin {"
	append content "    position: absolute;"
	append content "    width: 0px;"
	append content "    border: 3px solid $winColor;"
	append content "}"
	append content "hdoor {"
	append content "    position: absolute;"
	append content "    height: 0px;"
	append content "    border: 4px solid $doorColor;"
	append content "}"
	append content "vdoor {"
	append content "    position: absolute;"
	append content "    width: 0px;"
	append content "    border: 4px solid $doorColor;"
	append content "}"
	append content "</style>"
	append content "</head>"
}

# proc SendResponse
proc BuildBody {sock} {
  global staticContent
  global dynamicContent
  global staticContentSize

  BuildDynamicContent
#	puts $dynamicContent
#	puts "dynContent length: [string length $dynamicContent]"
#  flush stdout

#  set ByteCount [expr $staticContentSize + 14] 
  set ByteCount [expr $staticContentSize + [string length $dynamicContent] + 14]

  fconfigure $sock -translation binary -buffering none
  puts -nonewline $sock "HTTP/1.1 200 OK\r\n"
  puts -nonewline $sock "Content-Type: text/html;\r\n"
  puts -nonewline $sock "Connection: keep-alive;\r\n"
  puts -nonewline $sock "Content-length: $ByteCount;\r\n"
  puts -nonewline $sock "\r\n"
  puts -nonewline $sock $staticContent
  puts -nonewline $sock $dynamicContent
  puts -nonewline $sock "</body></html>"
  incr echo(counter)
	close $sock
}

proc Echo { sock } {
  global echo
	global dynamicContent

  fconfigure $sock -blocking 0
  set line [gets $sock]
#	puts $line
  # consume all
  while {[gets $sock lline] >= 0} {
#		puts $lline
  }
	if {[lindex $line 1] == "/"} {
		set dynamicContent {}
  	BuildBody $sock
	} else {
		close $sock
	}
}

if {0} {
proc BBuildDynamic {} {
	global dynamicBodyContent
	global dyNodes
	global Nodes

	while {true} {
		if {[string index $line 0] == "#"} {
			continue
		}
		if {[string index $line 0] == ";"} {
			continue
		}
		#puts $line
		set Tag [lindex $line 0]
		if {$Tag eq "vwall"} {
			set Length "height:"
		} elseif {$Tag eq "vwin"} {
			set Length "height:"
		} elseif {$Tag eq "vdoor"} {
			set Length "height:"
		} else {
			set Length "width:"
		}
		set Top [lindex $line 1]
		set Left [lindex $line 2]
		append Length [lindex $line 3]
		set Color [lindex $line 4]
		append fixedBodyContent "<$Tag style=\"top:${Top}px;left:${Left}px;${Length}px;border-color:$Color\"></$Tag>"
	}
}
}

proc InitStaticContent { filename dcontent } {
	upvar $dcontent content
	global Left_Offset
	global Top_Offset

	set fp [open $filename r]
	fconfigure $fp -buffering line

	append content "<body>"
	append content "<p>Larsen's Home Security</p>"
#	append content "<meta http-equiv=\"refresh\" content=\"5\">"

	while {[gets $fp line] >= 0} {
		if [eof $fp] {
#			catch {close $fp}
			break
		}
#		gets $fp line
		if {[string index $line 0] == "#"} {
			continue
		}
		if {[string index $line 0] == ";"} {
			continue
		}
		set Tag [lindex $line 0]
		if {$Tag eq "vwall"} {
			set Length "height:"
		} elseif {$Tag eq "vwin"} {
			set Length "height:"
		} elseif {$Tag eq "vdoor"} {
			set Length "height:"
		} else {
			set Length "width:"
		}
		set Top [expr [lindex $line 1] + $Top_Offset]
		set Left [expr [lindex $line 2] + $Left_Offset]
		append Length [lindex $line 3]
		set Color [lindex $line 4]
		if {[string length $Color] == 0} {break}
		append content "<$Tag style=\"top:${Top}px;left:${Left}px;${Length}px;border-color:$Color\"></$Tag>"
	}
	catch {close $fp}
}

proc parseDynamic {filename} {
	global dyNodes
	global Nodes
	global Left_Offset
	global Top_Offset

	set fp [open $filename r]
	fconfigure $fp -buffering line
	while {true} {
		if [eof $fp] {
			catch {close $fp}
			break
		}
		gets $fp line
		if {[string index $line 0] == "#"} {
			continue
		}
		if {[string index $line 0] == ";"} {
			continue
		}
#		puts $line
		# remove trailing comments
		regexp {^[^;]+} $line  List
		# separate words with one space character
		set LList [regexp -inline -all -- {\S+} $List]
		set Node [shift LList]
		set Switch [shift LList]
		set State [shift LList]
#		lassign $List Node Switch State Type Top Left Length Color
#		puts "Node=$Node  Switch=$Switch  State=$State  Type=$Type  Top=$Top  Left=$Left Length=$Length Color=$Color"

		if {[lindex $LList 0] != "na"} {
#			puts $LList
			set Top [expr [lindex $LList 1] + $Top_Offset]
			set Left [expr [lindex $LList 2] + $Left_Offset]
			set LLList [lreplace $LList 1 2 $Top $Left]
#			puts $LLList
			dict set dyNodes ${Node} ${Switch}${State} $LLList
		} else {
			dict set dyNodes ${Node} ${Switch}${State} "na" 
		}
		dict set Nodes $Node State Dis
		dict set Nodes $Node SW1 na
		dict set Nodes $Node SW2 na
		dict set Nodes $Node Ctr 0
		dict set Nodes $Node Vcc 0
		dict set Nodes $Node Temp 0
	}
}

proc BuildDynamicContent { } {
	global dynamicContent
	global Nodes
	global dyNodes
	global echo

#	set dynamicContent "<p>$echo(counter)</p>"
#	incr echo(counter)
	
	foreach NodeIdValue [dict keys $Nodes] {
  	set value [dict get $Nodes $NodeIdValue]
		set val1 [dict get $value "SW1"]
		if {$val1 != "na"} {
			set value1 [dict get $dyNodes $NodeIdValue]
			set val11 [dict get $value1 "SW1${val1}"]
#			puts $val11
			BuildDynamicItem $val11
		}
  	set val2 [dict get $value "SW2"]
		if {$val2 != "na"} {
			set value2 [dict get $dyNodes $NodeIdValue]
			set val22 [dict get $value2 "SW2${val2}"]
#			puts $val22
			BuildDynamicItem $val22
		}
	}
}

proc BuildDynamicItem { line } {
	global dynamicContent

	#puts $line
	set Tag [lindex $line 0]
	if {$Tag eq "vwall"} {
		set Length "height:"
	} elseif {$Tag eq "vwin"} {
		set Length "height:"
	} elseif {$Tag eq "vdoor"} {
		set Length "height:"
	} else {
		set Length "width:"
	}
	set Top [lindex $line 1]
	set Left [lindex $line 2]
	append Length [lindex $line 3]
	set Color [lindex $line 4]
	append dynamicContent "<$Tag style=\"top:${Top}px;left:${Left}px;${Length}px;border-color:$Color\"></$Tag>\r\n"
}


proc shift {ls} {
	upvar 1 $ls LIST
	if {[llength $LIST]} {
		set ret [lindex $LIST 0]
		set LIST [lreplace $LIST 0 0]
		return $ret
	}
}

proc Reader { pipe } {
	global Nodes
	global dyNodes
	global echo

	if [eof $pipe] {
		close $echo(logFd)
		catch {close $pipe}
		return
	}
	set timeStamp [clock seconds]
	gets $pipe LIST
	puts "$timeStamp $LIST"
	puts $echo(logFd) "$timeStamp $LIST"
	flush $echo(logFd)

#	set LIST [list $line]
#	set Time [shift LIST]
#	puts -nonewline "Time: $Time  "
	set NodeIdKey [shift LIST]
	set NodeIdValue [shift LIST]
	dict set Nodes $NodeIdValue State Enb
#	foreach {Key Value} $LIST 
	while {[llength $LIST]} {
#		set ret [lindex $LIST 0]
#		set LIST [lreplace $LIST 0 0]
#		puts $ret
		set Key [shift LIST]
		regexp {^[^:]+} $Key  Key
		set Value [shift LIST]
#		puts -nonewline "$Key = $Value  "
		dict set Nodes $NodeIdValue $Key $Value
	}
	dict set Nodes $NodeIdValue timeStamp $timeStamp
}


set PWD [pwd]
set Nodes {}
set dyNodes {}
set Left_Offset 0
set Top_Offset -120
set wallColor black 
set winColor green 
set doorColor brown 
set staticContent {} 
set dynamicContent {}
set echo(counter) 0
set echo(port) [lindex $argv 0]
set echo(home) [lindex $argv 1]
set echo(counter) 0
InitStyleContent staticContent $wallColor $winColor $doorColor
InitStaticContent ${PWD}/fixed.txt staticContent
parseDynamic ${PWD}/dynamic.txt
set staticContentSize [string length $staticContent]
#puts "staticContentSize: $staticContentSize"
if {0} {
foreach item [dict keys $dyNodes] {
	set value [dict get $dyNodes $item]
	puts "$item: $value"
}
}

#BuildFixed $echo(home)/fixed.txt
#parseDynamic $echo(home)/dynamic.txt
#puts $fixedBodyContent
#puts $scontent
#puts "Socket Port $echo(port);  Home $echo(home)"
set echo(main) [socket -server EchoAccept $echo(port)]

set echo(logFd) [open $echo(home)/lofi_rx.log a]
fconfigure $echo(logFd) -buffering line

if {1} {
set pipe [open "|sudo ./lofi_rpi -lS"]
fconfigure $pipe -buffering line
fileevent $pipe readable [list Reader $pipe]
}

vwait forever
 
