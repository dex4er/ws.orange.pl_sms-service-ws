#!/bin/sh

if ! command -v soapcli >/dev/null 2>&1; then
    echo "Install App::soapcli Perl module:"
    echo "$ sudo cpanm App::soapcli"
    exit 1
fi

timestamp=`date +%Y-%m-%dT%H:%M:%S`

soapcli -v '{DeliverShortMessage:{sms:{recipient:123,originator:507998000,content:"TEST",transactionId:"d4b550bf40207900",timestamp:"$timestamp"}}}' \
    mo-sms-service-ws.wsdl ${1:-http://localhost:5000/}
