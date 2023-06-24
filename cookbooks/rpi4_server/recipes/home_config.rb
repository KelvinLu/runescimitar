#
# Cookbook:: rpi4_server
# Recipe:: home_config
#

operator_user = Etc.getpwnam(node['rpi4_server']&.[]('operator_user'))
operator_home = Dir.home(operator_user.name)

cookbook_file File.join(operator_home, '.inputrc') do
  source '.inputrc'

  owner operator_user.uid
  group operator_user.gid
  mode '0644'
end

directory File.join(operator_home, '.config', 'systemd') do
  owner operator_user.uid
  group operator_user.gid
  mode '0755'
end

directory File.join(operator_home, '.config', 'systemd', 'user') do
  owner operator_user.uid
  group operator_user.gid
  mode '0755'
end

USER_PS1_STANZA = <<~'BASH'.strip
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
BASH

Etc.passwd do |user|
  bashrc_file = File.join(user.dir, '.bashrc')

  if (user.shell == '/bin/bash') && File.file?(bashrc_file)
    file "#{bashrc_file}.orig" do
      content lazy { File.open(bashrc_file).read }

      mode    '0644'

      action  :create_if_missing
      only_if { File.open(bashrc_file).read.include?(USER_PS1_STANZA) }
    end

    file bashrc_file do
      content lazy {
        File.open(bashrc_file).read.split(USER_PS1_STANZA).join(
          [
            "# Default, templated PS1 was removed by Chef at #{Time.now}",
            *(USER_PS1_STANZA.lines.map { |line| '# ' + line.strip })
          ].join("\n")
        )
      }

      mode    '0644'

      action  :create
      only_if { File.open(bashrc_file).read.include?(USER_PS1_STANZA) }
    end
  end
end
