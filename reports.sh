#!/bin/sh

hammer report list --search 'eventful=true and applied > 0'| less
hammer --csv report list --search 'eventful=true and applied > 0'| less
curl -k https://localhost:443/api/reports?search="eventful=true and applied>0" -u admin:redhat123 | python -mjson.tool|less
