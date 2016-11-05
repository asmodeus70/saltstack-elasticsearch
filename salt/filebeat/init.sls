filebeat_install:
  archive.extracted:
    - name: C:\Program Files\Filebeat 
    - source: salt://filebeat/files/beat.zip
    - archive_format: zip
    - if_missing: C:\Program Files\Filebeat\