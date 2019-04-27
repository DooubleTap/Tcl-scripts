#############################################################################
# Script info:
#  Uworld/EVA for ircu 2008
#  This Bot is a MUST on any ircu/Nefarious2 network. It will allow you to
#  see every join/part/nick/kick/connections/disconnections happening.
#  I recomment not to allow every staff members, but only network admins
#  that you 100% trust, to join the channel where EVA will run. 
#############################################################################    
# Credits:
#  Version 1 : Monday January 5 2008
#  Authors: Cesar - Progs E-mail: (unknown PM me for edit on GitHub)
#  Editor: Seb/xplorer E-Mail: seb@abovenet.org
#############################################################################
# Compatible P10 extended numeric (ircu2.10.10.*+)
# Using Allmost Everything that UWORLD normally does.
# (gline/kill/kick/mode/badchan/xwho/compte-clones/trust/clone|collide)
# Flags:
# O (mode serveur, xwho, kick)
# K (kill, chankill, hostkill)
# G (gline)
# N (Adminstration: connection, badchans)
# Z (Allow Actions on IRCOPS)
# P (Clones Controls)
#############################################################################
# You Are Required to add a connection Block on the Hub So Eva Will Launch  #
#############################################################################

### Configuration

#UWorld's Server Name
set uw(serv) Hub.Network.Org
set uw(sinfo) "Acknowledge"
#The name of the server that will have UW/Eva
set uw(rserv) EVA.NETWORK.ORG
#IP,port,pass UW/EVA's Server.
set uw(link) **********
set uw(port) **********
set uw(pass) **********
set uw(chan) #Eva
set uw(defr) "Forced Quit"
set uw(num) F3
#Nick!ident@host
set uw(nick) EVA
set uw(host) Eva.Service.Bot
set uw(ident) Eva
set uw(rname) "To Protect And To Serv"
set uw(chanclone) #EVA
#Max amount of legal clones before gline
set uw(clone) 5
set uw(glineclonetps) 3600
set uw(glinecloneraison) "Too many connections from your host, ghost"
#temps d'xclose en minutes (0 > Does not leave unless its splitted)
set uw(xclosetime) 30

###  Proceeds

# Server life

proc uwevent {idx arg} {
 if {$arg == ""} {
  putserv "PRIVMSG $::uw(chan) :Service Disconnected! Restarting in 5 seconds!"
  utimer 5 {doxco -s}
  return 1
 }
catch {
  global uw action ircop nickw oper numserver trust nickn
  set arg [split $arg]
  set event [lindex $arg 1]
  set pref [lindex $arg 0]
 #putlog "uwevent debug: idx($idx) arg($arg)"
  if {$event=="G"} {send "$uw(num) Z $uw(serv) :$uw(rserv)";return 0}
  if {$event=="N"} {
    global clone nickn num
    if {[lindex $arg 4]!=""} {
      set i 8
      set host [lindex $arg 6]
      set nick [lindex $arg 2]
      set umodes [lindex $arg 7]
      set id [lindex $arg 5]
      if {[string index $umodes 0] == "+"} {
        incr i
        if [string match +*r* $umodes] {incr i}
        if [string match +*H* $umodes] {incr i}
        if [string match +*h* $umodes] {incr i}
      }
      set num($nick) [set nm [lindex $arg $i]]
      set nickn($nm) $nick
      set clone($nm) "$host $id"
      if [string match +*o* $umodes] {set oper($nm) "1 [unixtime]"}

      set is_trusted [isindb $trust(hostlist) $host]
      if [info exists clone($host)] {
        incr clone($host) 1
        if {$is_trusted != -1} {
          dccbroadcast "Clones \[$clone($host)\] $host : $nick!$id \0034Trusted"
        } else {
          dccbroadcast "Clones \[$clone($host)\] $host : $nick!$id"
        }
      } else {set clone($host) 1}

      if {$clone($host) >= $uw(clone) && ($is_trusted == -1 || ($trust(clones!$is_trusted) != 0 && $clone($host) > $trust(clones!$is_trusted)))} {
	 send "$uw(num) GL * +*!*@$host $uw(glineclonetps) [unixtime] [expr [unixtime] + $uw(glineclonetps)] :\[$clone($host)\] [expire $uw(glineclonetps)], $uw(glinecloneraison)"
        putlog "Adding gline for *@$host \[$clone($host)\] [expire $uw(glineclonetps)], $uw(glinecloneraison)"
      } elseif {$clone($host) == [expr $uw(clone) -1] && $is_trusted == -1} {
        send "$uw(num)uuu O $nm :\[\0034Warning\3\] You possess currently  $clone($host) One more clone and you host will been glined."
      }

      sendlog "> CONNECT $nick $id@$host ($numserver($pref) Clones: \[$clone($host)\])"
    } else {
      set anick $nickn($pref)
      set nnick [lindex $arg 2]
      set nickn($pref) $nnick
      set num($nnick) $pref
      unset num($anick)
      sendlog "= NICK $anick -> $nnick"
    }
    return 0
  }
  if {$event=="Q"} {
    global nickn
    set lnick $nickn($pref)
    decrclone $lnick
    sendlog "< QUIT by $lnick [join [lrange $arg 2 end]]"
    return 0
  }
  if {$event=="J"} {
    global nickn
    sendlog "> JOIN [lindex $arg 2] by $nickn($pref)"
    foreach  c [split [lindex $arg 2] ,] {chckchan $c $pref}
    return 0
  }
  if {$event=="K"} {
    global nickn
    if [info exists numserver($pref)] {set k $numserver($pref)} else {set k $nickn($pref)}
    sendlog "< KICK $nickn([lindex $arg 3]) by $k on [lindex $arg 2] [join [lrange $arg 4 end]]"
    return 0
  }
  if {$event=="L"} {
    global nickn
    sendlog "< PART [lindex $arg 2] by $nickn($pref) [join [lrange $arg 3 end]]"
    return 0
  }
  if {$event=="C"} {
    global nickn
    sendlog "> JOIN [lindex $arg 2] by $nickn($pref) (Creating)"
    foreach  c [split [lindex $arg 2] ,] {chckchan $c $pref}
    return 0
  }
  if {$event=="B"} {
    if {![strcasecmp $uw(chan) [lindex $arg 2]] && ![info exists uw(ttm)]} {
      set uw(ttm) [lindex $arg 3]
      send "$uw(num) B $uw(chan) [lindex $arg 3] +ntsi $uw(num)uuu:ov"
    }
    return 0
  }
  if {$event=="EB"} {
    if {![strcasecmp $numserver($pref) $uw(rserv)]} {
      if ![info exists uw(ttm)] {send "$uw(num) B $uw(chan) [unixtime] +ntsi $uw(num)uuu:ov"}
      send "$uw(num) EB"
      send "$uw(num) EA"
    }
    return 0
  }
  if {$pref == "SERVER"} {
    set servtmp [string tolower [lindex $arg 1]]
    set srvn [string range [lindex $arg 6] 0 1]
    if [info exists numserver($srvn)] {
      servdelclone $srvn
      putlog "NETMERGE deu $servtmp (Clearing clones)"
      if [info exists uw(ttm)] {unset uw(ttm)}
    }
    set numserver($srvn) $servtmp
    return 0
  }
  if {$event=="S"} {
    set servtmp [string tolower [lindex $arg 2]]
    set srvn [string range [lindex $arg 7] 0 1]
    if [info exists numserver($srvn)] {
      servdelclone $srvn
      putlog "NETMERGE due $servtmp (Clearing clones)"
    }
    set numserver($srvn) $servtmp
    return 0
  }
  if {$event=="SQ"} {
    set slist [array get numserver]
    set snum [lindex $slist [expr [lsearch $slist [string tolower [lindex $arg 2]]] - 1]]
    if [info exists numserver($snum)] {
      servdelclone $snum
      putlog "SQUIT deu [lindex $arg 2] (Clearing clones)"
      unset numserver($snum)
    }
    return 0
  }
  if {$event=="D"} {
    global nickn
#   discriminate if source is either a server or a nick
    if [info exists numserver($pref)] {set k $numserver($pref)} else {set k $nickn($pref)}
    if [info exists nickn([lindex $arg 2])] {
      sendlog "< KILL de $k by $nickn([lindex $arg 2]) :[join [lrange $arg 4 end]]"
      decrclone $nickn([lindex $arg 2])
      if {[lindex $arg 2] == "$uw(num)uuu"} {conuw}
    }
    return 0
  }
  if {$event=="M"} {
    global nickn num
    if {[string index [lindex $arg 2] 0] == "#"} {
      set tmp ""
      if [info exists numserver($pref)] {set k $numserver($pref)} else {set k $nickn($pref)}
      foreach u [lrange $arg 4 end] {
        if [info exists nickn($u)] {lappend tmp $nickn($u)} else {lappend tmp $u}
      }
      sendlog "= MODE [join [lrange $arg 2 3]] [join $tmp] by $k"
      return 0
    }

    global clone
    sendlog "= MODE [join [lrange $arg 2 end]] by $nickn($pref)"
    if [string match *+o* [lindex $arg 3]] {
      set oper($pref) "1 [unixtime]"
      return 0
    }
    if [string match *-*o* [lindex $arg 3]] {
       if [info exists oper($pref)] {unset oper($pref)}
       return 0
    }
    return 0
  }
#receiving NAMES /  nicklist & stockage
  if {$event == "353"} {
    set listing [lrange $arg 5 end]
    set tmpact [split $action]
    foreach ni $listing {
      set n [string trim $ni @!+:]
      if {[lindex $tmpact 1] == "whol"} {
        putdcc [lindex $action 0] "[getmask [getnum $n]] -> $n"
      }
      if {[lindex $tmpact 1] == "deopall" && $n != $uw(nick)} {
        if [string match *@* $ni] {lappend nickw $n}
      } elseif {[lindex $tmpact 1] == "opall"} {
        if ![string match *@* $ni] {lappend nickw $n}
      } else {
        if [info exists oper([getnum $n])] {lappend ircop $n}
        if {$n != $uw(nick)} {lappend nickw $n}
      }
    }
    return 0
  }
#end NAMES => action
  if {$event == "366"} {
    set tmpact [split $action]
    set i [lindex $tmpact 0]
    set evt [lindex $tmpact 1]
    if {$evt == "whol"} {putdcc $i "That a Total of [llength $nickw] nicks on [lindex $tmpact 2]."}

    if {$evt == "who0"} {
      putdcc $i "It have [llength $nickw] nicks on [lindex $tmpact 2]."
      if [llength $nickw] {putdcc $i "List of nicks: [join $nickw]"}
      if [llength $ircop] {putdcc $i "It have [llength $ircop] IRCop on [lindex $tmpact 2].";putdcc $i "Opers list: [join $ircop]"}
    }

    if {$evt == "kickall" || $evt == "xclose"} {
      global num
      set c [lindex $tmpact 2]
      set r [join [lrange $tmpact 3 end]]

      if {$evt == "kickall"} {set prefix $uw(num)} else {set prefix "$uw(num)uuu"}
      if ![matchattr [idx2hand $i] Z] {
        foreach nick $nickw {
          if {[lsearch $ircop $nick]==-1} {putdcc $uw(idx) "$prefix K $c $num($nick) $r"}
        }
      } else {
        foreach nick $nickw {putdcc $uw(idx) "$prefix K $c $num($nick) $r"}
      }
      putdcc $i "KickAll: \[[llength $nickw]\] nicks on $c, than \[[llength $ircop]\] IRCops."
    }

    if {$evt == "killchan"} {
      global num
      set r [join [lrange $tmpact 3 end]]
      foreach nick $nickw {
        if {[lsearch $ircop $nick] == -1 && [info exist num($nick)]} {
          send "$uw(num)uuu D $num($nick) :$uw(host)!$uw(nick) ($r)"
        }
      }
      putdcc $i "KillChan: \[[llength $nickw]\] nicks on [lindex $tmpact 2], than \[[llength $ircop]\] IRCops (exempted)."
    }

    if {$evt == "deopall"} {mmode [lindex $tmpact 2] - o $nickw}
    if {$evt == "opall"} {mmode [lindex $tmpact 2] + o $nickw}
    set ircop ""
    set nickw ""
    return 0
  }
  if {$event == "P" || $event == "O"} {
    global nickn
    set tn [lindex $arg 2]
    if [info exists numserver($pref)] {
      set k $numserver($pref)
    } elseif [info exists nickn($pref)] {set k $nickn($pref)} else {return 0}

    if {[lindex $arg 3]==":VERSION"} {send "$uw(num)uuu O $pref :VERSION This is Just An illusion! "}
#add for antispam Sun 7/12/03 -Cesar
    if {[string first \$ $tn] == -1} {
     # There is a $ in the target.. that means global notice, so the next line will fail.
     putlog "$event|^B$nickn($tn)^B de $k [join [lrange $arg 3 end]]"
    }
    return 0
  }
  if {$event == "AD" || $event == "V"} {
    global admin nickn
    send "$uw(num) 258 $pref :Informations Adminstratives/Techniques on $uw(serv)"
    send "$uw(num) 258 $pref :$uw(serv) is a service UWorld TCL Modified By xplorer for irc.Boomnet.org"
    send "$uw(num) 258 $pref :Adminis: $admin"
    sendlog "= $event par $nickn($pref)"
    return 0
  }
  if {$event == "W"} {
    if ![strcasecmp [string trim [lindex $arg 3] :] $uw(nick)] {
      send "$uw(num) 311 $pref $uw(nick) $uw(ident) $uw(host) * :$uw(rname)"
      send "$uw(num) 319 $pref $uw(nick) :Somewhere Sometimes"
      send "$uw(num) 312 $pref $uw(nick) $uw(serv) :$uw(sinfo)"
      send "$uw(num) 313 $pref $uw(nick) :is a NetWork Service"
      send "$uw(num) 317 $pref $uw(nick) [expr [unixtime] - $uw(uptime)] $uw(uptime) :idle time, signon time"
      send "$uw(num) 318 $pref $uw(nick) :end of  /WHOIS."
      return 0
    }
  }
  if {$event=="247"} {
    global xinfo xinfor
    set mask [lindex $arg 4]
    set tps [expr [lindex $arg 5]-[unixtime]]
    set raison [join [lrange $arg 6 end]]
    set i [lindex $xinfo 0]
    set x [lindex $xinfo 1]
    set m "Matching G-line $mask expire on [duration $tps] \[Reason: $raison\]"
    if [regexp ^(<|>|=)(\[0-9\]){1,100}$ $x] {
      set t [string range $x 1 end]
      set q [string index $x 0]
      if {($q=="=" && $tps==$t) || ($q==">" && $tps>$t) || ($q=="<" && $tps<$t)} {putdcc $i $m;incr xinfor}
      return 0
    }
    if [string match -* $x] {
      set x [string range $x 1 end]
      append x " [lrange $xinfo 2 end]"
      if [string match -nocase "*$x*"  $raison] {putdcc $i $m;incr xinfor}
      return 0
    }
    if [string match -nocase $x $mask] {putdcc $i $m;incr xinfor}
    return 0
  }
  if {$event=="219"} {
    global xinfo xinfor
    putdcc [lindex $xinfo 0] "$xinfor G-lines find corresponding."
    unset xinfor xinfo
    return 0
  }
  return 0
} foo
if {$foo != 0} {
 sendlog "= \002ERROR\002 ($foo)"
 if {[info exists errorInfo]} {
  sendlog "= \002errorinfo\002 ([join $errorInfo])"
 }
 sendlog "= \002ARG\002 arg($arg)"
}
}

# initialisation
set ircop ""
set nickw ""
set action ""

proc fread {fi} {set f [open $fi r];set t [gets $f];close $f;return $t}
proc fwrite {fi arg} {set f [open $fi w];puts $f $arg;close $f}
proc fcreate {ff} {set f [open $ff w];close $f}
proc dur {t} {return [duration [expr [unixtime]-$t]]}

proc strcasecmp {a b} {return [string compare -nocase $a $b]}
proc strc {n} {set s " ";return [string range $s 1 $n]}

if ![file exist gline.box] {fcreate gline.box}
if {[file exist trusted.list] && ![info exists trust(hostlist)]} {
  set fd [open trusted.list]
  set trust(hostlist) ""
  while {![eof $fd]} {
    set ligne [split [gets $fd]]
    set host [lindex $ligne 0]
    append trust(hostlist) " $host"
    set trust(ts!$host) [lindex $ligne 1]
    set trust(expire!$host) [lindex $ligne 2]
    set trust(by!$host) [lindex $ligne 3]
    set trust(clones!$host) [lindex $ligne 4]
    set trust(comment!$host) [join [lrange $ligne 5 end]]
  }
  close $fd
}

if ![file exist trusted.list] {fcreate trusted.list;set trust(hostlist) "";putlog "I create trust DB"}

if {[file exist badchan.list] && ![info exists uw(BadChan)]} {foreach l [fread badchan.list] {append uw(BadChan) " [lindex $l 0]"}}
if ![file exist badchan.list] {fcreate badchan.list;set uw(BadChan) "";putlog "I create badwords DB"}

if {[file exist excchan.list] && ![info exists uw(ExcChan)]} {foreach l [fread excchan.list] {append uw(ExcChan) " [lindex $l 0]"}}
if ![file exist excchan.list] {fcreate excchan.list;set uw(ExcChan) "";putlog "I create excwords DB"}
if ![info exists uw(ExcChan)] {set uw(ExcChan) ""}
if ![info exists uw(BadChan)] {set uw(BadChan) ""}
if ![info exists trust(hostlist)] {set trust(hostlist) ""}

#ss procs usefull
proc sendlog {text} {global uw;putdcc $uw(idx) "$uw(num)uuu P $uw(chan) :\[[strftime "%H:%M:%S"]\] $text"}

proc send {argl} {
  global uw nickn oper num numserver
  set arg [split $argl]
  set event [lindex $arg 1]
  set pref [lindex $arg 0]
  if {$event=="D"} {
    if {[lindex $arg 2] == "$uw(num)uuu"} {return 0}
    if [info exists nickn([lindex $arg 2])] {
      set nick $nickn([lindex $arg 2])
      if [info exists numserver($pref)] {set k $numserver($pref)} else {set k $nickn($pref)}
      sendlog "< KILL of $k on $nick [join [lrange $arg 3 end]]"
      decrclone $nick
    }
  }
  if {$event=="N"} {
    global clone
    sendlog "> NICK [lindex $arg 2] [lindex $arg 5]@[lindex $arg 6] ($uw(serv) Clones \[$clone([lindex $arg 6])\])"
  }
  if {$event=="J"} {sendlog "> JOIN [lindex $arg 2] by $nickn($pref)"}
  if {$event=="L"} {sendlog "< PART [lindex $arg 2] by $nickn($pref) [join [lrange $arg 3 end]]"}
  if {$event=="Q"} {sendlog "< QUIT $nickn($pref) [join [lrange $arg 2 end]]"}
  if {$event=="M"} {
    if [info exists numserver($pref)] {set k $numserver($pref)} else {set k $nickn($pref)}
    if {[string index [lindex $arg 2] 0] == "#"} {
      set tmp ""
      foreach u [lrange $arg 4 end] {
        if [info exists nickn($u)] {lappend tmp $nickn($u)} else {lappend tmp $u}
      }
      sendlog "= MODE [join [lrange $arg 2 3]] [join $tmp] by $k"
    } else {sendlog "= MODE [join [lrange $arg 2 end]] by $k"}
  }
  putdcc $uw(idx) $argl
}

proc avert {i} {putdcc $i "Access Denied."}

proc conuw {} {
  global uw num nickn clone oper
  set num($uw(nick)) $uw(num)uuu
  set nickn($uw(num)uuu) $uw(nick)
  set clone($uw(num)uuu) "$uw(host) $uw(ident)"
  set clone($uw(host)) 1
  send "$uw(num) N $uw(nick) 1 1 $uw(ident) $uw(host) +okpdi B\]AAAB $uw(num)uuu :$uw(rname)"
  set oper($uw(num)uuu) "1 [unixtime]"
  if [info exists uw(ttm)] {
    send "$uw(num)uuu J $uw(chan)"
    send "$uw(num) OM $uw(chan) +osnit $uw(num)uuu"
  }
}

# subproc check

proc chckchan {chan nick} {
global uw
  if {[isindb $uw(BadChan) $chan]!=-1 && [isindb $uw(ExcChan) $chan]==-1} {
    global nickn
    putdcc $uw(idx) "$uw(num)uuu J $chan"
    putdcc $uw(idx) "$uw(num)uuu OM $chan +onitms $uw(num)uuu"
    putdcc $uw(idx) "$uw(num)uuu T $chan :Channel is locked You will be Kicked!"
    putdcc $uw(idx) "$uw(num)uuu K $chan $nick :Channel Is Closed!"
    if {$uw(xclosetime) != 0} {timer $uw(xclosetime) [list putdcc $uw(idx) "$uw(num)uuu L $chan :Freeing BadChannels"]}
    dccbroadcast "Illegal join by $nickn($nick) On $chan"
    sendlog "> CLOSING $chan by $uw(nick) (Cleaning Channel)"
    return 0
  }
  return 0
}

proc decrclone {nick} {
global clone num nickn oper
  if [info exists num($nick)] {
    set n $num($nick)
    if [info exists clone($n)] {
      set h [lindex [split $clone($n)] 0]
      incr clone($h) -1
      if {$clone($h)==0} {unset clone($h)}
      unset clone($n)
    }
    if [info exists oper($n)] {unset oper($n)}
    if [info exists nickn($n)] {unset nickn($n)}
    unset num($nick)
  }
  return 0
}

proc servdelclone {exns} {
global nickn
  foreach n [array names nickn $exns???] {decrclone $nickn($n)}
}

proc clrchr {a} {
  regsub -all -- {\\} $a {\\\\} a
  regsub -all -- {\[} $a {\[} a
  regsub -all -- {\]} $a {\]} a
  regsub -all -- {\{} $a {\{} a
  regsub -all -- {\}} $a {\}} a
  regsub -all -- {\"} $a {\"} a
  return $a
}

proc loggline {args} {
  set temp [fread gline.box]
  fwrite gline.box [lappend temp [list [lindex $args 0] [expr [unixtime]+[lindex $args 1]] [string trim [join [lrange $args 2 end]] :]]]
  return 0
}

proc enforcegline {} {
  global uw
  set glinel [fread gline.box]
  set t ""
  foreach gline $glinel {
    if {[lindex $gline 1] > [unixtime]} {
      send "$uw(num) GL * +[lindex $gline 0] [expr [lindex $gline 1]-[unixtime]] :[join [lrange $gline 2 end]]"
      lappend t $gline
    }
  }
  fwrite gline.box $t
  return 0
}

proc checkgline {} {
  global uw
  set glinel [fread gline.box]
  set t ""
  foreach gline $glinel {if {[lindex $gline 1] > [unixtime]} {lappend t $gline}}
  fwrite gline.box $t
  return 0
}

proc checkhost {host} {
  if ![string match *@* $host] {
    if {[string index $host 0] == "."} {set host *$host}
    set host *@$host
  }
  if {[string index $host 0] == "@"} {set host *$host}
  return $host
}

proc getnicks {h} {
global nickn clone oper
  set r ""
  set o ""
  foreach n [array names nickn] {
    set c [split $clone($n)]
    if [string match -nocase $h [lindex $c 1]@[lindex $c 0]] {
      lappend r $nickn($n)
      if [info exists oper($n)] {lappend o $nickn($n)}
    }
  }
  return [list $r $o]
}

proc gethost {nick} {
global clone
  if {$nick == "*"} {return *@*}
  set n [getnum $nick]
  if {$n != -1} {return *@[lindex [split $clone($n)] 0]}
  return -1
}

proc getnum {nick} {
global num
  if {$nick=="*"} {return -1}
  if [info exist num($nick)] {return $num($nick)}
  set i [lsearch [string tolower [array names num]] [clrchr [string tolower $nick]]]
  if {$i!=-1} {return $num([lindex [array names num] $i])}
  return -1
}

proc getmask {num} {global clone;return [lindex [split $clone($num)] 1]@[lindex [split $clone($num)] 0]}

proc mmode {c t m n} {
global uw
  set nn 6;set d "x";set a ""
  while {$nn > 0} {append a $m;append d " $a";incr nn -1}
  set a ""
  foreach nu $n {
    set nn [getnum $nu]
    if {$nn != -1} {
      append a " $nn"
      if {[llength $a]>5} {send "$uw(num) M $c $t[lindex $d 6] $a";set a ""}
    }
  }
  if {$a!=""} {send "$uw(num) M $c $t[lindex $d [llength $a]] $a"}
  return
}

# commands services

bind dcc - xgline xgline

proc xgline {hand idx text} {
global uw trust
  if ![matchattr $hand G] {avert $idx;return 0}
  set text [split $text]
  set arg1 [lindex $text 0]
  set arg2 [lindex $text 1]
  set p 0
  set f 0
  set g 0

  if [string match -* $arg1] {
    if [string match -*p* $arg1] {set p 1}
    if [string match -*g* $arg1] {set g 1}
    if [string match -*f* $arg1] {set f 1}
    set host $arg2
    set r "[raison [lrange $text 2 end]] - $hand"
  } else {
    set host $arg1
    set r "[raison [lrange $text 1 end]] - $hand"
  }

  if {$text=="" || $host=="" || [regexp "!" $host]} {putdcc $idx "Syntaxe : .xgline \[-g|-p|-f\] <host/nick> <time:unit> <reason>";return 0}
  if [regexp @|\\.|\\* $host] {set host [checkhost $host]} else {set host [gethost $host]}
  if {[string match \\*@* $host] && ([isindb $trust(hostlist) [lindex [split $host @] 1]]!=-1) && (![matchattr $hand Z] || $p==0)} {
    putdcc $idx "This host ([lindex [split $host @] 1]) is protected and you do not have flag needed."
    return 1
  }
  if {$host==-1} {putdcc $idx "Nick not connected.";return 0}
  set i [getnicks $host]
  set opers [lindex $i 1]
  set nicks [lindex $i 0]
  if {$f==0 && [llength $nicks] > 1} {
    putdcc $idx "This host cover so many  users"
    putdcc $idx "Plz use the arg '-f' for force Gline"
    putdcc $idx "Nicks List: [join $nicks]"
    return 0
  }
  if {($p==0 || ![matchattr $hand Z]) && [llength $opers]>0} {
    putdcc $idx "This host cover IRCops and you do not have flag needed. I will Tell on you :p"
    putdcc $idx "Opers List: [join $opers]"
    return 0
  }
  set t [lrange $r 1 end]
  send "$uw(num) GL * +$host [lindex $r 0] [unixtime] [expr [unixtime] + [lindex $r 0]] :\[[llength $nicks]\] [join $t], [expire [lindex $r 0]]"
  putdcc $idx "G-Line for $host expire in [duration [lindex $r 0]], \[[llength $nicks]\] [expire [lindex $r 0]] [join $t]"
  if {$g!=0} {loggline $host [lindex $r 0] :[expire [lindex $r 0]], $t}
  return 1
}

#under proceed gline [3]
proc raison {text} {
  global uw
  if {$text==""} {return "3600 $uw(defr)"}
  if ![regexp ^\[0-9\]{1,30}:\[sdmhj\]$ [lindex $text 0]] {return "3600 [lrange $text 0 end]"}
  if {[llength $text]<2} {return "[timed [lindex $text 0]] $uw(defr)"}
  return "[timed [lindex $text 0]] [lrange $text 1 end]"
}

proc timed {text} {
  set unit [lindex [split $text :] 1]
  set nb [lindex [split $text :] 0]
  set data "s m h d j"
  set corr "1 60 3600 86400 86400"
  if {[lsearch $data $unit]==-1} {return 3600} else {set x [lindex $corr [lsearch $data $unit]]}
  return [expr $x * $nb]
}

proc expire {time} {
  set date [ctime [expr $time + [unixtime]]]
  set da "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
  set n "[split [lindex $date 3] :]"
  return "expire the [lindex $date 2]/[expr [lsearch $da [lindex $date 1]] + 1]/[lindex $date 4] ・[lindex $n 0]:[lindex $n 1]"
}

#[3/3]

bind dcc - xwho xwho

proc xwho {hand idx text} {
global action uw num clone
  if ![matchattr $hand O] {avert $idx;return 0}
  set text [split $text]
  set arg1 [lindex $text 0]
  set arg2 [lindex $text 1]
  if {$arg1 == "-n"} {
    if {$arg2 ==" "} {putdcc $idx "Syntax : .xwho -n <nick mask>";return 0}
    set i 0
    foreach n [array names num] {
      if [string match -nocase $arg2 $n] {putdcc $idx "$n -> [getmask $num($n)]";incr i}
    }
    putdcc $idx "It have $i bads nicks $arg2."
    return 1
  }
  if {$arg1=="-l"} {set list l;set host $arg2} else {set host $arg1;set list 0}
  if {$host==""} {putdcc $idx "Syntax : .xwho \[-l\] <host/nick>";return 0}
  if [string match #* $host] {set action "$idx who$list $host";putdcc $uw(idx) "$uw(num)uuu E $host";return 1}
  if [regexp @|\\.|\\* $host] {set host [checkhost $host]} else {set host [gethost $host]}
  if {$host==-1} {putdcc $idx "Nick not connected.";return 0}
  set i [getnicks $host]
  set opers [lindex $i 1]
  set nicks [lindex $i 0]
  if {$list!=0} {
    if ![llength $nicks] {putdcc $idx "It have no nicks on $host.";return 1}
    foreach n $nicks {putdcc $idx "[getmask $num($n)] -> $n"}
    putdcc $idx "That total of [llength $nicks] nicks on $host."
    return 1
  }
  if ![llength $nicks] {putdcc $idx "No one nick find on $host.";return 1}
  putdcc $idx "It have [llength $nicks] nicks on $host."
  putdcc $idx "Nicks List: [join $nicks]"
  if [llength $opers] {putdcc $idx "It have [llength $opers] IRCops on $host.";putdcc $idx "Opers List: [join $opers]"}
  return 1
}
bind dcc - xkill xkill

proc xkill {hand idx text} {
global uw oper
  if ![matchattr $hand K] {avert $idx;return 0}
  set text [split $text]

  if [string match -*p* $text] {set p 1} else {set p 0}
  set n [lindex $text $p]
  set r [lrange $text [expr $p + 1] end]

  if {$n == ""} {putdcc $idx " Syntax : .xkill \[-p\] <nick> \[<reason>\]";return 0}
  set i [getnum $n]
  if {$i == -1} {putdcc $idx "Nick not connected: $n";return 0}
  if {[info exists oper($i)] && (![matchattr $hand Z] || $p==0)} {putdcc $idx "You do not have The Correct flag to KILL an IRCop. (Use argument -p if you have +Z flag)";return 0}
  if {$r == ""} {set r "$uw(defr)"} else {set r "[join $r]"}
  send "$uw(num)uuu D $i :$r"
  return 1
}

bind dcc - xkick xkick

proc xkick {hand idx text} {
global uw oper
  if ![matchattr $hand O] {avert $idx;return 0}
  set text [split $text]
  if {[llength $text]<2 || ![string match #* [join $text]]} {putdcc $idx " Correct Syntax : .xkick <#chan> <nick> \[<raison>\]";return 0}
  set targ [lindex $text 1]
  set n [getnum $targ]
  if {$n==-1} {putdcc $idx "Nick not connected: $targ";return 0}
  if {[info exists oper($n)] && ![matchattr $hand Z]} {putdcc $idx "You do not have flag for to KICK IRCop.";return 0}
  set r "[join [lrange $text 2 end]]"
  if {[llength $text]<3} {set r "$uw(defr)"}
  send "$uw(num)uuu J [lindex $text 0]"
  send "$uw(num)uuu OM [lindex $text 0] +o $uw(num)uuu"
  send "$uw(num)uuu K [lindex $text 0] $n :$r"
  send "$uw(num)uuu L [lindex $text 0]"
  return 1
}

bind dcc - xban xban

proc xban {hand idx text} {
global clone uw oper
  if ![matchattr $hand O] {avert $idx;return 0}
  set text [split $text]
  if {[llength $text]<2 || ![string match #* [join $text]]} {putdcc $idx " The syntax is : .xban <#chan> <nick> \[<reason>\]";return 0}
  set targ [lindex $text 1]
  set n [getnum $targ]
  if {$n==-1} {putdcc $idx "Nick not connected: $targ";return 0}
  if {[info exists oper($n)] && ![matchattr $hand Z]} {putdcc $idx "You do not have flag for to KICK IRCop.";return 0}
  set r "[join [lrange $text 2 end]]"
  if {[llength $text]<3} {set r "$uw(defr)"}
#ban stuf (Diff IP/Host) ..
  set ban *!*[lindex $clone($n) 1]@
  if {[lindex $clone($n) 2]!=""} {set t [lindex $clone($n) 2]} else {set t [lindex $clone($n) 0]}
  if [regexp ^\[0-9\]\{1,3\}.\[0-9\]\{1,3\}.\[0-9\]\{1,3\}.\[0-9\]\{1,3\}$ $t] {
    set t [string range $t 0 [expr [string length $t]-[string length [lindex [split $t .] end]]-1]]*
  } else {set t *[string range $t [string length [lindex [split $t .] 0]] end]}
  append ban $t
 send "$uw(num)uuu J [lindex $text 0]"
  send "$uw(num)uuu OM [lindex $text 0] +o $uw(num)uuu"
  send "$uw(num)uuu M [lindex $text 0] +b $ban"
  send "$uw(num)uuu K [lindex $text 0] $n :$r"
  send "$uw(num)uuu L [lindex $text 0]" 
  return 1
}

bind dcc - xop xop

proc xop {hand idx text} {
  if ![matchattr $hand O] {avert $idx;return 0}
  set text [split $text]
  if {[llength $text]<2 || ![string match #* [join $text]]} {putdcc $idx " Syntax : .xop <#chan> <nick...>";return 0}
  mmode [lindex $text 0] + o [lrange $text 1 7]
  return 1
}

bind dcc - xdeop xdeop

proc xdeop {hand idx text} {
  if ![matchattr $hand O] {avert $idx;return 0}
  set text [split $text]
  if {[llength $text]<2 || ![string match #* [join $text]]} {putdcc $idx " Syntax : .xdeop <#chan> <nick...>";return 0}
  mmode [lindex $text 0] - o [lrange $text 1 7]
  return 1
}

bind dcc - xvoice xvoice

proc xvoice {hand idx text} {
  if ![matchattr $hand O] {avert $idx;return 0}
  set text [split $text]
  if {[llength $text]<2 || ![string match #* [join $text]]} {putdcc $idx " Syntax : .xvoice <#chan> <nick...>";return 0}
  mmode [lindex $text 0] + v [lrange $text 1 7]
  return 1
}

bind dcc - xdevoice xdevoice

proc xdevoice {hand idx text} {
  if ![matchattr $hand O] {avert $idx;return 0}
  set text [split $text]
  if {[llength $text]<2 || ![string match #* [join $text]]} {putdcc $idx " Syntax : .xdevoice <#chan> <nick...>";return 0}
  mmode [lindex $text 0] - v [lrange $text 1 7]
  return 1
}

bind dcc - xmode xmode

proc xmode {hand idx text} {
  global uw
  if ![matchattr $hand O] {avert $idx;return 0}
  if {[llength $text]<2 || ![string match #* $text]} {putdcc $idx " Syntax : .xmode <#chan> <modes>";return 0}
  send "$uw(num)uuu OM $text"
  return 1
}

bind dcc - xungline ungline

proc ungline {hand idx text} {
global uw
  if ![matchattr $hand G] {avert $idx;return 0}
  if {$text==""} {putdcc $idx "  The syntax is : .xungline <user@host>";return 0}
  set host [checkhost [lindex [split $text] 0]]
  send "$uw(num) GL * -$host"
  putdcc $idx "$uw(serv) remove the G-line for $host."
  set glinel [fread gline.box]
  set t ""
  foreach gline $glinel {if [strcasecmp [lindex $gline 0] $host] {lappend t $gline}}
  fwrite gline.box $t
  return 1
}

bind dcc - xhostkill xhostkill

proc xhostkill {hand idx text} {
global num oper uw
  if ![matchattr $hand G] {avert $idx;return 0}
  set text [split $text]
  if {$text==""} {putdcc $idx "Syntax : .xhostkill \[-f\] <host/nick> <reason>";return 0}
  set f 0
  set host [lindex $text 0]
  if {[string index $host 0] == "-"} {
    set tmp "[join [lrange $text 2 end]] - $hand"
    if {[llength $text]<3} {set tmp "$uw(defr) - $hand"}
    if [string match -*f* $host] {set f 1}
    set host [lindex $text 1]
  } else {
    set tmp "[join [lrange $text 1 end]] - $hand"
    if {[llength $text]<2} {set tmp "$uw(defr) - $hand"}
  }

  if [regexp @|\\.|\\* $host] {set host [checkhost $host]} else {set host [gethost $host]}
  if {$host==-1} {putdcc $idx "Nick not connected.";return 0}
  set i [getnicks $host]
  set opers [lindex $i 1]
  set nicks [lindex $i 0]
  if {[llength $nicks]==0} {putdcc $idx "No one nick on $host.";return 0}
  if {$f==0 && [llength $nicks] > 1} {
    putdcc $idx "This host cover so many users"
    putdcc $idx "Plz use argument '-f' for force kills"
    putdcc $idx "Nicks List: [join $nicks]"
    return 0
  }
  foreach n $nicks {
    set nm $num($n)
    if [info exists oper($nm)] {
      if [matchattr $hand Z] {send "$uw(num)uuu D $nm :$uw(host)!$uw(nick) ($tmp)"}
    } else {send "$uw(num)uuu D $nm :$uw(host)!$uw(nick) ($tmp)"}
  }
  putdcc $idx "Hostkill: \[[llength $nicks]\] bads nicks $host, than \[[llength $opers]\] IRCops."
  return 1
}

bind dcc - xkillchan xkillchan

proc xkillchan {hand idx text} {
global uw action
  if ![matchattr $hand G] {avert $idx;return 0}
  set text [split $text]
  if ![string match #* $text] {putdcc $idx "Syntax : .xkillchan <#chan> <reason>";return 0}
  set tmp [join [lrange $text 1 end]]
  if {$tmp==""} {set tmp "Channel Kill"}
  set action "$idx killchan [lindex $text 0] $tmp ($hand)"
  send "$uw(num)uuu E [lindex $text 0]"
  return 1
}

bind dcc - xkickall xkickall

proc xkickall {hand idx text} {
global uw action
  if ![matchattr $hand K] {avert $idx;return 0}
  set text [split $text]
  if ![string match #* $text] {putdcc $idx "Syntax : .xkickall <#chan> <reason>";return 0}
  set tmp [join [lrange $text 1 end]]
  if {$tmp==""} {set tmp "Channel closed"}
  set action "$idx kickall [lindex $text 0] :$tmp^O  "
  putdcc $uw(idx) "$uw(num)uuu E [lindex $text 0]"
  return 1
}

bind dcc - xclose xclose

proc xclose {hand idx text} {
global uw action
  if ![matchattr $hand K] {avert $idx;return 0}
  set text [split $text]
  set c [lindex $text 0]
  set i 1
  set xtime $uw(xclosetime)
  if ![string match #* $c] {putdcc $idx "Syntax : .xclose <#chan> \[Time:unit\] <reason>";return 0}

  if [regexp ^\[0-9\]{1,30}:\[sdmhj\]$ [set expire [lindex $text 1]]] {set xtime [expr [timed $expire] / 60];incr i}

  set tmp [join [lrange $text $i end]]
  if {$tmp==""} {set tmp "Channel closed"}
  putdcc $uw(idx) "$uw(num)uuu J $c"
  putdcc $uw(idx) "$uw(num)uuu OM $c +onitms $uw(num)uuu"
  putdcc $uw(idx) "$uw(num)uuu T $c :This Chan do not follow this server rules, plz part!"
  set action "$idx xclose $c :$tmp ($hand)"
  putdcc $uw(idx) "$uw(num)uuu E $c"
  if {$xtime != 0} {timer $xtime [list putdcc $uw(idx) "$uw(num)uuu L $c :Freeing BadChannels"]}
  sendlog "> JOIN $c by $uw(nick) (Closing)"
  return 1
}

bind dcc - xleave xleave

proc xleave {hand idx text} {
global uw
  if ![matchattr $hand K] {avert $idx;return 0}
  set text [split $text]
  if ![string match #* [join $text]] {putdcc $idx "Syntax : .xleave <#chan> <reason>";return 0}
  set r [lrange $text 1 end]
  if {$r==""} {set r "Freeing BadChannels"}
  send "$uw(num)uuu L [lindex $text 0] :$r"
  foreach t [timers] {if [string match "*$uw(num)uuu L [lindex $text 0] :*" [lindex $t 1]] {killtimer [lindex $t 2]}}
  return 1
}

bind dcc - xjoin xjoin

proc xjoin {hand idx text} {
global uw
  if ![matchattr $hand K] {avert $idx;return 0}
  set text [split $text]
  if ![string match #* [join $text]] {putdcc $idx "Syntax : .xjoin <#chan>";return 0}
  send "$uw(num)uuu J [lindex $text 0]"
  send "$uw(num)uuu OM [lindex $text 0] +o $uw(num)uuu"
  foreach t [timers] {if [string match "*$uw(num)uuu J [lindex $text 0]" [lindex $t 1]] {killtimer [lindex $t 2]}}
  return 1
}

bind dcc - xclearmodes xclearmodes
proc xclearmodes {hand idx text} {
global uw action
  if ![matchattr $hand O] {avert $idx;return 0}
  set text [split $text]
  if ![string match #* [join $text]] {putdcc $idx "Syntax : .xclearmodes <#chan>";return 0}
  send "$uw(num) CM [lindex $text 0] bklripsmcC"
  return 1
}

bind dcc - xopersend xopersend
proc xopersend {hand idx text} {
global oper uw
  if ![matchattr $hand G] {avert $idx;return 0}
  if {$text==""} {putdcc $idx "Syntax : .xopersend <message>";return 0}
  foreach n [array names oper] {send "$uw(num)uuu O $n :\[Oper MSG\] $text"}
  return 1
}


#clones serv
bind dcc - xclone xclone

proc xclone {hand idx text} {
global uw num nickn clone 
  if ![matchattr $hand P] {avert $idx;return 0}
  set text [split $text]
  if {[llength $text]<5 || ![string match *.* [lindex $text 2]]} {
    putdcc $idx "Syntaxe : .xclone <nick> <ident> <host> <numeric> <real-name> \[chan\]"
    putdcc $idx "Numeric must begin by '$uw(num)' (CAPS) and have at all 5 characters (ex: $uw(num)AAA) but to be different than '$uw(num)uuu'"
    return 0
  }
  set mynick [lindex $text 0]
  set mynum [lindex $text 3]
  if {[info exists num($mynick)] || [info exists nickn($mynum)]} {putdcc $idx "NO Nick collision autorised, choose another nick";return 0}
  if ![string match $uw(num)??? $mynum] {
    putdcc $idx "Numeric is invalid!"
    putdcc $idx "Numeric must begin by '$uw(num)' and have at all 5 characters (ex: $uw(num)AAA)"
    return 0
  }
  if {[string index [lindex $text end] 0] == "#"} {
    set realname [join [lrange $text 4 [expr [llength $text]-2]]]
  } else {set realname [join [lrange $text 4 end]]}
  set h [lindex $text 2]
  set num($mynick) $mynum
  set nickn($mynum) $mynick
  set clone($mynum) "$h [lindex $text 1]"
  if [info exists clone($h)] {incr clone($h)} else {set clone($h) 1}
 send "$uw(num) N $mynick 1 [unixtime] [lrange $text 1 2] +diwkx $uw(serv) $mynum :$realname"
 if [string match #* [lindex $text end]] {send "$mynum J [lindex $text end]"}
  send "$mynum J $uw(chanclone)"
  return 1
}

bind dcc - xquit xquit

proc xquit {hand idx text} {
global nickn uw
  if ![matchattr $hand P] {avert $idx;return 0}
  set text [split $text]
  if {$text == ""} {putdcc $idx "   Syntax : .xquit <nick> \[reason\]";return 0}

  set i [getnum [lindex $text 0]]
  if {$i == -1 || ![string match $uw(num)??? $i] || $i=="$uw(num)uuu"} {putdcc $idx "I do not know this clone.";return 0}
  if {[llength $text]>1} {set r [join [lrange $text 1 end]]} else {set r "Quit: Quit"}
  send "$i Q :$r"
  decrclone $nickn($i)
  return 1
}

bind dcc - xpart xpart

proc xpart {hand idx text} {
  global uw
  if ![matchattr $hand P] {avert $idx;return 0}
  set text [split $text]
  if ![string match #* [lindex $text 1]] {putdcc $idx "   Syntax : .xpart <nick> <#chan> \[reason\]";return 0}

  set i [getnum [lindex $text 0]]
if {![matchattr $hand Z] && [string match $uw(num)uuu $i]} {putdcc $idx "You Do Not Have Required Flag (Z) For To Use This Clone!";return 0}
  if {$i==-1 || ![string match $uw(num)??? $i]} {putdcc $idx "I do not know this clone.";return 0}
#|| $i=="$uw(num)uuu"
  if {[llength $text]>2} {set r [join [lrange $text 2 end]]} else {set r "Service"}
  send "$i L [lindex $text 1] :$r"
  return 1
}

bind dcc - xmove xmove

proc xmove {hand idx text} {
global uw
 set mynick [lindex $text 0]
  if ![matchattr $hand P] {avert $idx;return 0}
  set text [split $text]
  if ![string match #* [lindex $text 1]] {putdcc $idx "   Syntax : .xmove <nick> <#chan>";return 0}

  set i [getnum [lindex $text 0]]
 if {![matchattr $hand Z] && [string match $uw(num)uuu $i]} {putdcc $idx "You Do Not Have Required Flag (Z) For To Use This Clone!";return 0}
  if {$i==-1 || ![string match $uw(num)??? $i]} {putdcc $idx "I Do Not Know This clone.";return 0}
  send "$i J [join [lindex $text 1]]"
  return 1
}

##

bind dcc - wallops wallops
bind dcc - wallusers wallusers
bind dcc - xsay xsay
bind dcc - xinviteme xinviteme
bind dcc - xwall xwall
bind dcc - operlist operlist
bind dcc - xopall xopall
bind dcc - xdeopall xdeopall

proc xinviteme {hand idx text} {
global uw
  if ![matchattr $hand O] {avert $idx;return 0}
  if {$text==""} {putdcc $idx "Syntax : .xinviteme <nick>";return 0}
  set lnick [lindex [split $text] 0]
  set i [getnum $lnick]
  if {$i==-1} {putdcc $idx "Nick not connected: $lnick";return 0}
  putdcc $uw(idx) "$uw(num)uuu I $lnick $uw(chan)"
  return 1
}

proc wallops {hand idx text} {
global uw
  if ![matchattr $hand K] {avert $idx;return 0}
  if {$text==""} {putdcc $idx "Syntax : .wallops <message>";return 0}
  send "$uw(num)uuu WA :$text"
  return 1
}

proc wallusers {hand idx text} {
global uw
  if ![matchattr $hand K] {avert $idx;return 0}
  if {$text==""} {putdcc $idx "Syntax : .wallusers <message>";return 0}
  send "$uw(num)uuu WU :$text"
  return 1
}

proc xsay {hand idx text} {
  global uw
  if ![matchattr $hand P] {avert $idx;return 0}
  set text [split $text]
  if {[llength $text]<3} {putdcc $idx "Syntax : .xsay <nick> <#chan> <message>";return 0}
  set i [getnum [lindex $text 0]]
  if  {![matchattr $hand Z] && [string match $uw(num)uuu $i]} {putdcc $idx "You Do Not Have Required Flag (+Z) For To Use This Clone!";return 0} 
  if {$i==-1 || ![string match $uw(num)??? $i]} {putdcc $idx "I Do Not Know This clone.";return 0}
  send "$i P [lindex $text 1] :[lrange $text 2 end]"
  return 1
}

proc xwall {hand idx text} {
global uw
  if ![matchattr $hand N] {avert $idx;return 0}
  if {$text==""} {putdcc $idx "Syntax : .xwall <message>";return 0}
  send "$uw(num)uuu O $*.* :\[Notice Global Notice\] $text"
  return 1
}

proc operlist {hand idx text} {
global oper nickn clone
  putdcc $idx "Opers List:"
  foreach o [array names oper] {putdcc $idx "> $nickn($o) [strc [expr 20-[string length $nickn($o)]]] ([getmask $o]) Oper Since [dur [lindex $oper($o) 1]]"}
  return 1
}

proc xopall {hand idx arg} {
  global uw action
  if ![matchattr $hand G] {avert $idx;return 0}

  set c [lindex [split $arg] 0]
  if ![string match #* $c] {putdcc $idx "Syntax : .xopall <#chan>";return 0}
  set action "$idx opall $c"
  send "$uw(num)uuu E $c"
  return 1
}

proc xdeopall {hand idx arg} {
  global uw action
  if ![matchattr $hand G] {avert $idx;return 0}

  set c [lindex [split $arg] 0]
  if ![string match #* $c] {putdcc $idx "Syntax : .xdeopall <#chan>";return 0}
  set action "$idx deopall $c"
  send "$uw(num)uuu E $c"
  return 1
}

#Administration commands (N)
bind dcc - xconnect xco
proc xco {hand idx text} {
  if ![matchattr $hand N] {avert $idx;return 0}
  doxco $text
  return 1
}

proc doxco {text} {
global uw numserver oper clone nickn uptime
  if {[info exists uw(idx)] && [valididx $uw(idx)]} {
    if {$text=="-s"} {
      send "$uw(num) SQ $uw(serv) 0 :Rebooting Services!"
    } else {putlog "UWorld seem correctly connected. Type '.xconnect -s' for squit and reconnect.";return 0}
  }
  if [info exists numserver] {unset numserver}
  if [info exists clone] {unset clone}
  if [info exists oper] {unset oper}
  if [info exists nickn] {unset nickn}
  if [info exists num] {unset num}
  if ![catch {connect $uw(link) $uw(port)} uw(idx)] {
    putlog "Uworld Connection $uw(serv) on idx($uw(idx))..."
    send "PASS :$uw(pass)"
    send "SERVER $uw(serv) 1 $uptime [unixtime] J10 $uw(num)AA\] +s :$uw(sinfo)"
    set numserver($uw(num)) $uw(serv)
    set uw(uptime) [unixtime]
    control $uw(idx) uwevent
  } else {putlog "Connexion from $uw(serv) to $uw(idx) impossible."}
  if [info exists uw(ttm)] {unset uw(ttm)}
  conuw
  return 1
}

bind dcc - xenforcegline xenforcegline
proc xenforcegline {hand idx text} {
  if [matchattr $hand N] {enforcegline;putdcc $idx "G-lines have been redo.";return 1}
  avert $idx
  return 0
}

#proc & binds for chans prohibited

proc addword {t f hand idx arg} {
global uw
  if ![matchattr $hand N] {avert $idx;return 0}
  if {$arg==""} {putdcc $idx "\[+$t\] -> Error! You must specify a $t to add!";return 0}
  set bd [lindex $arg 0]
  set r [join [lrange $arg 1 end]]
  if {$r==""} {
    if [string match *Bad* $t] {set r "BAD !"} else {set r "Exempted"}
    putdcc $idx "\[+$t\] -> No reason : default is : $r"
  }
  set result [isindb $uw($t) [string tolower $bd]]
  if {$result==-1} {
    append uw($t) " $bd"
    set glist [fread $f]
    lappend glist "$bd - add the [strftime "%d %b %Y ・%H:%M"] by $hand ($r)"
    fwrite $f  $glist
    putdcc $idx "\[+$t\] -> $bd added success! ($r)"
    return 1
  }
  putdcc $idx "\[+$t\] -> $bd is cover yet by $result - Stop"
  return 0
}

proc delword {t f hand idx arg} {
global uw
  if ![matchattr $hand N] {avert $idx;return 0}
  if {$arg==""} {putdcc $idx "\[-$t\] -> Error! You must specify a $t to erase!";return 0}
  set bd [lindex $arg 0]
  set tmp 0
  foreach n $uw($t) {
    if ![strcasecmp $n $bd] {
      set uw($t) [lreplace $uw($t) $tmp $tmp]
      set glist [fread $f]
      set tmp ""
      foreach n $glist {if [strcasecmp [lindex $n 0] $bd] {lappend tmp $n}}
      fwrite $f $tmp
      putdcc $idx "\[-$t\] -> $bd erased success!"
      return 1
    }
    incr tmp
  }
  putdcc $idx "\[-$t\] -> $bd isn't in list (.x$t for verify)"
  return 0
}

proc isindb {list a} {
  foreach w $list {if [string match -nocase $w $a] {return $w}}
  return -1
}

proc displist {f idx} {
  putdcc $idx "\n-=- List of [lindex [split $f .] 0] -=-\n\n"
  set glist [fread $f]
  foreach f $glist {putdcc $idx "        [lindex $f 0] [lrange $f 1 end]"}
  return 1
}

bind dcc - +xbadchan addbadword
bind dcc - -xbadchan delbadword
bind dcc - xbadchan listword

proc addbadword {hand idx arg} {return [addword BadChan badchan.list $hand $idx $arg]}

proc delbadword {hand idx arg} {return [delword BadChan badchan.list $hand $idx $arg]}

proc listword {hand idx arg} {return [displist badchan.list $idx]}

bind dcc - +xexchan addexcword
bind dcc - -xexchan delexcword
bind dcc - xexchan excword

proc addexcword {hand idx arg} {return [addword ExcChan excchan.list $hand $idx $arg]}

proc delexcword {hand idx arg} {return [delword ExcChan excchan.list $hand $idx $arg]}

proc excword {hand idx arg} {return [displist excchan.list $idx]}

#proc & binds for hosts trusted

bind dcc - +xtrust trust:add
bind dcc - -xtrust trust:del
bind dcc - xtrustlist xlisttrust

proc xlisttrust {hand idx arg} {
global trust
  foreach h $trust(hostlist) {
    if {$arg == "" || [string match -nocase $arg $h]} {trust:show $idx $h}
  }
  return 1
}

proc trust:write {} {
global trust
  set fd [open trusted.list "w"]
  foreach h $trust(hostlist) {puts $fd "$h $trust(ts!$h) $trust(expire!$h) $trust(by!$h) $trust(clones!$h) $trust(comment!$h)"}
  close $fd
}

proc trust:show {idx h} {
global trust
  if {$trust(expire!$h) != 0} {
    putdcc $idx "Host: $h \[[llength [lindex [getnicks *@$h] 0]]/$trust(clones!$h)\] \
      Added by $trust(by!$h) the [strftime "%d %b %Y ・%H:%M" $trust(ts!$h)] for \
      [duration $trust(expire!$h)] Comment: $trust(comment!$h)"
  } else {
    putdcc $idx "Host: $h \[[llength [lindex [getnicks *@$h] 0]]/$trust(clones!$h)\] \
      Added by $trust(by!$h) the [strftime "%d %b %Y ・%H:%M" $trust(ts!$h)] \
      Comment: $trust(comment!$h)"
  }
}

proc trust:add {hand idx arg} {
  global trust

  if ![matchattr $hand N] {avert $idx;return 0}
  set arg [split $arg]
  if {[llength $arg] < 3} {
    putdcc $idx "\[Xtrust\] ->  Syntax : .+xtrust <host/ip/mask> <clone limit|0> <expiration|0> \[comment\]"
    return 0
  }

  set host [string tolower [lindex $arg 0]]
  set expire [lindex $arg 2]
  set clonenb [lindex $arg 1]

  if [regexp @|! $host] {
    putdcc $idx "Host with form host.domain.extension No'!', no '@', wildcards are autorised."
    return 0
  }

  if ![string is digit $clonenb] {
    putdcc $idx "The limit number of clones must be a number or 0 for unlimited"
    return 0
  }

  if {$expire != "0" && ![regexp ^\[0-9\]{1,30}:\[sdmhj\]$ $expire]} {
    putdcc $idx "The expiration time must be in form time:unit ou '0' for unlimited"
    return 0
  } elseif {$expire != "0"} {set expire [timed $expire]}

  if [info exists trust(clones!$host)] {
    putdcc $idx "The host $host is  protected yet(Added the [strftime "%d %b %Y ・%H:%M" $trust(ts!$host)] par $trust(by!$host)), updating..."
  } elseif {[set tmp [isindb $trust(hostlist) $host]] != -1} {
    putdcc $idx "$host is allready cover by another protection:"
    trust:show $idx $tmp
    return 0
  } else {putdcc $idx "Add of $host to protected..";append trust(hostlist) " $host"}

  if {[llength $arg] > 3} {set trust(comment!$host) [join [lrange $arg 3 end]]} else {set trust(comment!$host) "NONE"}

  set trust(clones!$host) $clonenb
  set trust(expire!$host) $expire
  set trust(by!$host) $hand
  set trust(ts!$host) [unixtime]

  trust:show $idx $host
  trust:write
  return 1
}

proc trust:del {hand idx arg} {
global trust

  if ![matchattr $hand N] {avert $idx;return 0}
  set host [string tolower [lindex [split $arg] 0]]
  if {$host == ""} {putdcc $idx "\[Xtrust\] ->  Syntax : .-xtrust <host/ip/mask>";return 0}

  if ![info exists trust(clones!$host)] {
    putdcc $idx "\[Xtrust\] -> $host is not protected."
    return 0
  }

  set tmp [lsearch $trust(hostlist) $host]
  set trust(hostlist) [lreplace $trust(hostlist) $tmp $tmp]
  unset trust(ts!$host) trust(by!$host) trust(expire!$host) trust(comment!$host) trust(clones!$host)

  trust:write
  putdcc $idx "\[Xtrust\] -> $host erased successfull from protection list"
  return 1
}

bind time - "0 0 * * *" trust:purge

proc trust:purge {min hour day month year} {
global trust
  set count 0
  set tts [unixtime]

  foreach h $trust(hostlist) {
    if {$trust(expire!$h) != "0" && [expr $trust(ts!$h) + $trust(expire!$h)] < $tts} {
      incr count
      set tmp [lsearch $trust(hostlist) $h]
      set trust(hostlist) [lreplace $trust(hostlist) $tmp $tmp]
      unset trust(ts!$h) trust(by!$h) trust(expire!$h) trust(comment!$h) trust(clones!$h)
    }
  }
  if {$count != 0} {putlog "\[Xtrust\] $count trusts purged";trust:write}
}


bind dcc - xhelp xhelp

proc xhelp {h i text} {
  global botnick uw
  set cmd [string tolower [lindex [split $text] 0]]
  if {$cmd == "" || $cmd == "all"} {
    putdcc $i "Visualisation of commands $botnick: (Only Commands than You have access)"
    putdcc $i "All : xstatus operlist xadmin"
    if [matchattr $h O] {putdcc $i "Flag +O : xtrustlist xbadchan  xexchan xop xdeop xmode xkick xwho xban xclearmodes xlclone"}
    if [matchattr $h K] {putdcc $i "Flag +K : xkill wallops xkickall xclose xleave xjoin"}
    if [matchattr $h G] {putdcc $i "Flag +G : xhostkill xkillchan xgline xungline xopall xdeopall xopersend"}
    if [matchattr $h P] {putdcc $i "Flag +P : xclone xmove xpart xquit xsay"}
    if [matchattr $h N] {putdcc $i "Flag +N : +xtrust -xtrust +xbadchan -xbadchan +xexchan -xexchan xconnect xwall xenforcegline"}
    putdcc $i "You can use .xhelp <commande>  for more informations about some command."
    if [matchattr $h Z] {putdcc $i "4Warning ! You have flag +Z. You can do what You want with IRCops. Pay attention to what You Do..."}
    return 1
  }
  set s Syntax:
  set u Use:
  set e Example:
  switch -- $cmd {
    "xtrustlist" {putdcc $i "$s .xtrustlist\n$u Give list of hosts protected (not G-lined for clones, etc.)"}
    "xbadchan" {putdcc $i "$s .xbadchan\n$u Give list of words who do not be on channel name (xclose of chan)"}
    "xexchan" {putdcc $i "$s .xexchan\n$u Give list of words who protect from xclose"}
    "xop" {putdcc $i "$s .xop <#chan> <nick1..>\n$u Permit to use server for to Op users than you want.\n$e .xop #services Progs Cesar"}
    "xdeop" {putdcc $i "$s .xdeop <#chan> <nick1..>\n$u Permit to use server for DeOp users than you want.\n$e .xdeop #services Progs Cesar"}
    "xmode" {putdcc $i "$s .xmode <#chan> <modes> \[parameters\]\n$u Permit to change channel mode \n$e .xmode #services +i"}
    "xkick" {putdcc $i "$s .xkick <#chan> <nick> \[reason\]\n$u Permit to eject user from some chan\n$e .xkick #services VelSatis"}
    "xvoice" {putdcc $i "$s .xvoice <#chan> <nick1..>\n$u Permit to use server for Voice users.\n$e .xvoice #services Progs Cesar"}
    "xdevoice" {putdcc $i "$s .xdevoice <#chan> <nick1..>\n$u Permit to use server for DeVoice users.\n$e .xdevoice #services Progs Cesar"}
    "xwho" {
      putdcc $i "$s .xwho \[-l\] <nick/host>\nUse  : Permit to see all users on host and in case of same users use same host"
      putdcc $i "Paramete:r -l = permit to display users from same list\n$e .xwho -l *@*.wanadoo.fr <= permit to see all users used wanadoo"
    }
    "xban" {putdcc $i "$s .xban <#chan> <nick> \[reason\]\n$u Permit to use server for to Ban and Kick user\n$e .xban #services NeuNeuMan Error nick, I hope"}
    "xkill" {putdcc $i "$s .xkill <pseudo> \[raison\]\n$u Permit to kill user (KILL IRCop only if you have required flag )\n$e .xkill heavy heavy !"}
    "wallops" {putdcc $i "$s .wallops <message>\n$u Permit to send wallops via $uw(nick)\n$e .wallops Hi All !"}
    "xsay" {putdcc $i "$s .xsay <robot> <#chan> <message>\n$u Permit to make say some to clone\n$e .xsay BonD #services Salut !"}
    "xkickall" {putdcc $i "$s .xkickall <#chan> \[reason\]\n$u Permit to kick all users from  chan (KICK IRCop only if you have required flag )\n$e .xkickall #sex bye"}
    "xclose" {putdcc $i "$s .xclose <#chan> \[time:unit\] \[reason\]\n$u Permit to close some chan (kickall and modes +sntim)\n$e .xclose #neuneuland bye"}
    "xjoin" {putdcc $i "$s .xjoin <#chan>\n$u Make $uw(nick) join chan Xclose and op itself\n$e .xjoin #xclose"}
    "xleave" {putdcc $i "$s .xleave <#chan> \[reason\]\n$u Make part $uw(nick) from chan Xclose\n$e .xleave #xclose free"}
    "xungline" {putdcc $i "$s .xungline <host>\n$u Permit to remove gline from list\n$e .xungline ~??@*"}
    "xgline" {
      putdcc $i "$s .xgline \[-p|-g|-f\] <host/nick> \[<time:unit>\] \[<reason>\]"
      putdcc $i "$u Gline a host. $uw(nick) can find too a host from nick (G-Line type *@host)"
      putdcc $i "Remarque: The gline time by this form time:unit where unit is to choose in s, m, h, d (s=seconde,m=minute,h=hour,d=day)"
      putdcc $i "         By default, reason is '$uw(defr)' and gline long one hour (3600 secondes)."
      putdcc $i "         If host than you want to gline cover IRCop or  exempted one, it will be gline only if you have required flag (+Z)"
      if [matchattr $h Z] {putdcc $i "         4Warning: you have flag +Z. If you want to gline IRCop or exempted host, use parameter -p before host"}
      putdcc $i "Parameter: -g > log the gline in case of split from server.\nParameter: -p > G-line host even it have IRCops on it, restricted to +Z."
      putdcc $i "$e .xgline -f *@*aol.com 2:d Lourds !\nParameter: -f > force Gline if it have users on same host"
    }
    "xclone" {
      putdcc $i "$s .xclone <nick> <ident> <host> <numeric> <real-name> \[chan\]\n$u Create clone on server $uw(serv). If you do not know to use numerics, DO NOT use this command."
      putdcc $i "$e .xclone UnBot Bot Host.du.bot.net $uw(num)AAA Le ptit bot #chat"
    }
    "xquit" {putdcc $i "$s .xclone <nick> \[message\]\n$u Make disconnect clone.\n$e .xquit Super-Menteur Les aventures de Super Menteur"}
    "+xtrust" {putdcc $i "$s .+xtrust <host> <clones limits|0> <expiration-0> \[comment\]\n$u Add host to list hosts protected (NO Gline)\n$e .+xtrust 4.4.5.6 30 2:j LAN"}
    "-xtrust" {putdcc $i "$s .-xtrust <host>\n$u Remove a host from list hosts protected (NO Gline)\n$e .-xtrust 1A829044.abo.wanadoo.fr"}
    "+xbadchan" {putdcc $i "$s .+xbadchan <mot>\n$u Add word to list bads chans \n$e .+xbadchan sex"}
    "-xbadchan" {putdcc $i "$s .-xbadchan <mot>\n$u Remove words from list bads chans \n$e .-xbadchan sex"}
    "+xexchan" {putdcc $i "$s .+xexchan <mot>\n$u Add a word to list chans autorised\n$e .+xexchan sex"}
    "-xexchan" {putdcc $i "$s .-xexchan <mot>\n$u Remove words to list chans autorised\n$e .-xexchan sex"}
    "xconnect" {putdcc $i "$s .xconnect \[-s\]\n$u Reconnect server $uw(serv) and $uw(nick)"}
    "xstatus" {putdcc $i "$s .xstatus\n$u Give some info about Uworld."}
    "xopersend" {putdcc $i "$s .xopersend <message>\n$u Send message to ALL IRCops connected."}
    "xlclone" {putdcc $i "$s .xlclone \[-l\] \[nombre\]\n$u Return list of Hosts clones  (d馭aut: 2) IF '-l' is tell, list of nicks"}
    "xclearmodes" {putdcc $i "$s .xclearmodes <chan>\n$u Remove tall modes  from chan (+kblipms) and do deopall"}
    "xopall" {putdcc $i "$s .xopall <#chan>\n$u Op All Users non op on chan specified\n$e .xopall #opless"}
    "xdeopall" {putdcc $i "$s .xdeopall <#chan>\n$u DeOp All Users op on chan specified\n$e .xdeopall #opless"}
    "operlist" {putdcc $i "$s .operlist\n$u Return list of  IRCops connected."}
    "xadmin" {putdcc $i "$s .xadmin\n$u Give list access to UWorld,  flags, presence etc.."}
    "xwall" {putdcc $i "$s .xwall <message important>\n$u Send une notice to all users.\n$e .xwall Reboot"}
    "xopersend" {putdcc $i "$s .xopersend <message important>\n$u Send notice to all Opers.\n$e .xwall Attaque"}
    "xenforcegline" {putdcc $i "$s .xenforcegline\n$u Redo all Glines log via  '-g'"}
    "xkillchan" {putdcc $i "$s .xkillchan <#chan> \[reason\]\n$u Permit to kill all users from chan ( KILL IRCop only if you have  flag requied)\n$e .xkillchan #sex bye"}
    "xhostkill" {putdcc $i "$s .xhostkill  \[-p|-g|-f\] <host/nick> \[reason\]\n$u Permit to kill all users on host  (KILL IRCop only if you have flag requied)\n$e .xhostkill ~?@* Clones"}
    default {putdcc $i "The command $cmd do not exist. PLZ verify with .xhelp all";return 0}

  }
  return 1
}

bind dcc - xstatus xstatus
proc xstatus {hand idx arg} {
global uw botnick
  set nb 0
  foreach f "O K G P N" {append fs "$f: [llength [userlist $f]] "}
  foreach n [userlist O] {if {[hand2idx $n]!=-1} {incr nb}}
  putdcc $idx "Services UWorld TCL online from $botnick since [dur $uw(uptime)]"
  putdcc $idx "   My Robot: $uw(nick) online like $uw(ident)@$uw(host) ($uw(rname))"
  putdcc $idx "   My Server: $uw(serv) connected to $uw(rserv) ($uw(sinfo)) Port: $uw(port)"
  putdcc $idx "Number of Access: [llength [userlist O]] than $fs  Login: $nb"
  putdcc $idx "Configuration:    Reason default: $uw(defr) Number Max of clones: $uw(clone)"
  putdcc $idx "                  G-Line for clone: [duration $uw(glineclonetps)] Reason: $uw(glinecloneraison)"
  return 1
}

bind dcc - xadmin xadmin
proc xadmin {hand idx arg} {
  set s [strc 6]
  putdcc $idx "Hand[strc 5] Logu・$s Nick-Actuel [strc 21] (Flags) Last Seen"
  foreach h [userlist O] {
    if [valididx [hand2idx $h]] {set e "3YES"} else {set e "4NO"}
    if {[hand2nick $h]!=""} {set n [hand2nick $h]} else {set n "N/A"}
    if {[getuser $h LASTON]!=""} {set never [dur [lindex [getuser $h LASTON] 0]]} else {set never "Never"}
    regexp {[GKNOPZ]{1,6}} [chattr $h] filter
    putdcc $idx "$h[strc [expr 9-[string length $h]]] $e $s $n [strc [expr 20-[string length $n]]] ($filter) Last seen: $never"
  }
  return 1
}

bind dcc - xlclone xlclone
proc xlclone {hand idx arg} {
global clone trust
  if ![matchattr $hand O] {avert $idx;return 0}
  set arg [split $arg]
  if {[lindex $arg 0] == "-l"} {set l 1} else {set l 0}
  if {[lindex $arg $l] == "" || ![string is digit [lindex $arg $l]]} {set n 2} else {set n [lindex $arg $l]}
  set j 0
  foreach h [array names clone *.*] {
    if {$clone($h) >= $n} {
      incr j
      if {[isindb $trust(hostlist) $h] >= 0} {
        putdcc $idx "\[$clone($h)\] Clones On *@$h (4Trusted)"
      } else {
        if {$l} {
          putdcc $idx "\[$clone($h)\] Clones On *@$h [join [lindex [getnicks *@$h] 0]]"
        } else {
          putdcc $idx "\[$clone($h)\] Clones On *@$h"
        }
      }
    }
  }

  putdcc $idx "Total of $j Clones Find (>= $l clones/host)"
  return 1
}

bind dcc - xstats xstats
proc xstats {hand idx arg} {
  global numserver nickn uw xinfo xinfor oper
  set arg [split $arg]
  set type [string tolower [lindex $arg 0]]
  set ex [string tolower [join [lrange $arg 1 end]]]
  switch -- $type {
    "network" {
      foreach n [array names numserver] {
        set a [llength [array names nickn $n???]]
        set b [llength [array names oper $n???]]
        putdcc $idx "$numserver($n) -> $a users ([expr $a/[array size nickn].0*100] %) $b Opers ([expr $b/[array size oper].0*100] %)"
      }
      return 1
    }
    "gline" {
      if {$ex==""} {putdcc $idx "Syntax : .xstats gline <all|mask|<\"expiration time\"|>\"expiration time\"|=\"expiration time\"|-reason>";return 0}
      if {$ex=="all"} {set ex "*"}
      set xinfo "$idx $ex";set xinfor 0
      send "$uw(num)uuu R G"
      return 1
    }
  }
  putdcc $idx "Syntax : .xstats <arg>\n For now avalaible: network and gline"
  return 0
}

putlog "Eva.tcl LOADED use '.xhelp' for command Listing."

if {![info exists uw(idx)]} {
 putlog "Service not detected, starting!"
 doxco -s
 return 0
}

