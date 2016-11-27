#!/bin/bash
# {{ ansible_managed }}
service tessdb pause ; sleep 1
sqlite3 -csv -header /var/dbase/tess.db <<EOF
.separator ;
SELECT v.name AS Name, v.mac_address AS MAC, (v.latitude || ' ' || v.longitude) AS Coordinates , (v.site || ', ' || v.location || ', ' || v.province) AS Location, v.contact_email as User, v.zero_point as ZP, v.filter as Filter
FROM tess_v AS v
WHERE v.valid_state = "Current"
ORDER BY CAST(substr(v.name, 6) as decimal) ASC;
EOF
service tessdb resume
