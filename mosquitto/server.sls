{%- from "mosquitto/map.jinja" import server with context %}
{%- if server.enabled %}

mosquitto_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

/etc/mosquitto/mosquitto.conf:
  file.managed:
  - source: salt://mosquitto/files/mosquitto.conf
  - template: jinja
  - user: root
  - group: root
  - mode: 644
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

{%- endif %}