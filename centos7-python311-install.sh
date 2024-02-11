#! /bin/bash

PREFIX=${HOME}
SOURCEDIR="${HOME}/python-script-source"
PYTHONVER="3.11.8"

echo -e "  Checking if group "Development Tools" is installed.\n"
if [ $(yum grouplist installed | grep -c 'Development Tools') -eq 1 ]; then
  echo "  Development Tools found, continuing"
else
  echo "  Development Tools not installed, exiting."
  exit
fi

echo "  Attempting to install openssl-1.1.1w in ${HOME}/openssl"
# Install openssh1.1.1
cd ${HOME}
mkdir $SOURCEDIR
mkdir ${HOME}/openssl
cd $SOURCEDIR
wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar -xvf openssl-1.1.1w.tar.gz
cd openssl-1.1.1w
./config --prefix=$PREFIX/openssl --openssldir=$PREFIX/openssl
make && make install

echo -e "\n\n"
echo "  Updating bash_profile with necessary variables at the end of ${HOME}/.bash_profile and reloading bash profile"
echo "  NOTE: Please verify that the changes are acceptable to you, it can potentially impact your work on other systems!"
sleep 3
cat >> ${HOME}/.bash_profile << EOF

##### Added by the python 3.11 install script #####
export PATH=$HOME/openssl/bin:$PATH
export LD_LIBRARY_PATH=$HOME/openssl/lib
export LC_ALL="en_US.UTF-8"
export LDFLAGS="-L /home/username/openssl/lib -Wl,-rpath,/home/username/openssl/lib"
EOF
. ${HOME}/.bash_profile

echo "  Verifying Oopenssl is showing 1.1.1w..."
if [ $(openssl version | grep -c '1.1.1w') -eq 1 ]; then
  echo "  Openssl looks good, moving on!"
else
  echo "  Something is wrong with Openssl install, exiting"
  exit
fi
sleep 3

echo -e "\n  Attempting to install python ${PYTHONVER}"
sleep 3
# Install python
mkdir ${HOME}/python-${PYTHONVER}
cd $SOURCEDIR
wget https://www.python.org/ftp/python/${PYTHONVER}/Python-${PYTHONVER}.tgz
tar -xvf Python-${PYTHONVER}.tgz
cd Python-${PYTHONVER}
#echo -e "  Checking if zlib-devel is installed.\n"
#if [ $(yum list installed | grep -c 'zlib-devel') -eq 1 ]; then
#  echo "  zlib-devel found, continuing"
#else
#  echo " zlib-devel not found."
#  exit
#fi
sed -i '/zlib/s/^#//' ./Setup
./configure --prefix=${HOME}/python-${PYTHONVER} --with-openssl=${HOME}/openssl
make && make install