curl -XPOST -u 'elastic:tztest!323' 'https://es.tztest.com/_reindex?pretty' -d'
{
  "source": {
    "index": "nginx"
  },
  "dest": {
    "index": "nginx_bak"
  }
}
'

