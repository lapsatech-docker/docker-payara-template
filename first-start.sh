#!/bin/bash

MARK_FILE=${PAYARA_CONFIG_VOLUME}/.has-been-started-once

test -f ${MARK_FILE} && exit 0 # have run once

echo "[ First boot ]"

touch $MARK_FILE || exit 1

test -d ${PAYARA_RUN_ONCE_PATH} || exit 0

cd ${PAYARA_RUN_ONCE_PATH}

for F in `ls *.sh`
do
	if [ -x $F ]
	then
		echo "Running $F"
		/bin/bash -c ./$F || exit 1
	fi
done
