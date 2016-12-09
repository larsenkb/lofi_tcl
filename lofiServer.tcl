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

proc buildHorizontalWall {name top left length} {
	global wallColor
	global scontent
	global bcontent
	append scontent "div.$name {"
	append scontent "  position: absolute;"
	append scontent "  top: ${top}px;"
	append scontent "  left: ${left}px;"
	append scontent "  width: ${length}px;"
	append scontent "  height: 0px;"
	append scontent "  border: 5px solid $wallColor;"
	append scontent "}"
	append bcontent "<div class=\"$name\"></div>"
}

proc buildVerticalWall {name top left length} {
	global wallColor
	global scontent
	global bcontent
	append scontent "div.$name {"
	append scontent "  position: absolute;"
	append scontent "  top: ${top}px;"
	append scontent "  left: ${left}px;"
	append scontent "  width: 0px;"
	append scontent "  height: ${length}px;"
	append scontent "  border: 5px solid $wallColor;"
	append scontent "}"
	append bcontent "<div class=\"$name\"></div>"
}

proc buildFixedWindow {name top left width height border} {
	global scontent
	global fixedWindowColor
	global bcontent
	append scontent "div.$name {"
	append scontent "  position: absolute;"
	append scontent "  top: ${top}px;"
	append scontent "  left: ${left}px;"
	append scontent "  width: ${width}px;"
	append scontent "  height: ${height}px;"
	append scontent "  border: ${border}px solid $fixedWindowColor;"
	append scontent "}"
	append bcontent "<div class=\"$name\"></div>"
}

proc BuildBody {sock} {
  global echo
  global scontent
  global bcontent
  global Top
  global Left
    fconfigure $sock -translation binary -buffering none
    set bcontent "<body>"
    append bcontent "<meta http-equiv=\"refresh\" content=\"5\">"
    set scontent "<html>"
    append scontent "<head>"
    append scontent "<title>Larsen Security</title>"
	append scontent "<style>"
	buildVerticalWall "sw_corner_1" $Top $Left 30
	buildHorizontalWall "sw_corner_2" $Top $Left 40
	buildFixedWindow "master_window_2" [expr {$Top + 85}] $Left 0 40 3
	buildVerticalWall "s_house_wall" 355 $Left 200
    buildVerticalWall "s_gar_wall" 630 $Left 150
	buildHorizontalWall "se_corner_1" 785 $Left 30
	buildHorizontalWall "e_corner_2" 785 248 30
	buildVerticalWall "n_gar_wall_1" 630 278 150
	buildVerticalWall "n_gar_wall_2" 432 278 120
	buildFixedWindow "front_window_2" 343 282 0 40 3
	buildFixedWindow "master_bath_window_11" $Top 100 20 0 3 
	buildHorizontalWall "w_wall_2" $Top 152 30
	buildFixedWindow "master_bath_window_21" $Top 192 30 0 3 
	buildHorizontalWall "w_wall_3" $Top 264 30
	buildFixedWindow "dining_window_12" $Top 336 60 0 3 
	buildHorizontalWall "w_wall_4" $Top 436 70
	buildFixedWindow "kitchen_window_11" $Top 514 40 0 3 
	buildHorizontalWall "w_wall_5" $Top 604 70
	buildHorizontalWall "w_wall_6" $Top 740 90
	buildFixedWindow "boy_window_11" $Top 840 40 0 3 
	buildHorizontalWall "w_wall_7" $Top 932 40
	buildVerticalWall "n_wall_1" $Top 978 130
	buildFixedWindow "n_window_11" 320 982 0 40 3 
	buildVerticalWall "n_wall_2" 410 978 130
	buildHorizontalWall "e_corner_3" 550 938 40
	buildFixedWindow "toy_window_11" 554 892 40 0 3 
	buildHorizontalWall "e_corner_4" 550 800 40
	append scontent "</style>"
    append scontent "</head>"
#    append content "<body>"
#    append content "<meta http-equiv=\"refresh\" content=\"5\">"
#    append content "<h1>Forth $echo(counter)</h1>"
 
#    append content {<div style="position: relative; left: 0; top: 0;">}
#    append content {  <img src="a.png" style="position: relative; top: 0; left: 0;"/>}
#    append content {  <img src="a.png" style="position: absolute; top: 0px; left: 20px;">}
#    append content "\n</div>"
    
#    append content "<p><em>Forth</em> is a stack-oriented language and interactive environment.\n"

#	append content "<div class=\"absolute1\"></div>"
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

#proc BuildPng {sock pngFile} {
#  global echo
#    fconfigure $sock -translation binary
#    puts $sock "HTTP/1.1 200 OK"
#    puts $sock "Content-Location: $pngFile;"
#    puts $sock "Vary: negotiate,accept;"
#    puts $sock "Accept-Ranges: bytes;"
#    puts $sock "Content-Length: [file size $pngFile];"
#    puts $sock "Keep-Alive: timeout=15, max=100;"
#    puts $sock "Connection: Keep-Alive;"
 
#    puts $sock "Content-Type: image/png;"
#    puts $sock ""
    
##    puts "$pngFile [file size $pngFile]"
##    fconfigure $sock -translation binary -buffering none
##    puts -nonewline $sock $content
#    set fp [open $pngFile "rb"]
#    puts -nonewline $sock [read -nonewline $fp]
#    flush $sock
#    close $fp
#    close $sock
##    fconfigure $sock -buffering line
#}

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
set fixedWindowColor "#73AD21"
set bcontent ""
set scontent ""
set content ""
set echo(counter) 0
set echo(port) [lindex $argv 0]
set echo(home) [lindex $argv 1]
set fp [open $echo(home)/fixed.txt r]
fconfigure $fp -buffering line
while {true} {
	if [eof $fp] {
		catch {close $fp}
		exit
	}
	gets $fp line
	puts $line
}
close $fp
exit
puts "Socket Port $echo(port);  Home $echo(home)"
set echo(main) [socket -server EchoAccept $echo(port)]
vwait forever
  
