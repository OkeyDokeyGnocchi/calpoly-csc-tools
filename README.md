# calpoly-csc-tools

## Current tools
- centos7-python3.X-install.sh - installs python (currently 3.11.8) and dependencies from source for CentOS 7
  - Script has been tested and verified working on CentOS 7 and Amazon Linux 2
- centos7-gcc-install.sh - installs gcc (currently 13.2.0) and dependencies from source for CentOS 7

### Caveats
- all scripts are provided as-is, there is no official support or endorsement from calpoly, ITS, etc.
- by default the skel for homedirs does not allow write access to .bash_profile. This will cause parts of the script to fail. You can `chmod 600 ~/.bash_profile` before running to allow yourself and the scripts to write to .bash_profile.
- centos7-gcc-install.sh - Installing a different version of gcc and its dependencies can have unexpected consequences, only proceed if necessary. This install can take a _long_ time to complete.
