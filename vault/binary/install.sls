{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}
{%- set conf_dir = salt['file.dirname'](v['params']['config']) -%}

{%- if v.install %}
  {#- Install Vault from precompiled binary #}
  {%- if v.use_upstream in ('binary', 'archive') %}

    {#- Path prefix for local (salt fileserver) files #}
    {%- set local_path = salt['file.join'](v.binary.download_local, v.version) %}
    {#- Path prefix for remote (upstream) files #}
    {%- set remote_path = salt['file.join'](v.binary.download_remote, v.version) %}
    {#- Path prefix for remote (upstream) sha256sum file #}
    {%- set source_hash_remote_path = salt['file.join'](v.binary.source_hash_remote, v.version) %}

include:
  - {{ tplroot }}.shell_completion.bash.install
  - {{ tplroot }}.service.install

    {#- Install prerequisies #}
vault_binary_install_prerequisites:
  pkg.installed:
    - pkgs: {{ v.binary.prereq_pkgs|tojson }}

    {#- Create group and user #}
vault_binary_install_group:
  group.present:
    - name: {{ v.group }}
    - system: true

vault_binary_install_user:
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
      - group: vault_binary_install_group
    - require_in:
      - sls: {{ tplroot }}.service.install

    {#- Create directories #}
vault_binary_install_bin_dir:
  file.directory:
    - name: {{ salt['file.dirname'](v.bin) }}
    - makedirs: true

    {#- Download archive, extract archive install binary to it's place #}
    {#- TODO: Download and validate SHA file with gpg? https://www.hashicorp.com/security.html #}
vault_binary_install_download_archive:
  file.managed:
    - name: {{ v.binary.temp_dir }}/{{ v.version }}/vault_{{ v.version }}_linux_amd64.zip
    - source:
      - {{ local_path }}/vault_{{ v.version }}_linux_amd64.zip
      - {{ remote_path }}/vault_{{ v.version }}_linux_amd64.zip
    {%- if v.binary.skip_verify %}
    - skip_verify: true
    {%- else %}
    {#- source_hash only applicable when downloading via HTTP[S],
        it's not used when downloading from salt fileserver (salt://) #}
    - source_hash: {{ source_hash_remote_path }}/vault_{{ v.version }}_SHA256SUMS
    {%- endif %}
    - makedirs: true
    - unless: test -f {{ v.bin }}-{{ v.version }}

vault_binary_install_extract_bin:
  archive.extracted:
    - name: {{ v.binary.temp_dir }}/{{ v.version }}
    - source: {{ v.binary.temp_dir }}/{{ v.version }}/vault_{{ v.version }}_linux_amd64.zip
    - skip_verify: true
    - enforce_toplevel: false
    - require:
      - file: vault_binary_install_download_archive
    - unless: test -f {{ v.bin }}-{{ v.version }}

vault_binary_install_install_bin:
  file.rename:
    - name: {{ v.bin }}-{{ v.version }}
    - source: {{ v.binary.temp_dir }}/{{ v.version }}/{{ salt['file.basename'](v.bin) }}
    - require:
      - file: vault_binary_install_bin_dir
    - watch:
      - archive: vault_binary_install_extract_bin

    {#- Create symlink into system bin dir #}
vault_binary_install_bin_symlink:
  file.symlink:
    - name: {{ v.bin }}
    - target: {{ v.bin }}-{{ v.version }}
    - force: true
    - require:
      - archive: vault_binary_install_extract_bin
      - file: vault_binary_install_install_bin
    - require_in:
      - sls: {{ tplroot }}.shell_completion.bash.install

    {#- Fix problem with service startup due SELinux restrictions on RedHat falmily OS-es
        thx. https://github.com/saltstack-formulas/consul-formula/issues/49 for idea #}
    {%- if grains['os_family'] == 'RedHat' %}
vault_binary_install_bin_restorecon:
  module.run:
      {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
      {%- if 'module.run' in salt['config.get']('use_superseded', [])
              or grains['saltversioninfo'] >= [3005] %}
    - file.restorecon:
        - {{ v.bin }}-{{ v.version }}
      {%- else %}
    - name: file.restorecon
    - path: {{ v.bin }}-{{ v.version }}
      {%- endif %}
    - require:
      - file: vault_binary_install_install_bin
    - require_in:
      - sls: {{ tplroot }}.shell_completion.bash.install
    - onlyif: "LC_ALL=C restorecon -vn {{ v.bin }}-{{ v.version }} | grep -q 'Would relabel'"
    {% endif -%}

    {#- Remove temporary files #}
vault_binary_install_cleanup:
  file.absent:
    - name: {{ v.binary.temp_dir }}
    - require_in:
      - sls: {{ tplroot }}.service.install

  {#- Another installation method is selected #}
  {%- else %}
vault_binary_install_method:
  test.show_notification:
    - name: vault_binary_install_method
    - text: |
        Another installation method is selected. If you want to use binary
        installation method set 'vault:use_upstream' to 'binary' or 'archive'.
        Current value of vault:use_upstream: '{{ v.use_upstream }}'
  {%- endif %}

{#- Vault is not selected for installation #}
{%- else %}
vault_binary_install_notice:
  test.show_notification:
    - name: vault_binary_install
    - text: |
        Vault is not selected for installation, current value
        for 'vault:install': {{ v.install|string|lower }}, if you want to install Vault
        you need to set it to 'true'.

{%- endif %}
