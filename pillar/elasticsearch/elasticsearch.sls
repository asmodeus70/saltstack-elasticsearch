elastic.repo:
    pkgrepo.managed:
      - name: Elasticsearch 2.x
      - humanname: Elasticsearch repository for 2.x packages
      - baseurl: https://packages.elastic.co/elasticsearch/2.x/centos
      - gpgcheck: 1
      - gpgkey: https://packages.elastic.co/GPG-KEY-elasticsearch
      - enabled: 1

