#!/bin/bash
# {{ ansible_managed }}

sqlite3 -csv -header /var/dbase/tess.db <<EOF
SELECT r.tess_id, i.name, i.calibration_k, count(*) AS readings
FROM tess_readings_t AS r
JOIN tess_t AS i USING (tess_id)
GROUP BY r.tess_id;
EOF
