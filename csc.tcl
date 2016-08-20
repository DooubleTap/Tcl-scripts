package require http 2.7
package require tls

bind pub -|- .csc checkcsc

proc checkcsc {nick host hand chan arg} {
	set valchan [join [lindex [split $arg] 0]]
	if { $valchan == "" } { return 0 }
	http::config -useragent "lynx"
	::http::register https 443 [list ::tls::socket -ssl2 0 -ssl3 0 -tls1 1]
	set dachan [wt:filter $valchan]
	set token [http::geturl "https://cservice.undernet.org/live/check_app.php?name=$dachan"]
	set html [http::data $token]
	if {[string match "*No applications*" $html]} {
		puthelp "PRIVMSG $chan :$valchan: Is not in any kind of registration process, Try again."
		return 0
	}
	if {[string match "*DB is currently being maintained*" $html]} {
		puthelp "PRIVMSG $chan :$valchan: The CService Database in unavailable At The moment. Please Try again later."
		return 0
	}
	upvar #0 $token state
	foreach {name value} $state(meta) {
		if {[regexp -nocase ^location$ $name]} {
			set regurl "https://cservice.undernet.org/live/$value"
			set token [http::geturl $regurl]
			set html [http::data $token]
			set html [split $html "\n"]
			set regobj 0
			set regcomment ""
			foreach line $html {
				if {[string match "*by user :*" $line]} {
					regexp {(.*)<b>(.*)</b>(.*)} $line match blah reguser blah
				}

				if {[string match "*Posted on :*" $line]} {
					regexp {(.*)<b>(.*)</b>(.*)} $line match blah regdate blah
				}
				if {[string match "*Current status :*" $line]} {
					regexp {(.*)<b>(.*)</b>(.*)} $line match blah regstatus blah
					regsub -all {<[^>]*>} $regstatus {} regstatus
				}
				if {[string match "*Decision comment :*" $line]} {
					regexp {(.*)<b>(.*)</b>(.*)} $line match blah regcomment blah
					regsub -all {<[^>]*>} $regcomment {} regcomment2
				}

				if {[string match "*Comment :*" $line]} {
					incr regobj 1
				}
				if {![info exists regcomment2]} {
					set regcomment2 "n/a"
				}
			}
		}
	}
	set regstatus2 [string tolower $regstatus]
	if {$regstatus2 == "pending"} {
		set regstatus "\00312$regstatus"
	} elseif {$regstatus2 == "incoming"} {
		set regstatus "\00308$regstatus"
	} elseif {$regstatus2 == "rejeced"} {
		set regstatus "\00304$regstatus"
	} elseif {$regstatus2 == "accepted"} {
		set regstatus "\00309$regstatus"
	} elseif {$regstatus2 == "ready for review"} {
		set regstatus "\00306$regstatus"
	} elseif {$regstatus2 == "cancelled by the applicant"} {
		set regstatus "\00314$regstatus"
	}
	putserv "PRIVMSG $chan :CService Status for $valchan --> $regstatus" 
	putserv "PRIVMSG $chan :Username: $reguser - Date: $regdate - Objections: $regobj - Coments: $regcomment2"
	putserv "PRIVMSG $chan :URL: $regurl"
	return 0
}

proc wt:filter {x {y ""} } {
	for {set i 0} {$i < [string length $x]} {incr i} {
		switch -- [string index $x $i] {
			"Ã©" {append y "%E9"}
			"Ã¨" {append y "%E8"}
			"Ã®" {append y "%CE"}
			"Ã‰" {append y "%E9"}
			"Ãˆ" {append y "%E8"}
			"ÃŽ" {append y "%CE"}
			"&" {append y "%26"}
			"#" {append y "%23"}
			" " {append y "+"}
			default {append y [string index $x $i]}
		}
	}
	return $y
}


################################################## ###############################


putlog "Check CService Channel Aplication check from blackshadow, updated translated and fixed for SSL by Sebastien"
