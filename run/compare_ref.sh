#!/bin/bash

diff vga_log.txt ../ref/vga_log.txt
STATUS=$?

[ $STATUS -eq 0 ] && echo "[SUCCESS] Outputs match." || echo "[ERROR] Outputs do not match!!!"

