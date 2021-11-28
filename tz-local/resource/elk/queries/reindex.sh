curl -XPOST -u 'elastic:tzcorp!323' 'elk.ejntest.com:9200/_reindex?pretty' -d'
{
  "source": {
    "index": "nginx-2018.04.02"
  },
  "dest": {
    "index": "nginx-2018.04.02-b"
  }
}
,
  "version": 100
}'

exit 0


