#!/usr/bin/perl
# libnotify.pl for X-Chat, by s0ulslack (Tony Annen)
# Distributed under the terms of the GNU General Public License, v2 or later
# $Header: ~/.xchat2/libnotify.pl, v1.4 2018/03/18 10:21:00 $
# Need help? /msg s0ulslack on Freenode

# uses notification-daemon/libnotify to display queries, nick highlights,
# notices and kicks when XChat isn't focused  (ignores ctcp/dcc events)

# optional:
# show notifications even if xchat is focused
# show only initial notification per event
# play audio on notifications (uses "play" from sox)
# logging highlights/events to a seperate tab
# notification when kicked from channels
# ignoring Nick/ChanServ/X notices

## always show notifications even if xchat is focused? 
$all=1;

## only show first notification per nick?
$initial=0;

## notify when kicked from channels?
$kick=1;

## ignore chan/nickserv/x notices?
$ignore=1;

$sendsms = 0;
$smsexec = "/home/valleedelisle/bin/sms.pl moi";
$sendping = 1;
$pingexec = "/home/valleedelisle/bin/kping.pl";
## log events to a seperate tab?
$log=1;
$logtab="\@highlights";
$hlwords = "dhill|NEW COLLAB CASE.*\[Stack\]|NEW NCQ CASE.*\[Stack\]|NEW NNO CASE.*\[Stack\]|ping sbr-stack|ping vz-eoss|ping sprint-eoss|stack-seg";
## notification display time? (in milliseconds, 1000ms = 1sec)
$time="7000";
$scriptFolder = "$ENV{'HOME'}/.config/hexchat/addons/notify";

## play audio on events? ($soundfile must exist and "play" (from sox) installed)
$soundfile="$scriptFolder/libnotify.wav";


IRC::register("libnotify.pl", "1.4", "Notifications of msgs, nick highlights, notices and kicks", "");
IRC::add_message_handler("PRIVMSG", "privmsg_handler");
IRC::add_message_handler("NOTICE", "notice_handler");
IRC::add_message_handler("KICK", "kick_handler");

# sanity check, make sure notify-send is found
if(-e "/sbin/notify-send"){
  $ns="/sbin/notify-send";
}elsif(-e "/bin/notify-send"){
  $ns="/bin/notify-send";
}elsif(-e "/usr/sbin/notify-send"){
  $ns="/usr/sbin/notify-send";
}elsif(-e "/usr/bin/notify-send"){
  $ns="/usr/bin/notify-send";
}
if(!$ns){
  IRC::print("libnotify-1.4.pl not loaded!\nYou must have libnotify installed.");
  return 0;
}
$ns = "-t 5000 -a xchat -i xchat ";

# lets finger out the sound
if(-e "/sbin/play"){
  $play="/sbin/play";
}elsif(-e "/bin/play"){
  $play="/bin/play";
}elsif(-e "/usr/sbin/play"){
  $play="/usr/sbin/play";
}elsif(-e "/usr/bin/play"){
  $play="/usr/bin/play";
}
if(-e "$soundfile" && -x "$play"){
  $sound=1;
}

# display configuration
if($all == "1"){ $sa="notifying if focused/unfocused"; }else{ $sa="notifying if unfocused"; }
if($sound == "1"){ $s="+audio alerts"; }else{ $s="-audio alerts"; }
if($log == "1"){ $l="+event logging"; }else{ $l="-event logging"; }
IRC::print("libnotify loaded ($sa ($s, $l))");


# privmsg
sub privmsg_handler{
 $mynick=(IRC::get_info(1));
 local($line)=@_;
 if($line=~ m/:(.+?)\!.+? PRIVMSG $mynick :(.*)/){
  if($line=~ /xdcc\s+.*(?:send|list)/i){ return 0; }
  if($line=~ /\s+.*(?:ping|version|time|finger|xdcc|dcc)/i){ return 0; }
  $user=$1;
  $message=$2; $message=~  s/\+//s; $message=~  s/-//s; $message=~  s/\<//s; $message=~  s/\>//s; $message =~ s/\|/\\\|/g;
  if(-e "$scriptFolder/.lmn"){ $oldmn=`cat $scriptFolder/.lmn`; chomp($oldmn); }
  $window=Xchat::get_info("win_status");
  if($window eq "active" && $all == "1"){ $window="hidden"; }
  if($window eq "hidden" or $window eq "normal"){
   if($user eq $oldmn && $initial == "1"){ return 0; }
   system("$ns \"Query: $user\" \"$message\"");
   if($sound == "1"){ system("$play $soundfile"); }
   $suser = $user;
   $suser =~ s/\|/\\\|/g;
   system("$smsexec privmsg $suser: \"$message\"") if ($sendsms == 1);
   system("$pingexec privmsg $suser: \"$message\"") if ($sendping == 1);

  }
  system("echo \"$user\" > $scriptFolder/.lmn");
 }

 # nick highlights
 if($line =~ /$mynick|$hlwords/i) {
  if ($line=~ m/:(.+?)\!.+? PRIVMSG (#.*) :(.*)/i){
   $user=$1;
   $channel=$2;
   $message=$3; $message=~  s/\+//s; $message=~  s/-//s; $message=~  s/\<//s; $message=~  s/\>//s; $message =~ s/\|/\\\|/g;
   if(-e "$scriptFolder/.lhn"){ $oldhl=`cat $scriptFolder/.lhn`; chomp($oldhl); }
   if(-e "$scriptFolder/.lahn"){ $oldahl=`cat $scriptFolder/.lahn`; chomp($oldahl); }
   $window=Xchat::get_info("win_status");
   if($window eq "active" && $all == "1"){ $window="hidden"; }
   if($window eq "hidden" or $window eq "normal"){
   if($message=~/ACTION/){
    $message=~  s/.*ACTION //s; $message=~  s/.\z//s;
    if($log){
     IRC::command("/query -nofocus $logtab");
     IRC::print_with_channel("\cC8$channel\cO\11$user $message\n","$logtab","");
    }
    if($user eq $oldahl && $initial == "1"){ return 0; }
    system("$ns \"$channel\" \"* $user $message\"");
    if($sound == "1"){ system("$play $soundfile"); }
    $suser = $user;
    $suser =~ s/\|/\\\|/g;
    system("$smsexec $suser \\$channel: \"$message\"") if ($sendsms == 1);
    system("$pingexec $suser \\$channel: \"$message\"") if ($sendping == 1);
    system("echo \"$user\" > $scriptFolder/.lahn");
    return 0;
   }
   if($log){
     IRC::command("/query -nofocus $logtab");
     IRC::print_with_channel("\cC8$user/$channel\cO\11$message\n","$logtab","");
    }
    if($user eq $oldhl && $initial == "1"){ return 0; }
    system("$ns \"$channel\" \"$user: $message\"");
    if($sound == "1"){ system("$play $soundfile"); }
    $suser = $user;
    $suser =~ s/\|/\\\|/g;
    system("$smsexec $suser \\$channel: \"$message\"") if ($sendsms == 1);
    system("$pingexec $suser \\$channel: \"$message\"") if ($sendping == 1);
    system("echo \"$user\" > $scriptFolder/.lhn");
   }
  }
 }
}


# notices
sub notice_handler{
  $mynick=(IRC::get_info(1));
  local($line)=@_;
  if($line=~ m/:(.+?)\!.+? NOTICE $mynick :(.*)/){
    $user=$1;
    $message=$2; $message=~  s/\+//s; $message=~  s/-//s; $message=~  s/\<//s; $message=~  s/\>//s; $message =~ s/\|/\\\|/g;
    if($ignore == "1" && $user eq "NickServ" or $user eq "ChanServ" or $user eq "X"){ return 0; }
    if(-e "$scriptFolder/.lnn"){ $oldnn=`cat $scriptFolder/.lnn`; chomp($oldnn); }
    if($log){
      IRC::command("/query -nofocus $logtab");
      IRC::print_with_channel("\cC8($user)\cO\11$message\n","$logtab","");
    }
    if($user eq $oldnn && $initial == "1"){ return 0; }
    $window=Xchat::get_info("win_status");
    if($window eq "active" && $all == "1"){ $window="hidden"; }
    if($window eq "hidden" or $window eq "normal"){
      system("$ns \"Notice: $user\" \"$message\"");
      system("echo \"$user\" > $scriptFolder/.lnn");
	}
	if($sound == "1"){ system("$play $soundfile"); }
        $suser = $user;
        $suser =~ s/\|/\\\|/g;
        system("$smsexec notice $suser: \"$message\"") if ($sendsms == 1);
	system("$pingexec notice $suser: \"$message\"") if ($sendping == 1);

  }
}

# kicks
sub kick_handler{
if($kick == "0"){ return 0; }
$mynick=(IRC::get_info(1));
local($line)=@_;
if($line=~ m/:(.+?)\!.+? KICK (#.*) $mynick :(.*)/){
  $user=$1;
  $channel=$2;
  $message=$3; $message=~  s/\+//s; $message=~  s/-//s; $message=~  s/\<//s; $message=~  s/\>//s; $message =~ s/\|/\\\|/g;
  system("$ns -u critical \"Kicked from $channel\" \"$user kicked you ($message)\"");
  if($log){
    IRC::command("/query -nofocus $logtab");
    IRC::print_with_channel("\cC8$channel\cO\11$user kicked you ($message)\n","$logtab","");
  }
  if($sound == "1"){ system("$play $soundfile"); }
  $suser = $user;
  $suser =~ s/\|/\\\|/g;
  system("$smsexec kick $suser \\$channel: \"$message\"") if ($sendsms == 1);
  system("$pingexec kick $suser \\$channel: \"$message\"") if ($sendping == 1);

 }
}
