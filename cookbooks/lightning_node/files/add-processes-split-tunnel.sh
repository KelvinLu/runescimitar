#!/bin/sh

# Add lnd processes to split tunnel
pgrep -x lnd | xargs -I % sh -c 'echo % >> /sys/fs/cgroup/net_cls/lightning_vpn/tasks' &> /dev/null

count=$(cat /sys/fs/cgroup/net_cls/lightning_vpn/tasks | wc -l)

if [ $count -eq 0 ];then
  echo '> no processes available for tunneling'
else
  echo "> ${count} process(es) successfully assigned"
fi
