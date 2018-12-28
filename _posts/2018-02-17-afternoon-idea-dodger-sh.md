---
layout: post
title: dodger.sh - Play in your shell!
date: 2018-02-17
permalink: dodger-sh
---

> I created a small game called dodger.sh one evening to learn bash syntax.
>
> You can download and play [here](https://github.com/joshspicer/dodger.sh)

```#!/bin/bash

# dodger.sh
# Written by Josh Spicer (hello@joshspicer.com)

#### VARIABLES/CONSTANTS ####


gameInProgress=true

#Keep track of time
oldTime=$((`date +%s` % 15))
newTime=$((`date +%s` % 15))

lane[0]="___@@@@@@@@@@@@@@@"
lane[1]="@@@___@@@@@@@@@@@@"
lane[2]="@@@@@@___@@@@@@@@@"
lane[3]="@@@@@@@@@___@@@@@@"
lane[4]="@@@@@@@@@@@@___@@@"
lane[5]="@@@@@@@@@@@@@@@___"

laneState="333333" # 6 Lanes on the screen at a time
		   # Each digit represents which type of lane is in that position.
exitedLane=-1      # Start at -1 bc it's invalid


person[0]=".&................"
person[1]="....&............."
person[2]=".......&.........."
person[3]="..........&......."
person[4]=".............&...."
person[5]="................&."

playerState=3    # 0-5 possible player locations

# displays all the lanes
printLanes() {
	clear
	echo ${lane[${laneState:0:1}]}
	echo ${lane[${laneState:1:1}]}
	echo ${lane[${laneState:2:1}]}
	echo ${lane[${laneState:3:1}]}
	echo ${lane[${laneState:4:1}]}
	echo ${lane[${laneState:5:1}]}
}

# displays the player in the correct location


# Moves each lane down by 1
# Uses a random number to determine the newest lane
# Add newest lane to the front of laneState
# Remove the oldest lane from laneState
rotateLanes() {
	exitedLane=${laneState:5:1}
	next="$((RANDOM % 6))"
	concat="$next$laneState"
	laneState="${concat:0:6}"
}

# Print the player in whichever location playerState says she's at.
printPlayer() {
	clear # clear the board
	printLanes # immediately put the board back
	echo "${person[playerState]}" # print the new player
}


movePlayer() {

	if [ $1 -gt 0 ]
	then
		right
        else
		left
	fi
}

right() {
	if ! [ $playerState -ge 5 ]
	then
		$((playerState++))
	else
		playerState=0
	fi

}

left() {
	if ! [ $playerState -le 0 ]
	then
		$((playerState--))
	else
		playerState=5
	fi
}

laneLoop() {
	printLanes
	rotateLanes
}

readInput() {
	read -r -s -n 1 -t 1 key
	case "$key" in
		'q') echo "-1";;
		'w') echo "1";;
		*) echo "0";;
	esac
}

checkGameOver() {
	echo "$playerState"
	echo "$exitedLane"

	if ! [ $exitedLane -eq $playerState ]
	then
		gameInProgress=false
	fi
}


###### MAIN ######
clear
echo "----------------------"
echo "| Welcome to dodger  |"
echo "|                    |"
echo "| Left: Q            |"
echo "| Right: W           |"
echo "----------------------"
sleep 2

while $gameInProgress; do

# User's response
response="$(readInput)"


#If user pressed a key, process it
if  ! [  "$response" -eq 0 ];
        then
            movePlayer $response
        fi

newTime=$((`date +%s` % 15))

if [ "$newTime" != "$oldTime" ]; then
	oldTime=$newTime
	laneLoop
	checkGameOver
fi

printPlayer

done

## Game is over at this point
clear
echo "GAME OVER!"

```
