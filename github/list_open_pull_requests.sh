#!/bin/bash

[ $# -eq 1 ] || exit 1

# Generate a token there: https://github.com/settings/tokens
TOKEN="$1"

# Get the list of OpenXT repos
repos=`curl -H "Authorization: token $TOKEN" -s "https://api.github.com/users/openxt/repos?per_page=100" | jq '.[].name' | cut -d '"' -f 2`

total=0
for i in $repos;
do
    # Get the json list of pull requests
    PULLS="`curl -H "Authorization: token $TOKEN" -s https://api.github.com/repos/openxt/$i/pulls`"
    # Get the list of pull request numbers
    PRS="`echo $PULLS | jq '.[].number'`"
    OIFS=$IFS
    IFS=$'\n'
    TITLES=(`echo $PULLS | jq '.[].title'`)
    LOGINS=(`echo $PULLS | jq '.[].user.login' | tr -d '"'`)
    IFS=$OIFS
    if [ "$PRS" != "" ]; then
        echo "Repository: $i  -- Open pull requests:"
        n=0
        for PR in $PRS; do
            echo -n "https://github.com/OpenXT/$i/pull/$PR"
            echo " - ${TITLES[$n]} (${LOGINS[$n]})"
            n=$(( $n + 1 ))
        done
	total=$(( $total + $n ))
	echo
    fi
done

echo "TOTAL: $total open pull requests"
