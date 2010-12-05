#!/bin/bash
#
# bat_alert.sh
#
# © Franck LABADILLE  ; franck {att} kernlog [dot] net
# IRC : Franck@irc.oftc.net
#
# (Version 0.1  ; 2010-02-11 )
# (Version 0.2  ; 2010-02-13 )
# (Version 0.3  ; 2010-02-14 )
# (Version 0.4  ; 2010-02-16 )
# (Version 0.5  ; 2010-02-18 )
# Version 0.6  ; 2010-02-27
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
#
################################################################################
# bat_alert.sh is a bash script which has the purpose to help you not to forget 
# that your laptop battery is discharging.
# For that, it will do :
#	* Send you emails
#	* Make sounds with the PC  BEEP
#	* Display written warning messages on your screen
#	* Change your wallpaper
#	* Adjust the screen brightness
#	* Ask for turning down WIFI
#	* Ask for shutdown computer at last to preserve data from power failure
# All of these actions are fully configurable, depending on battery STATE, if you
# want that they appens ONCE per STATE or severals.
# You define your STATES like you want, and time in state between to battery is
# checked.
# You define your settings in a config file ; you may have several config files
# in order to make bat_alert.sh works differently, depending where you are.
# When a new version comes with new parameters in the config file, bat_alert.sh
# keeps your old settings, and warn you of the new settings availables.
#
# DEPENDS : acpi(/apm), bash, 
#
# RECOMMENDS : aosd_cat, amixer, postfix|exim, xterm, fbsetroot
#
# SUGGEST : xsetroot, Esetroot|fbsetbg
#
################################################################################
################################################################################
###########                            CHANGELOG                     ###########
################################################################################
################################################################################
#
##############
# Changelog 0.6
##############
#
#	* Add a directory for old_config_files
#	* Add brightness adjust fonctionnality
#	* Add -t option for terminal (no X11) ; only mail, noise and brightness
#	* Add $PREVIOUS_STATE
#	* Add the rolling wallpaper possibility
#	* Corrected bugs in the upgrade_rc() / add an oldconfdir.
#	* 
#
##############
## Changelog 0.5
##############
#
#	* The upgrade_rc function tells now clearly the name of new variables
#	  availables
#	* Add 2 new functions (yet unused) : variables_names_version() and
#	  variables_names_changed to tell change of variables names 
#	* Add possibility to configure aosd_cat arguments depending on $STATE
#	* Add "NEVER" option which does the same as "" for $SINCEXXXXstart
#	* Add $STATIC_WALLPAPER for your background not being touched
#	* Explained a few much some variables in configrc
#	* Add 2 test_states () functions
#	* Add WIFI interface down possibility
#	* Made functions : mail_action(), noise_action(), term_action(),
#	  aosd_action(), wifi_action() in order to clean actions_huge...()
#	  and made function usual_actions() to call actions above
#	* Add tests in check_variables()
#
##############
## Changelog 0.4
##############
#
#	* Minors bugs corrections
#	* Removed unneeded $tmpline in mixer_table()
#	* Function upgrade_rc() for the USER not to lose his settings
#	* Add a licence
#	* Changed the way to kill bat_alert in a real "cancel shutdown process"
#	* Add 60 sec timer before shutdown : thx to Bertrand Janin (tamentis)
#
###############
# Changelog 0.3
###############
#
#	* Clean the check_variables () (old : chk_continue) ; Thx to Bertrand Janin (tamentis)
#	* Change location $TMPBATDIR to ${HOME}/.bat_alert/tmp
#	* Add a config file in ${HOME}/.bat_alert/bat_alertrc
#	* Use of getopts with options
#		* -c config_file    : for loading alternative config file
#		* -d	: debug (not fully implemented ; sort of verbose mode)
#		* -h	: display help and exit
#		* -v	: show bat_alert version
#		* -V	: show bat_alert version
#	* Add a way to kill bat_alert.sh in order to cancel shutdown process
#	* Add $RCVERSION
#
###############
# Changelog 0.2
###############
#
#	* Add possibility to set arguments on some commands
#	* Add aosd_cat (thx to Bertrand Janin (tamentis) for the idea)
#	* Add a before shutdown command possibility
#	* Add functions :
#		* check_continue ()
#		* battery_info ()
#		* Faosd ()
#		* launch_xterm ()
#		* test_since ()
#	* Clean up functions "actions"
#	* Add a Changelog
#	* Add a TODO list
#	* Correct beep bug when severals beeps
#
################################################################################
################################################################################
############                             TODO                        ###########
################################################################################
################################################################################
#
#	* Adjust powersafe-performance 
#	* Work with APM and pmud
#	* Rewrite in python bat_alert
#	* Add kill / trap to reload/change config on the fly
#	* Add a way for USER to put his own command in $STATE he wants
#	  and not lose it in an upgrade process.
#
#                                    ~~~~~~~~~
#                                    ~ FIXED ~
#                                    ~~~~~~~~~
#	* Clean in mixer_table() the $tmpline
#       * Make a config file in order to launch $0 with different config
#       * Make bat_alert.sh able to fill in alone the first config file
#       * Add an easy way to stop the shutdown process
#       * Clean the check_continue () 
#       * AUTOUPDATE rcfile
#	* Add a timer for knowing time we have before shutdown
#	* Add possibility to make oasd_cat work differently, depending 
#         on $STATE ( = $HUGE → $TINY)
#	* Add Wifi down possibility and a way to cancel this process.	
#	* Adjust process like brightness
#	* Add a console-only mode
#	* Do a rolling wallpaper, and not only at the end awful xsetroot
#	* Make the RC_CONFIG file more clear, well explained variables
#
################################################################################
################################################################################
###########                   BEGINNING  OF BAT_ALERT.SH              ##########
################################################################################
################################################################################

################################################################################
################################################################################
################################################################################
#####                                                                      #####
#####     DO NOT EDIT AFTER THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING    #####
#####                                                                      ##### 
################################################################################
################################################################################
################################################################################

VERSION="0.6" ;
DATEVERSION="2010-02-27" ;

############################################
### Some more variables
############################################

BATDIR="${HOME}/.bat_alert" ;

TMPBATDIR="${BATDIR}/tmp" ;
if [[ -d "$TMPBATDIR" ]]; then
	rm -rf "${TMPBATDIR}/*" ;
fi

AMIXDIR="${TMPBATDIR}/amixer_settings" ;
if [[ -d "$AMIXDIR" ]]; then
	rm -rf "$AMIXDIR/*" ;
fi

BAT_INFO="${TMPBATDIR}/bat_info.txt" ;

mixer="$(which amixer) -q "$SOUNDCARDAMIXER" sset" ;

############################################
### getoptions
# -c config file
# -d debug == verbose
# -h help
# -V version
############################################

while getopts c:dhtvV OPTION ; do
	case "$OPTION" in
		c)
			CONFIG="$OPTARG" ;
			;;
		d)
			DEBUG="yes" ;
			;;
		h)
			HELP="yes" ;
			;;
		t)
			TERMINAL="yes" ;
			;;
		v|V)
			VERS="yes" ;
			;;
		*)
			HELP="yes" ;
			;;
	esac
done

############################################
### Functions -- Définition des fonctions
############################################

############################################
### If there is not a config file, create one default config
### in ${BATDIR}
############################################

create_default_config () {
	echo -ne "#!/bin/bash
############################################
### Variables' definition -- Définition de variables utilisateur
############################################

##############
## Choose here the PERCENTAGE of battery left
## Must be between \"1\" and \"99\" ; we will later refer to that
## as the battery STATE.
##
## more than \$HUGE % of battery left ; typically : do nothing
## between \$HIGH and \$HUGE, do some stuff to begin to warn you
## and so on, untill \$TINY
## Below \$TINY, do emergency stuff
##############
HUGE=\"50\" ;
HIGH=\"25\" ;
MED=\"12\" ;
SMALL=\"6\" ;
TINY=\"2\" ;

##############
## Time you want the program sleeps 
## before testing battery again, in SECONDS
#
# SLcharge : Battery on charge
# SLhuge : More than \$HUGE% battery left
# SLhigh : Between \$HIGH & \$HUGE % left
# SLmed : Between \$MED & \$HIGH % left
# SLsmall : Between \$SMALL & \$MED % left
# SLtiny : Between \$TINY & \$SMALL % left
# SLdown ; Less than \$TINY % battery left
##############

SLcharge=\"500\" ;
SLhuge=\"1200\" ;
SLhigh=\"800\" ;
SLmed=\"400\" ;
SLsmall=\"200\" ;
SLtiny=\"100\" ;
SLdown=\"50\" ;

###################################
### How to set next variables
###################################
#
# bat_alert.sh as a bunch of actions it does depending on the 
# battery STATE define above : HUGE, HIGH, MED, SMALL and TINY.
#
# Some variables will always refer to the same kind of thing
########
# SINCEXXXXXstart
########
# \$SINCEXXXXXXstart refers to which STATE of battery left will
# tell bat_alert.sh to begins actions of the XXXXXX alert.
# Values to \$SINCEXXXXXstart can be :
#  *\"HUGE\"  : bat_alert will start the action since the battery state 
#   is between 100% and \$HUGE % of battery of battery left.
#  *\"HIGH\"  : bat_alert'll perform the action since the battery will
#   quit the \$HUGE % of battery left, entering the \$HIGH STATE.
#  *\"MED\"  : action begins when entering \$MED  STATE
#  *\"SMALL\" : action begins when entering \$SMALL  STATE
#  *\"TINY\" : action begins when entering \$TINY  STATE.
#  *\"NEVER\"  : when you do not want bat_alert to perform this kind of action
#  *\"\"  ; same as \"NEVER\".
# There is an other STATE in the program ; this is the \"DOWN\"  STATE
# you can NOT choose this STATE for a  \$SINCEXXXXXstart. In this STATE, bat_alert
# will do emergency stuffs. \"DOWN\" STATE occurs when there is
# LESS than \"\$TINY\" % of battery left.
#########
# XXXXX_ONE
#########
# There is some actions you may want to be done regulary, (everytime the battery state
# is checked, define above in \$SLxxxx= ) in order to keep you in mind that 
# the battery is going down ; and others actions, more annoying, that should 
# occur only when a STATE change.
# To choose an action should occur only ONCE (when the STATE change, beginning
# the first time as define in \$SINCEXXXXstart above) and not occurs again before
# the next STATE change, the value of \$XXXX_ONE must be set to \"yes\".
#

#################################
###
### actions of bat_alert.sh
###
#################################

##############
## MailTo ; change if needed
##############
MAILUSER=\"\${USER}@localhost\" ;
# \$SINCEMAILstart tells when bat_alert.sh begins to mail you to warn you
# variable can be set to : HUGE, HIGH, MED, SMALL, TINY, NEVER or nothing 
#
# Only one mail will be sent for HUGE, then next email when battery reach
# HIGH, then when battery reach MED then SMALL...
# It will NEVER send any email if SINCEMAILstart=\"\" , or \"NEVER\"
SINCEMAILstart=\"MED\" ;

##############
## Noise - sound ; change if needed
##############
#
# Same as before for the mail for setting the variable
# But the PC will beep everytime the bat-alert checks.
# It will NEVER beep only if SINCENOISEstart=\"\" or \"NEVER\"
#
SINCENOISEstart=\"MED\" ;
# If you prefer that it beeps only when a state changes
# ( HUGE to HIGH, SMALL TO TINY ... enable to \"yes\"
BEEP_ONE=\"no\" ;

# Set percent of volume to beep
# At first (HUGE), beep can be soft (10)
# At the end of battery, it should be stronger to warn you
# if you're away
HUGESND=\"10\" ;
HIGHSND=\"15\" ;
MEDSND=\"20\" ;
SMALLSND=\"35\" ;
TINYSND=\"50\" ;
DOWNSND=\"80\" ;

# And now, set the number of BEEP the computer will do
# ( 0.5 seconds between each beep ; soon configurable)
# Of course, it won't beep before SINCENOISEstart
HOWMANY_BEEP_HUGE=\"1\" ;  # 1 beep if STATE = HUGE
HOWMANY_BEEP_HIGH=\"1\" ;
HOWMANY_BEEP_MED=\"1\" ;
HOWMANY_BEEP_SMALL=\"2\" ; # 2 beeps if STATE = SMALL
HOWMANY_BEEP_TINY=\"3\" ;
HOWMANY_BEEP_DOWN=\"5\" ; # when next to power failure, beeps 5 times

# This setting should NOT be edit, unless you have several sound cards,
# you're using amixer and you know what you're doing
# variable can be set to \"-c 0\" , \"-c 1\" , \"-c 3\" ...
# leaving it at : \"\" will use system default, likely : \"-c 0\"
# see \"man amixer\"
SOUNDCARDAMIXER=\"\" ;

##############
## Warning displayed on screen
##############
#
## AOSD_CAT
#
# I RECOMMEND installing \"aosd_cat\" a little programm to echo text on the window manager
# With it, no xterm will pop up to annoy you : it is \"transparent\".
# If you have aosd_cat, please turn variable to \"yes\".
AOSD_CAT=\"no\" ;
# After having read  aosd_cat --help , you may set up your owns arguments
# in the next variable :
AOSD_CAT_ARG=\"-p 7 -R cyan -f 200 -u 2500 -o 300\" ;
# You may also be more specific on aosd's arguments depending on battery's STATE...
# In the case a specific AOSD_ARG_\$STATE is left blank ( \"\" ), then the defaults
# arguments above (AOSD_CAT_ARG) will be used.
AOSD_ARG_HUGE=\"-p 7 -R purple -f 1000 -u 500 -o 1000\" ;
AOSD_ARG_HIGH=\"-p 4 -R purple -f 600 -u 1500 -o 700\" ;
AOSD_ARG_MED=\"-p 4 -R cyan -f 500 -u 2500 -o 500\" ;
AOSD_ARG_SMALL=\"-p 4 -R green -f 300 -u 5000 -o 1500\" ;
AOSD_ARG_TINY=\"-p 4 -R red -f 100 -u 10000 -o 2000\" ;
# Choose HUGE, HIGH, MED, SMALL, TINY, NEVER or \"\" for start of SINCEAOSDstart
SINCEAOSDstart=\"HUGE\" ;
# As before (noise) : if you want to display aosd only ONCE per state change
# (HUGE → HIGH ...), enable to \"yes\"
AOSD_ONE=\"no\" ;

#
## XTERM
#
# If you DO NOT have aosd_cat, BUT YOU HAVE xterm, you can leave this variable to yes
# But as it is very annoying, you'll probably want to set it to \"no\" and rather
# install aosd_cat (with libaosd) !
XXXterm=\"yes\" ;
# You may set up some XTERM_ARG (man xterm) or leave it blank
XTERM_ARG=\"-geometry 60x6+3+4\"
# As before (mail, noise, aosd) : at what state does it begin to start ?
SINCETERMstart=\"MED\" ;
# As for noise... only one term pops up per HUGE, HIGH...
# enable to \"yes\" for only one term (at state change)
TERM_ONE=\"yes\" ;

##############
## Wallpaper
##############
# And now, what about changing the wallpaper, still depending on battery
# STATE ???
# It could be a daylight landscape when battery is full, turning into night
# when battery's almost empty ; or a hottie in bikini who put on her clothes
# I'm pretty sure you'll come with a good idea.
# At the very end I recommend to use not a wallpaper as usual, but switch to
# a full color annoying if possible. The purpose is to remind you run to
# your AC adaptator. So we'll have 2 programs variables. You can choose to put
# the same program in both, of course
###
# The wallpaper will be change at the end, when only TINY battery is left
# Choose a color that will warn you really high
# The default is RED
# Please use in \$WARN_WALL a prog with arguments you have
# WARN_WALL could be set to xsetroot, or better : fbsetroot, ... use what you have and like !
# you can also leave it blank : the last wallpaper won't be touch.
# WARN_WALL only appears since TINY STATE.
WARN_WALL=\"xsetroot\" ;
# WARN_WALL_ARG could be set to a flashy (annoying ?) color, for exemple ;  man \$WARN_WALL 
# to set what you want
WARN_WALL_ARG=\"-solid red\" ;
###
# \$WALLPAPER is use to set back the wallpaper when AC is plugged, and
# to change wallpaper from \"in charge\" STATE , HUGE, HIGH, MED and SMALL.
# Use a command you have (Esetroot, fbsetbg...) ;  fbsetbg -l  --> put back the previous wallpaper ;)
# Or leave blank  : \"\"
WALLPAPER=\"fbsetbg\" ;
# In the argument var \$WALLPAPER_ARG, fill in arguments after   man wallpaper_command
# like PATH/TO/YOUR/FAVORITE/WALLPAPER  or leave blank
WALLPAPER_ARG_CHARGE=\"\" ;
WALLPAPER_ARG_HUGE=\"\" ;
WALLPAPER_ARG_HIGH=\"\" ;
WALLPAPER_ARG_MED=\"\" ;
WALLPAPER_ARG_SMALL=\"\" ;
# Next one is a default ; if you left one or more 
# WALLPAPER_ARG_STATE blank, the next will be used instead.
WALLPAPER_ARG=\"-l\" ;
# IF YOU DON'T WANT YOUR WALLPAPER BEEING CHANGED, 
# YOU CAN TURN NEXT VARIABLE TO \"yes\"
# (same as leaving blank \$WALLPAPER above)
STATIC_WALLPAPER=\"no\" ;

##############
## ADJUST BRIGHTNESS
##############
# Be careful ! This option need you to be able to write in a file
# that have only root permissions. Your root administrator has to 
# give you permissions to write on the file. Here is one method.
#
# in root :
#  # addgroup brightness      (or use existing group : adm, wheel, your \$USER group...)
#  # adduser \$USER brightness            (or wheel, or whatever group you want)
#  # chgrp brightness /sys/class/backlight/???/brightness  (find the right PATH)
#  # chmod 664 /sys/class/backlight/???/brightness
# Then unlog and relog (at worst, if you're not sure how to unlog, just reboot ! (just jokin'))
# The USER is now able to change brightness with this command :
# echo xx > /sys/class/backlight/???/brighness
# xx must be greater than 0 and less or equal to /sys/class/backlight/???/max_brightness
###############
# Do you want bat_alert to adjust brightness ?
ADJ_BRIGHTNESS=\"no\" ;  # Read carefully howto in config file \"bat_alertrc\" before
# PATH to directory where there is at least these two files :
# \"brightness\"  AND \"max_brightness\".
BACKLIGHT_DIR=\"/sys/class/backlight/eeepc/\" ;   # Where the brightness is set
# And now, % of brightness, depending on STATE ; between 0 and 100
BRIGHTHUGE=\"100\" ;    # 100% of max_brightness
BRIGHTHIGH=\"80\" ;
BRIGHTMED=\"60\" ;	# 60% of max_brightness
BRIGHTSMALL=\"40\" ;
BRIGHTTINY=\"20\" ;	# 20% of max_brightness
BRIGHTDOWN=\"1\" ;
# You can also make brightness decrease SINCE...
SINCEBRIGHTstart=\"HUGE\" ;  # HUGE → NEVER ;

##############
## WIFI DOWN
##############
# Here you set your Wifi interface as it appears in /sbin/ifconfig
# and in /etc/network/interfaces
I_WIFI=\"wlan0\" ;  # wifi interface
# Next, tell when bat_alert.sh ask you for stopping wifi. (HUGE → NEVER)
# A xterm will popup ; if you don't close xterm window, the 
# wifi will be stopped one minute later.
SINCEWIFIDOWNstart=\"TINY\" ;  # when bat_alert propose to stop wifi
# Ask USER for closing wifi only once per STATE
WIFI_ONE=\"yes\" ;  # Proposing closing wifi once or more per STATE

#############
## Shutdown
##############
# If \$USER can shutdown the computer, it would be a great idea to do it 
# before Power failure
# You may set a command to do before shuting down the computer in
# \$BEFORE_SHUT , (for exemple : sudo /sbin/ifconfig wlan0 down )
# or leave it blank : \"\"  .
#
# variable \$SHUTDOWN could be set to :
#		sudo shutdown -h now
#		sudo /usr/sbin/s2disk -r /dev/PATH/TO/SWAP
# or could be left to   \"\"  ; in this case, computer won't be shutdown.
BEFORE_SHUT=\"\" ;
SHUTDOWN=\"\" ;

##############
## At least
##############
#
# AFTER SETTING ALL VARIABLES BEFORE LIKE YOU WANT, ENABLE bat_alert.sh
# BY CHANGING THIS VARIABLE ( START_BAT_ALERT ) TO \"yes\"
START_BAT_ALERT=\"no\" ;

###########################################
###########################################
###      DO NOT CHANGE THIS, PLEASE     ###
RCVERSION=\"0.6\" ;
###########################################
###########################################" > ${BATDIR}/bat_alertrc-tmp

}

new_default_config () {
	mv ${BATDIR}/bat_alertrc-tmp ${BATDIR}/bat_alertrc ;
	echo -ne "\nA default config file ${BATDIR}/bat_alertrc as been created ;
Please fill it in correctly while reading it.
You can also create alternative config_file by launching :
bat_alert.sh -c other/config/file   \n\n" ;
	exit 0 ;
}

#################################
###
### UPGRADE CONFIG FILE
###
#################################

##
## This 4 functions will help upgrade the olds bat_alertrc files
##
 
inform_user () {
	## In order that this commands are executed before the rm occurs in next function
	xterm -hold -e cat $BATALRCDIFF 2>/dev/null &
	sleep 1 ;
	cat $BATALRCDIFF | mail -s "bat_alert.sh new configuration file" "$MAILUSER" ;
}

variables_names_changed () {
## This function is here if I need to change the name of a variable but not its
## value. Maybe it will never be used.
	NEWVARNAME="${TMPBATDIR}/changed_name.txt" ;
	touch $NEWVARNAME ;
	for i in $OLDVARTOCHANGE ; do
		KEY_OLD=$(grep "^$i=" "$BATALRCOLD" | cut -d "=" -f 1) ;
		if [[ "$i" = "$KEY_OLD" ]]; then
			case $i in
				foo)
					sed 's/^foo=/foo2=/' "$BATALRCOLD" ;
					echo -ne "\$foo as been replaced by \$foo2 in your config file\n" >> $NEWVARNAME ;
					;;
				bar)
					sed 's/^bar=/hurray=/' "$BATALRCOLD" ;
					echo -ne "\$bar as been replaced by \$hurray in your config file\n" >> $NEWVARNAME ;
					;;
			esac
		fi
	done
	if [[ -n $(cat "$NEWVARNAME") ]]; then
		echo -ne "bat_alert.sh needed to rename the variable above in order to keep working ;\n\
variable's value is unchanged, except if specified.\n\
Sorry for the inconvenience.\n" >> $NEWVARNAME ;
		xterm -hold -e "echo $NEWVARNAME" 2>/dev/null &
		sleep 1 ;
		cat $NEWVARNAME | mail -s "bat_alert.sh changement of variables names" "$MAILUSER" ;
		rm $NEWVARNAME ;
	fi
}

variables_names_version () {
## With the function variables_names_changed above, we determine
## if the new rcversion needs name changements
	case $RCVERSCHK in
		try)
			OLDVARTOCHANGE="foo bar"
			variables_names_changed ;
			;;
		0.3)
			;;
		0.4)
			;;
		0.5)
			;;
	esac

}

upgrade_rc () {
	
	## First, We want to save old config file of $USER, "in case of..."

	## in a special dir for old conf...
	OLDCONFDIR="${BATDIR}/OLD_CONF" ;
	if [[ ! -d "$OLDCONFDIR" ]]; then
		mkdir $OLDCONFDIR ;
	fi
	## We put all old conf from before.
	ls ${BATDIR} | grep OLD$ > ${BATDIR}/nada ;
	STAYOLDCONF=$(cat "${BATDIR}/nada") ;
	if [[ -n "$STAYOLDCONF" ]]; then
		mv ${BATDIR}/*-OLD $OLDCONFDIR ;
	fi
	rm ${BATDIR}/nada ;

	## Now we create the "new" old conf, the one we use we the version
	## before the upgrade
	cp $CONFIG ${CONFIG}-${RCVERSCHK}-$(date +%y%m%d)-OLD ;

	## The new version_config file is (from create_defaut_config() )
	BATALRCTMP="${BATDIR}/bat_alertrc-tmp" ;

	## We now take interessant informations (not the #comments, nor the $RCVERSION) 
	## from the user old config
	BATALRCOLD="${BATDIR}/old_config-tmp" ;
	touch $BATALRCOLD ;
	grep -v ^# $CONFIG | sed '/^$/d' | grep -v ^RCVERSION > ${BATDIR}/old_config-tmp ;
	## And from the new config...
	BATALRCNEW="${BATDIR}/new_config-tmp" ;
	touch $BATALRCNEW ;
	grep -v ^# $BATALRCTMP | sed '/^$/d' | grep -v ^RCVERSION > ${BATDIR}/new_config-tmp ;

	variables_names_version ;

	while read -r line ; do
		## Getting important information : variable's name ($KEY) and its $VALUE
		KEY_OLD=$(echo "$line" | cut -d "=" -f 1) ;
		# VALUE_OLD is the one configured by $USER ; we want to keep it
		VALUE_OLD=$(echo "$line" | cut -d '"' -f 2 | sed 's/\//\\\//g' ) ;
		VALUE_NEW=$(grep ^$KEY_OLD= "$BATALRCTMP" | cut -d '"' -f 2 | sed 's/\//\\\//g' ) ;

		# Replace NEW by OLD
		sed -e "s/$KEY_OLD=\"$VALUE_NEW\" \;/$KEY_OLD=\"$VALUE_OLD\" \;/g" "$BATALRCTMP" > "$CONFIG" ;

		## For not that a the end of the loop, we see only last variable changed...
		mv "$CONFIG" $BATALRCTMP

	done < "${BATDIR}/old_config-tmp"

	## We now will compare variable's name in both rcfiles, in order to tell USER new ones.
	### To avoid errors depending on in which we were when we launched bat_alert -c config,
	### we will rename the $CONFIG
	BATALRCDIFF="${CONFIG}-${VERSION}-RC_diff.txt"
	touch $BATALRCDIFF ;
	echo -ne "These new variables has been added to your config file $CONFIG ;\n\
Please edit your config file to verify you agree with new settings.\n" > $BATALRCDIFF ;
	# Get old variables names
	cut -d "=" -f 1 "$BATALRCOLD" > ${BATALRCOLD}_keys ;
	# Get new variables names
	cut -d "=" -f 1 "$BATALRCNEW" > ${BATALRCNEW}_keys ;
	# Compare variables names from old config with the ones from new config
	# and write to the file $BATALRCDIFF variables names that appears
	# only in the new config file.
	while read -r line ; do
		if [[ -z $(grep "$line" ${BATALRCOLD}_keys) ]]; then
			ADDVAR="$(grep "^${line}=" $BATALRCNEW)" ;
			echo -ne "${ADDVAR}\n" >> $BATALRCDIFF ;
		fi
	done < "${BATALRCNEW}_keys"

	# Send user the names with the values of new variables, in order he knows
	# what he could change.
	inform_user ;
		
	# And class file we do not need any more
	mv $BATALRCDIFF $OLDCONFDIR
	mv ${BATDIR}/*-OLD $OLDCONFDIR

	# Remove temp-file
	rm "${BATDIR}/old_config-tmp" ;
	rm "$BATALRCNEW" ;
	rm "${BATALRCOLD}_keys" ;
	rm "${BATALRCNEW}_keys" ;
	# Remove temp file replacing upgraded config
	mv $BATALRCTMP "$CONFIG" ;
}

##############
## Now, functions for script to work
##############
##
## Some more config setting before getting in the real thing 
## if everythings OK
##

check_variables () {
	# Test if all the variables are in the right range
	if [[ 99 -lt $HUGE || $HUGE -lt $HIGH || $HIGH -lt $MED || $MED -lt $SMALL || $SMALL -lt $TINY || $TINY -lt 1 ]]; then
		echo -ne "Please fill in correctly HUGE HIGH MED SMALL TINY\n" ;
		exit 2 ;
	fi

	for i in $HUGESND $HIGHSND $MEDSND $SMALLSND $TINYSND $DOWNSND ; do
		if [[ 100 -lt $i || 0 -gt $i ]]; then
			echo -ne "Please fill in correctly VARIABLESND (BEEP VOLUME)\n" ;
			exit 3 ;
		fi
	done

	if [[ $ADJ_BRIGHTNESS = "yes" ]]; then
		if [[ -d "$BACKLIGHT_DIR" ]]; then
			BACKLIGHT_DIR="$(echo $BACKLIGHT_DIR | sed s,/$,, )" ;
			if [[ -f "${BACKLIGHT_DIR}/brightness" && -f "${BACKLIGHT_DIR}/maxbrightness" ]]; then
				for i in $BRIGHTHUGE $BRIGHTHIGH $BRIGHTMED $BRIGHTSMALL $BRIGHTTINY $BRIGHTDOWN ; do
					if [[ 100 -lt $i || 0 -gt $i ]]; then
					echo -ne "Please fill in correctly percentage for brightness (BRIGHTVARIABLE)\n" ;
					exit 3 ;
					fi
				done
			else
				echo -ne "Please verify your $BACKLIGHT_DIR contains the files "brightness" and "max_brightness"\n" ;
				exit 4 ;
			fi
		else
			echo -ne "Please verify your PATH $BACKLIGHT_DIR \n" ;
			exit 4 ;
		fi
	fi

	for i in $HOWMANY_BEEP_HUGE $HOWMANY_BEEP_HIGH $HOWMANY_BEEP_MED $HOWMANY_BEEP_SMALL \
		$HOWMANY_BEEP_TINY $HOWMANY_BEEP_DOWN; do
		if [[ 10 -lt $i || 1 -gt $i ]]; then
			echo -ne "Please fill in correctly HOWMANY_BEEP_VARIABLES\n" ;
			exit 3 ;
		fi
	done

	if [[ -x $(which $WALLPAPER) ]]; then
		if [[ -z "$WALLPAPER_ARG_CHARGE" || -z "$WALLPAPER_ARG_HUGE" || \
		-z "$WALLPAPER_ARG_HIGH" || -z "$WALLPAPER_ARG_MED" || -z "$WALLPAPER_ARG_SMALL" ]]; then
			if [[ -z "$WALLPAPER_ARG" ]]; then
				echo -ne "Please fill in correctly WALLPAPER_ARG.\n";
				exit 6 ;
			fi
		fi
	fi
	if [[ -x $(which $WARN_WALL) ]]; then
		if [[ -z "$WARN_WALL_ARG" ]]; then
			echo -ne "Please fill in correctly WARN_WALL_ARG\n" ;
			exit 6 ;
		fi
	fi

	for i in $SINCEMAILstart $SINCENOISEstart $SINCETERMstart $SINCEWIFIDOWNstart \
		$SINCEBRIGHTstart ; do
		if [[ -n $i && $i != "HUGE" && $i != "HIGH" && \
		$i != "MED" && $i != "SMALL" && $i != "TINY" \
		&& $i != "NEVER" ]]; then
			echo -ne "Please fill in correctly SINCEVARIABLES\n" ;
			exit 7 ;
		fi
	done

	if [[ "$AOSD_CAT" = "yes" && -z "$SINCEAOSDstart" || "$SINCEAOSDstart" = "HUGE" || \
	 "$SINCEAOSDstart" = "HIGH" || "$SINCEAOSDstart" = "MED" || "$SINCEAOSDstart" = "SMALL" \
	|| "$SINCEAOSDstart" = "TINY" || "$SINCEAOSDstart" = "NEVER" ]]
	then
		
		SINCEMAIL="$SINCEMAILstart" ;
		SINCETERM="$SINCETERMstart" ;
		SINCEAOSD="$SINCEAOSDstart" ;
		SINCENOISE="$SINCENOISEstart" ;
		SINCEWIFIDOWN="$SINCEWIFIDOWNstart" ;
		SINCEBRIGHT="$SINCEBRIGHTstart" ;
		chk_power_man ;
	else
		echo -ne "Please fill in correctly SINCEAOSDstart\n" ;
		exit 5 ;
	fi
}

#################################
###
### Some actions will be done only if USER doesn't interrupt
### them, likely because he isn't in front of computer
###
#################################

cancel_action () {
	xterm -hold -e "\
		i=60 ; \
		while [ \$((i--)) -gt 0 ]; do \
			clear ; \
			if [[ \$i = "0" ]]; then \
				clear ; \
				echo -ne \"$WARNING_ACTION\" ;\
				$ACTION ; \
			fi ;\
			echo -ne \"$WARNING_MSG\"; \
			sleep 1; \
		done" 2>/dev/null &
}

##############
## send email
##############
bat_email () {
	# send an email to tell how much battery is left
	if [[ -n $SINCEMAIL ]]; then
		echo "battery is only $PERCENT_LEFT full and havi $TIME_LEFT left" | mail -s "Battery $PERCENT_LEFT left" "$MAILUSER" ;
	fi
}

##############
## Make noise
##############

## Restore mixer settings after the beep, just like you love
## your mixer
##
restore_mixer () {
	cd $AMIXDIR ;
	for MIXLINE in * ; do
		case $MIXLINE in
			Master)
				# Get settings Master
				MAPB=$(cat $MIXLINE | awk '{print $2}') ;
				MAMU=$(cat $MIXLINE | awk '{print $3}') ;
				# Restore Master
				$mixer $MIXLINE $MAPB $MAMU ;
				;;
			PCM)
				# Get & Restore PCM
				PCMPBL=$(cat $MIXLINE | awk '{print $2}') ;
				PCMPBR=$(cat $MIXLINE | awk '{print $3}') ;
				$mixer $MIXLINE ${PCMPBL},${PCMPBR} ;
				;;
			Headphone|Speaker|Beep)
				L_PB=$(cat $MIXLINE | awk '{print $2}') ;
				L_MU=$(cat $MIXLINE | awk '{print $3}') ;
				R_PB=$(cat $MIXLINE | awk '{print $4}') ;
				R_MU=$(cat $MIXLINE | awk '{print $5}') ;
				$mixer $MIXLINE ${L_PB},${R_PB} ${L_MU},${R_MU} ;
				;;
		esac
	done
	cd $BATDIR ;
}

#
# Setting up mixer for the annoying noisy BEEP !!!
#
noisy_beep () {
	$mixer Master $MAPERCENT unmute
	$mixer PCM $PCMPERCENT unmute
	for MIXLINE in Headphone Speaker Beep ; do
		$mixer $MIXLINE $LINEPERCENT unmute ;
	done

	for (( i = 0; i < $NUMBER_BEEP; i++ )); do
		echo -ne "\a" ;
		sleep .5 ;
	done

}

## Create a table to store amixer's data in order to restore it
## right after the pc's beep.
##
mixer_table () {
	# Creating a directory in ${TMPBATDIR}/amixer_settings to stock mixer settings
	if [[ -x $(which amixer) ]]; then
		# flush all settings
		if [[ -d $AMIXDIR ]] ; then
			rm -rf $AMIXDIR ;
		fi
		mkdir "$AMIXDIR" ;
		
		#####
		# Files where settings will be stored properly
		#####

		# table_tmp the almost right table, before "sed"
		# [on] → unmute    and   [off] → mute
		AMIX_TABLE_TMP="${AMIXDIR}/amix_table_tmp.txt" ;
		touch "$AMIX_TABLE_TMP" ;
		# table of amixer settings done
		AMIX_TABLE="${AMIXDIR}/amix_table.txt" ;
		touch $AMIX_TABLE ;
		
		# As, in the script, cat $AMIX_TABLE doesn't read line by line
		# but send all lines in one big line, and
		# for taking back in a loop easily settings,
		# each mixer controler will get its own file.
		for MIXLINE in Master PCM Headphone Speaker Beep ; do
			AMIXLINE="${AMIXDIR}/${MIXLINE}" ;
			touch $AMIXLINE ;
		done

		# Get mixer settings
		AMIX_SCONT="${AMIXDIR}/amix_scontent.txt" ;
		amixer scontents > $AMIX_SCONT ;
		# Get important information
		AMIX_SORT="${AMIXDIR}/amix_sort.txt" ;
		touch $AMIX_SORT ;
		egrep -T 'Simple|Mono|Front' "$AMIX_SCONT" | grep -v channels > "$AMIX_SORT" ;

		# Write down cleanly what we'll need

		while read -r line ; do
			# identify the line
			id_line=$(echo "$line" | awk '{print $1}' ) ;
			
			case "$id_line" in
				Simple)
					if [[ -n $AMIX_TABLE_TMP ]]; then
						if [[ -z $Left_PB ]]; then
							echo -ne "$Mixer \t $Mono_PB \t $Mono_MU \n" >> $AMIX_TABLE_TMP ;
						else
							echo -ne "$Mixer \t $Left_PB \t $Left_MU \t $Right_PB \t $Right_MU \n" >> $AMIX_TABLE_TMP ;
						fi
					Mixer="" ;
					Mono_PB="" ;
					Mono_MU="" ;
					Left_PB="" ;
					Left_MU="" ;
					Right_PB="" ;
					Right_MU="" ;
					fi
					Mixer=$(echo "$line" | awk '{print $4}' | sed s/\'//g | sed 's/,0//') ;
					;;
				Mono:)
					Mono_PB=$(echo "$line" | awk '{print $3}' ) ;
					if [[ -n $Mono_PB ]]; then
						Mono_MU=$(echo "$line" | awk '{print $6}' | sed 's/\[//g;s/\]//g') ;
					fi
					;;
				Front)
					# Left or Right ?
					SIDE=$(echo "$line" | awk '{print $2}' | sed s/://) ;
					case $SIDE in
						Left)
							Left_PB=$(echo "$line" | awk '{print $4}') ;
							Left_MU=$(echo "$line" | awk '{print $7}' | sed 's/\[//g;s/\]//g') ;
							;;
						Right)
							Right_PB=$(echo "$line" | awk '{print $4}' ) ;
							Right_MU=$(echo "$line" | awk '{print $7}' | sed 's/\[//g;s/\]//g') ;
							;;
					esac
					;;
			esac

		done <"$AMIX_SORT"
	else
		echo -ne "I don't know what your mixer is ; Maybe beep alert won't work properly.\n" ;
	fi
	rm "$AMIX_SORT" ;

	# turn all [on] → unmute  and all  [off] → mute
	sed 's/ on/unmute/g;s/ off/mute/g' $AMIX_TABLE_TMP > $AMIX_TABLE ;
	rm $AMIX_TABLE_TMP ;

	# Write in each $TMPBATDIR/$AMIXDIR/$MIXLINE  informations about each mixer controller
	while read -r line ; do
			CONTROLER=$(echo "$line" | awk '{print $1}') ;
			if [[ -n $CONTROLER ]]; then
				echo $line > "${AMIXDIR}/$CONTROLER" ;
			fi
	done < "$AMIX_TABLE"
	rm "$AMIX_TABLE" ;
	rm "$AMIX_SCONT" ;
}

##############
## What about writting on term / root-window some warnings too ??? :)
##############

battery_info () {
	# Write down to a file ($TMPBATDIR/bat_info.txt) what will be given in
	# the written warning
	echo -ne "\t$TIME_LEFT before power failure ;\n\t battery : $PERCENT_LEFT left" > "$BAT_INFO" ;
}

Faosd () {
	# launch aosd_cat with what is on "$BAT_INFO"
	if [[ "$AOSD_CAT" = "yes" ]]; then
		AOSD="$(which aosd_cat)" ;
		if [[ -x "$AOSD" ]]; then
			$AOSD $AOSD_CAT_ARG -i "$BAT_INFO" &
		fi
	fi	
}

launch_xterm () {
	if [[ "$XXXterm" != "no" ]]; then
		if [[ -x $(which xterm) ]]; then
			# launch xterm and echo into information about battery found on $TERMINFO
			xterm $XTERM_ARG -hold -e cat "$BAT_INFO" 2>/dev/null &
			# We don't want the term window to stay forever :
			PIDterm=$! ;
			sleep 5 && kill "$PIDterm" ;
		fi
	fi
}

##############
## What will append to Wifi 
##############


wifi_down () {

		WARNING_MSG_WIFI="\nThe wifi interface \$I_WIFI is about to be closed in\n\n\
\t\t \$i seconds\n\n\
TO CANCEL AUTOMATIC WIFI DOWN PROCESS, JUST CLOSE THIS XTERM WINDOW.";
		WARNING_MSG="$WARNING_MSG_WIFI" ;
		WARNING_ACTION="\n\n\t bringing interface \$I_WIFI DOWN !!!\n\n";
		if [[ -x /sbin/ifdown ]]; then
			ACTION="sudo /sbin/ifdown $I_WIFI" ;
			cancel_action ;
		elif [[ -x /sbin/ifconfig ]]; then
			ACTION="sudo /sbin/ifconfig $I_WIFI down" ;
			cancel_action ;
		else
			xterm -hold -e echo -ne "Can't find neither ifdown nor ifconfig ;\n\
Please enter in contact with me and, for the moment, disable \$SINCEWIFIDOWNstart (NEVER)." ;
		fi

}

##############
## Change the backlight brightness
##############
adjust_brightness () {

	echo $NEWBRIGHT > ${BACKLIGHT_DIR}/brightness ;
}

#############
## Put the right wallpaper
#############
set_wallpaper () {
	case $STATE in
		DOWN,TINY)
			if [[ -x $(which $WARN_WALL) ]]; then
				$WARN_WALL $WARN_WALL_ARG ;
			fi
			;;
		SMALL)
			if [[ -x $(which $WALLPAPER) ]]; then
				if [[ -n $WALLPAPER_ARG_SMALL ]]; then
					$WALLPAPER $WALLPAPER_ARG_SMALL ;
				else
					$WALLPAPER $WALLPAPER_ARG ;
				fi
			fi
			;;
		MED)
			if [[ -x $(which $WALLPAPER) ]]; then
				if [[ -n $WALLPAPER_ARG_MED ]]; then
					$WALLPAPER $WALLPAPER_ARG_MED ;
				else
					$WALLPAPER $WALLPAPER_ARG ;
				fi
			fi
			;;
		HIGH)
			if [[ -x $(which $WALLPAPER) ]]; then
				if [[ -n $WALLPAPER_ARG_HIGH ]]; then
					$WALLPAPER $WALLPAPER_ARG_HIGH ;
				else
					$WALLPAPER $WALLPAPER_ARG ;
				fi
			fi
			;;
		HUGE)
			if [[ -x $(which $WALLPAPER) ]]; then
				if [[ -n $WALLPAPER_ARG_HUGE ]]; then
					$WALLPAPER $WALLPAPER_ARG_HUGE ;
				else
					$WALLPAPER $WALLPAPER_ARG ;
				fi
			fi
			;;
	esac

}

###############################
### Tests of $SINCE*   (HUGE, ..., SMALL...)
###############################

test_since () {

	case $STATE in
		DOWN)
			if [[ "$SINCE" = "HUGE" || "$SINCE" = "HIGH" || "$SINCE" = "MED" || "$SINCE" = "SMALL" || "$SINCE" = "TINY" || "$SINCE" = "DOWN" ]]; then
				Tsince="yes" ;
			else
				Tsince="no" ;
			fi
			;;
		TINY)
			if [[ "$SINCE" = "HUGE" || "$SINCE" = "HIGH" || "$SINCE" = "MED" || "$SINCE" = "SMALL" || "$SINCE" = "TINY" ]]; then
				Tsince="yes" ;
			else
				Tsince="no" ;
			fi
			;;
		SMALL)
			if [[ "$SINCE" = "HUGE" || "$SINCE" = "HIGH" || "$SINCE" = "MED" || "$SINCE" = "SMALL" ]]; then
				Tsince="yes" ;
			else
				Tsince="no" ;
			fi
			;;
		MED)
			if [[ "$SINCE" = "HUGE" || "$SINCE" = "HIGH" || "$SINCE" = "MED" ]]; then
				Tsince="yes" ;
			else
				Tsince="no" ;
			fi
			;;
		HIGH)
			if [[ "$SINCE" = "HUGE" || "$SINCE" = "HIGH" ]]; then
				Tsince="yes" ;
			else
				Tsince="no" ;
			fi
			;;
		HUGE)
			if [[ "$SINCE" = "HUGE" ]]; then
				Tsince="yes" ;
			else
				Tsince="no" ;
			fi
			;;
	esac
}

#################################
###
### Test arg depending on STATE
###
#################################
#
test_arg_aosd_state () {
	case $STATE in
		DOWN|TINY)
			if [[ -n "$AOSD_ARG_TINY" ]]; then
				AOSD_CAT_ARG="$AOSD_ARG_TINY" ;
			fi
			;;
		SMALL)
			if [[ -n "$AOSD_ARG_SMALL" ]]; then
				AOSD_CAT_ARG="$AOSD_ARG_SMALL" ;
			fi
			;;
		MED)
			if [[ -n "$AOSD_ARG_MED" ]]; then
				AOSD_CAT_ARG="$AOSD_ARG_MED" ;
			fi
			;;
		HIGH)
			if [[ -n "$AOSD_ARG_HIGH" ]]; then
				AOSD_CAT_ARG="$AOSD_ARG_HIGH" ;
			fi
			;;
		HUGE)
			if [[ -n "$AOSD_ARG_HUGE" ]]; then
				AOSD_CAT_ARG="$AOSD_ARG_HUGE" ;
			fi
			;;
	esac
}

test_brightness_state () {
	MAXBRIGHT=$(cat ${BACKLIGHT_DIR}/max_brightness) ;
	case $STATE in
		DOWN)
			NEWBRIGHT=$(($MAXBRIGHT*$BRIGHTDOWN/100)) ;
			;;
		TINY)
			NEWBRIGHT=$(($MAXBRIGHT*$BRIGHTTINY/100)) ;
			;;
		SMALL)
			NEWBRIGHT=$(($MAXBRIGHT*$BRIGHTSMALL/100)) ;
			;;
		MED)
			NEWBRIGHT=$(($MAXBRIGHT*$BRIGHTMED/100)) ;
			;;
		HIGH)
			NEWBRIGHT=$(($MAXBRIGHT*$BRIGHTHIGH/100)) ;
			;;
		HUGE)
			NEWBRIGHT=$(($MAXBRIGHT*$BRIGHTHUGE/100)) ;
			;;
	esac
}

test_beep_state () {
	case $STATE in
		DOWN)
			VOLSND="$DOWNSND" ;
			if [[ -n "$HOWMANY_BEEP_DOWN" ]]; then
				NUMBER_BEEP="$HOWMANY_BEEP_DOWN" ;
			fi
			;;	
		TINY)
			VOLSND="$TINYSND"
			if [[ -n "$HOWMANY_BEEP_TINY" ]]; then
				NUMBER_BEEP="$HOWMANY_BEEP_TINY" ;
			fi
			;;
		SMALL)
			VOLSND="$SMALLSND"
			if [[ -n "$HOWMANY_BEEP_SMALL" ]]; then
				NUMBER_BEEP="$HOWMANY_BEEP_SMALL" ;
			fi
			;;
		MED)
			VOLSND="$MEDSND"
			if [[ -n "$HOWMANY_BEEP_MED" ]]; then
				NUMBER_BEEP="$HOWMANY_BEEP_MED" ;
			fi
			;;
		HIGH)
			VOLSND="$HIGHSND"
			if [[ -n "$HOWMANY_BEEP_HIGH" ]]; then
				NUMBER_BEEP="$HOWMANY_BEEP_HIGH" ;
			fi
			;;
		HUGE)
			VOLSND="$HUGESND"
			if [[ -n "$HOWMANY_BEEP_HUGE" ]]; then
				NUMBER_BEEP="$HOWMANY_BEEP_HUGE" ;
			fi
			;;
	esac
}

#################################
###
### Test of state for action with
###  $ACTION_ONE="yes"
###
#################################

test_state_one () {
	## There is no STATE below the DOWN STATE...
	if [[ "$STATE" != "DOWN" ]]; then
		## does USER want the specific action
		## done only ONCE per STATE ?
		NEWSINCE="" ;
		if [[ "$ACTION_ONE" = "yes" || "$ACTION_ONE" = "YES" ]]; then
			## The $SINCEACTION var may be changed
			case $STATE in
				TINY)
					NEWSINCE="DOWN" ;
					;;
				SMALL)
					NEWSINCE="TINY"
					;;
				MED)
					NEWSINCE="SMALL" ;
					;;
				HIGH)
					NEWSINCE="MED" ;
					;;
				HUGE)
					NEWSINCE="HIGH" ;
					;;
			esac
		fi
	fi

}

#################################
###
### Actions that appends
###
#################################

mail_action () {
	SINCE="$SINCEMAIL"
	test_since ;
	if [[ "$Tsince" = "yes" ]]; then
		bat_email ;
		if [[ $STATE = "DOWN" ]]; then
			echo "The computer is about to shutdown" | mail -s "emergency shutdown" "$MAILUSER" ;
		fi
		ACTION_ONE="yes"
		test_state_one ;
		SINCEMAIL="$NEWSINCE" ;
	fi
}

noise_action () {
	SINCE="$SINCENOISE"
	test_since ;
	if [[ "$Tsince" = "yes" ]]; then
		mixer_table ;
		NUMBER_BEEP=1 ;
		test_beep_state ;
		MAPERCENT="$VOLSND" ;
		PCMPERCENT="$VOLSND" ;
		LINEPERCENT="$VOLSND" ;		
		noisy_beep ;
		restore_mixer ;
		ACTION_ONE="$BEEP_ONE" ;
		test_state_one ;
		if [[ -n "$NEWSINCE" ]] ;then
			SINCENOISE="$NEWSINCE" ;
		fi
	fi
}

term_action () {
	# Send to test_since () and get response for written warning
	SINCE="$SINCETERM"
	test_since ;
	if [[ "$Tsince" = "yes" ]]; then
		launch_xterm ;
		ACTION_ONE="$TERM_ONE" ;
		test_state_one ;
		if [[ -n "$NEWSINCE" ]];then
			SINCETERM="$NEWSINCE" ;
		fi
	fi
}

aosd_action () {
	SINCE="$SINCEAOSD" ;
	test_since ;
	if [[ "$Tsince" = "yes" ]]; then
		test_arg_aosd_state ;
		Faosd ;
		ACTION_ONE="$AOSD_ONE" ;
		test_state_one ;
		if [[ -n "$NEWSINCE" ]]; then
			SINCEAOSD="$NEWSINCE" ;
		fi
	fi
}

wifi_action () {
	SINCE="$SINCEWIFIDOWN" ;
	test_since ;
	if [[ "$Tsince" = "yes" ]]; then
		wifi_down ;
		ACTION_ONE="$WIFI_ONE" ;
		test_state_one ;
			if [[ -n "$NEWSINCE" ]] ;then
				SINCEWIFIDOWN="$NEWSINCE" ;
			fi
	fi
}

brightness_action () {
	if [[ "$ADJ_BRIGHTNESS" = "yes" || "$ADJ_BRIGHTNESS" = "YES" ]]; then
		SINCE="$SINCEBRIGHT" ;
		test_since ;
		if [[ "$Tsince" = "yes" ]]; then
			test_brightness_state ;
			adjust_brightness ;
			ACTION_ONE="yes" ;
			test_state_one ;
			if [[ -n "$NEWSINCE" ]]; then
				SINCEBRIGHT="$NEWSINCE" ;
			fi
		fi
	fi
}

wallpaper_action () {

	if [[ "$STATIC_WALLPAPER" != "yes" ]]; then
		if [[ $STATE != $PREVIOUS_STATE ]]; then
			set_wallpaper ;
		fi
	fi
}
###############################
### State of battery to call actions to do
###############################

##############
## actions when less than $TINY battery left
##############
usual_actions () {
	# Prepare informations about battery
	battery_info ;
	mail_action ;
	noise_action ;
	term_action ;
	aosd_action ;
	wifi_action ;
	brightness_action ;
	wallpaper_action ;
}

action_DOWN () {

	usual_actions ;

	# ShutDown computer for safety
	if [[ -n "$SHUTDOWN" ]]; then
		WARNING_MSG_SHUTDOWN="\nThe computer is about to shutdown properly in\n\n\
\t\t \$i seconds\n\n\
in order to save your unsaved data (power failure is bad !).\n\
TO CANCEL AUTOMATIC SHUTDOWN AT YOUR OWN RISKS, \n\
JUST CLOSE THIS XTERM WINDOW." ;
		WARNING_MSG="$WARNING_MSG_SHUTDOWN" ;
		WARNING_ACTION="\n\n\tSHUTTING DOWN COMPUTER !!!\n\n" ;
		ACTION=""$BEFORE_SHUT" ; "$SHUTDOWN"" ;
		cancel_action ;
	fi

        # if $SHUTDOWN="" ; bat_alert.sh keeps warning
	sleep "${SLdown}" ;
	PREVIOUS_STATE=$STATE ;
	chk_power_man ;
}

##############
## actions when between $SMALL and $TINY battery left
##############
action_TINY () {

	usual_actions ;

	sleep "${SLtiny}" ;
	PREVIOUS_STATE=$STATE ;
	chk_power_man ;
}

##############
## actions when between $MED and $SMALL battery left
##############
action_SMALL () {

	usual_actions ;

	sleep "${SLsmall}" ;
	PREVIOUS_STATE=$STATE ;
	chk_power_man ;
}

##############
## actions when between $HIGH and $MED battery left
##############
action_MED () {

	usual_actions ;

	sleep "${SLmed}" ;
	PREVIOUS_STATE=$STATE ;
	chk_power_man ;
}

##############
## actions when between $HUGE and $HIGH battery left
##############
action_HIGH () {
	usual_actions ;

	sleep "${SLhigh}" ;
	PREVIOUS_STATE=$STATE ;
	chk_power_man ;
}
##############
## actions when more than $HUGE battery left
##############
action_HUGE () {
	## View comments on action_down ()  , please

	usual_actions ;

	sleep "${SLhuge}" ;
	PREVIOUS_STATE=$STATE ;
	chk_power_man ;
}

###############################
### End of actions
###############################

##############
# function that will tells, depends on how
# battery's percent is left
##############
choose_action () {
	# More than $HUGE battery left
	if [[ "${PERCENT}" -ge "$HUGE" ]]; then
		STATE="HUGE" ;

	# Between $HIGH & $HUGE left
	elif [[ "${PERCENT}" -ge "$HIGH" && "${PERCENT}" -lt "$HUGE" ]]; then
		STATE="HIGH" ;

	# Between $MED & $HIGH left
	elif [[ "${PERCENT}" -ge "$MED" && "${PERCENT}" -lt "$HIGH" ]]; then
		STATE="MED" ;

	# Between $SMALL & $MED left
	elif [[ "${PERCENT}" -ge "$SMALL" && "${PERCENT}" -lt "$MED" ]]; then
		STATE="SMALL" ;

	# Between $TINY & $SMALL left
	elif [[ "${PERCENT}" -ge "$TINY" && "${PERCENT}" -lt "$SMALL" ]]; then
		STATE="TINY" ;

	# Less than $TINY battery left
	else
		STATE="DOWN" ;
	fi
	
	action_"$STATE" ;
}

##############
## If your power manager is acpi :
##############
chk_bat_acpi () {

	## write in a /tmp file informations if the battery is discharging right now
	CH_DCH="${TMPBATDIR}/Battery_info.txt" ;
	if [[ -f $CH_DCH ]]; then
		rm $CH_DCH ;
	fi
	touch $CH_DCH
	$(which acpi) | grep Discharging > $CH_DCH ;
	OFFLINE="$(cat $CH_DCH)" ;

	## "Do not do" nothing if battery on AC ; only sleeps for a while and look again
	## and keep variables up to date by puting them on original state
	if [[ -z "$OFFLINE" ]] ; then
		STATE="CHARGE" ;
		SINCEBRIGHT="$SINCEBRIGHTstart" ;
		SINCEMAIL="$SINCEMAILstart" ;
		if [[ -x $(which $WALLPAPER) ]]; then
			if [[ $STATE != $PREVIOUS_STATE ]]; then
				if [[ -n "$WALLPAPER_ARG_CHARGE" ]] ;then
					$WALLPAPER $WALLPAPER_ARG_CHARGE ;
				else
					$WALLPAPER $WALLPAPER_ARG ;
				fi
			fi
		fi
		if [[ "$BEEP_ONE" = "yes" || "$BEEP_ONE" = "YES" ]] ;then
			SINCENOISE="$SINCENOISEstart" ;
		fi
		if [[ "$AOSD_ONE" = "yes" || "$AOSD_ONE" = "YES" ]]; then
			SINCEAOSD="$SINCEAOSDstart" ;
		fi
		if [[ "$TERM_ONE" = "yes" || "$TERM_ONE" = "YES" ]]; then
			SINCETERM="$SINCETERMstart" ;
		fi
		if [[ "$WIFI_ONE" = "yes" || "$WIFI_ONE" = "YES" ]]; then
			SINCEWIFIDOWN="$SINCEWIFIDOWNstart" ;
		fi
		sleep "${SLcharge}" ;
		PREVIOUS_STATE=$STATE ;
		chk_power_man ;

	## create var in order to have actions later
	else	
		PERCENT_LEFT="$(awk '{print $4}' $CH_DCH | sed s/,//)" ;
		PERCENT="$(echo "${PERCENT_LEFT}" | sed s/%//)" ;
		TIME_LEFT="$(awk '{print $5}' $CH_DCH)" ;
		choose_action ;
	fi
}

##############
## If your power manager is apm :
##############
chk_bat_apm () {
	echo "TODO" ;
	exit 100 ;
}

##############
## Which is your power manager (acpi, apm, ???)
##############
chk_power_man () {
	if [[ -z "${PWMAN}" ]]; then

		if [[ -x $(which acpi) ]]; then
			PWMAN="acpi" ;
			chk_bat_"${PWMAN}" ;

		elif [[ -x $(which apm) ]]; then
			PWMAN="apm" ;
			chk_bat_"${PWMAN}" ;
		else
			echo -ne "Power manager system unknown\nI recognize only acpi and apm\nPlease send me bug report" ;
			exit 1 ;
		fi
	else
		chk_bat_"${PWMAN}" ;
	fi
}

############################################
### End functions
############################################

############################################
### Start program
############################################

## Does USER only want / need some help
if [[ "$HELP" = "yes" ]]; then
	echo -ne "
bat_alert.sh is a bash script which has the purpose to help you not to forget 
that your laptop battery is discharging.
For that, it will do :
	* Send you emails
	* Make sounds with the PC  BEEP
	* Display written warning messages on your screen
	* Change your wallpaper
	* Adjust the screen brightness
	* Ask for turning down WIFI
	* Ask for shutdown computer at last to preserve data from power failure
All of these actions are fully configurable, depending on battery STATE, if you
want that they appens ONCE per STATE or severals.
You define your STATES like you want, and time in state between to battery is
checked.
You define your settings in a config file ; you may have several config files
in order to make bat_alert.sh works differently, depending where you are.
When a new version comes with new parameters in the config file, bat_alert.sh
keeps your old settings, and warn you of the new settings availables.
bat_alert (version ${VERSION}) is a small script which purpose 
is to help you remember that your laptop isn't AC plugged, so you 
won't be surprise by a power failure. It accept for arguments :\n
-c config_file  # if you want to start it with another settings
-d   		# debug / verbose version ; not implemented yet
-h		# help ; what you're reading right now
-t		# terminal (no X11) ; only mail, noise 
		  and brightness may be use in this case
-V|-v		# show version of bat_alert and exit.\n\n"
	exit 0 ;
fi

## USER want to know the version of the program
if [[ "$VERS" = "yes" ]]; then
	echo -ne "bat_alert version "$VERSION" ; released the "$DATEVERSION"\n" ;
	exit 0 ;
fi

if [[ -d "$BATDIR" ]]; then
	mkdir "$TMPBATDIR" ;
	touch "$BAT_INFO" ;

	# If no alternate config file were specified in command line,
	# then use the default config file.
	if [[ -z $CONFIG ]]; then
		CONFIG="${BATDIR}/bat_alertrc" ;
		if [[ ! -f $CONFIG ]]; then
			create_default_config ;
			new_default_config ;
		fi
	fi

	# We are going to check now if the config file version is up to date
	RCVERSCHK=$(grep ^RCVERSION $CONFIG | cut -d '"' -f 2) ;
	if [[ "$RCVERSCHK" != "$VERSION" ]]; then
		. $CONFIG
		create_default_config
		upgrade_rc ;
	fi
	
	## And then launch it
	. $CONFIG

	## We don't need XXXterm to launch if AOSD_CAT is enabled.
	if [[ "$AOSD_CAT" = "yes" || "$AOSD_CAT" = "YES" ]]; then
		XXXterm="no" ;
	fi

	## In a CONSOLE_ONLY mode, without X11, we have to disable some 
	## fonctionnalities, leaving unchanged the others defined by USER
	if [[ $TERMINAL = "yes" ]]; then
		AOSD_CAT="no" ;
		XXXterm="no" ;
		STATIC_WALLPAPER="yes" ;
		SINCEWIFIDOWNstart="NEVER" ;
	fi

	if [[ "$START_BAT_ALERT" = "yes" || "$START_BAT_ALERT" = "YES" ]]; then
		cd $BATDIR ;
		# Test if all variables are well set
		if [[ -z $HUGE || -z $HIGH || -z $MED || -z $SMALL || -z $TINY ]]; then
			echo -ne "Please edit bat_alert.sh, and adjust variables correctly ; VERY SIMPLE !!!\n"
		fi
		check_variables ;
	else
		echo -ne "Please set up properly all variables in ${BATDIR}/bat_alertrc\n" ;
		exit 1 ;
	fi
else
	# No bat_alert directory found ; we are going to create one, and at the same 
	# time, create a default bat_alertrc config file.
	mkdir "$BATDIR" ;
	create_default_config ;
	new_default_config ;
fi
