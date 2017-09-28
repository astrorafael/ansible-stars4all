#!/bin/bash
# {{ ansible_managed }}

# Arguments from the command line & default values
dbase="${1:-/var/dbase/tess.db}"
out_dir="${2:-/var/dbase/reports}"

# get the name from the script name without extensions
name=$(basename ${0%.sh})

/usr/sbin/service tessdb pause
sleep 1

sqlite3 -csv -header ${dbase} <<EOF > ${out_dir}/${name}.csv"
.separator ;
SELECT i.name AS Name, i.zero_point as ZP, i.filter as Filter, i.valid_since AS Since, i.valid_until AS Until, i.valid_state AS 'Change State'
FROM tess_t AS i
ORDER BY CAST(substr(i.name, 6) as decimal) ASC, i.valid_since ASC;
EOF

/usr/sbin/service tessdb resume
