curl -XPOST -u 'elastic:tzcorp!323' 'https://es.ejntest.com/_reindex?pretty' -d'
{
  "source": {
    "index": "nginx"
  },
  "dest": {
    "index": "nginx_bak"
  }
}
'

