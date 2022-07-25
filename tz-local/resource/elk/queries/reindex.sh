curl -XPOST -u 'elastic:tztest!323' 'elk.tztest.com:9200/_reindex?pretty' -d'
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


