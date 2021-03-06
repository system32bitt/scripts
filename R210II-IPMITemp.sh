#!/bin/bash

# ----------------------------------------------------------------------------------
# Script for checking the temperature reported by the ambient temperature sensor,
# and if deemed too high send the raw IPMI command to enable dynamic fan control, as
# well as notifying the admin via discord webhook.
# Using crontab is recommended.
#
# Requires:
# ipmitool – apt-get install ipmitool
# lm-sensors - apt-get install lm-sensors
# discord.sh - (on github, must specify file path below)
# ----------------------------------------------------------------------------------

# DISCORD.SH LOCATION
WEBHOOK=/root/crontab_scripts/dependencies/discord.sh

# IDLE SPEED
# Set this to a percentage in hexadecimal of what the idle fan speed should be.
IDLE=1D

# LOAD SPEED
# Set this to a percentage in hexadecimal of what the fan speed should be when under load.
LOAD=3C

# WARNING TEMPERATURE
# Change this to the temperature in celsius you are comfortable with.
WARNTEMP=55

# CRITICAL TEMPERATURE
# Set this for when the temperature is in a critical state and needs dynamic fan control.
CRITTEMP=70

# WEBHOOK URL
# Set this to the webhook url specified on Discord.
URL=

# Do not edit.
TEMP=$(sensors |grep Package |grep -Po '\d{2}' | head -1)

# Enable Manual Fan Control
ipmitool raw 0x30 0x30 0x01 0x00

# Critical Temperature Logic
if [[ $TEMP > $CRITTEMP ]];
  then
    # Notify
    printf "Critical: Temperature has exceeded warning spec. Enabling dynamic control. ($TEMP C)" | systemctl-cat -t R210II-IPMI-TEMP
     echo "Critical: Temperature has exceeded warning spec. Enabling dynamic control. ($TEMP C)"
    source $WEBHOOK --webhook-url=$URL --text "Critical: Temperature has exceeded warning spec. Enabling dynamic control. ($TEMP C)"
    # Set Dynamic Fan Control
    ipmitool raw 0x30 0x30 0x01 0x01
    exit 0
fi

# Warning Temperature Logic
if [[ $TEMP > $WARNTEMP ]];
  then
    # Notify
    printf "Warning: Temperature is too high! Raising Speed.. ($TEMP C)" | systemd-cat -t R210II-IPMI-TEMP
    echo "Warning: Temperature is too high! Raising Speed.. ($TEMP C)"
    source $WEBHOOK --webhook-url=$URL --text "Warning: Temperature is too high! Raising Speed.. ($TEMP C)"
    # Set Load Fan Speed
    ipmitool raw 0x30 0x30 0x02 0xff 0x$LOAD >/dev/null 2>&1
  else
    # Notify
    printf "Temperature OK ($TEMP C)" | systemd-cat -t R210II-IPMI-TEMP
    echo "Temperature OK ($TEMP C)"
    # Only uncomment this if you need consistent reporting (unlikely)
    #source $WEBHOOK --webhook-url=$URL --text "Temperature OK ($TEMP C)"
    # Set Idle Fan Speed
    ipmitool raw 0x30 0x30 0x02 0xff 0x$IDLE >/dev/null 2>&1
fi