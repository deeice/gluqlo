#!/bin/sh
#
# Simple alarm clock
#

alarm=07:45

# ANSI colors (darK,Red,Green,Yellow,
#  Blue,Magenta,Cyan,White,Normal)
K="\033[1;30m"
R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
M="\033[1;35m"
C="\033[1;36m"
W="\033[1;37m"
N="\033[0m"

ESC=`echo -e "\033"`

cleanup () {
echo -e "\033[0;00m"
loadfont < /etc/consolefont.psf
clear
echo $KLED >/sys/class/backlight/pxabus\:keyboard-backlight/brightness
echo $DLED >/sys/class/backlight/pxabus\:display-backlight/brightness
echo $LLED >/sys/class/leds/z2\:green\:charged/brightness
echo $MLED >/sys/class/leds/z2\:amber\:charging/brightness
echo $RLED >/sys/class/leds/z2\:green\:wifi/brightness
}

giveup () {
ret=$?
cleanup
#exit $ret
# propagating C-c kills gmenu2x wrapper sh
exit 0 
# Wrapper may need: trap - INT TERM; ...
}

# Get LED state, then trap signals 
KLED=$(cat /sys/class/backlight/pxabus\:keyboard-backlight/brightness)
DLED=$(cat /sys/class/backlight/pxabus\:display-backlight/brightness)
LLED=$(cat /sys/class/leds/z2\:green\:charged/brightness)
MLED=$(cat /sys/class/leds/z2\:amber\:charging/brightness)
RLED=$(cat /sys/class/leds/z2\:green\:wifi/brightness)
trap giveup INT TERM

# ALSA should be loaded by default on jffs
#if test ! -c /dev/snd/pcmC0D0p
#then
#  echo "Loading ALSA (sound) ..." > /dev/tty0
#  /mnt/ffs/bin/setup-alsa.sh > /dev/tty0 < /dev/tty0
#fi

# Make sure we can display latin chars for the cute little �
echo "$(printf "\033")%G"
echo "$(printf "\033")%@"

# Set alarm time.
clear
loadfont < /usr/share/consolefonts/ter-132b.psf
echo -e "\033[2;0H    `date +"%H:%M:%S %p"`"
echo -e "\033[4;0H    `date +"%a, %b %d"`"
echo -e -n "\033[7;0H  Set alarm: "$R"$alarm"$B
echo -e -n "\033[5D"
read time
case "$time" in
  ??:??) alarm=$time ;;
  *) ;;
esac
echo $N

# Dim the lights.
echo 0 >/sys/class/leds/z2\:green\:charged/brightness
echo 0 >/sys/class/leds/z2\:amber\:charging/brightness
echo 0 >/sys/class/leds/z2\:green\:wifi/brightness
echo 0 >/sys/class/backlight/pxabus\:keyboard-backlight/brightness
#echo 2 >/sys/class/backlight/pxabus\:display-backlight/brightness
echo 1 >/sys/class/backlight/pxabus\:display-backlight/brightness

case "$alarm" in
  0* | 10* | 11* ) AM="AM" ;;
  *) AM="PM" ;;
esac

# Display flipclock until wakeup.
#cd /root/projects/fc
#./fc -4d "Alarm at $alarm" & 

# Try ttyclock with skinny font and red. 
#/root/projects/ttyclock/ttyclock -t -k -c -C 1 

# Display gluqlo flipclock until wakeup.
cd /root/projects/gluqlo
./gluqlo -f -ampm -red -wake $alarm & 

# Show clock until alarm.
clear
quit=false
until [ "$quit" = "true" ]; do
  echo -e "\033[2;0H    `date +"%I:%M:%S %p"`"
  echo -e "\033[4;0H    `date +"%a, %b %d"`"
  echo -e -n "\033[7;0H    �  $alarm $AM\033[11D"
  #  sleep 1
  IFS= read -s -n1 -t1 cmd
  case "$cmd" in
    q | " " | "${ESC}") giveup ;;
    *) ;;
  esac

  time=`date +%H:%M`
  if [ "$time" = "$alarm" ]; then
    quit=true
  fi
done

echo $DLED >/sys/class/backlight/pxabus\:display-backlight/brightness
echo -e -n "\033[7;0H      "$G"Wakeup!  "$N
echo -e -n "\033[2D"

# Kill flipclock so alarm off is accessible.
#killall fc
#killall ttyclock
killall gluqlo

# Beep if internet radio unavailable. 
ping -c5 8.8.8.8>>/dev/null
inet=$?
cleanup
if [ $inet -eq  0 ] ; then
  gmu
else
  # mpg123tty4 -Z -C /usr/share/alarm.mp3
  killall mpg123
#  mpg123 -Z -C /usr/share/alarm.mp3
  mpg123 -Z -C /root/radio/alarm.mp3
fi
    
clear
exit 0
