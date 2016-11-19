#!/bin/bash
# {{ ansible_managed }}

sqlite3 -csv -header /var/dbase/tess.db <<EOF
.separator ;
SELECT v.name AS Name, v.mac_address AS MAC, (v.latitude || ' ' || v.longitude) AS Coordinates , (v.site || ', ' || v.location || ', ' || v.province) AS Location, v.contact_email as User, v.calibration_k as ZP
FROM tess_v AS v
WHERE v.calibrated_state = "Current"
ORDER BY CAST(substr(v.name, 6) as decimal) ASC;
EOF
