#!/bin/bash
# {{ ansible_managed }}

sqlite3 -csv -header /var/dbase/tess.db <<EOF
.separator ;
SELECT i.name AS Name, i.calibration_k as ZP, i.calibrated_since AS Since, i.calibrated_until AS Until, i.calibrated_state AS 'Change State'
FROM tess_t AS i
ORDER BY CAST(substr(i.name, 6) as decimal) ASC, i.calibrated_since ASC;
EOF
