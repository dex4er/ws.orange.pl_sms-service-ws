#!/bin/sh

if [ $# -lt 2 ]; then
    echo "$0 url text"
    exit 1
fi

if ! command -v xml2wbxml >/dev/null; then
    xml2wbxml
    exit 1
fi

url=$1
description=$2

date_created=$(date --utc "+%Y-%m-%dT%H:%M:%SZ")
date_expires=$(date --utc --date "3 days" "+%Y-%m-%dT%H:%M:%SZ")

xml=$(cat << END
<!DOCTYPE si PUBLIC "-//WAPFORUM//DTD SI 1.0//EN" "http://www.wapforum.org/DTD/si.dtd">
<si>
 <indication href="$url" created="$date_created" si-expires="$date_expires">$description</indication>
</si>
END
)

ira_wbxml=$(echo "$xml" | xml2wbxml - -o - 2>/dev/null | perl -e 'local $/; $_=<STDIN>; print uc unpack "H*", $_')

head_pdu="000601AE"

pdu="$head_pdu$ira_wbxml"
udh="0605040B8423F0"

pdul=$(( $(echo -n "$pdu" | wc -c) / 2 ))
udhl=$(( $(echo -n "$udh" | wc -c) / 2 ))
udl=$(( 1 + $udhl + $pdul ))

printf "%02X%02X%s%s\n" $udl $udhl $udh $pdu
