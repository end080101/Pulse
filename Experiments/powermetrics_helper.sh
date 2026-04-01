#!/bin/bash
# pm_helper.sh - Extracts CPU die temperature using powermetrics

# We run powermetrics once per 2 seconds, sampling thermal sensors.
# We grep for "CPU die temperature" and extract the numeric value.
sudo powermetrics --samplers thermal -i 2000 -n 1 | awk '/CPU die temperature/ {print $4}'
