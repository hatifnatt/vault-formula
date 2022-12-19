{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}

{%- if v.install %}
  {#- Install systemd service file #}
  {%- if grains.init == 'systemd' %}
include:
  - {{ tplroot }}.service

vault_service_install_systemd_unit:
  file.managed:
    - name: {{ salt['file.join'](v.service.systemd.unit_dir,v.service.name ~ '.service') }}
    - source: salt://{{ tplroot }}/files/vault.service.jinja
    - user: {{ v.root_user }}
    - group: {{ v.root_group }}
    - mode: 644
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
    - require_in:
      - sls: {{ tplroot }}.service
    - watch_in:
      - module: vault_service_install_reload_systemd

    {#- Reload systemd after new unit file added, like `systemctl daemon-reload` #}
vault_service_install_reload_systemd:
  module.wait:
    {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
    {%- if 'module.run' in salt['config.get']('use_superseded', [])
    or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
    {%- else %}
    - name: service.systemctl_reload
    {%- endif %}
    - require_in:
      - sls: {{ tplroot }}.service

  {%- else %}
vault_service_install_warning:
  test.configurable_test_state:
    - name: vault_service_install
    - changes: false
    - result: false
    - comment: |
        Your OS init system is {{ grains.init }}, currently only systemd init system is supported.
        Service for Vault is not installed.

  {%- endif %}

{#- Vault is not selected for installation #}
{%- else %}
vault_service_install_notice:
  test.show_notification:
    - name: vault_service_install
    - text: |
        Vault is not selected for installation, current value
        for 'vault:install': {{ v.install|string|lower }}, if you want to install Vault
        you need to set it to 'true'.

{%- endif %}
