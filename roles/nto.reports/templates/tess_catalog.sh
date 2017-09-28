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
SELECT v.name AS Name, v.mac_address AS MAC, (v.latitude || ' ' || v.longitude) AS Coordinates , (v.site || ', ' || v.location || ', ' || v.province) AS Location, v.contact_email as User, v.zero_point as ZP, v.filter as Filter
FROM tess_v AS v
WHERE v.valid_state = "Current"
ORDER BY CAST(substr(v.name, 6) as decimal) ASC;
EOF

/usr/sbin/service tessdb resume
