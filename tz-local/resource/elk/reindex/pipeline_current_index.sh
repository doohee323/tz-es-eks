#!/usr/bin/env bash

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}

eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')
NS=elk

admin_password=$(prop 'project' 'admin_password')
admin_password="elastic:${admin_password}"
echo ${admin_password}
ES_URL="es.${NS}.${eks_project}.${eks_domain}"

curl -XPUT -u ${admin_password} ${ES_URL}/_ingest/pipeline/test_current_index \
-H 'Content-Type: application/json' \
-d '{
  "description" : "test_current_index data ingestion",
  "processors": [
    {
      "csv": {
        "field": "message",
        "target_fields": [
            "username","print_count","print_time"
        ]
      }
    },
    {
      "date": {
        "field": "print_time",
        "target_field": "print_time",
        "formats": [ "yyyy-MM-dd HH:mm:ss" ],
        "timezone": "America/Los_Angeles"
      }
    },
    {
      "convert": {
        "field": "print_count",
        "type": "double"
      }
    }
  ]
}
'

curl -XGET -u ${admin_password} ${ES_URL}'/_ingest/pipeline/test_current_index?pretty'
