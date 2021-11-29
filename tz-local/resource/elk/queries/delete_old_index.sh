#sudo apt install python-pip
#sudo pip install --upgrade pip
#sudo pip install elasticsearch-curator

# delete indexes made before 90 days with prefix nginx- 
#curator_cli --host elk.tztest.com --port 9200 delete_indices --filter_list '[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":90},{"filtertype":"pattern","kind":"prefix","value":"nginx-"}]'

# delete indexes made before 60 days
sudo /usr/local/bin/curator_cli --host localhost --port 9200 delete_indices \
	--filter_list '[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":60},{"filtertype":"pattern","kind":"prefix","value":"nginx-"}]'

sudo /usr/local/bin/curator_cli --host localhost --port 9200 delete_indices \
	--filter_list '[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":60},{"filtertype":"pattern","kind":"prefix","value":"stats-"}]'

sudo /usr/local/bin/curator_cli --host localhost --port 9200 delete_indices \
	--filter_list '[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":60},{"filtertype":"pattern","kind":"prefix","value":"user_action-"}]'

sudo /usr/local/bin/curator_cli --host localhost --port 9200 delete_indices \
	--filter_list '[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":60},{"filtertype":"pattern","kind":"prefix","value":"error_action-"}]'

exit 0

curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/-bnginx-*-b';

curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/nginx-2017*';
curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/stats-2017*';

curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/error_action-2017*';
curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/erroraction-2017*';
curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/user_action-2017*';
curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/useraction-2017*';

curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/.monitoring-es-2-2017*';
curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/.watcher-history-3-2017*';
curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/.monitoring-kibana-2-2017*';
curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tztest.com/.monitoring-logstash-2-2017*';

	