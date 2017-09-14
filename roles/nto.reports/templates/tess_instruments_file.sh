#!/bin/bash
# {{ ansible_managed }}

DBASE="/var/dbase/tess.db"
INSTRUMENTS_FILE="/var/dbase/tess_instruments_file.txt"

query_names() {
sqlite3 ${DBASE} <<EOF
SELECT name 
FROM tess_t 
WHERE name like 'stars%' 
AND valid_state = 'Current' 
ORDER by name ASC;
EOF
}

service tessdb pause ; sleep 2
query_names > ${INSTRUMENTS_FILE}
service tessdb resume
