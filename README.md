# runescimitar

`runescimitar` is a node based on the Raspberry Pi 4, running Ubuntu Server.

Its purpose is to be a portable Bitcoin full node.

Most of the setup is based on the excellent RaspiBolt guide
(https://raspibolt.org).

## Setup

1. Obtain a Raspberry Pi 4.
2. Install Ubuntu Server onto the device.
    - Raspberry Pi Imager is a helpful tool for creating the installation media.
        - N.B. Setting no options under "Advanced options" is recommended.
3. Boot the device with the installation media, allowing for first-time setup.
4. Perform any necessary, basic setup.
    - e.g.; creating or modifying user accounts, configuring `sshd` setup ...
5. Update packages; `apt update`, `apt upgrade`.
6. Install Ruby (via `ruby-install`).
    - The version provided through Aptitude may be extremely outdated.
    - Install Make; `apt install make`.
    - Install `ruby-install` by following the installation steps at
      `https://github.com/postmodern/ruby-install`.
    - Install Ruby; `ruby-install --update ruby`.
    - Install `chruby` by following the installation steps at
      `https://github.com/postmodern/chruby`.
7. Install Chef; `apt install chef chef-bin`.
    - The installation will prompt for the Chef server URL, which may be left
      empty.
8. Bootstrap configuration.
    1. Clone this repository.
    2. Vend cookbooks managed by Berkshelf.
        - Berkshelf should utilize the built Ruby, use `chruby` to switch to it.
        - `gem install --user-install berkshelf --no-document`
        - `berks vendor --berksfile ./nodes/runescimitar.berksfile ./berkshelf/`
9. Run `chef-solo`.
    - Chef should utilize the system Ruby, use `chruby` to switch to it.
    - `chef-solo --config ./solo.rb --json-attributes ./nodes/runescimitar.json --node-name runescimitar`.
    - `chef-solo --config ./solo.rb --json-attributes ./nodes/runescimitar.json --node-name runescimitar --override-runlist "${run_list:?}"`.

## Idiosyncrasies

### `/var` `noexec` and package managers

- When `/var` is bind-mounted onto a filesystem with the `noexec` option,
  package managers may misbehave. Notably, `apt` and `dpkg` execute scripts
  relevant to a package's configuration process that are stored within
  `/var/lib/dpkg`.
    - See `find /var -type f -executable`.
    - As a workaround, do `mount --bind /var/lib/dpkg /var/lib/dpkg` followed by
      `mount -o remount,bind,exec,nosuid,nodev /var/lib/dpkg` prior to running
      the Chef Client. These changes does not persist and are reset on reboot.

## Procedures

### Bind-mounting `/var` across filesystems

- Procure an alternate location on a secondary filesystem (i.e.; a filesystem
  that is currently not hosting `/` -- see `df -hT`) to host `/var`.
    - For example, consider a secondary filesystem mounted at "`/alternate`".
- Create the new `/var` on the secondary filesystem; `mkdir /alternate/var`.
- Start single user mode; `init 1`.
- Change directory to the current `/var`; `cd /var`.
- Copy the contents onto the alternate location; `cp -ax . /alternate/var`
- Make `/var` empty, in preparation to use as a mount point;
  - Keep a backup copy; `cd / && mv /var /var.old`, ...
  - ... or `rm -rf /var && mkdir /var`.
- Temporarily `mount --bind /alternate/var /var`.
- Persist the change as an entry in `/etc/fstab`.
  - `/alternate/var /var none bind 0 0`.
- Return to multi user mode; `init 5`.
