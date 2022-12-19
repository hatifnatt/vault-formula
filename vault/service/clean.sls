{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}

{#- Stop and disable service #}
vault_service_clean_dead:
  service.dead:
    - name: {{ v.service.name }}

vault_service_clean_disabled:
  service.disabled:
    - name: {{ v.service.name }}

{#- Install systemd service file #}
{%- if grains.init == 'systemd' %}

vault_service_clean_systemd_unit:
  file.absent:
    - name: {{ salt['file.join'](v.service.systemd.unit_dir, v.service.name ~ '.service') }}
    - watch_in:
      - module: vault_service_clean_reload_systemd

  {%- if v.use_upstream in ('binary', 'archive') %}
vault_service_clean_leftover_systemd_unit:
  file.absent:
    - name: {{ salt['file.join']('/usr/lib/systemd/system', v.service.name ~ '.service') }}
    - watch_in:
      - module: vault_service_clean_reload_systemd
  {%- endif %}

  {#- Reload systemd after unit file is removed, like `systemctl daemon-reload` #}
vault_service_clean_reload_systemd:
  module.wait:
  {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
  {%- else %}
    - name: service.systemctl_reload
  {%- endif %}

{%- else %}
vault_service_clean_warning:
  test.configurable_test_state:
    - name: vault_service_clean
    - changes: false
    - result: false
    - comment: |
        Your OS init system is {{ grains.init }}, currently only systemd init system is supported.
        Service for Vault is not altered (not removed).

{%- endif %}
