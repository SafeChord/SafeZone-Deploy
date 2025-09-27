
#!/bin/bash
set -e

echo "Seeding SafeZone default data..."


END_DATE=szcli system time status | grep current_date | cut -d'=' -f2 | xargs 

START_DATE=$(date -d "$END_DATE - 33 days" +%Y-%m-%d)
# 6. Run the dataflow simulation for the computed interval.
szcli dataflow simulate "$START_DATE" --enddate="$END_DATE"

echo "Seeding default data completed."