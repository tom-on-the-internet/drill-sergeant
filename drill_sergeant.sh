#!/usr/bin/env bash

# Set the script name and directory name
# For easy reference below
SCRIPT_FILE=$(readlink -f "$0")
DIRECTORY=$(dirname "$SCRIPT_FILE")
DATA_FILE="$DIRECTORY"/data
ROUTINE_FILE="$DIRECTORY"/routine

yell_for_work() {
  # this is what the drill sergeant will yell
  TITLE='ATTENTION!'
  MESSAGE='\nYou owe me...\n\n'$(cat "$DATA_FILE")

  # make sure the data file exists
  touch "$DATA_FILE"

  mpv "$DIRECTORY"/sound.mp3 &
  notify-send -i "$DIRECTORY"/image.jpg "$TITLE" "$MESSAGE"
}

update_data_file() {
  # make sure the data file exists
  touch "$DATA_FILE"

  # initialize timestamp
  grep -q LAST_UPDATE "$DATA_FILE" || echo LAST_UPDATE="$(date +%s)" >> "$DATA_FILE"

  # figure out if we should do anything



  # make sure each activity exists in the data file
  while read -r line;
  do
    activity=$(echo "$line" | cut -d : -f 1)
    grep -q "$activity" "$DATA_FILE" || echo "$activity"=0 >> "$DATA_FILE"
  done < "$ROUTINE_FILE"


  # increment the number owed
  while read -r line; do
     activity=$(echo "$line" | cut -d : -f 1)
     count_owed=$(echo "$line" | cut -d : -f 2)
     current_count=$(grep "$activity" "$DATA_FILE" | cut -d '=' -f 2-)
     new_total=$((count_owed + current_count))

     # replace count
     sed -i -e "s/$activity=$current_count/$activity=$new_total/g" "$DATA_FILE"
   done < "$ROUTINE_FILE"
}

# Decide what to do
# If the command has the "poke" argument the drill sergeant will yell for work
# Otherwise, he'll expect you to input your work
[ "$1" = 'poke' ] && update_data_file && yell_for_work && exit

