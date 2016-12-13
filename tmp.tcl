#!/usr/bin/tclsh
#

proc EchoAccept {sock addr port} {
  global echo
  set echo(addr,$sock) [list $addr $port]
  fileevent $sock readable [list Echo $sock]
}

proc InitStyleContent { dcontent wallColor winColor doorColor } {
	upvar $dcontent content

	append content "<html>\r\n"
	append content "<head>\r\n"
	append content "<style>\r\n"
	append content "hwall {\r\n"
	append content "    position: absolute;\r\n"
	append content "    height: 0px;\r\n"
	append content "    border: 6px solid $wallColor;\r\n"
	append content "}\r\n"
	append content "vwall {\r\n"
	append content "    position: absolute;\r\n"
	append content "    width: 0px;\r\n"
	append content "    border: 6px solid $wallColor;\r\n"
	append content "}\r\n"
	append content "hwin {\r\n"
	append content "    position: absolute;\r\n"
	append content "    height: 0px;\r\n"
	append content "    border: 3px solid $winColor;\r\n"
	append content "}\r\n"
	append content "vwin {\r\n"
	append content "    position: absolute;\r\n"
	append content "    width: 0px;\r\n"
	append content "    border: 3px solid $winColor;\r\n"
	append content "}\r\n"
	append content "hdoor {\r\n"
	append content "    position: absolute;\r\n"
	append content "    height: 0px;\r\n"
	append content "    border: 4px solid $doorColor;\r\n"
	append content "}\r\n"
	append content "vdoor {\r\n"
	append content "    position: absolute;\r\n"
	append content "    width: 0px;\r\n"
	append content "    border: 4px solid $doorColor;\r\n"
	append content "}\r\n"
	append content "</style>\r\n"
	append content "</head>\r\n"
}

# proc SendResponse
proc BuildBody {sock} {
  global staticContent
  global dynamicContent
  global staticContentSize

  BuildDynamicContent dynamicContent

  set ByteCount [expr $staticContentSize + [string length $dynamicContent] + 14]

  fconfigure $sock -translation binary -buffering none
  puts -nonewline $sock "HTTP/1.1 200 OK\r\n"
  puts -nonewline $sock "Content-Type: text/html;\r\n"
  puts -nonewline $sock "Connection: keep-alive;\r\n"
  puts -nonewline $sock "Content-length: $ByteCount;\r\n"
  puts -nonewline $sock "\r\n"
  puts -nonewline $sock $staticContent
  puts -nonewline $sock $dynamicContent
  puts -nonewline $sock "</body>"
  puts -nonewline $sock "</html>"
  incr echo(counter)
}

proc Echo {sock} {
  global echo

  fconfigure $sock -blocking 0
  set line [gets $sock]
  # consume all
  while {[gets $sock lline] >= 0} { }
  BuildBody $sock
}

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
		append fixedBodyContent "<$Tag style=\"top:${Top}px;left:${Left}px;${Length}px;border-color:$Color\"></$Tag>\r\n"
	}
}

proc InitStaticContent { filename dcontent } {
	upvar $dcontent content

	set fp [open $filename r]
	fconfigure $fp -buffering line

	append content "<body>"
	append content "<meta http-equiv=\"refresh\" content=\"5\">"

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
		set Top [lindex $line 1]
		set Left [lindex $line 2]
		append Length [lindex $line 3]
		set Color [lindex $line 4]
		if {[string length $Color] == 0} {break}
		append content "<$Tag style=\"top:${Top}px;left:${Left}px;${Length}px;border-color:$Color\"></$Tag>\r\n"
	}
	catch {close $fp}
}

proc parseDynamic {filename} {
	global dyNodes

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
			dict set dyNodes $Node $Switch $State Enb 1
			dict set dyNodes $Node $Switch $State Css $LList
#			dict set dyNodes $Node $Switch $State Type $Type
#			dict set dyNodes $Node $Switch $State Top $Top
#			dict set dyNodes $Node $Switch $State Left $Left
#			dict set dyNodes $Node $Switch $State Length $Length
#			dict set dyNodes $Node $Switch $State Color $Color
		} else {
			dict set dyNodes $Node $Switch $State Enb 0
		}
	}
}

proc BuildDynamicContent { dcontent } {
	upvar $dcontent content
	set content {}
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
	if [eof $pipe] {
		catch {close $pipe}
		return
	}
	gets $pipe LIST
	puts $LIST
#	set LIST [list $line]
	set Time [shift LIST]
	puts -nonewline "Time: $Time  "
	set NodeIdKey [shift LIST]
	set NodeIdValue [shift LIST]
#	foreach {Key Value} $LIST 
	while {[llength $LIST]} {
#		set ret [lindex $LIST 0]
#		set LIST [lreplace $LIST 0 0]
#		puts $ret
		set Key [shift LIST]
		regexp {^[^:]+} $Key  Key
		set Value [shift LIST]
		puts -nonewline "$Key = $Value  "
		dict set Nodes $NodeIdValue $Key $Value
	}
puts "\r\nNumber of Nodes: [dict size $Nodes]"
puts $Nodes
}


set PWD [pwd]
set Nodes {}
set dyNodes {}
set Left 50
set Top 180
set wallColor black 
set winColor green 
set doorColor brown 
set staticContent {} 
set dynamicContent {}
set echo(counter) 0
set echo(port) [lindex $argv 0]
set echo(home) [lindex $argv 1]
InitStyleContent staticContent $wallColor $winColor $doorColor
InitStaticContent ${PWD}/fixed.txt staticContent
parseDynamic ${PWD}/dynamic.txt
set staticContentSize [string length $staticContent]
puts "staticContentSize: $staticContentSize"

#BuildFixed $echo(home)/fixed.txt
#parseDynamic $echo(home)/dynamic.txt
#puts $fixedBodyContent
#puts $scontent
puts "Socket Port $echo(port);  Home $echo(home)"
set echo(main) [socket -server EchoAccept $echo(port)]

#set pipe [open "|sudo ./lofi_rpi -lS"]
#fconfigure $pipe -buffering line
#fileevent $pipe readable [list Reader $pipe]

vwait forever
 
