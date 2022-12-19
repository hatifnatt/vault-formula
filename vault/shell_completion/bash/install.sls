{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}

{#- Install systemwide bash autocomplete for vault #}
{%- if v.shell_completion.bash.install %}
  {#- Install bash autocompletion package first #}
vault_shell_completion_bash_install_package:
  pkg.installed:
    - name: {{ v.shell_completion.bash.package }}

vault_shell_completion_bash_install_completion:
  file.managed:
    - name: {{  salt['file.join'](v.shell_completion.bash.dir, 'vault') }}
    - mode: 644
    - makedirs: true
    - contents: |
        complete -C {{ v.bin }} vault

{#- Bash autocompletion for vault is not selected for installation #}
{%- else %}
vault_shell_completion_bash_install_notice:
  test.show_notification:
    - name: vault_shell_completion_bash_install
    - text: |
        Bash autocompletion for Vault is not selected for installation, current value
        for 'vault:shell_completion:bash:install': {{ v.shell_completion.bash.install|string|lower }},
        if you want to install Bash autocompletion for Vault you need to set it to 'true'.

{%- endif %}
