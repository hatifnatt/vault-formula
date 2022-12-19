{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import vault as v %}
include:
{%- if v.use_upstream in ('binary', 'archive') %}
  - .binary.clean
{%- elif v.use_upstream in ('repo', 'package') %}
  - .package.clean
{%- endif %}
