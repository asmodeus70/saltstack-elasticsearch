
{% from "sssd/map.jinja" import map with context %}

sssd_dependencies:
  pkg.installed:
   - pkgs:
     - realmd
     - sssd
     - oddjob
     - oddjob-mkhomedir
     - adcli
     - samba-common
     - krb5-workstation

sssd_config:
  file.managed:
   - name: {{ map.sssd_dir }}/{{ map.sssd_conf }}
   - source: salt://sssd/files/sssd.conf
   - mode: 600

krb5_config:
  file.managed:
   - name: {{ map.krb5_dir }}/{{ map.krb5_conf }}
   - source: salt://sssd/files/krb5.conf


sssd_service:
  service.running:
   - name: {{ map.sssd_service }}
   - enable: True
   - watch:
     - file: sssd_config
