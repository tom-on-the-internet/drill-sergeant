#!/usr/bin/env bash

# Set the script name and directory name
# For easy reference below
SCRIPT_FILE=$(readlink -f "$0")
DIRECTORY=$(dirname "$SCRIPT_FILE")
DATA_FILE="$DIRECTORY"/data
IMAGE_FILE="$DIRECTORY"/image.jpg
MESSAGE_FILE="$DIRECTORY"/message
ROUTINE_FILE="$DIRECTORY"/routine

store_message() {
  echo You owe me... '\n' > "$MESSAGE_FILE"

  while read -r line; do
     activity=$(echo "$line" | cut -d = -f 1)
     count_owed=$(echo "$line" | cut -d = -f 2)
     [[ $line != *"LAST_UPDATE"* ]] && echo "$count_owed $activity"
   done < "$DATA_FILE" >> "$MESSAGE_FILE"
}

yell_for_work() {
  # this is what the drill sergeant will yell
  TITLE='ATTENTION!'
  MESSAGE=$(cat "$MESSAGE_FILE")

  # make sure the data file exists
  touch "$DATA_FILE"

  mpv "$DIRECTORY"/sound.mp3 &
  notify-send -i "$IMAGE_FILE" "$TITLE" "$MESSAGE"
}

update_data_file() {
  # make sure the data file exists
  touch "$DATA_FILE"

  # initialize timestamp
  grep -q LAST_UPDATE "$DATA_FILE" || echo LAST_UPDATE="$(date +%s)" >> "$DATA_FILE"

  # figure out if we should do anything
  time_stamp=$(grep LAST_UPDATE "$DATA_FILE" | cut -d = -f 2)
  current_time=$(date +%s)
  time_stamp_diff="$(( current_time-time_stamp))"
  hours_since_last_update="$(( time_stamp_diff/3600 ))"

  [[ $hours_since_last_update != "0" ]] && sed -i -e "s/$time_stamp/$current_time/g" "$DATA_FILE"

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

show_first_input_prompt() {
  printf "\n\n"
  pixcat thumbnail --size 256 --align left "$IMAGE_FILE"
  printf "\nWhat do have to report, maggot?\n\n"

  # increment the number owed
  i=0
  while ((i++)); read -r line; do
    activity=$(echo "$line" | cut -d : -f 1)
    echo [$i] "$activity"
  done < "$ROUTINE_FILE"

  echo
}

show_second_input_prompt() {
  # increment the number owed
  i=0
  while ((i++)); read -r line; do
    [[ $i != "$first_input" ]] && continue
    activity=$(echo "$line" | cut -d : -f 1)
    echo "How many $activity did you do?"
  done < "$ROUTINE_FILE"

  echo
}

update_amount() {
  i=0
  while ((i++)); read -r line; do
    [[ $i != "$first_input" ]] && continue
    activity=$(echo "$line" | cut -d : -f 1)
    current_count=$(grep "$activity" "$DATA_FILE" | cut -d '=' -f 2-)
    new_total="$(( current_count - second_input ))"
    new_total="$(( "$new_total" < 0 ? 0 : "$new_total" ))"
    sed -i -e "s/$activity=$current_count/$activity=$new_total/g" "$DATA_FILE"
    printf "\nOK. You have $new_total $activity left.\n"
  done < "$ROUTINE_FILE"
}

# If the command has the "poke" argument the drill sergeant will yell for work
[ "$1" = 'poke' ] && update_data_file && yell_for_work && exit

# Otherwise take input
show_first_input_prompt
read -r -s -n1 first_input

show_second_input_prompt
read -r second_input

update_amount
