#!/usr/bin/env bash

# Set the script name and directory name
# For easy reference below
SCRIPT_FILE=$(readlink -f "$0")
DIRECTORY=$(dirname "$SCRIPT_FILE")
DATA_FILE="$DIRECTORY"/data
MESSAGE_FILE="$DIRECTORY"/message
ROUTINE_FILE="$DIRECTORY"/routine

store_message() {
  echo You owe me... '\n' > "$MESSAGE_FILE"

  while read -r line; do
     activity=$(echo "$line" | cut -d = -f 1)
     count_owed=$(echo "$line" | cut -d = -f 2)
     [[ $line != *"LAST_UPDATE"* ]] && echo "$count_owed $activity" >> "$MESSAGE_FILE"
   done < "$DATA_FILE"
}

yell_for_work() {
  # this is what the drill sergeant will yell
  TITLE='ATTENTION!'
  MESSAGE=$(cat "$MESSAGE_FILE")

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
  time_stamp=$(grep LAST_UPDATE $DATA_FILE | cut -d = -f 2)
  current_time=$(date +%s)
  time_stamp_diff="$(( current_time-time_stamp))"
  hours_since_last_update="$(( time_stamp_diff/3600 ))"

  sed -i -e "s/$time_stamp/$current_time/g" "$DATA_FILE"

  # make sure each activity exists in the data file
  while read -r line;
  do
    activity=$(echo "$line" | cut -d : -f 1)
    grep -q "$activity" "$DATA_FILE" || echo "$activity"=0 >> "$DATA_FILE"
  done < "$ROUTINE_FILE"


  # increment the number owed
  while read -r line; do
     activity=$(echo "$line" | cut -d : -f 1)
     number_per_hour=$(echo "$line" | cut -d : -f 2)
     count_owed="$(( number_per_hour*hours_since_last_update ))"
     current_count=$(grep "$activity" "$DATA_FILE" | cut -d '=' -f 2-)
     new_total=$((count_owed + current_count))

     # replace count
     sed -i -e "s/$activity=$current_count/$activity=$new_total/g" "$DATA_FILE"
   done < "$ROUTINE_FILE"

   store_message
}

# Decide what to do
# If the command has the "poke" argument the drill sergeant will yell for work
# Otherwise, he'll expect you to input your work
[ "$1" = 'poke' ] && update_data_file && yell_for_work && exit

