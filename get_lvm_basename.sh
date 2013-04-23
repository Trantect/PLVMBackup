#!/bin/bash

find /dev/SHARED_LVM -type l -print|xargs -n1 basename
