logstash:
  pkgrepo.managed:
    - humanname: logstash repository for 2.2 packages
    - baseurl: http://packages.elasticsearch.org/logstash/2.2/centos
    - gpgcheck: 1
    - gpgkey: http://packages.elasticsearch.org/GPG-KEY-elasticsearch
    - enabled: 1
