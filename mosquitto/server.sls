{%- from "mosquitto/map.jinja" import server with context %}
{%- if server.enabled %}

# If source is set in pillar, add it.
mosquitto_repository_managed:
  pkgrepo:
    {%- if server.apt_repo is defined %}
    - managed
    - key_url: {{ server.apt_key_url }}
    - enabled: True
    - name: {{ server.apt_repo }}
    {%- else %}
    - absent
    {%- endif %}
    - humanname: mosquitto repo
    - file: /etc/apt/sources.list.d/mosquitto-buster.list

mosquitto-config-backed-up:
  file.copy:
    - name: /etc/mosquitto/mosquitto.conf.bak
    - source: /etc/mosquitto/mosquitto.conf
    - onlyif: test -f /etc/mosquitto/mosquitto.conf
    - force: true

mosquitto-config-old-config-removed:
  file.absent:
    - name: /etc/mosquitto/mosquitto.conf

mosquitto_config_file:
  file.managed:
  - name: /etc/mosquitto/mosquitto.conf
  {%- if server.version %}
  {%- if server.version.startswith("2.") %}
  - source: salt://mosquitto/files/mosquitto-2_0.conf
  {%- else %}
  - source: salt://mosquitto/files/mosquitto.conf
  {%- endif %}
  {%- else %}
  - source: salt://mosquitto/files/mosquitto.conf
  {%- endif %}
  - template: jinja
  - makedirs: true
  - user: root
  - group: root
  - mode: 644

mosquitto_packages:
  pkg.installed:
  - name: mosquitto
  {%- if server.version %}
  - version: {{ server.version }}
  {%- else %}
  - version: 1.*
  {%- endif %}
  - require:
    - file: mosquitto_config_file

mosquitto-service-timeoutstopsec-configured:
  file.managed:
    - name: /etc/systemd/system/mosquitto.service.d/01-set-timeoutstopsec.conf
    - source: salt://mosquitto/files/01-set-timeoutstopsec.conf
    - makedirs: true
    - require:
      - pkg: mosquitto_packages

{%- if server.config is defined %}
{%- for key in server.config.keys() %}
/etc/mosquitto/conf.d/{{ key }}.conf:
  file.managed:
    - contents_pillar: "mosquitto:server:config:{{ key }}"
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: mosquitto_service
{%- endfor %}
{%- endif %}

mosquitto_service:
  service.running:
  - enable: true
  - name: {{ server.service }}
  - watch:
    - file: /etc/mosquitto/mosquitto.conf

{%- else %}

mosquitto_service:
  service.dead:
  - enable: false
  - name: {{ server.service }}

mosquitto-config-removed:
  file.absent:
    - name: /etc/mosquitto/mosquitto.conf

mosquitto-confd-cleared:
   file.directory:
      - name: /etc/mosquitto/conf.d/         
      - clean: True

{%- endif %}
