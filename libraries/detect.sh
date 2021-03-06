#!/bin/bash
# Functions For Detecting Current Distribution

# Ubuntu Detection (Issue File)
if grep -iq "ubuntu" /etc/issue; then
	# Set Distribution To Ubuntu
	DISTRIBUTION=ubuntu
fi

# Ubuntu Detection (LSB Release)
if command -v lsb_release &> /dev/null; then
	if lsb_release -a 2> /dev/null | grep -iq "ubuntu"; then
		# Set Distribution To Ubuntu
		DISTRIBUTION=ubuntu
	fi
fi

if [ $DISTRIBUTION == "ubuntu" ]; then
	DISTRIBUTION_VERSION=$(lsb_release -c | cut -f2)
fi
