{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs, build_source %}

{%- if v.install %}
  {#- Manage Vault TLS key and certificate #}
include:
  - {{ tplroot }}.service

  {%- if not v.config.data|traverse('listener:tcp:tls_disable', False)
      and v.tls.self_signed
      and 'tls_key_file' in v.config.data|traverse('listener:tcp', {})
      and 'tls_cert_file' in v.config.data|traverse('listener:tcp', {})
  %}
    {#- Create self sifned TLS (SSL) certificate #}
vault_config_tls_prereq_packages:
  pkg.installed:
    - pkgs: {{ v.tls.packages|json }}

vault_config_tls_selfsigned_key:
  x509.private_key_managed:
    - name: {{ v.config.data.listener.tcp.tls_key_file }}
    - user: {{ v.user }}
    - group: {{ v.group }}
    - mode: 640
    - makedirs: true
    - require:
      - pkg: vault_config_tls_prereq_packages

vault_config_tls_selfsigned_cert:
  x509.certificate_managed:
    - name: {{ v.config.data.listener.tcp.tls_cert_file }}
    - signing_private_key: {{ v.config.data.listener.tcp.tls_key_file }}
    {{- format_kwargs(v.tls.cert_params) }}
    - user: {{ v.user }}
    - group: {{ v.group }}
    - mode: 640
    - makedirs: true
    - require:
      - x509: vault_config_tls_selfsigned_key
    - watch_in:
      - service: vault_service_{{ v.service.status }}

  {%- elif not v.config.data|traverse('listener:tcp:tls_disable', False)
      and not v.tls.self_signed
      and 'tls_key_file' in v.config.data|traverse('listener:tcp', {})
      and 'tls_cert_file' in v.config.data|traverse('listener:tcp', {})
  %}

vault_config_tls_provided_key:
  file.managed:
    - name: {{ v.config.data.listener.tcp.tls_key_file }}
    - source:
    {{- build_source(v.tls.key_file_source, path_prefix='files/tls') }}
    - user: {{ v.user }}
    - group: {{ v.group }}
    - mode: 640
    - makedirs: true
    - watch_in:
      - service: vault_service_{{ v.service.status }}

vault_config_tls_provided_cert:
  file.managed:
    - name: {{ v.config.data.listener.tcp.tls_cert_file }}
    - source:
    {{- build_source(v.tls.cert_file_source, path_prefix='files/tls') }}
    - user: {{ v.user }}
    - group: {{ v.group }}
    - mode: 640
    - makedirs: true
    - watch_in:
      - service: vault_service_{{ v.service.status }}

  {#- Not enough data to configure TLS #}
  {%- else %}
vault_config_tls_skipped:
  test.show_notification:
    - name: vault_config_tls_skipped
    - text: |
        Not enough data to configure TLS.
        TLS must be enabled in Vault configuration `listener:tcp:tls_disable: false`
        Current value:
        vault:config:data:listener:tcp:tls_disable: '{{ v.config.data|traverse('listener:tcp:tls_disable', '')|string|lower }}'
        
        You must provide values for `key_file` and `cert_file` in pillars
        Current values:
        vault:config:data:listener:tcp:tls_key_file: '{{ v.config.data|traverse('listener:tcp:tls_key_file', '') }}'
        vault:config:data:listener:tcp:tls_cert_file: '{{ v.config.data|traverse('listener:tcp:tls_cert_file', '') }}'
        
        Also you need to enable self signed certificate generation
        vault:tls:self_signed: '{{ v.tls.self_signed|string|lower }}'
        
        OR provide existing key and certificate files
        vault:tls:key_file_source: '{{ v.tls.get('key_file_source', '') }}'
        vault:tls:cert_file_source: '{{ v.tls.get('cert_file_source', '') }}'
        Note, formula have default values 'tls.key', 'tls.crt' but actual files
        are not provided with formula, you need to put them into folder 'vault/files/tls'
        on Salt file server.

{%- endif %}

{#- Vault is not selected for installation #}
{%- else %}
vault_config_tls_install_notice:
  test.show_notification:
    - name: vault_config_tls_install_notice
    - text: |
        Vault is not selected for installation, current value
        for 'vault:install': {{ v.install|string|lower }}, if you want to install Vault
        you need to set it to 'true'.

{%- endif %}
