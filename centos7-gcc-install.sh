#! /bin/bash

PREFIX=${HOME}
SOURCEDIR="${HOME}/gcc-script-source"
GCCVER="13.2.0"
GCCMINORVER="13.2"
GCCDIR="${HOME}/gcc-${GCCVER}"
LOGFILE="${HOME}/gcc${GCCMINORVER}-install.log"
GMPVER="6.3.0"
MPFRVER="4.2.1"

echo "  Starting gcc-${GCCMINORVER} install, redirecting all output to ${LOGFILE}" | tee -a $LOGFILE
echo "  NOTE: This script only enables c & c++ by default, please use CTRL+C to cancel and update this script if you need other language support!"
echo "  NOTE: Installing a user-specific version of gcc can have unexpected consequences, only proceed if you're sure"
echo -e "\n  NOTE: gcc installs take up a lot of space, please ensure you have a good amount (>5GB) of free space in your homedir before installing!"
echo "  Sleeping 20 seconds to give time to cancel if needed..."
sleep 20

cd ${HOME}
mkdir $SOURCEDIR

mkdir $GCCDIR
cd $SOURCEDIR
echo -e "\n  Attempting to install gcc-${GCCVER} in ${GCCDIR}" | tee -a $LOGFILE
echo "  Downloading gcc-${GCCVER}.tar.gz" | tee -a $LOGFILE
wget https://ftp.gnu.org/gnu/gcc/gcc-$GCCVER/gcc-$GCCVER.tar.gz >>$LOGFILE 2>&1
echo "  Extracting gcc-${GCCVER}.tar.gz" | tee -a $LOGFILE
tar -xvf gcc-$GCCVER.tar.gz >>$LOGFILE 2>&1
cd gcc-$GCCVER
echo "  Getting GCC prereqs with included script"
./contrib/download_prerequisites
echo "  Configuring gcc-${GCCVER}" | tee -a $LOGFILE
./configure --prefix=$PREFIX/gcc-$GCCVER --enable-languages=c,c++ --disable-multilib
echo "  Make and make installing gcc-${GCCVER}. This will take a while, please stand by" | tee -a $LOGFILE
make | tee -a $LOGFILE
make install | tee -a $LOGFILE

echo -e "\n\n" | tee -a $LOGFILE
echo "  Backing up bash_profile as ${HOME}/.bash_profile-gcc-install.bak" | tee -a $LOGFILE
cp ${HOME}/.bash_profile ${HOME}/.bash_profile-gcc-install.bak
echo "  Updating bash_profile with necessary variables at the end of ${HOME}/.bash_profile and reloading bash profile" | tee -a $LOGFILE
echo "  NOTE: Please verify that the changes are acceptable to you, it can potentially impact your work on other systems!" | tee -a $LOGFILE
cd $HOME
sleep 3

cat >> ${HOME}/.bash_profile << EOF
##### Added by centos7-gcc-install.sh script #####
export CC=$HOME/gcc-$GCCVER/bin/gcc
export CXX=$HOME/gcc-$GCCVER/bin/g++
export PATH=$HOME/gcc-$GCCVER/bin:$PATH
export LD_LIBRARY_PATH=$HOME/gcc-$GCCVER/lib64:$LD_LIRBARY_PATH
EOF

echo -e "\n  Checking that gcc and g++ are found where expected." | tee -a $LOGFILE
echo "  gcc-$GCCMINORVER: $(ls $HOME/gcc-$GCCVER/bin/gcc)"
echo "  g++-$GCCMINORVER: $(ls $HOME/gcc-$GCCVER/bin/g++)"

echo -e "\n\n  NOTE: You will need to source .bash_profile to use your new settings" | tee -a $LOGFILE
echo "    this can be done with the command '. ~/.bash_profile' or by logging out/in" | tee -a $LOGFILE

echo -e "\n  Cleaning up source directory ($SOURCEDIR) to save space" | tee -a $LOGFILE
rm -rf $SOURCEDIR

echo "  Cleanup complete.  Log can be found at ${LOGFILE}" | tee -a $LOGFILE
echo "  To revert this install, remove the ${GCCDIR} directory and remove the lines added to ~/.bash_profile after the line '##### Added by the centos7-gcc-install.sh script #####'" | tee -a $LOGFILE
echo "  Exiting." | tee -a $LOGFILE