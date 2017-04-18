#!/usr/bin/env bash

export PATH="${PATH}:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
export LC_ALL=C

set -e
ME="${0}"

run() {
    printf >&2 " > "
    printf >&2 "%q " "${@}"
    printf >&2 "\n"
    "${@}"
    return $?
}

cd /etc/gvpe/status

if [ ! -f ./status ]
	then
	echo >&2 "Is GVPE running?"
	exit 1
fi

EVENTS=0
NODES_ALL=0
NODES_UP=0
NODES_DOWN=0
timestamp="NEVER"
. ./status

if [ "${timestamp}" = "NEVER" ]
	then
	echo >&2 "GVPE is not connected"
	exit 1
fi

cat <<EOF

GVPE Status on ${MYNODENAME} (Node No ${MYNODEID})

Total Events: ${EVENTS}
Last Event: $(date -r ./status "+%Y-%m-%d %H:%M:%S")

Up ${NODES_UP}, Down ${NODES_DOWN}, Total ${NODES_ALL} nodes

EOF

while read x
do
	[ "${x}" = "${MYNODENAME}" ] && continue

	. ./${x}
	[ "${status}" != "up" ] && continue
	[ "${pip}" = "dynamic" ] && continue

	echo >&2 "pinging ${name} (${ip})"
	echo "$(run ping -c 3 -n -q "${ip}" | tail -n 1 | cut -d '=' -f 2 | cut -d '/' -f 2)|${name}"
done <nodes | sort -n | (
	echo "# automatically generated by ${ME}"
	i=$(( (NODES_ALL * 10) + 100))
	while IFS="|" read t n
	do
		echo
		echo "# ${n} average time ${t}"
		echo "node = ${n}"
		echo "router-priority = $((i -= 10))"
	done
) >../routing.conf.new

run cp ../routing.conf ../routing.conf.old
run mv ../routing.conf.new ../routing.conf