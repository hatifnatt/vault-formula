{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}
{#- Find all vault binaries with version i.e. /usr/local/bin/vault-1.11.2 etc. #}
{%- set vault_versions = salt['file.find'](v.bin ~ '-*',type='fl') %}

include:
  - {{ tplroot }}.shell_completion.bash.clean
  - {{ tplroot }}.service.clean

{#- Remove symlink into system bin dir #}
vault_binary_clean_bin_symlink:
  file.absent:
    - name: {{ v.bin }}

{%- for binary in vault_versions %}
  {%- set version = binary.split('-')[-1] %}
vault_binary_clean_bin_v{{ version }}:
  file.absent:
    - name: {{ binary }}
    - require:
      - file: vault_binary_clean_bin_symlink

{%- endfor %}

{#- Remove user and group #}
vault_binary_clean_user:
  user.absent:
    - name: {{ v.user }}

vault_binary_clean_group:
  group.absent:
    - name: {{ v.group }}
