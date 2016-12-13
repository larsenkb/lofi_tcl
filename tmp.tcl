#!/usr/bin/tclsh
#

set default "index.html"


proc EchoAccept {sock addr port} {
  global echo
  set echo(addr,$sock) [list $addr $port]
  fileevent $sock readable [list Echo $sock]
}

proc BuildStyle {} {
	global scontent
	global wallColor
	global winColor
	global doorColor

	set    scontent "<html>\r\n"
	append scontent "<head>\r\n"
	append scontent "<style>\r\n"
	append scontent "hwall {\r\n"
	append scontent "    position: absolute;\r\n"
	append scontent "    height: 0px;\r\n"
	append scontent "    border: 6px solid $wallColor;\r\n"
	append scontent "}\r\n"
	append scontent "vwall {\r\n"
	append scontent "    position: absolute;\r\n"
	append scontent "    width: 0px;\r\n"
	append scontent "    border: 6px solid $wallColor;\r\n"
	append scontent "}\r\n"
	append scontent "hwin {\r\n"
	append scontent "    position: absolute;\r\n"
	append scontent "    height: 0px;\r\n"
	append scontent "    border: 3px solid $winColor;\r\n"
	append scontent "}\r\n"
	append scontent "vwin {\r\n"
	append scontent "    position: absolute;\r\n"
	append scontent "    width: 0px;\r\n"
	append scontent "    border: 3px solid $winColor;\r\n"
	append scontent "}\r\n"
	append scontent "hdoor {\r\n"
	append scontent "    position: absolute;\r\n"
	append scontent "    height: 0px;\r\n"
	append scontent "    border: 4px solid $doorColor;\r\n"
	append scontent "}\r\n"
	append scontent "vdoor {\r\n"
	append scontent "    position: absolute;\r\n"
	append scontent "    width: 0px;\r\n"
	append scontent "    border: 4px solid $doorColor;\r\n"
	append scontent "}\r\n"
	append scontent "</style>\r\n"
	append scontent "</head>\r\n"
}

proc BuildBody {sock} {
  global echo
  global scontent
  global bcontent
  global fixedBodyContent
  global Top
  global Left
    fconfigure $sock -translation binary -buffering none
    set bcontent "<body>"
    append bcontent "<meta http-equiv=\"refresh\" content=\"5\">"

	append bcontent $fixedBodyContent

    append bcontent "</body>"
    append bcontent "</html>"
	append content $scontent $bcontent
    puts -nonewline $sock "HTTP/1.1 200 OK\r\n"
    puts -nonewline $sock "Content-Type: text/html;\r\n"
    puts -nonewline $sock "Connection: keep-alive;\r\n"
    puts -nonewline $sock "Content-length: [string length $content];\r\n"
    puts -nonewline $sock "\r\n"
    puts -nonewline $sock "$content"
    incr echo(counter)
}

#proc Echo {sock} {
#  global echo
#  fconfigure $sock -blocking 0
#  set line [gets $sock]
#  gets $sock lline
#  while {[string compare $lline ""] != 0} {
#    gets $sock lline
#  }
#  set shortName "/"
#  regexp {/[^ ]*} $line shortName
#  set many [string length $shortName]
#  set last [string index $shortName [expr {$many-1}]]
#  if {$last=="/"} then {set shortName "/"}
#  set wholeName $shortName
#    if {$wholeName=="/"} {
#        BuildBody $sock
#    } else {
##        set imgFile [string range $wholeName 1 end]
##        BuildPng $sock $imgFile
#    }
#}

proc Echo {sock} {
  global echo
  fconfigure $sock -blocking 0
  set line [gets $sock]
  gets $sock lline
  while {[string compare $lline ""] != 0} {
    gets $sock lline
  }
  BuildBody $sock
}

proc BuildDynamic {} {
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

proc BuildFixed {filename} {
	global fixedBodyContent
	global echo

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


set Nodes {}
set dyNodes {}
set Left 50
set Top 180
set wallColor black 
set winColor green 
set doorColor brown 
set bcontent {}
set scontent {}
set content {}
set fixedBodyContent {}
set echo(counter) 0
set echo(port) [lindex $argv 0]
set echo(home) [lindex $argv 1]
BuildStyle
set PWD [pwd]
BuildFixed ${PWD}/fixed.txt
parseDynamic ${PWD}/dynamic.txt
#BuildFixed $echo(home)/fixed.txt
#parseDynamic $echo(home)/dynamic.txt
#puts $fixedBodyContent
#puts $scontent
puts "Socket Port $echo(port);  Home $echo(home)"
set echo(main) [socket -server EchoAccept $echo(port)]

#set pipe [open "|sudo ./lofi_rpi -lS"]
#fconfigure $pipe -buffering line
#fileevent $pipe readable [list Reader $pipe]

#vwait forever
 
