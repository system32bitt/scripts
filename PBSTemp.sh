#!/bin/bash

# ----------------------------------------------------------------------------------
# Script for checking the temperature reported by the ambient temperature sensor,
# and if deemed too high notifies the admin via discord webhook.
# Adapted from R210II-IPMITemp.sh for devices unable to use IPMI for fan control.
# Using crontab is recommended.
#
# Requires:
# lm-sensors - apt-get install lm-sensors
# discord.sh - (on github, must specify file path below)
# ----------------------------------------------------------------------------------

# DISCORD.SH LOCATION
WEBHOOK=/root/crontab_scripts/dependencies/discord.sh

# WARNING TEMPERATURE
# Change this to the temperature in celsius you are comfortable with.
WARNTEMP=55

# CRITICAL TEMPERATURE
# Set this for when the temperature is in a critical state and needs dynamic fan control.
CRITTEMP=70

# WEBHOOK URL
# Set this to the webhook url specified on Discord.
URL=

# This may need to be edited depending on your system, but should work.
TEMP=$(sensors |grep Package |grep -Po '\d{2}' | head -1)

# Critical Temperature Logic
if [[ $TEMP > $CRITTEMP ]];
  then
    # Notify
    printf "Critical: Temperature has exceeded warning spec. Enabling dynamic control. ($TEMP C)" | systemctl-cat -t PBS-TEMP
    echo "Critical: Temperature has exceeded warning spec. Enabling dynamic control. ($TEMP C)"
    source $WEBHOOK --webhook-url=$URL --text "Critical: Temperature has exceeded warning spec. Enabling dynamic control. ($TEMP C)"
    exit 0
fi

# Warning Temperature Logic
if [[ $TEMP > $WARNTEMP ]];
  then
    # Notify
    printf "Warning: Temperature is too high! ($TEMP C)" | systemd-cat -t PBS-TEMP
    echo "Warning: Temperature is too high! ($TEMP C)"
    source $WEBHOOK --webhook-url=$URL --text "Warning: Temperature is too high! Raising Speed.. ($TEMP C)"
    # Set Load Fan Speed
    ipmitool raw 0x30 0x30 0x02 0xff 0x$LOAD >/dev/null 2>&1
  else
    # Notify
    printf "Temperature OK ($TEMP C)" | systemd-cat -t PBS-TEMP
    echo "Temperature OK ($TEMP C)"
    # Only uncomment this if you need consistent reporting (unlikely)
    #source $WEBHOOK --webhook-url=$URL --text "Temperature OK ($TEMP C)"
fi