#!/bin/bash

# A UI for detecting and selecting all displays.
# Probes xrandr for connected displays and lets user select one to use.
# User may also select "manual selection" which opens arandr.
# I plan on adding a routine from multi-monitor setups later.

function twoscreen { # If multi-monitor is selected and there are two screens.

    mirror=$(printf "no\\nyes" | dmenu -i -p "Mirror displays?")
    # Mirror displays using native resolution of external display and a scaled
    # version for the internal display
    if [ "$mirror" = "yes" ]; then
        external=$(echo "$screens" | dmenu -i -p "Optimize resolution for:")
        internal=$(echo "$screens" | grep -v "$external")

        res_external=$(xrandr --query | sed -n "/^$external/,/\+/p" | tail -n 1 | awk '{print $1}')
        res_internal=$(xrandr --query | sed -n "/^$internal/,/\+/p" | tail -n 1 | awk '{print $1}')

        res_ext_x=$(echo $res_external | sed 's/x.*//')
        res_ext_y=$(echo $res_external | sed 's/.*x//')
        res_int_x=$(echo $res_internal | sed 's/x.*//')
        res_int_y=$(echo $res_internal | sed 's/.*x//')

        scale_x=$(echo "$res_ext_x / $res_int_x" | bc -l)
        scale_y=$(echo "$res_ext_y / $res_int_y" | bc -l)

        xrandr --output "$external" --auto --scale 1.0x1.0 --output "$internal" --auto --same-as "$external" --scale "$scale_x"x"$scale_y"
    else

        primary=$(echo "$screens" | dmenu -i -p "Select primary display:")
        secondary=$(echo "$screens" | grep -v "$primary")
        direction=$(printf "left\\nright" | dmenu -i -p "What side of $primary should $secondary be on?")
        xrandr --output "$primary" --auto --scale 1.0x1.0 --output "$secondary" --"$direction"-of "$primary" --auto --scale 1.0x1.0
    fi
}

function morescreen { # If multi-monitor is selected and there are more than two screens.
    primary=$(echo "$screens" | dmenu -i -p "Select primary display:")
    secondary=$(echo "$screens" | grep -v "$primary" | dmenu -i -p "Select secondary display:")
    direction=$(printf "left\\nright" | dmenu -i -p "What side of $primary should $secondary be on?")
    tertiary=$(echo "$screens" | grep -v "$primary" | grep -v "$secondary" | dmenu -i -p "Select third display:")
    xrandr --output "$primary" --auto --output "$secondary" --"$direction"-of "$primary" --auto --output "$tertiary" --"$(printf "left\\nright" | grep -v "$direction")"-of "$primary" --auto
}

function multimon { # Multi-monitor handler.
    case "$(echo "$screens" | wc -l)" in
        1) xrandr $(echo "$allposs" | awk '{print "--output", $1, "--off"}' | tr '\n' ' ') ;;
        2) twoscreen ;;
        *) morescreen ;;
    esac ;}

# Get all possible displays
allposs=$(xrandr -q | grep "connected")

# Get all connected screens.
screens=$(echo "$allposs" | grep " connected" | awk '{print $1}')

# Get user choice including multi-monitor and manual selection:
chosen=$(printf "%s\\nmulti-monitor\\nmanual selection" "$screens" | dmenu -i -p "Select display arangement:") &&
    case "$chosen" in
        "manual selection") arandr ; exit ;;
        "multi-monitor") multimon ;;
        *) xrandr --output "$chosen" --auto --scale 1.0x1.0 $(echo "$screens" | grep -v "$chosen" | awk '{print "--output", $1, "--off"}' | tr '\n' ' ') ;;
    esac

# Fix background if screen size/arangement has changed.
bash "$(dirname "$(realpath "$0")")"/../spells/changeMeWall.spell
# Re-remap keys if keyboard added (for laptop bases)
#remaps
# Restart dunst to ensure proper location on screen
pgrep -x dunst >/dev/null && killall dunst && setsid dunst &
