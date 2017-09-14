#!/bin/bash
# {{ ansible_managed }}

instruments_file=$1

if  [[ ! -f $instruments_file || ! -r $instruments_file ]]; then
	echo "Instrument file $instruments_file does not exists or is not readable."
	echo "Exiting"
	exit 1
fi


bulk_dump_by_instrument() {
instrument_name=$1
sqlite3 -csv -header /var/dbase/tess.db <<EOF
.separator ;
SELECT (d.julian_day + t.day_fraction) AS julian_day, (d.sql_date || 'T' || t.time || 'Z') AS timestamp, r.sequence_number, l.site, i.name, r.frequency, r.magnitude, i.zero_point, r.sky_temperature, r.ambient_temperature
FROM tess_readings_t AS r
JOIN tess_t          AS i USING (tess_id)
JOIN location_t      AS l USING (location_id)
JOIN date_t          AS d USING (date_id)
JOIN time_t          AS t USING (time_id)
WHERE i.name = "${instrument_name}"
ORDER BY r.date_id ASC, r.time_id ASC;
EOF
}


# Stops background database I/O
service tessdb pause ; sleep 2

# Loops over the instruments file and dumping data
for instrument in $( cat $instruments_file ); do
	echo "Generating compresed CSV for TESS $instrument"
	bulk_dump_by_instrument ${instrument} | gzip > /var/dbase/reports/${instrument}.csv.gz
done

# Resume background database I/O
service tessdb resume


