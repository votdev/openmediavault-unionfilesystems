{% set config = salt['omv_conf.get']('conf.service.unionfilesystems') %}

{% for pool in config.filesystem %}
{% set poolmount = salt['omv_conf.get_by_filter'](
  'conf.system.filesystem.mountpoint',
  {'operator':'stringEquals', 'arg0':'uuid', 'arg1':pool.self_mntentref}) %}
{% set mntDir = poolmount[0].dir %}

{% set branchDirs = [] %}
{% for mntent in pool.mntentref %}
{% set branchDir = salt['omv_conf.get_by_filter'](
  'conf.system.filesystem.mountpoint',
  {'operator':'stringEquals', 'arg0':'uuid', 'arg1':mntent}) %}
{% set _ = branchDirs.append(branchDir[0].dir) %}
{% endfor %}

{% set options = [] %}
{% set options = pool.options.split(',') %}
{% set _ = options.append('category.create=' + pool.create_policy) %}
{% set _ = options.append('minfreespace=' + pool.min_free_space) %}

create_filesystem_mountpoint_{{ pool.self_mntentref }}:
  file.accumulated:
    - filename: "/etc/fstab"
    - text: "{{ branchDirs | join(':') }}\t\t{{ mntDir }}\tfuse.mergerfs\t{{ options | join(',') }}\t0 0"
    - require_in:
      - file: append_fstab_entries
{% endfor %}
