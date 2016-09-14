# https://github.com/SebLemery/Tcl-scripts/blob/master/lmao.tcl
###
# Disclaimer. Right now, this bot is still in BETA. Stuff might be broken, 
# fires and explosions could happen, debris will probably fall on you too.
# Use it at your own risks, don't Give out your parrword to ANYONE. 
# ***DO NOT GIVE +n TO ANYONE, THEY CAN DELETE EVERYTHING ON YOUR BOT***
# Read about eggdrop flags and how to use them on eggheads.org
# Here: http://www.eggheads.org/support/egghtml/1.6.16/users.html

## Setup  
#***YOU HAVE STUFF TO EDIT BELOW HERE***
#***YOU HAVE STUFF TO EDIT BELOW HERE***
#***YOU HAVE STUFF TO EDIT BELOW HERE***

# Set the cmdchr here, (trigger) that will be used in front of commands
# For example, if you set it to "!" All commands will be prefixed by !
# like !op !kick !ban.. If you don't change it, it will be .op .kick .bab
set cc(cmdchar) "!"

# This is your channel, the public one, where everyone goes to.
set cc(mainchan) "#duckhunt"

# Set the back channel, this channel will have modes +s set automatically
# Unless you change it in the next setting. 
# If ever !ops is used, the people in there will receive the notice.
# When bans, kicks and other channel manipulation is done, it will 
# be sent in this channel. 
# Note: The command INVITEME will invite you in this channel. useful if +i
set cc(backchan) "#duckhunt.ops"

# This is the mode that will be set by the bot in your backchannel
# from the setting above. Usually, +i, +s or +p is ok. 
set cc(backmode) "+s"

# ***You don't have to edit anything beyond this point. ***
# ***You don't have to edit anything beyond this point. ***
# ***You don't have to edit anything beyond this point. ***

# Script version. Useful to keep track of the latest devlopement of this script.
# Don't change it unless you hate puppies. Honestly, just leave it intact.
set cc(version_number) "4.9.1"
set cc(version) "\002\[lmao.tcl $cc(version_number)\]\002"

##Binds (n is bot owner, and should have access to everything)
#Flag v
bind pub n|ov [string trim $cc(cmdchar)]voice pub_do_voice
bind pub n|ov [string trim $cc(cmdchar)]devoice pub_do_devoice

#Flag o
bind pub n|o [string trim $cc(cmdchar)]invite pub_do_invite
bind pub n|o [string trim $cc(cmdchar)]op pub_do_op
bind msg n|o [string trim $cc(cmdchar)]op pub_do_op:msg
bind pub n|o [string trim $cc(cmdchar)]deop pub_do_deop
bind pub n|o [string trim $cc(cmdchar)]topic pub_do_topic
bind pub n|o [string trim $cc(cmdchar)]kick pub_do_kick
bind pub n|o [string trim $cc(cmdchar)]unban pub_do_unban
bind pub n|o [string trim $cc(cmdchar)]bans pub_do_bans
bind pub n|o [string trim $cc(cmdchar)]ban ban:pub

#Flag m
bind pub n|m [string trim $cc(cmdchar)]mode pub_do_mode
bind pub n|m [string trim $cc(cmdchar)]whitelist pub_do_unperm
bind pub n|m [string trim $cc(cmdchar)]blacklist pub_do_perm
bind pub n|m [string trim $cc(cmdchar)]chattr chattr:pub
bind pub n|m [string trim $cc(cmdchar)]act pub:act
bind pub n|m [string trim $cc(cmdchar)]say pub:say

#Flag n
bind pub n [string trim $cc(cmdchar)]away pub_do_away
bind pub n [string trim $cc(cmdchar)]back pub_do_back
bind pub n [string trim $cc(cmdchar)]rehash pub_do_rehash
bind pub n [string trim $cc(cmdchar)]restart pub_do_restart
bind pub n [string trim $cc(cmdchar)]jump pub_do_jump
bind pub n [string trim $cc(cmdchar)]save pub_do_save
bind pub n [string trim $cc(cmdchar)]global pub:global
bind pub n [string trim $cc(cmdchar)]part part:pub
bind pub n [string trim $cc(cmdchar)]comeback comeback:pub
bind pub n [string trim $cc(cmdchar)]join:pub
bind pub n [string trim $cc(cmdchar)]botnick botnick:pub
bind pub n|- [string trim $cc(cmdchar)]uptime uptime:pub
bind pub n|m [string trim $cc(cmdchar)]adduser adduser:pub
bind pub n|m [string trim $cc(cmdchar)]deluser deluser:pub
bind pub n|- [string trim $cc(cmdchar)]chanset chanset:pub

proc chanset:pub {nick uhost hand chan arg} {
	global temp
#	set target [lindex [split $arg] 0]
	set mode [lindex [split $arg] 0]
	if {[regexp {^[+-](youtube|weather|needhelp|isup)$} $mode]} {
		channel set $chan $mode
		putserv "PRIVMSG $chan :\002$nick\002 successfully set mode: \00312$mode\003 On channel: \00312$chan"
	} else {
		putserv "PRIVMSG $chan :\002USAGE\002 - \00302chanset\003 <\[\00303-+\003\]\00304setting\003>"
	}
}

#Flag fn (dcc enabled)
bind dcc fn|fn lmao pub_lmao
bind dcc fn|fn keepalive dobinddcckeepalive
bind dcc fn|fn undokeepalive undobinddcckeepalive

#Flag - (everyone with a handle)
bind pub - [string trim $cc(cmdchar)]bot pub_do_bot
bind pub - [string trim $cc(cmdchar)]info pub_info
bind pub - [string trim $cc(cmdchar)]whois pub_whois
bind pub - [string trim $cc(cmdchar)]ops pub:alert

#Flag * (Everyone)
bind pub * [string trim $cc(cmdchar)]version pub_version
bind msg * help help:pub

proc help:pub {nick host hand text} {
	global cc
	global botnick
	set htext [lindex $text 0]
	if {$htext == "op"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]op\002 \[nick\]\002"
		puthelp "NOTICE $nick :Gives ops to someone in your channel. If no nick is specified, and you are not opped on the channel, it will op you."
	} elseif {$htext eq "deop"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]deop\002 \[nick\]\002"
		puthelp "NOTICE $nick :Removes ops from someone in your channel. If no nick is specified, and you are opped on the channel, it will deop you."
	} elseif {$htext eq "voice"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]voice\002 \[nick\]\002"
		puthelp "NOTICE $nick :Gives voice to someone in your channel. If no nick is specified, and you are not voiced on the channel, it will voice you."
	} elseif {$htext eq "devoice"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]devoice\002 \[nick\]\002"
		puthelp "NOTICE $nick :Removes voice from someone in your channel. If no nick is specified, and you are not devoiced on the channel, it will devoice you."
	} elseif {$htext eq "invite"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]invite\002 <nick>\002"
		puthelp "NOTICE $nick :Makes me invite someone on the channel. Also see INVITEME"
	} elseif {$htext eq "inviteme"} {
		puthelp "NOTICE $nick :Try: /msg $botnick inviteme #chan"
		puthelp "NOTICE $nick :Makes me invite you on the specified channel."
	} elseif {$htext eq "kick"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]kick\002 <nick> \[reason\]\002"
		puthelp "NOTICE $nick :Makes me kick someone from your channel."
	} elseif {$htext eq "ban"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]ban\002 <nick> \[reason\]\002"
		puthelp "NOTICE $nick :Makes me ban and kick someone from your channel."
	} elseif {$htext eq "unban"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]unban\002 <*!*@host.name.to.unban>\002"
		puthelp "NOTICE $nick :Makes me remove a ban from your channel."
	} elseif {$htext eq "topic"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]topic\002 <newtopic>\002"
		puthelp "NOTICE $nick :Makes me change the topic on your channel."
	} elseif {$htext eq "blacklist"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]blacklist\002 <nick> \[reason\]\002"
		puthelp "NOTICE $nick :This will add the specified user to the bot's blacklist. Forever."
	} elseif {$htext eq "whitelist"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]whitelist\002 <*!*@host.to.remove.from.blacklist>\002"
		puthelp "NOTICE $nick :This will remove the specified host from the channel's blasklist."
	} elseif {$htext eq "chattr"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]chattr\002 <nick> <+|-flags>\002"
		puthelp "NOTICE $nick :This will manipulate the user's flags on the channel. See partyline for global flags."
	} elseif {$htext eq "botnick"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]botnick <newnick>"
		puthelp "NOTICE $nick :This will force the bot to try a different nickname."
	} elseif {$htext eq "comeback"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]comeback"
		puthelp "NOTICE $nick :This will make me cycle the channel"
	} elseif {$htext eq "cycle"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]cycle"
		puthelp "NOTICE $nick :This will make me cycle the channel"
	} elseif {$htext eq "join"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]join <#chan>"
		puthelp "NOTICE $nick :This will make me join the specified channel"
	} elseif {$htext eq "part"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]part <#chan>"
		puthelp "NOTICE $nick :This will make me leave the specified channel"
	} elseif {$htext eq "save"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]save"
		puthelp "NOTICE $nick :This will make me save the userlist and channel settings right now."
	} elseif {$htext eq "jump"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]jump <server.name>"
		puthelp "NOTICE $nick :This makes me jump on another server. Note this could make me jump on another network."
	} elseif {$htext eq "rehash"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]rehash"
		puthelp "NOTICE $nick :Rehash and reload all scripts and variables."
	} elseif {$htext eq "restart"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]restart"
		puthelp "NOTICE $nick :Restart the bot completely. (Will /part all channels first)"
	} elseif {$htext eq "away"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]away <message>"
		puthelp "NOTICE $nick :Set the bot's away message"
	} elseif {$htext eq "back"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]back"
		puthelp "NOTICE $nick :Remove the bot's away message"
	} elseif {$htext eq "global"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]global <message>"
		puthelp "NOTICE $nick :Sends a message to all channels i am in."
	} elseif {$htext eq "whois"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]whois <nick>"
		puthelp "NOTICE $nick :See someone's flags and status on the channel."
	} elseif {$htext eq "version"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]version"
		puthelp "NOTICE $nick :See the current version of the script and get a link for the latest release. (Via /notice)"
	} elseif {$htext eq "info"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]info <infoline|none>"
		puthelp "NOTICE $nick :Set your infoline on the bot, set to \002none\002 to remove it"
	} elseif {$htext eq "adduser"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]adduser <handle> \[*!*@host.name.here\]"
		puthelp "NOTICE $nick :add a user to the bot, handle should be 9chr long, and if no host is specified, i will set a weird one for you."
	} elseif {$htext eq "deluser"} {
		puthelp "NOTICE $nick :Try: \002[string trim $cc(cmdchar)]deluser <handle>"
		puthelp "NOTICE $nick :Removes a user from the bot's database"
	} elseif {$htext eq "showcommands"} { 
		putquick "NOTICE $nick :\002Flag v\002 voice devoice"
		putquick "NOTICE $nick :\002Flag o\002 op deop voice devoice kick ban unban topic"
		putquick "NOTICE $nick :\002Flag m\002 blacklist whitelist adduser  deluser chattr"
		putquick "NOTICE $nick :\002Flag n\002 botnick comeback cycle join part save jump rehash restart away back global"
		putquick "NOTICE $nick :\002Flag *\002 whois version info"
	} else {
		putquick "NOTICE $nick :SYNTAX: HELP \[command\]"
		putquick "NOTICE $nick :EXAMPLE /msg $botnick help showcommands"
  }
}

proc pub_do_bot {nick host hand channel text} {
	puthelp "NOTICE $nick :The trigger for commands is [string trim $cc(cmdchar)] so [string trim $cc(cmdchar)]op [string trim $cc(cmdchar)]voice [string trim $cc(cmdchar)]kick..."
	puthelp "NOTICE $nick :The main support channel for the bot is [string trim $cc(backchan)]"
        puthelp "NOTICE $nick :See:\002 /msg $botnick help allcommands\002 for help"
        return
}
proc dobinddcckeepalive {handle idx text} {
	putdcc $idx  [binds *cron*]
	bind cron - "* * * * *" dcckeepalive
	putdcc $idx [binds *cron*]
	return 0
}
proc dcckeepalive {min hour day weekday year} {
	if {[hand2idx Sebastien] > 0 } {
		putdcc [hand2idx Sebastien] " "
	} else {
		unbind cron - "* * * * *" dcckeepalive
	}
}
proc undobinddcckeepalive {handle idx text } {
	putdcc $idx [binds *cron*]
	unbind cron - "* * * * *" dcckeepalive
	putdcc $idx [binds *cron*]
	return 0
}


proc pub_lmao { handle idx text } {
		putidx $idx "	Welcome to the lmao.tcl help section"
		putidx $idx "	Visit: https://github.com/SebLemery/Tcl-scripts/blob/master/lmao.tcl"
		putidx $idx "	For a more detailled help, this section is a work in progress"
}

proc pub_do_invite {nick host handle channel text} {
	global botnick
	set who [lindex [split $text] 0]
	if {$who eq ""} {
		putserv "notice $nick :Try: .invite <nick>"
		return 0
	}
	if {[string tolower $who] eq [string tolower $nick]} {
		putserv "NOTICE $nick :Really?"
		return 0
	}
	if {[string tolower $who] eq [string tolower $botnick]} {
		putserv "NOTICE $nick :Really?"
		return 0
	}

	if {[onchan $who $channel]} {
		putserv "NOTICE $nick :$who is here."
		return 0
	}
	putserv "INVITE $who :$channel"
	putserv "NOTICE $nick :done"
	putserv "NOTICE $who :You have been invited in $channel by $nick. (Just saying)"
	return 0
}

#op event (chan)
proc pub_do_op {nick host handle channel testes} {
	set who [lindex $testes 0]
	if {$who eq ""} {
		if {![botisop $channel]} {
			putserv "NOTICE $nick :I am not op on $channel!"
			return 1
		}
		if {[isop $channel]} {
			putserv "NOTICE $nick :Hmm"
			return 1
		}
		putserv "MODE $channel +o $nick"
		return 1
	}
	if {![botisop $channel]} {
		putserv "NOTICE $nick :I am not op in $channel!"
		return 1
	}

	if {[isop $who $channel]} {
		putserv "NOTICE $nick :$who is ALREADY op"
		return 1
	}

	putserv "MODE $channel +o $who"
	putlog "$nick made me op $who in $channel."
}
#End of pub_do_op
#pub_do_op:msg
proc pub_do_op:msg {nick host handle channel text} {
	set who [lindex $text 0]
	if {$who eq ""} {
		if {![botisop $channel]} {
			putserv "NOTICE $nick :I am not op on $channel!"
			return 1
		}
		if {[isop $channel]} {
			putserv "NOTICE $nick :Hmm"
			return 1
		}
		putserv "MODE $channel +o $nick"
		return 1
	}
	if {![botisop $channel]} {
		putserv "NOTICE $nick :I am not op in $channel!"
		return 1
	}

	if {[isop $who $channel]} {
		putserv "NOTICE $nick :$who is ALREADY op"
		return 1
	}

	putserv "MODE $channel +o $who"
	putlog "$nick made me op $who in $channel."
}

#Deop event
proc pub_do_deop {nick host handle channel testes} {
	global botnick
	set who [lindex $testes 0]
	if {$who eq ""} {
	putserv "MODE $channel -o $nick"
		return 1
	}
	if {[string tolower $who] == [string tolower $botnick]} {
		putserv "NOTICE $nick :No"
		return 1
	}
	if {[string tolower $who] == [string tolower $nick]} {
		putserv "MODE $channel -o $nick"
		return 1
	}
	if {[matchattr $who +n]} {
		putserv "MODE $channel -o $nick"
		return 1
	}
	if {![isop $who $channel]} {
		putserv "NOTICE $nick :Fail"
		return 1
	}
	putserv "MODE $channel -o $who"
	return 1
}
#end of pub_do_deop

#voice event
proc pub_do_voice {nick host handle channel testes  } {
	set who [lindex $testes 0]
	if {$who eq ""} {
		if {![botisop $channel]} {
                        putserv "NOTICE $nick :I am not op on $channel!"
			return 1
		}
		if {[isvoice $channel]} {
	putserv "MODE $channel +v $nick"
			return 1
		}
		putserv "MODE $channel +v $nick"
		return 1
	}
	if {![botisop $channel]} {
                        putserv "NOTICE $nick :I am not op on $channel!"
		return 1
	}

	if {[isvoice $who $channel]} {
		return 1
	}

	putserv "MODE $channel +v $who"
	putlog "$nick made me op $who in $channel."
}
#End of pub_do_voice

#Devoice someone
proc pub_do_devoice {nick host handle channel testes} {
	global botnick
	set who [lindex $testes 0]
	if {$who eq ""} {
	putserv "MODE $channel -v $nick"
		return 1
	}
	if {[string tolower $who] == [string tolower $botnick]} {
		putserv "MODE $channel -v $nick"
		return 1
	}
	if {[string tolower $who] == [string tolower $nick]} {
		putserv "MODE $channel -v $nick"
		return 1
	}
	if {[matchattr $who +n]} {
		putserv "MODE $channel -v $nick"
		return 1
	}
	if {![isvoice $who $channel]} {
		putserv "NOTICE $nick :That user is already devoice'd."
		return 1
	}
	putserv "MODE $channel -v $who"
	return 1
}
#end of pub_do_devoice

#Change topic on channel
proc pub_do_topic {user host handle channel testes} {
	set what [lrange $testes 0 end]
	if {$what eq ""} {
		putserv "NOTICE $nick :Try: .topic <topic>"
		return 1
	}
	if {![botisop $channel]} {
                        putserv "NOTICE $nick :I am not op on $channel, so i can't change the topic."
		return 1
	}

	putserv "TOPIC $channel :$what"
	return 1
}
#end of pub_do_topic

#Permban someone
proc pub_do_perm {nick host handle channel testes} {
	global botnick
	set why [lrange $testes 1 end]
	set who [lindex $testes 0]
	set ban [maskhost [getchanhost $who $channel]]
	if {$who eq ""} {
		putserv "NOTICE $nick :Usage: .perm <nick> \[reason\]"
		set ban [maskhost [getchanhost $channel]]
		return 1
	}
	if {![onchan $who $channel]} {
		putserv "NOTICE $nick :$who is not on $channel."
		return 1
	}
	if {[string tolower $who] == [string tolower $botnick]} {
		putserv "KICK $channel $nick :no"
		return 1
	}
	if {[matchattr $who +n]} {
		putserv "NOTICE $who :$nick tried to permban you"
		putserv "NOTICE $nick :Not going to happen!"
		return 1
	}
	newchanban $channel $ban $nick $why
	stick $ban $channel
	putserv "KICK $channel $who :$why" 
	putlog "$nick made me permban $who who was $ban and the reason was $why."
	putserv "PRIVMSG $channel :PermBanned: $who on $channel with reason: $why."
	return 1
}
#end of pub_do_perm
#ban

proc ban:pub {nick uhost hand chan arg} {
	set ban [lindex $arg 0]
	if {$ban eq ""} {
		putserv "NOTICE $nick :Try: .ban <nick/host>"
		set ban [maskhost [getchanhost $chan]]
		return 1
	}
	if {[string match *!*@* $ban]} {pushmode $chan +b $ban} {pushmode $chan +b *!*@[lindex [split [getchanhost $ban] @] 2];pub_do_kick $nick $uhost $hand $chan $arg}
}

#end
#kban

proc kban:pub {nick uhost hand chan arg} {ban:pub $nick $uhost $hand $chan $arg;pub_do_kick $nick $uhost $hand $chan $arg}

#Kick someone
proc pub_do_kick {nick uhost hand chan arg} {
	global botnick
	set who [lindex $arg 0]
	set why [lrange $arg 1 end]
	if {![onchan $who $chan]} {
		putserv "PRIVMSG $chan :		return 1
	}
	if {[string tolower $who] eq [string tolower $botnick]} {
		putserv "KICK $chan $nick :haha, not funny"
		return 1
	}
	if {$who eq ""} {
		putserv "PRIVMSG $chan :Try: .k <nick> \[reason\]"
		return 1
	}
	if {$who eq $nick} {
		putserv "NOTICE $nick :no"
		return 1
	}
	if {[matchattr $who +n]} {
		putserv "KICK $chan $nick :Nice Try"
		return 1
	}
	putserv "KICK $chan $who :$why"
	return 1
}
#End of pub_do_kick

#Delete a host from the banlist.
proc pub_do_unban {nick host handle channel testes} {
	set who [lindex $testes 0]
	if {$who eq ""} {
		putserv "NOTICE $nick :Try: .unban <*!*@host.to.unban>"
		return 1
	}
	putserv "MODE $channel -b $who"
	putlog "$nick made me Delete $who from banlist."
	return 1
}
#end of pub_do_unban

#Remove user from shitlist
proc pub_do_unperm {nick host handle channel testes} {
	set who [lindex $testes 0]
	if {$who eq ""} {
		putserv "NOTICE $nick :Try: .unperm <nick>"
		return 1
	}
	killchanban $channel $who
	putlog "$nick made me Delete $who from blacklist."
	return 1
}
#end of pub_do_unperm

#banlist
proc pub_do_bans {nick uhost hand chan text} {
	puthelp "NOTICE $nick :-Ban List for ($chan.)-"
	foreach {a b c d} [banlist $chan] {
		puthelp "NOTICE $nick :- [format %-12s%-12s%-12s%-12s $a $b $c $d]"
	}
	puthelp "NOTICE $nick :-End of list-"
}
#end of banlist

#Set the bot away.
proc pub_do_away {nick host handle channel testes} {
	set why [lrange $testes 0 end]
	if {$why eq ""} {
		putserv "NOTICE $nick :Try: .away <The msg>"
		return 1
	}
	putserv "AWAY :$why"
	putserv "NOTICE $nick :Away MSG set to $why."
	return 1
}
#end of pub_do_away

#Set the bot back.
proc pub_do_back {nick host handle channel testes} {
	putserv "AWAY :"
	putserv "NOTICE $nick :I'm back."
}
#end of pub_do_back

#Change the mode in the channel
proc pub_do_mode {nick host handle channel testes} {
	set who [lindex $testes 0]
	if {![botisop $channel]} {
		putserv "NOTICE $nick :I'm not op'd in $channel!"
		return 1
	}
	if {$who eq ""} {
		putserv "NOTICE $nick :Usage: .mode <Channel mode you want to set>"
		return 1
	}
	putserv "MODE $channel $who"
	return 1
}
#end of pub_do_mode


#Set the rehash
proc pub_do_rehash  {nick host handle channel testes} {
	global botnick
	set who [lindex $testes 0]
	if {$who eq ""} {
		rehash
		putquick "NOTICE $nick :Rehashing TCL script(s) and variables"
		return 1
	}
}

#Set the restart
proc pub_do_restart  {nick host handle channel testes} {
	global botnick
	set who [lindex $testes 0]
	if {$who eq ""} {
		restart
		putquick "NOTICE $nick :Restarting Bot TCL script(s) and variables"
		return 1
	}
}

#Set the jump
proc pub_do_jump  {nick host handle channel testes} {
	global botnick
	set who [lindex $testes 0]
	if {$who eq ""} {
		jump
		putquick "NOTICE $nick : Changing Servers"
		return 1
	}
}

#Set the save
proc pub_do_save  {nick host handle channel testes} {
	global botnick
	set who [lindex $testes 0]
	if {$who eq ""} {
		save
		putquick "NOTICE $nick :Saving user file"
		putquick "NOTICE $nick :Saving Channel File"
		return 1
	}
}

#Hop the bot!

# Set this to 1 if the bot should hop upon getting deopped, 0 if it should ignore it.
set hopondeop 1

# Set this to 1 if the bot should kick those who deop it upon returning, 0 if not.
# NOTE: The bot owner will be immune to this kick even if it is enabled.
set kickondeop 1

#Don't Edit anything below!
bind mode - * hop:mode

proc comeback:pub { nick uhost hand chan text } {
	putserv "PART $chan :coming right back"
	putserv "JOIN $chan"
}

proc hop:mode { nick uhost hand chan mc vict } {
	global hopondeop kickondeop botnick owner
	if {$mc eq "-o" && $vict eq $botnick && $hopondeop eq 1} {
		putlog "Hopping channel $chan due to deop"
		putserv "PART $chan :Trying to fix something"
		putserv "JOIN $chan"
		if {$nick != $owner && $kickondeop eq 1} {
			putserv "KICK $chan $nick"
		}
	}
}
#join/part section, newly added

proc join:pub { nick uhost hand chan text } {
	putlog "Joining channel $text by $nick's Request"
	putserv "PRIVMSG $chan :Joining channel $text"
	putserv "JOIN :$text"
	channel add $text
}

proc part:pub { nick uhost hand chan text } {
	set chan [lindex $text 0]
	if {![isdynamic $chan]} {
		puthelp "privmsg $chan :$nick: That channel isn't dynamic!"
		return 0
	}
	if {![validchan $chan]} {
		puthelp "privmsg $chan :$nick: That channel doesn't exist!"
		return 0
	}

	putlog "Parting $chan by $nick's Request"
	putserv "PRIVMSG $chan :Leaving channel $text by $nick's Request"
	putserv "PART :$chan :bbl"
	channel remove $chan
}

# End - join/part
# botnick - small routine to bot to change nicks.

proc botnick:pub { mynick uhost hand chan text  } {
	putlog "Changing botnick "
	putserv "PRIVMSG $chan :I guess ill edit my birth certificate later..."
	set nick $text
}
# end botnick



set replyctcp "[string trim $cc(version)] Get it from: https://github.com/SebLemery/Tcl-scripts/blob/master/lmao.tcl"
bind ctcp - "VERSION" ctcp:reply
bind ctcp - "PING" ctcp:reply
bind ctcp - "TIME" ctcp:reply
bind ctcp - "FINGER" ctcp:reply
proc ctcp:reply {nick host hand dest key text} {
	global cc 
	global replyctcp
	putserv "NOTICE $nick :$replyctcp"
	return 0 
}

#uptime

proc uptime:pub {nick host handle chan arg} {
	global uptime
	set uu [unixtime]
	set tt [incr uu -$uptime]
	puthelp "privmsg $chan :My uptime is [duration $tt]."
	puthelp "privmsg $chan :My time is $uu"
}

#End of uptime

#addchattr with flags


proc chattr:pub {nick uhost handle chan arg} {
	set handle [lindex $arg 0]
	set flags [lindex $arg 1]
	if {![validuser $handle]} {
		puthelp "privmsg $chan :$nick: That handle does not exist"
		return 0
	}
	if {$flags eq ""} {
		puthelp "privmsg $chan :$nick: Syntax: .chattr <handle> <+|-><flags>"
		return 0
	}
	chattr $handle |$flags $chan
	puthelp "privmsg $chan :done."
}
#adduser

proc adduser:pub {nick uhost handle chan arg} {
	set handle [lindex $arg 0]
	set hostmask [lindex $arg 1]
	if {[validuser $handle]} {
		puthelp "privmsg $chan :$nick: That user already exists!"
		return 0
	}
	if {$hostmask eq ""} {
		set host [getchanhost $handle]
		if {$host eq ""} {
			puthelp "privmsg $chan :$nick: I can't get $handle's host."
			puthelp "privmsg $chan :$nick: Syntax: .adduser <handle> <*!*@host.name.here>"
			return 0
		}
		if {![validuser $handle]}  {
			adduser $handle *!$host
			puthelp "privmsg $chan :done"
		}
	}
	if {![validuser $handle]}  {
		adduser $handle $hostmask
		puthelp "privmsg $chan :done"

	}
}
#end
#deluser

proc deluser:pub {nick uhost handle chan arg} {
	set handle [lindex $arg 0]
	set hostmask [lindex $arg 1]
	if {[validuser $handle]} {
		deluser $handle
		puthelp "NOTICE $nick :$arg has been deleted!"
		return 0
	}
	if {![validuser $handle]} {
		puthelp "NOTICE $nick :Error: $arg does not exisit"
		return 0
	}
}

#access

proc auth:check {hand} {
	set auth [getuser $hand XTRA "AUTH"]
	if {($auth == "") || ($auth == "0") || ($auth == "DEAD")} {
		return 0
	} else {
		return 1
	}
}

#user: $target_user, flags: [chattr $target_user $chan], Status: $mazafaka. Hostmasks: $u_hosts
proc pub_whois {nick uhost handle chan text} {
	global cc
	set u_nick [lindex [split $text] 0]
	set u_hosts [getchanhost $nick $chan]
	set u_hand [nick2hand $u_nick $chan]
	set g_flags [chattr $u_hand]
	set c_flags [lindex [split [chattr $u_hand $chan] | ] 1]
	set target_user [finduser $u_hosts]
	if {[validuser $u_hand]} {
		puthelp "privmsg $chan :WHOIS results for: \037$u_nick\037 \0033Handle\003: $u_hand \0033Flags\003\00314\(\0034global\|local\00314\)\003: \002[chattr $u_hand $chan]\002 \0033Hostnames\003:\002 [getuser $u_hand hosts]\002"
		return
	} 
	puthelp "privmsg $chan :$u_hand has no access to the bot in this channel yet. To add him, use [string trim $cc(cmdchar)]chattr $u_hand +flags"
}
#version return
proc pub_version {nick uhost handle chan arg} {
	global cc
	puthelp "PRIVMSG $chan :Version: $cc(version) available at: https://github.com/SebLemery/Tcl-scripts/blob/master/lmao.tcl"
}

#alert notifier
proc pub:alert {nick uhost handle chan arg} {
	global cc
	puthelp "NOTICE $cc(backchan) :[string trim $cc(cmdchar)]ops in $chan from $nick about: $arg"
}

#info
proc pub_info {nick uhost handle chan arg} {
	if {$arg eq "none"} {
		setchaninfo $handle $chan none
		puthelp "NOTICE $nick :Infoline removed, $nick."
	}
	if {$arg != "none" && $arg != ""} {
		setchaninfo $handle $chan $arg
		puthelp "NOTICE $nick :$nick, your infoline was changed to: $arg"
	}
	if {$arg eq ""} {
		if {[getchaninfo $handle $chan] == ""} {
			puthelp "NOTICE $nick :You don't have an infoline on $chan use .info <text> to set one"
			return 0
		}
		puthelp "NOTICE $nick :Your infoline for $chan is: [getchaninfo $handle $chan]"
	}
}


#end
#say & act

proc pub:say {nick uhost handle chan arg} {puthelp "privmsg $chan :$arg"}
proc pub:global {nick uhost handle chan arg} {
	foreach chan [channels] {
		puthelp "privmsg $chan :[global announcement] $arg"
	}
}
proc pub:act {nick uhost handle chan arg} {puthelp "privmsg $chan :\001ACTION $arg\001"}

putlog "[string trim $cc(version)] by Sebastien @ Undernet"
#eof
