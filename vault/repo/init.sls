{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if v.install %}
  {#- If vault:use_upstream is 'repo' or 'package' official repo will be configured #}
  {%- if v.use_upstream in ('repo', 'package') %}

    {#- Install required packages if defined #}
    {%- if v.repo.prerequisites %}
vault_repo_prerequisites:
  pkg.installed:
    - pkgs: {{ v.repo.prerequisites|tojson }}
    {%- endif %}

    {#- If only one repo configuration is present - convert it to list #}
    {%- if v.repo.config is mapping %}
      {%- set configs = [v.repo.config] %}
    {%- else %}
      {%- set configs = v.repo.config %}
    {%- endif %}
    {%- for config in configs %}
vault_repo_{{ loop.index0 }}:
  pkgrepo.managed:
    {{- format_kwargs(config) }}
    {%- endfor %}

  {#- Another installation method is selected #}
  {%- else %}
vault_repo_install_method:
  test.show_notification:
    - name: vault_repo_install_method
    - text: |
        Another installation method is selected. Repo configuration is not required.
        If you want to configure repository set 'vault:use_upstream' to 'repo' or 'package'.
        Current value of vault:use_upstream: '{{ v.use_upstream }}'
  {%- endif %}

{#- Vault is not selected for installation #}
{%- else %}
vault_repo_install_notice:
  test.show_notification:
    - name: vault_repo_install
    - text: |
        Vault is not selected for installation, current value
        for 'vault:install': {{ v.install|string|lower }}, if you want to install Vault
        you need to set it to 'true'.

{%- endif %}
