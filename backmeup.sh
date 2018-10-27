#!/bin/bash

echo -e "\033[34mBack me up inside\033[0m"

cd $(dirname "$(realpath $0)")

if git diff-index --quiet HEAD --
then
    echo -e "\033[34mNothing to backup\033[0m"
    exit 1
fi

echo -e "\033[32m"
git add --verbose --all
echo -e "\033[0m"
git commit -m"Backup spell book | $(date '+%d/%m/%y %H:%M')"
./updatespellbook.sh

if [[ $? == 1 ]];
then
    echo -e "\033[31mCan't backup\033[0m"
else
    echo -e "\033[32mBack me up and save me"
fi