function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
admin_password=$(prop 'project' 'admin_password')
admin_password="elastic:${admin_password}"
echo ${admin_password}
ES_URL="es.elk.es-eks-a.tztest.com"

curl -XPUT -u ${admin_password} ${ES_URL}/_ingest/pipeline/test_new_index \
-H 'Content-Type: application/json' \
-d '{
  "description" : "test_new_index data ingestion",
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

curl -XGET -u ${admin_password} ${ES_URL}'/_ingest/pipeline/new_index?pretty'
