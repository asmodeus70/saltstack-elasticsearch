{% from "elasticsearch/map.jinja" import map with context %}

# This section sets up the firewall rules for Elasticsearch
# First we create a new elasticsearch firewall profile.

firewall_config:
  file.managed:
    - name: {{ map.firewall_dir }}/{{ map.firewall_conf }}
    - source: salt://elasticsearch/files/elasticsearch.xml
    - stateful: True

# Now we ensure that the firewall is running and enabled.

firewalld:
  service.running:
    - name: firewalld
    - enable: True

# And now we apply the firewall rules for elasticsearch and http.

firewall_rules:
  firewalld.present:
    - name: internal
    - services:
      - http
      - elasticsearch

# This bit watches for changes to the firewall rules and reloads the firewall
# if it detects changes.

firewalld_watch:
  service.running:
    - name: firewalld
    - reload: True
    - watch:
      - firewalld: internal

# Now we create the repository file for Elasticsearch.

repo_config:
  file.managed:
    - name: {{ map.repo_dir }}/{{ map.repo_file }}
    - source: salt://elasticsearch/files/elasticsearch.repo

# Next we check to see if Elasticsearch is installed and again if it's
# not present then we install it.

elasticsearch:
  pkg.installed:
    - name: {{ map.server }}
    - require:
      - file: {{ map.repo_dir }}/{{ map.repo_file }}

# This step ensures that the Elasticsearch daemon will always start on boot
# and also start the service for us.

elastic_service:
  service.running:
    - name: {{ map.service }}
    - enable: True
    - require:
      - pkg: elasticsearch

# Now we create the Kibana repository file.

kibana_repo:
  file.managed:
    - name: {{ map.repo_dir }}/{{ map.kibana_file }}
    - source: salt://elasticsearch/files/kibana.repo

# Next we install Kibana itself.
kibana:
  pkg.installed:
    - name: {{ map.kibana_app }}
    - require:
      - file: {{ map.repo_dir }}/{{ map.kibana_file }}

# And finally we make sure that the service will start on boot and is currently
# running. If it isn't then it will be started.

kibana_service:
  service.running:
  - name: {{ map.kibana_app }}
  - enable: True
  - require:
    - pkg: kibana
  - watch: 
    - file: {{ map.kibana_dir}}/{{map.kibana_config}}

# This config file is used to secure the Kibana install.

kibana_config:
  file.managed:
    - name: {{ map.kibana_dir}}/{{map.kibana_config}}
    - source: salt://elasticsearch/files/kibana.yml
    - require:
      - pkg: kibana

# Now we install the Nginx reverse proxy and required tools.

nginx:
  pkg.installed:
    - pkgs:
      - {{ map.proxy }}
      - {{ map.tools }}
      - {{ map.utils }}

# This file configures Nginx to display the default Kibana web interface.

nginx_conf:
  file.managed:
    - name: {{ map.nginx_dir }}/{{ map.nginx_kibana_conf }}
    - source: salt://elasticsearch/files/kibana.conf

nginx_main_conf:
  file.managed:
    - name: {{ map.nginx_main_dir }}/{{ map.nginx_main_conf }}
    - source: salt://elasticsearch/files/nginx.conf

# This sets up very basic web security.

nginx_passwd:
  file.managed:
    - name: {{ map.htpasswd_dir }}/{{ map.htpasswd }}
    - source: salt://elasticsearch/files/htpasswd.users
    - mode: 644

# And finally we make sure that the service will start on boot and is currently
# running. If it isn't then it will be started.

nginx_service:
  service.running:
  - name: {{ map.proxy }}
  - enable: True
  - require:
    - pkg: {{ map.proxy }}
  - watch:
    - file: {{ map.nginx_dir }}/{{ map.nginx_kibana_conf}}

# Next we configure the Logstash repo file.

logstash_repo:
  file.managed:
    - name: {{ map.repo_dir }}/{{ map.logstash_repo_file }}
    - source: salt://elasticsearch/files/logstash.repo

# And now we install Logstash.

logstash:
  pkg.installed:
    - name: {{ map.logstash_app }}
    - require:
      - file: {{ map.repo_dir }}/{{ map.logstash_repo_file }}

# Create a self signed cert usinf the server's IP address as the alternate 
# signing name.

cert_gen:
  file.managed:
    - name: {{ map.cert_dir }}/{{ map.cert }}
    - source: salt://elasticsearch/files/openssl.cnf
    - template: jinja
    - context: 
       elk_ip: {{ salt['network.interfaces']()['eno16780032']['inet'][0]['address'] }}

# This first line just checks to see if the cert has already been created and if it
# has then it skips this step.

{% if not salt['file.file_exists']('/etc/pki/tls/certs/logstash-forwarder.crt') %}
cert_create:
  cmd.run:
    - name: openssl req -config /etc/pki/tls/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout /etc/pki/tls/private/logstash-forwarder.key -out /etc/pki/tls/certs/logstash-forwarder.crt
{% endif %}

# These files manage the input and output filters of Logstash.

02beats_input:
  file.managed:
    - name: {{ map.beats_dir }}/{{ map.beats_config }}
    - source: salt://elasticsearch/files/02-beats-input.conf

syslog_filtering:
  file.managed:
    - name: {{ map.beats_dir }}/{{ map.syslog_filter }}
    - source: salt://elasticsearch/files/10-syslog-filter.conf

elastic_output:
  file.managed:
    - name: {{ map.elastic_out_dir }}/{{ map.elastic_out_conf }}
    - source: salt://elasticsearch/files/30-elasticsearch-output.conf

# Check that the Logstash service has been enabled at boot and is currently running.
# It also checks for any changes made to it's config file. If it detects changes it
# restarts the service.

logstash_service:
  service.running:
  - name: {{ map.logstash_app }}
  - enable: True
  - require:
    - pkg: {{ map.logstash_app }}
  - watch:
    - file: {{ map.elastic_out_dir }}/{{ map.elastic_out_conf }}

# This section downloads and installs the filebeat dashboards.

dashboards:
  archive.extracted:
    - name: /opt/beats-dashboards 
    - source: salt://elasticsearch/files/dashboards/beats-dashboards-1.1.0.zip
    - archive_format: zip
    - if_missing: /opt/beats-dashboards/beats-dashboards-1.1.0/

{% if not salt['file.file_exists']('/etc/dashup') %}
install_dashboards:
  cmd.run:
    - name: |
        touch /etc/dashup
        chmod +x /opt/beats-dashboards/beats-dashboards-1.1.0/load.sh
        cd /opt/beats-dashboards/beats-dashboards-1.1.0/; ./load.sh
{% endif %}

{% if not salt['file.file_exists']('/etc/donejson') %}
json_dash:
  cmd.run:
    - name: |
        touch /etc/donejson
        chmod +x /opt/beats-dashboards/beats-dashboards-1.1.0/json_upload.sh
        /opt/beats-dashboards/beats-dashboards-1.1.0/json_upload.sh
{% endif %}

# This is just a memory tweak for Elasticsearch.

memory_tweak:
  file.managed:
    - name: {{ map.limits_dir }}/{{ map.limits_conf }}
    - source: salt://elasticsearch/files/limits.conf


