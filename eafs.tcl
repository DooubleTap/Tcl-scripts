# eafs.tcl ver. 1.0.5 - 2007.11.04
#
# Change on 1.0.5: Problems when bot discconects while running fixed. No more errors while scanning
# if host is unrechable.
#
# Change on 1.0.4: Check proxy list when voicing. Moved proxy list to memory. Activate and deactivate 
# messages now sent to the channel where command was executed. Some code cleanup. Command now work 
# for global or channel +o. Took out autoaddproxy option, too dangerous and useless. Fixed bug voicing
# nicks with brackets and not logged. Added option to send proxy messages to a back channel as msgs
# and not notices.
#
# Change on 1.0.3: changed output priorization. Changed proxy recognition including ~ in ident
#
# Change on 1.0.2: added a checking to avoid colission with other scripts on join and scanning 
# of all users in channel. Fixed security bug.
#
# Change on 1.0.1: added configuration for automatic hosts adding to the black list 
# by the bot or not, and to voice users in blacklist or not.
#
#
# This is an anti join/part flood script for eggdrop bots and Undernet Network
# It used the +D channel mode combined with the +m channel mode
# and selectively gives voice/access to users
#
# This script gives no guarantees of any kind. Use it at our own risk.
#
# Project from: #ayuda @ Undernet
# Coded by: ^The_law^  #thelawchannel @ Undernet
#

##################################
# CONFIGURATION AREA STARTS HERE #
##################################

# The channel this script will work at
set namechan "#social"

# Back channel name (optional). Set it to "" for no back channel 
set backchan "#Sebastien"

# Period between new users checks in seconds 
# (try to never go below 10 to avoid stressing the server since this will fire /names command)
set period 15

# Starting status which means if the script will start working immediately
# or will start in off status. You can activate or deactivate the script
# being a bot operator and using the commands !eafs on|off
# We found that best option is "on" because if bot goes down, and automatically get back in 
# and start working without human intervention.
set status "off" 

# Active channel modes
set active_modes "+Dm"

# Inactive channel modes
set inactive_modes "-Dm"

# Users logged in but without +x will have voice after a small delay 
# in seconds
set logged_no_x 10

# Users not logged in will have voice after a more extensive delay
set not_logged 30

# Msg to send to users logged in but without +x
# English
#set welcome_no_x "Welcome to $namechan. In a few seconds you will be voiced. Please be patient. (We are scanning you for opened ports, don't panic. Just +x to prevent this)"
# Spanish
set welcome_no_x ""

# Msg to send to users not logged in
# English
#set welcome_not_logged "Welcome to $namechan. In a minute you will be voiced. Please be patient. Consider registering on https://cservice.undernet.org/live for a udername, and login to it with usermode +x to make this wait faster. For more info join #userguide (We are scanning your ports, don't panic)"
# Spanish
set welcome_not_logged ""

# Set this to 1 if you want the script to avoid IPs/hosts in the blacklist to be voiced 
# if validated as potential proxys. Recommended, if you don't know better left it in 1.
set noproxysvoiced 1

# Set this to "f" if you want them to be onotices to the front channel, or "b" if you want them
# to be messages to the back channel. Other options will understood as "f"
set proxymsgtarget "b"

################################
# CONFIGURATION AREA ENDS HERE #
################################

# WARNING: changing anything below this line is potentially dangerous

# Set debug to 1 to get debug msgs through party line. Be careful since you 
# can get lots of them on big channels...
set debug 0

# Users to be voiced to avoid duplicated timers
set users_to_voice [list]

# List of common proxy ports (you can use your own ports if the bot bothers too much)
set proxy_ports [list 179 1080 3138 8080 8088 2080 8010 5490]

# List of hosts in blacklist
set blacklist [list]

# Timer ID of recurrent /names calls
set eafs_timer 0

########################################################################

proc eafs:start {} {
  global namechan status active_modes period blacklist eafs_timer
	global proxymsgtarget backchan

  if {[botonchan $namechan] && [botisop $namechan] && $status == "on"} {
 		# Load blacklist on memory
		set blacklist [list]

		# We open in mode +a bease we don't want an error if file does not exist
    set fp [open proxys.txt a+]
    seek $fp 0

    while {[gets $fp proxyip] >= 0} {
      if {[string trim $proxyip] != "" && [lsearch $blacklist $proxyip] == -1} {
        set blacklist [linsert $blacklist end $proxyip]
      }
    }

    close $fp

  	# Voice un-voiced and un-opped users before starting since channel will be +m 
 		set culist [chanlist $namechan]

   	foreach user $culist {
     	if {![isop $user $namechan] && ![isvoice $user $namechan]} {
       	pushmode $namechan +v $user
     	}
   	}

   	flushmode $namechan

		# Activate binds
		bind raw - 354 irc:rpl_whoreply
		bind raw - 355 irc:rpl_namreply
		bind raw - 366 irc:rpl_endofnames

		# Initial starting settings
		set users_to_voice [list]
		if {($proxymsgtarget != "f" && $proxymsgtarget != "b")
			|| $backchan == ""} {
			set proxymsgtarget "f"
		}

		# Lets start dancing!
   	putquick "MODE $namechan $active_modes"  
   	set eafs_timer [utimer $period eafs:check_names]

  } else {
    utimer 10 eafs:start 
  }
}

if {$status == "on"} {eafs:start}

# To make a safe turn off
proc eafs:stop {nick chan} {
  global namechan status inactive_modes eafs_timer

	if {$status == "off"} {
	 	# Deactivate binds
 		unbind raw - 354 irc:rpl_whoreply
 		unbind raw - 355 irc:rpl_namreply
 		unbind raw - 366 irc:rpl_endofnames

		# Turn timer off
 		if {$eafs_timer != 0} {killutimer $eafs_timer}

   	if {[botonchan $namechan] && [botisop $namechan]} {
 			# Change modes 
    	putquick "MODE $namechan $inactive_modes"  
		}	else {
   	 	puthelp "CNOTICE $nick $chan :EAFS Error: Could not turn $namechan modes to $inactive_modes"
		}
  }
}

#
# Command that will allow to activate, deactivate and check the script status
# This is available only to users registered inside the bot and with global +o 
# privilege or channel +o 
#

bind pub o|o !eafs irc:eafs

proc irc:eafs {nick uhost hand chan rest} {
  global status namechan period debug users_to_voice blacklist

  if {$rest == "on"} {
		if {$status == "off"} {
    	set status "on" 
			eafs:start
   	 	puthelp "CNOTICE $nick $chan :EAFS activated"
		} else {
   	 	puthelp "CNOTICE $nick $chan :EAFS already activated"
		}

  } elseif {$rest == "off"} {
		if {$status == "on"} {
    	set status "off"
			eafs:stop $nick $chan
    	puthelp "CNOTICE $nick $chan :EAFS deactivated"
		} else {
   	 	puthelp "CNOTICE $nick $chan :EAFS already deactivated"
		}

  } elseif {$rest == "status"} {
    puthelp "NOTICE $nick :EAFS Status: $status"

  } elseif {$rest == "debug-on"} {
    set debug 1
    puthelp "NOTICE $nick :EAFS Debug: on"

  } elseif {$rest == "debug-off"} {
    set debug 0
    puthelp "NOTICE $nick :EAFS Debug: off"

  } elseif {$rest == "voice-list"} {
    if {[llength $users_to_voice] > 0} {
			foreach {h1 h2 h3 h4 h5} $users_to_voice {
				puthelp "CNOTICE $nick $chan :$h1 $h2 $h3 $h4 $h5"
    	}
    } else {
      puthelp "CNOTICE $nick $chan :No users in list"
    }

  } elseif {[string match "addproxy*" $rest]} {
		set args [split $rest]
    if {[llength $args] == 2} {
	    set proxyip [lindex [split $rest] 1]

			if {[lsearch $blacklist $proxyip] == -1} {
				set blacklist [linsert $blacklist end $proxyip]
				eafs:saveblacklist
	      puthelp "CNOTICE $nick $chan :Added $proxyip to blacklist"
			} else {
	      puthelp "CNOTICE $nick $chan :$proxyip already in blacklist"
			}
		} else {
	    puthelp "CNOTICE $nick $chan :EAFS Syntax error: !eafs addproxy <host/ip>"
		}

  } elseif {[string match "delproxy*" $rest]} {
		set args [split $rest]
    if {[llength $args] == 2} {
	    set proxyip [lindex [split $rest] 1]

			if {[lsearch $blacklist $proxyip] != -1} {
				set blacklist [lreplace $blacklist [lsearch $blacklist $proxyip] [lsearch $blacklist $proxyip]]
				eafs:saveblacklist
	      puthelp "CNOTICE $nick $chan :Added $proxyip to blacklist"
			} else {
	      puthelp "CNOTICE $nick $chan :$proxyip not in blacklist"
			}
		} else {
	    puthelp "CNOTICE $nick $chan :EAFS Syntax error: !eafs delproxy <host/ip>"
		}
	} else {
    puthelp "CNOTICE $nick $chan :EAFS Command not found"
	}

  return 0
}

# This procedure simply do the hidden names check
proc eafs:check_names {args} {
  global namechan tid debug eafs_timer status

  if {$debug} {putlog "Checking invisible users on $namechan"}

	if {$status == "on"} {
	  putquick "NAMES -d $namechan"
  	set eafs_timer 0
	}

  return 0
}

# When we finish checking names, we restart timer to check again in xx seconds
proc irc:rpl_endofnames {from key text} {
  global status period namechan eafs_timer

  if {$status == "on" && [string match "*$namechan*" $text]} {
    set eafs_timer [utimer $period eafs:check_names]
  }

  return 0
}

# Procedure called on every reply from server to a /names command (if bind activated)
proc irc:rpl_namreply {from key text} {
  global unames tid period status eafs_timer

  set unames [split [lindex [split $text ":"] 1]] 
  foreach uname $unames {
		if {$status == "on"} {putserv "WHO $uname n%nuhart,951"}
  }

  return 0
}

# Procedure called on every /who reply
proc irc:rpl_whoreply {from key text} {
  global namechan botnick debug logged_no_x not_logged users_to_voice noproxysvoiced
  global welcome_not_logged welcome_no_x proxy_ports blacklist proxymsgtarget
	global backchan

  #text: <?> <id> <ident> <host> <nick> <username|0> :<name>

  set uinfo [split $text]
  set uident [lindex $uinfo 2]
  set uhost [lindex $uinfo 3]
  set uname [lindex $uinfo 4]
  set whoid [lindex $uinfo 1]
  set uuser [lindex $uinfo 5]
  set ureal [lindex $uinfo 6]

  # if <id> not = 951 it's not our WHO reply, 
  # also we should not continue if the WHO is about us
	# also not voice a banned user
  if {$key != 354 
      || $whoid != 951
      || [isbotnick $uname]
      || [isvoice $uname $namechan]
      || [isop $uname $namechan]
      || [matchban "${uname}!*${uident}@$uhost" $namechan]
			|| [lsearch $users_to_voice $uname] != -1} {
    return 0
  }

  if {$debug} {putlog "$uname is being checked"}

  ###############
  # User type 1 #
  ###############
  if {[string match "*.users.undernet.org" $uhost]
      && [lsearch $users_to_voice [escapebrackets $uname]] == -1
			&& ([lsearch $blacklist $uhost] == -1 || $noproxysvoiced == 0)} {

    if {$debug} {putlog "$uname is a logged +x user, we will give voice immediately"}

		if {[lsearch $users_to_voice $uname] == -1 
				&& ![isvoice $uname $namechan]} {
	   	set users_to_voice [linsert $users_to_voice end $uname]
	    givevoice [lsearch $users_to_voice [escapebrackets $uname]] $uhost
		}

  ###############
  # User type 2 #
  ###############
  } elseif {$uuser != "0"
            && [lsearch $users_to_voice [escapebrackets $uname]] == -1
						&& ([lsearch $blacklist $uhost] == -1 || $noproxysvoiced == 0)} {

    if {$debug} {putlog "$uname is a logged user, we will give voice after $logged_no_x seconds"}

    puthelp "CNOTICE $uname $namechan :$welcome_no_x"

		if {[lsearch $users_to_voice [escapebrackets $uname]] == -1 
				&& ![isvoice $uname $namechan]} {
	 		set users_to_voice [linsert $users_to_voice end $uname]
	   	utimer $logged_no_x "givevoice [lsearch $users_to_voice [escapebrackets $uname]] $uhost"
		}

  ###############
  # User type 3 #
  ###############
  } elseif {[lsearch $users_to_voice [escapebrackets $uname]] == -1} {

    if {$debug} {putlog "$uname is not logged, we will give voice after a scan"}

		set isproxy [eafs:proxyscan $uhost]
    
		if {[lsearch $blacklist $uhost] == -1 || $noproxysvoiced == 0} {
		  if {$isproxy > 0} {
				if {[lsearch $blacklist $uhost] != -1} {
					if {$proxymsgtarget == "b"} {
			     	puthelp "PRIVMSG $backchan :Blacklisted: ${uname}!${uident}@$uhost * $ureal"
					} else {
			     	puthelp "NOTICE @$namechan :Blacklisted: ${uname}!${uident}@$uhost * $ureal"
					}
				} else {
					if {$proxymsgtarget == "b"} {
			     	puthelp "PRIVMSG $backchan :Possible proxy: ${uname}!${uident}@$uhost * $ureal"
					} else {
			     	puthelp "NOTICE @$namechan :Possible proxy: ${uname}!${uident}@$uhost * $ureal"
					}
				}
			}

		  puthelp "CNOTICE $uname $namechan :$welcome_not_logged"

			if {[lsearch $users_to_voice [escapebrackets $uname]] == -1 
					&& ![isvoice $uname $namechan]} {
     		set users_to_voice [linsert $users_to_voice end $uname]
	     	utimer $not_logged "givevoice [lsearch $users_to_voice [escapebrackets $uname]] $uhost"
			}
		}

		if {$isproxy == 0} {
			set blacklist [lreplace $blacklist [lsearch $blacklist $uhost] [lsearch $blacklist $uhost]]
			eafs:saveblacklist
		}
  }

  return 0
}

# Procedure to give voice and maintain voicing list
proc givevoice {idx host} {
  global namechan users_to_voice debug blacklist noproxysvoiced

  if {[lsearch $blacklist $host] == -1 || $noproxysvoiced == 0} {
   	if {$debug} {putlog "Giving voice to $nick"}
   	putquick "MODE $namechan +v [lindex $users_to_voice $idx]"
  }

  set users_to_voice [lreplace $users_to_voice $idx $idx]

  return 0
}

# Procedure to save blacklist
proc eafs:saveblacklist {} {
	global blacklist

  set fp [open proxys.txt w]
	foreach proxyip $blacklist {
		puts $fp "$proxyip"
	}

  close $fp

	return 0
}

# Procedure to scan a host and see if it's a possible proxy
proc eafs:proxyscan {host} {
	global proxy_ports

	set ret 0

  foreach port $proxy_ports {
    if {$ret == 0} {
			if {[catch {socket -async $host $port} idx] == 0} {
  			if {[fconfigure $idx -error] == ""} {
          incr ret
          close $idx
          break
        }
			}
    }
  }

	return $ret
}

# To escape brackets characters in nicks like [ & ]
proc escapebrackets {svar} {
  set len [expr [string length $svar]-1]

  while {$len >= 0 && [string last "\[" $svar $len] != -1} {
    set pos [string last "\[" $svar $len]
    set svar [string replace $svar $pos $pos "\\\["]
    set len [expr $pos-1]
  }

  set len [expr [string length $svar]-1]

  while {$len >= 0 && [string last "\]" $svar $len] != -1} {
    set pos [string last "\]" $svar $len]
    set svar [string replace $svar $pos $pos "\\\]"]
    set len [expr $pos-1]
  }

  return $svar
}

# This is to make some cleanup on rehash and avoid duplicated bindings or timers
bind evnt 0 prerehash irc:prerehash
proc irc:prerehash {type} {
  global status eafs_timer

	# To stop timer of /names work
	if {$eafs_timer != 0} {killutimer $eafs_timer}
 
  unbind pub o|o !eafs irc:eafs
  unbind raw - 354 irc:rpl_whoreply  
  unbind raw - 355 irc:rpl_namreply
  unbind raw - 366 irc:rpl_endofnames

  return 0
}

# This is to prevent problems if we disconnect from server while running
bind evnt - disconnect-server eafs:disc
proc eafs:disc {type} {
	global status nick namechan

	if {$status == "on"} {
  	set status "off"
  	eafs:stop $nick $namechan
  	set status "on"
  	eafs:start
	}
}

putlog "EAFS module loaded v1.0.5 - 20071104"

