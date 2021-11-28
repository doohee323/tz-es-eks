# https://www.thirdrocktechkno.com/blog/6-steps-to-reindex-elasticsearch-data/
# https://medium.com/craftsmenltd/rebuild-elasticsearch-index-without-downtime-168363829ea4

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
CURRENT_INDEX="test_current-`date '+%Y%m%d'`"
NEW_INDEX="test_new-`date '+%Y%m%d'`"

# Step 1: Create a current index
curl -XDELETE -u ${admin_password} ${ES_URL}/${CURRENT_INDEX}
curl -XPUT -u ${admin_password} \
${ES_URL}/${CURRENT_INDEX} \
-H 'Content-Type: application/json' \
-d '{
    "mappings": {
        "properties": {
            "username": {
                "type": "text"
            },
            "print_count": {
                "type": "text"
            },
            "print_time": {
                "type": "date"
            }
        }
    }
}'

# Step 2: feeding data to current index
kubectl -n devops-dev exec -it bastion -- filebeat -e -d "*"
kubectl -n devops-dev exec -it bastion -- /bin/bash /data/test.sh current

# Step 3: Create a new index with newly updated mapping
curl -XDELETE -u ${admin_password} ${ES_URL}/${NEW_INDEX}
curl -XPUT -u ${admin_password} \
${ES_URL}/${NEW_INDEX} \
-H 'Content-Type: application/json' \
-d '{
    "mappings": {
        "properties": {
            "username": {
                "type": "text"
            },
            "print_count": {
                "type": "long"
            },
            "print_time": {
                "type": "date"
            }
        }
    }
}'

# Step 4: make read_index alias for current index
curl -XPOST -u ${admin_password} \
${ES_URL}/_aliases \
-H 'Content-Type: application/json' \
-d '{
    "actions": [
        {
            "add": {
                "index": "'${CURRENT_INDEX}'",
                "alias": "read_alias"
            }
        }
    ]
}'

# Now other applications can refer to read_alias for query.

# Step 5: make write_alias alias for new index
curl -XPOST -u ${admin_password} \
${ES_URL}/_aliases \
-H 'Content-Type: application/json' \
-d '{
    "actions": [
        {
            "add": {
                "index": "'${NEW_INDEX}'",
                "alias": "write_alias"
            }
        }
    ]
}'

# Step 6: feeding data to new index
kubectl -n devops-dev exec -it bastion -- filebeat -e -d "*" \
  --path.home /usr/share/filebeat02 \
  --path.config /etc/filebeat02 \
  --path.data /var/lib/filebeat02 \
  --path.logs /var/log/filebeat02

kubectl -n devops-dev exec -it bastion -- /bin/bash /data/test.sh new

# Step 7: reindex from current to new index
#curl -XPUT -u ${admin_password} \
#${ES_URL}/${NEW_INDEX} \
#-H 'Content-Type: application/json' \
#-d '{
#    "settings": {
#      "index.routing.allocation.include._tier_preference": "data_content,data_hot"
#    }
#  }'
#
#curl -XPUT -u ${admin_password} \
#${ES_URL}/${CURRENT_INDEX} \
#-H 'Content-Type: application/json' \
#-d '{
#    "settings": {
#      "index.routing.allocation.include._tier_preference": "data_content,data_cold"
#    }
#  }'

curl -XPOST -u ${admin_password} \
${ES_URL}/_reindex?wait_for_completion=true \
    -H 'Content-Type: application/json' \
    -d '{
    "source": {
        "index": "'${CURRENT_INDEX}'"
    },
    "dest": {
        "index": "'${NEW_INDEX}'"
    }
}'

#Step 8: add read_alias to new alias
curl -X POST -u ${admin_password} \
${ES_URL}/_aliases \
-H 'Content-Type: application/json' \
-d '{
    "actions": [
        {
            "add": {
                "index": "'${NEW_INDEX}'",
                "alias": "read_alias"
            }
        }
    ]
}'

#Step 9: delete old alias and index
curl -X POST -u ${admin_password} \
${ES_URL}/_aliases \
-H 'Content-Type: application/json' \
-d '{
    "actions": [
        {
            "remove": {
                "index": "'${CURRENT_INDEX}'",
                "alias": "write_alias"
            }
        }
    ]
}'

#Step 10: clean duplicated data during switching
curl -XGET -u ${admin_password} \
"${ES_URL}/${NEW_INDEX}/_search?scroll=10m&size=50" \
-H 'Content-Type: application/json' \
-d '{
    "query" : {
        "match_all" : {}
    }
}'

curl -XPOST -u ${admin_password} \
"${ES_URL}/${NEW_INDEX}/_search?pretty" \
#curl -XPOST -u ${admin_password} \
#"${ES_URL}/${NEW_INDEX}/_delete_by_query" \
-H 'Content-Type: application/json' \
-d '{
    "query":
    {
      "bool": {
        "must": [],
        "filter": [
          {
            "match_all": {}
          },
          {
            "range": {
              "print_time": {
                "gte": "2021-11-26T20:44:07.508Z",
                "lte": "2021-11-26T20:45:54.308Z",
                "format": "strict_date_optional_time"
              }
            }
          },
          {
            "match_phrase": {
              "username": "current"
            }
          }
        ],
        "should": [],
        "must_not": []
      }
    }
}
'
