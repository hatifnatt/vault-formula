{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}
{%- set conf_dir = salt['file.dirname'](v['params']['config']) %}

{%- if v.install %}
  {#- Manage Vault configuration #}
include:
  - {{ tplroot }}.install
  - {{ tplroot }}.service
  - {{ tplroot }}.config.tls

  {#- Create parameters / environment file #}
vault_config_env_file:
  file.managed:
    - name: {{ v.config.env_file }}
    - source: salt://{{ tplroot }}/files/env_params.jinja
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        params: {{ v.params|tojson }}
    - watch_in:
      - service: vault_service_{{ v.service.status }}

  {#- Create data dir #}
vault_config_directory:
  file.directory:
    - name: {{ conf_dir }}
    - user: {{ v.user }}
    - group: {{ v.group }}
    - dir_mode: 755
    - require_in:
      - sls: {{ tplroot }}.config.tls

  {#- Put config file in place #}
vault_config_file:
  file.managed:
    - name: {{ v['params']['config'] }}
    - source: salt://{{ tplroot }}/files/{{ v.config.source }}
    - user: {{ v.user }}
    - group: {{ v.group }}
    - mode: 640
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
    {#- By default don't show changes to don't reveal tokens. #}
    - show_changes: {{ v.config.show_changes }}
    - require:
        - file: vault_config_directory
        - sls: {{ tplroot }}.config.tls
    - watch_in:
      - service: vault_service_{{ v.service.status }}

  {#- Create data dir if Vault configured to store data as files #}
  {%- if v.config.data|traverse('storage:file:path', '') %}
vault_config_data_directory:
  file.directory:
    - name: {{ v.config.data|traverse('storage:file:path') }}
    - user: {{ v.user }}
    - group: {{ v.group }}
    - dir_mode: 750
    - makedirs: true
    - require_in:
      - service: vault_service_{{ v.service.status }}
  {% endif %}

{#- Vault is not selected for installation #}
{%- else %}
vault_config_install_notice:
  test.show_notification:
    - name: vault_config_install_notice
    - text: |
        Vault is not selected for installation, current value
        for 'vault:install': {{ v.install|string|lower }}, if you want to install Vault
        you need to set it to 'true'.

{%- endif %}
