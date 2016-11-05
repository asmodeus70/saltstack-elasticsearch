{% set beats = salt['grains.filter_by']({
    'Windows': {'pkg': 'beats', 'srv': 'beats'},
    'Centos': {'pkg': 'beats', 'srv': 'beats'},
}, default='Windows') %}

beats_install:
  pkg.installed:
    - name: {{ map.install_dir }}/{{ map.app_install }}
  service.running:
    - name: {{ map.filebeat_service }}