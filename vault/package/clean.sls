{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}

include:
  - {{ tplroot }}.shell_completion.bash.clean
  - {{ tplroot }}.service.clean

vault_package_clean:
  pkg.removed:
    - pkgs:
    {%- for pkg in v.package.pkgs %}
      - {{ pkg }}
    {%- endfor %}

{#- Remove user and group #}
vault_package_clean_user:
  user.absent:
    - name: {{ v.user }}

vault_package_clean_group:
  group.absent:
    - name: {{ v.group }}
