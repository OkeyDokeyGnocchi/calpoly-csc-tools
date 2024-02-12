#! /bin/bash

PREFIX=${HOME}
SOURCEDIR="${HOME}/python-script-source"
PYTHONVER="3.11.8"
PYTHONMINORVER="3.11"
LOGFILE="${HOME}/python${PYTHONMINORVER}-install.log"

echo "  Starting python${PYTHONMINORVER} install, redirecting all output to ${LOGFILE}" | tee -a $LOGFILE
sleep 5

echo -e "  Checking if group "Development Tools" is installed" | tee -a $LOGFILE
if [ $(yum grouplist installed | grep -c 'Development Tools') -eq 1 ]; then
  echo "  Development Tools found, continuing" | tee -a $LOGFILE
else
  echo "  Development Tools not installed, exiting" | tee -a $LOGFILE
  exit
fi

echo -e "\n  Attempting to install openssl-1.1.1w in ${HOME}/openssl" | tee -a $LOGFILE
cd ${HOME}
mkdir $SOURCEDIR
mkdir ${HOME}/openssl
cd $SOURCEDIR
echo "  Downloading openssl-1.1.1w.tar.gz" | tee -a $LOGFILE
wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz >>$LOGFILE 2>&1
echo "  Extracting openssl-1.1.1w.tar.gz" | tee -a $LOGFILE
tar -xvf openssl-1.1.1w.tar.gz >>$LOGFILE 2>&1
cd openssl-1.1.1w
echo "  Configuring openssl-1.1.1w" | tee -a $LOGFILE
./config --prefix=$PREFIX/openssl --openssldir=$PREFIX/openssl >>$LOGFILE 2>&1
echo "  Make and make installing openssl-1.1.1w. This will take a bit of time" | tee -a $LOGFILE
make >>$LOGFILE 2>&1
make install >>$LOGFILE 2>&1

echo -e "\n\n" | tee -a $LOGFILE
echo "  Updating bash_profile with necessary variables at the end of ${HOME}/.bash_profile and reloading bash profile" | tee -a $LOGFILE
echo "  NOTE: Please verify that the changes are acceptable to you, it can potentially impact your work on other systems!" | tee -a $LOGFILE
sleep 3
cat >> ${HOME}/.bash_profile << EOF

##### Added by the python 3.11 install script #####
export PATH=$HOME/openssl/bin:$PATH
export LD_LIBRARY_PATH=$HOME/openssl/lib
export LC_ALL="en_US.UTF-8"
export LDFLAGS="-L $HOME/openssl/lib -Wl,-rpath,$HOME/openssl/lib"
EOF
. ${HOME}/.bash_profile

echo -e "\n  Verifying OpenSSL is showing 1.1.1w" | tee -a $LOGFILE
if [ $(openssl version | grep -c '1.1.1w') -eq 1 ]; then
  echo "  OpenSSL looks good, moving on!" | tee -a $LOGFILE
else
  echo "  Something is wrong with OpenSSL install, exiting" | tee -a $LOGFILE
  exit
fi

echo -e "\n  Checking if zlib-devel is installed" | tee -a $LOGFILE
sleep 3
if [ $(yum list installed | grep -c 'zlib-devel') -eq 1 ]; then
  echo "  zlib-devel found, continuing" | tee -a $LOGFILE
else
  echo "  zlib-devel not found, attempting to install." | tee -a $LOGFILE
  cd $SOURCEDIR
  mkdir ${HOME}/zlib
  echo "  Downloading zlib-1.3.1.tar.gz" | tee -a $LOGFILE
  wget https://www.zlib.net/zlib-1.3.1.tar.gz >>$LOGFILE 2>&1
  echo "  Extracting zlib-1.3.1.tar.gz" | tee -a $LOGFILE
  tar -xvf zlib-1.3.1.tar.gz >>$LOGFILE 2>&1
  cd zlib-1.3.1
  echo "  Configuring zlib-1.3.1" | tee -a $LOGFILE
  ./configure --prefix=${HOME}/zlib >>$LOGFILE 2>&1
  echo "  Make and make installing zlib-1.3.1. This will take a bit of time" | tee -a $LOGFILE
  make >>$LOGFILE 2>&1
  make install >>$LOGFILE 2>&1
  sed -i '/^export LD_LIBRARY_PATH/ s/$/:${HOME}\/zlib\/lib/' ${HOME}/.bash_profile
  cat >> ${HOME}/.bash_profile << EOF
export C_INCLUDE_PATH=${HOME}/zlib/include
export CPLUS_INCLUDE_PATH=${HOME}/zlib/include
EOF
fi

echo -e "\n  Attempting to install python ${PYTHONVER}" | tee -a $LOGFILE
sleep 3
mkdir ${HOME}/python-${PYTHONVER}
cd $SOURCEDIR
echo "  Downloading Python-${PYTHONVER}.tgz" | tee -a $LOGFILE
wget https://www.python.org/ftp/python/${PYTHONVER}/Python-${PYTHONVER}.tgz >>$LOGFILE 2>&1
echo "  Extracting Python-${PYTHONVER}.tgz" | tee -a $LOGFILE
tar -xvf Python-${PYTHONVER}.tgz >>$LOGFILE 2>&1
cd Python-${PYTHONVER}
sed -i '/#zlib/c\zlib  zlibmodule.c -I${HOME}/zlib/include -L${HOME}/zlib/lib -lz' "$SOURCEDIR/Python-$PYTHONVER/Modules/Setup"
echo "  Configuring Python-${PYTHONVER}" | tee -a $LOGFILE
./configure --prefix=${HOME}/python-${PYTHONVER} --with-openssl=${HOME}/openssl >>$LOGFILE 2>&1
echo "  Make and make installing Python-${PYTHONVER}. This will take a bit of time" | tee -a $LOGFILE
make >>$LOGFILE 2>&1
make install >>$LOGFILE 2>&1

echo -e "\n  Updating path with aliases for new python and pip v${PYTHONVER}" | tee -a $LOGFILE
cat >> ${HOME}/.bash_profile << EOF
alias python${PYTHONMINORVER}="${HOME}/python-${PYTHONVER}/bin/python${PYTHONMINORVER}"
alias pip${PYTHONMINORVER}="${HOME}/python-${PYTHONVER}/bin/pip${PYTHONMINORVER}"
EOF

echo "\n  Checking that python and pip are found where they're expected." | tee -a $LOGFILE
ls $HOME/python-$PYTHONVER/bin/python$PYTHONMINORVER
ls $HOME/python-$PYTHONVER/bin/pip$PYTHONMINORVER

echo "  NOTE: You will need to source .bash_profile to use the new aliases" | tee -a $LOGFILE
echo "    this can be done with `. ~/.bash_profile` or by logging out/in" | tee -a $LOGFILE

sleep 5

echo -e "\n  Cleaning up source directory ($SOURCEDIR) to save space" | tee -a $LOGFILE
rm -rf $SOURCEDIR

echo "  Cleanup complete.  Log can be found at ${LOGFILE}" | tee -a $LOGFILE
echo "  Exiting." | tee -a $LOGFILE