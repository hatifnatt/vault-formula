{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}

{%- if v.install %}
  {#- Manage on boot service state in dedicated state to ensure watch trigger properly in service.running state #}
vault_service_{{ v.service.on_boot_state }}:
  service.{{ v.service.on_boot_state }}:
    - name: {{ v.service.name }}

vault_service_{{ v.service.status }}:
  service:
    - name: {{ v.service.name }}
    - {{ v.service.status }}
  {%- if v.service.status == 'running' %}
    - reload: {{ v.service.reload }}
  {%- endif %}
    - require:
        - service: vault_service_{{ v.service.on_boot_state }}
    - order: last

{#- Vault is not selected for installation #}
{%- else %}
vault_service_notice:
  test.show_notification:
    - name: vault_service_notice
    - text: |
        Vault is not selected for installation, current value
        for 'vault:install': {{ v.install|string|lower }}, if you want to install Vault
        you need to set it to 'true'.

{%- endif %}
