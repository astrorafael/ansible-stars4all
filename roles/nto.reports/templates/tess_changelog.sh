#!/bin/bash
# {{ ansible_managed }}

service tessdb pause ; sleep 1
sqlite3 -csv -header /var/dbase/tess.db <<EOF
.separator ;
SELECT i.name AS Name, i.zero_point as ZP, i.filter as Filter, i.valid_since AS Since, i.valid_until AS Until, i.valid_state AS 'Change State'
FROM tess_t AS i
ORDER BY CAST(substr(i.name, 6) as decimal) ASC, i.valid_since ASC;
EOF
service tessdb resume
