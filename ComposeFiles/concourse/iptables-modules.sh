#!/bin/bash

set -e

modprobe ip_tables
modprobe iptable_filter
modprobe iptable_nat

#update-alternatives --config iptables 