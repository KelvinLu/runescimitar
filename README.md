# runescimitar

`runescimitar` is a node based on the Raspberry Pi 4, running Ubuntu Server.

Its purpose is to be a portable Bitcoin full node, with many personal features.

Most of the setup is based on the excellent RaspiBolt guide
(https://raspibolt.org).

Obviously, feel free to take inspiration or fork this repository.

## On Bitcoin ...

Although the setup provides the `personal_user` a `gocryptfs`-mounted
"`~/workspace`", as well as `fstab` entries to reference actual removable media
items, _**the user should not store or transmit private key material through the
server or these mechanisms**_.

These features only aim to provide low-level security, which is suitable for
data relegated to less sensitive categories (_e.g.; public key material, PSBTs,
confidential notes, etc._) whose compromise would only jeopardize privacy
concerns and such (_i.e.; having no ability to ultimately control funds_).

For storing and using private keys, consider using an air-gapped solution
(_e.g.; a dedicated hardware wallet_) or any other implement besides this server.
Movement and control of funds should incorporate the usage of PSBTs.

## Features

- Three users; `wizard` (_operator, superuser_), `cleric` (_personal user_), and
  `nomad` (_guest user_).
- RaspiBolt-inspired ...
    - ... Bitcoin full node (_running Bitcoin Core, a Fulcrum SPV server, and
      having Sparrow wallet_).
    - ... Lightning node (_running LND, with Lightning Terminal and Ride The
      Lightning_).
    - ... fee and liquidity management (_`charge-lnd`, `rebalance-lnd`_).
    - ... visibility features (_Mempool, `lntop`_).
    - ... applications (_`Tor`, `nginx`_).
    - ... administration (_`ufw`, `fail2ban`, Circuit Breaker_).
    - ... system configuration (_`ulimit`s, swap space, `zram`_).
- Other features ...
    - X11 setup with `i3wm`, alongside personal themes and customization.
    - Remove Ubuntu Server cruft (_`snapd`, `cloud-init`,
      `unattended_upgrades`_).
    - Exploration tools (_`bx`/`libbitcoin-explorer`_).
    - Userspace-encrypted (_`gocryptfs`_) and temporary (_`tmpfs`_) workspace
      directories (_for the personal and guest user, respectively_).
    - Configuration for using physical media (_`fstab` entries for external
      drives and removable media_).
        - e.g.; for placing the blockchain, or otherwise for different purposes
          using various filesystems, across separate partitions and drives.
    - ... and more!

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

> The `rpi4_server::var_mount` recipe allows for binding `/var` across a
> different filesystem (e.g.; external drive).
>
> See `node['rpi4_server']['var_mount']['marker_file']`.
>
> This may be useful if the root filesystem remains on the Raspberry Pi's SD
> card, and if `/var` should be mounted elsewhere (e.g.; to avoid heavy write
> usage onto the SD card, without needing to vacate the root filesystem itself
> elsewhere).

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
