#! /bin/bash
# This is a script for installing OpenSSL-1.1.1w and KeyAccess client on RHEL 6/7
# OpenSSL portion tested and verified on:
#    - CentOS 6 VM clean install with yum repos fixed
#    - CentOS 7 VM minimal install, no modifications
# NOTE: Doesn't work with sh ./file.sh, needs bash. To use sh to run, remove the exec line below

USAGE="\nUSAGE: $(basename "$0") PROP_HOSTNAME KeyAccessS3Uri
\n    PROP_HOSTNAME = The server fqdn for KeyServer
\n    KeyAccessS3Uri = An s3 URI pointing to the KeyAccess client installer e.g., s3://env/installer-uri
"

# Verify we have both the PROP_HOSTNAME and KEYACCESS_INSTALLER_S3 URI
if [ -z $1 ]; then
    echo "  No input given for KeyAccess's PROP_HOSTNAME found, exiting."
    echo -e $USAGE
    exit 2
elif [ -z $2 ]; then
    echo "  No input given for KeyAccess Installer S3 URI, exiting."
    echo -e $USAGE
    exit 2
fi

# Verify aws cli is found, it should already be installed on existing systems
if ! command -v aws $> /dev/null; then
    echo "  aws cli not found, please verify it is installed. Exiting."
    exit 1
fi

# CLI Parameters
PROP_HOSTNAME=$1
KEYACCESS_INSTALLER_S3_URI=$2

# OPENSSL_PREFIX could be removed, this was added to ensure it doesn't come anywhere near touching the OS's default OpenSSL
OPENSSL_PREFIX="/opt/openssl1.1.1"
SOURCEDIR="openssl1.1.1-source"
LOGFILE="openssl1.1.1-install.log"
declare -a PREREQS=("gcc" "perl" "make" "wget")

# Set all stdout and stderr to tee to our LOGFILE for review if needed
exec > >(tee -a $LOGFILE) 2>&1

# Check if the directory for OPENSSL_PREFIX exists, if so we don't need to install it
if [ ! -d $OPENSSL_PREFIX ]; then
    # Get our pre-reqs verified and installed if needed
    echo -e "  Verifying pre-reqs"
    for package in "${PREREQS[@]}"; do
        if [ $(yum list installed | grep -c -w $package)  -eq 0 ]; then
            echo "  Missing $package, installing"
            yum install $package -y
        else
            echo "  Found $package, moving forward"
        fi
    done

    # Download, config, make, make install OPENSSL 1.1.1w in $OPENSSL_PREFIX
    echo "  Pre-reqs have been verified and installed"
    echo "  Getting OpenSSL1.1.1 source"
    mkdir -p $SOURCEDIR
    cd $SOURCEDIR
    wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz --no-check-certificate
    echo "  Extracting openssl-1.1.1w.tar.gz"
    tar -xvf openssl-1.1.1w.tar.gz
    cd openssl-1.1.1w
    echo "  Configuring openssl-1.1.1w"
    ./config --prefix=$OPENSSL_PREFIX --openssldir=$OPENSSL_PREFIX
    echo "  make and make installing openssl-1.1.1w. This will take some time..."
    make
    make install

    echo "  Installed openssl-1.1.1w at $OPENSSL_PREFIX"

    # Now we need to set a couple of symlinks for libraries to be where KeyAccess expects them
    echo "  Creating symlinks for KeyAccess to use libssl and libscrypto"
    ln -s "$OPENSSL_PREFIX/lib/libssl.so.1.1" "/usr/lib64/libssl.so.1.1"
    ln -s "$OPENSSL_PREFIX/lib/libcrypto.so.1.1" "/usr/lib64/libcrypto.so.1.1"
    echo "  Running 'ls' against the new files for manual verification"
    ls -ail /usr/lib64/lib*.so.1.1
    echo "  Running $OPENSSL_PREFIX/bin/openssl version for manual verification"
    $OPENSSL_PREFIX/bin/openssl version
else
    echo "  Directory $OPENSSL_PREFIX already exists on this system, skipping install."
fi

# KeyAccess
# Verify if the service already exists, skip if it does
if [ ! -f "/lib/systemd/system/keyaccess.service" ]; then
    echo "  KeyAccess service was not found, installing KeyAccess client"
    if [ ! -d $SOURCEDIR ]; then
        mkdir -p $SOURCEDIR
    fi
    cd $SOURCEDIR

    # Copy down the installer rpm file from s3 to working directory, verify it's there before attempting to install
    echo "  Getting the installer from s3 at $KEYACCESS_INSTALLER_S3_URI"
    aws s3 cp $KEYACCESS_INSTALLER_S3_URI ./keyaccess-installer.rpm
    if [ ! -f ./keyaccess-installer.rpm ]; then
        echo "  keyaccess-installer.rpm not found, verify S3 URI and retry. Exiting."
        exit 1
    fi

    echo "  Installing keyaccess client"
    env PROP_HOSTNAME=$PROP_HOSTNAME rpm -i ./keyaccess-installer.rpm
    if [ ! -f "/lib/systemd/system/keyaccess.service" ]; then
        echo "  KeyAccess service was not found, something may have gone wrong.  Exiting, please verify KeyAccess status."
        exit 1
    fi
else
    echo "  The file /lib/systemd/system/keyaccess.service already exists, is KeyAccess already installed? Skipping install."
fi

exit 0