{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}

{#- Remove systemwide bash autocomplete for vault #}
vault_shell_completion_bash_install_completion:
  file.absent:
    - name: {{ salt['file.join'](v.shell_completion.bash.dir, 'vault') }}
