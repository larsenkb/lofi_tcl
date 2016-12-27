#!/usr/bin/tclsh
#

proc EchoAccept {sock addr port} {
  global echo
	puts "sock: $sock  addr: $addr  port: $port"
	flush stdout
  set echo(addr,$sock) [list $addr $port]
  fileevent $sock readable [list Echo $sock]
}


# proc SendResponse
proc BuildBody {sock} {
	global echo

  fconfigure $sock -translation binary -buffering none

	set content "<html>"
	append content "<head><meta http-equiv=\"refresh\" content=\"5\"></head>"
	append content "<body>"
	append content "<p>$echo(counter)</p>"
	incr echo(counter)

  set ByteCount [expr [string length $content] + 14]

  puts  $sock "HTTP/1.1 200 OK"
  puts  $sock "Content-Type: text/html;"
  puts  $sock "Connection: keep-alive;"
  puts  $sock "Content-length: $ByteCount;"
  puts  $sock ""
  puts  $sock $content
  puts  $sock "</body></html>"
#	flush $sock
	close $sock
}

proc Echo { sock } {
  global echo

	puts "Echo: sock: $sock"

  fconfigure $sock -blocking 0
  set line [gets $sock]
	puts $line
  # consume all
	while {[gets $sock lline] >= 0} {
#		puts $lline
  }
	if {[lindex $line 1] == "/"} {	
  	BuildBody $sock
	} else {
		close $sock
	}
}


#set PWD [pwd]
set echo(counter) 0
set echo(port) [lindex $argv 0]
set echo(home) [lindex $argv 1]
puts "Socket Port $echo(port);  Home $echo(home)"
set echo(main) [socket -server EchoAccept $echo(port)]

vwait forever
 
