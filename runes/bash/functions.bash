#!/bin/bash

#shellcheck source=/home/mendess/.local/bin/library
. library

aura() {
    case "$1" in
        -R*)
            sudo pacman -Rsn "$2"
            # pacman "$1" "$2"
            ;;
        -Ss)
            curl -s "https://aur.archlinux.org/rpc/?v=5&type=search&by=name&arg=$1" \
                | jq '.results[] | "\(.Name) -> \(.Description)"'
            ;;
        -S)
            aura "${@:2}"
            ;;
        *)
            old="$(pwd)"
            cd /tmp || exit 1
            git clone https://aur.archlinux.org/"$1"
            cd "$1" || exit 1
            makepkg -si --clean "${@:2}"
            cd "$old" || exit 1
            ;;
    esac
}

make() {
    if [ -e Makefile ] || [ -e makefile ]
    then
        bash -c "make $*"
    else
        for i in *.c;
        do
            file=${i//\.c/}
            bash -c "make $file"
        done
    fi
}

ex() {
  if [ -f "$1" ] ; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"   ;;
      *.tar.gz)    tar xzf "$1"   ;;
      *.bz2)       bunzip2 -v "$1"   ;;
      *.rar)       unrar x "$1"   ;;
      *.gz)        gunzip "$1"    ;;
      *.tar)       tar xf "$1"    ;;
      *.tbz2)      tar xjf "$1"   ;;
      *.tgz)       tar xzf "$1"   ;;
      *.zip)       unzip "$1"     ;;
      *.Z)         uncompress "$1";;
      *.7z)        7z x "$1"      ;;
      *.xz)        xz -d "$1"     ;;
      *)           echo "$1 cannot be extracted via ex()" ;;
    esac
  else
    echo "$1 is not a valid file"
  fi
}

__append_to_recents() { # $1 line, $2 recents file
    mkdir -p ~/.cache/my_recents
    touch ~/.cache/my_recents/"$2"
    echo "$1" | cat - ~/.cache/my_recents/"$2" | awk '!seen[$0]++' | head -10 > temp && mv temp ~/.cache/my_recents/"$2"
}

__run_disown() {
    local file="$2"
    if [ "$file" = "" ] && [ -f ~/.cache/my_recents/"$1" ]; then
        file=$(sed -e 's/\/home\/mendess/~/' ~/.cache/my_recents/"$1" | dmenu -i -l "$(wc -l ~/.cache/my_recents/"$1")")
        [ "$file" = "" ] && return 1
        file=$HOME${file//\~//}
    fi
    file="$(realpath "$file")"
    "$1" "$file" &> /dev/null &
    disown
    [ -e "$file" ] && __append_to_recents "$file" "$1"
}

pdf() {
    __run_disown zathura "$1" && exit
}

za() {
    __run_disown zathura "$1"
}

alarm() {
    if [ $# -lt 1 ]; then
        echo provide a time string
        return 1
    fi
    {
        link="https://www.youtube.com/watch?v=4iC-7aJ6LDY"
        sleep "$1"
        mpv --no-video "$link" --input-ipc-server=/tmp/mpvalarm &
        notify-send -u critical "Alarm" "$2" -a "$(basename "$0")"
    } &
    disown
}

matrix() {
    echo -e "\e[1;40m"
    clear
    while :
    do
        echo $LINES $COLUMNS $(( RANDOM % COLUMNS)) $(( RANDOM % 72 ))
        sleep 0.05
    done \
        | awk '{ letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()"; c=$4; letter=substr(letters,c,1);a[$3]=0;for (x in a) {o=a[x];a[x]=a[x]+1; printf "\033[%s;%sH\033[2;32m%s",o,x,letter; printf "\033[%s;%sH\033[1;37m%s\033[0;0H",a[x],x,letter;if (a[x] >= $1) { a[x]=0; } }}'
}

loop() {
    n=""
    while ! [ "$n" = "n" ]
    do
        "$@"
        read -r n
    done
}

clearswap() {
    local drive
    drive="$(lsblk -i | grep SWAP | awk '{print $1}' | sed -r 's#[|`]-#/dev/#')"
    sudo swapoff "$drive"
    sudo swapon "$drive"
}

surfc() {
    surf "$1" &
    disown
    exit
}

poolIP() {
    docker inspect pgpool | jq '.[0].NetworkSettings.Networks.bridge.IPAddress' -r -e
}

discordStream() {
    echo https://www.discordapp.com/channels/"$1"/"$2" | xclip -sel clip
}


svim() {
    if [ -n "$1" ]; then
	    "$EDITOR" "$SPELLS"/"$1"
    else
        cd "$SPELLS" || exit 1
        local DIR
        DIR="$(find . -type f | grep -v '.git' | sed 's|^./||g' | fzf)"
        [ -n "$DIR" ] && "$EDITOR" "$DIR"
        cd - &>/dev/null || exit 1
    fi
}

k() {
	if lsusb | grep 'Mechanical' | grep 'Keyboard' &>/dev/null
    then
        setxkbmap us
        xmodmap -e 'keycode  21 = plus equal plus equal'
    else
        setxkbmap pt
    fi
}

advent-of-code() {
    if [[ "$1" != day* ]]; then echo "bad input: '$1'"; exit 1; fi
    cargo new "$1" || exit 1
    cd "$1" || exit 1
    echo '
[[bin]]
name = "one"
path = "src/one.rs"

[[bin]]
name = "two"
path = "src/two.rs"' >> Cargo.toml
    cp src/main.rs src/one.rs
    cp src/main.rs src/two.rs
    rm src/main.rs
}

degen() {
    python3 -c '
from random import choice
from sys import argv
print("".join((map(lambda x: x.upper() if choice([True, False]) else x.lower(), " ".join(argv[1:])))))
' "$@"
}

record() {
    if [ "$1" = right ]; then
        i=1920
    else
        i=0
    fi
    ffmpeg \
        -video_size 1920x1080 \
        -framerate 60 \
        -f x11grab \
        -i :0.0+$i,0 \
        "output-$(date +"%d_%m_%Y_%H_%M").mp4"
}

share() {
    FILE="$*"
    if [ -d "$FILE" ]
    then
        zip -r "/tmp/$(basename "$FILE").zip" "$FILE"
        FILE="/tmp/$(basename "$FILE").zip"
    fi
    scp "$FILE" mirrodin:~/disk0/Mirrodin/serve
    url="http://mendess.xyz/file/$(basename "$FILE")"
    echo "$url" | xclip -sel clip
    echo "$url"
}

connect() {
    if [ $# -lt 2 ]; then
        echo "Usage: $0 ssid password"
        return
    fi
    nmcli device wifi connect "$1" password "$2"
}
