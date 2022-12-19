{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}
{%- set conf_dir = salt['file.dirname'](v['params']['config']) -%}

{%- if v.install %}
  {#- Install Vault from packages #}
  {%- if v.use_upstream in ('repo', 'package') %}
include:
  - {{ tplroot }}.repo
  - {{ tplroot }}.shell_completion.bash.install
  - {{ tplroot }}.service.install

    {#- Install packages required for further execution of 'package' installation method #}
    {%- if 'prereq_pkgs' in v.package and v.package.prereq_pkgs %}
vault_package_install_prerequisites:
  pkg.installed:
    - pkgs: {{ v.package.prereq_pkgs|tojson }}
    - require:
      - sls: {{ tplroot }}.repo
    - require_in:
      - pkg: vault_package_install
    {%- endif %}

    {%- if 'pkgs_extra' in v.package and v.package.pkgs_extra %}
vault_package_install_extra:
  pkg.installed:
    - pkgs: {{ v.package.pkgs_extra|tojson }}
    - require:
      - sls: {{ tplroot }}.repo
    - require_in:
      - pkg: vault_package_install
    {%- endif %}

vault_package_install:
  pkg.installed:
    - pkgs:
    {%- for pkg in v.package.pkgs %}
      - {{ pkg }}{% if v.version is defined and 'vault' in pkg %}: '{{ v.version }}'{% endif %}
    {%- endfor %}
    - hold: {{ v.package.hold }}
    - update_holds: {{ v.package.update_holds }}
    {%- if salt['grains.get']('os_family') == 'Debian' %}
    - install_recommends: {{ v.package.install_recommends }}
    {%- endif %}
    - watch_in:
      - service: vault_service_{{ v.service.status }}
    - require:
      - sls: {{ tplroot }}.repo
    - require_in:
      - sls: {{ tplroot }}.service.install

    {#- Create group and user #}
vault_package_install_group:
  group.present:
    - name: {{ v.group }}
    - system: true
    - require:
      - pkg: vault_package_install

vault_package_install_user:
  user.present:
    - name: {{ v.user }}
    - gid: {{ v.group }}
    - system: true
    - password: '*'
    - home: {{ conf_dir }}
    - createhome: false
    - shell: /usr/sbin/nologin
    - fullname: Vault daemon
    - require:
      - group: vault_package_install_group
    - require_in:
      - sls: {{ slsdotpath }}.service.install

  {#- Another installation method is selected #}
  {%- else %}
vault_package_install_method:
  test.show_notification:
    - name: vault_package_install_method
    - text: |
        Another installation method is selected. If you want to use package
        installation method set 'vault:use_upstream' to 'package' or 'repo'.
        Current value of vault:use_upstream: '{{ v.use_upstream }}'
  {%- endif %}

{#- Vault is not selected for installation #}
{%- else %}
vault_package_install_notice:
  test.show_notification:
    - name: vault_package_install
    - text: |
        Vault is not selected for installation, current value
        for 'vault:install': {{ v.install|string|lower }}, if you want to install Vault
        you need to set it to 'true'.

{%- endif %}
