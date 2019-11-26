#!/bin/bash

# Function "center_text": center the text with a surrounding border

# first argument: text to center
# second argument: glyph which forms the border
# third argument: width of the padding

center_text()
{

    local terminal_width=80     # query the Terminfo database: number of columns
    local text="${1:?}"                   # text to center
    local glyph="${2:-=}"                 # glyph to compose the border
    local padding="${3:-2}"               # spacing around the text

    local text_width=${#text}

    local border_width=$(( (terminal_width - (padding * 2) - text_width) / 2 ))

    local border=                         # shape of the border

    # create the border (left side or right side)
    for ((i=0; i<border_width; i++))
    do
        border+="${glyph}"
    done

    # a side of the border may be longer (e.g. the right border)
    if (( ( terminal_width - ( padding * 2 ) - text_width ) % 2 == 0 ))
    then
        # the left and right borders have the same width
        local left_border=$border
        local right_border=$left_border
    else
        # the right border has one more character than the left border
        # the text is aligned leftmost
        local left_border=$border
        local right_border="${border}${glyph}"
    fi

    # space between the text and borders
    local spacing=

    for ((i=0; i<$padding; i++))
    do
        spacing+=" "
    done

    # displays the text in the center of the screen, surrounded by borders.
    printf "${left_border}${spacing}${text}${spacing}${right_border}\n"
}

lines=30
# padding=$lines-6-2
padding=0

for ((i=0; i< padding/2; i++))
  do
    echo ''
  done
figlet -w 80 -c 'FPGA WT-220'
center_text "JBR Engineering Research Ltd - 2019" "*" 2
center_text "Press CR or connect serial device to continue" "=" 2
for ((i=0; i< padding/2; i++))
  do
    echo ''
  done
