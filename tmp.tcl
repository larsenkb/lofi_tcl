set default "index.html"


#proc respond {sock code body {head "\n"}} {
#  puts -nonewline $sock "HTTP/1.1 $code OK\nContent-Type: text/html; \
#         \nConnection: keep-alive\nContent-length: [string length $body]\n$head\n$body"
#}

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
	
#	buildFixedWindow "master_bath_window_11" $Top 100 20 0 3 
#	buildFixedWindow "master_bath_window_21" $Top 192 30 0 3 
#	buildFixedWindow "dining_window_12" $Top 336 60 0 3 
#	buildFixedWindow "kitchen_window_11" $Top 514 40 0 3 
#	buildFixedWindow "boy_window_11" $Top 840 40 0 3 
#	buildFixedWindow "n_window_11" 320 982 0 40 3 
#	buildFixedWindow "toy_window_11" 554 892 40 0 3 
 

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

proc Echo {sock} {
  global echo
  fconfigure $sock -blocking 0
  set line [gets $sock]
    gets $sock lline
    while {[string compare $lline ""] != 0} {
        gets $sock lline
    }
  set shortName "/"
  regexp {/[^ ]*} $line shortName
  set many [string length $shortName]
  set last [string index $shortName [expr {$many-1}]]
  if {$last=="/"} then {set shortName "/"}
  set wholeName $shortName
    if {$wholeName=="/"} {
        BuildBody $sock
    } else {
#        set imgFile [string range $wholeName 1 end]
#        BuildPng $sock $imgFile
    }
}

set Left 50
set Top 180
set wallColor "#000000"
set winColor "#0000ff"
set doorColor "#AD7321"
set bcontent {}
set scontent {}
set content {}
set fixedBodyContent {}
set echo(counter) 0
set echo(port) [lindex $argv 0]
set echo(home) [lindex $argv 1]
set fp [open $echo(home)/fixed.txt r]
fconfigure $fp -buffering line
while {true} {
	if [eof $fp] {
		catch {close $fp}
		break
	}
	gets $fp line
	if {[string length $line] < 5} {
		catch {close $fp}
		break
	}
	puts $line
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
	append fixedBodyContent "<$Tag style=\"top:${Top}px;left:${Left}px;${Length}px\"></$Tag>\r\n"
}
puts $fixedBodyContent
BuildStyle
#puts $scontent
puts "Socket Port $echo(port);  Home $echo(home)"
set echo(main) [socket -server EchoAccept $echo(port)]
vwait forever
  
