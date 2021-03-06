#!/bin/sh

set -e

# Compiling components

# This script run from main build.sh script
# If you run it direct, set up $lazbuild first

# Rebuild widget dependent packages (only for lazarus < 1.2)
if [ -f /usr/lib/lazarus/default/ideintf/ideintf.lpk ] ; then
  if [ ! -d ~ ] ; then
    mkdir -p ${HOME}
  fi
  if [ ! -f ~/.fpc.cfg ] ; then
    cp /etc/fpc.cfg ~/.fpc.cfg
    echo -Fu~/.lazarus/lib/LazControls/lib/\$fpctarget/qt/ >> ~/.fpc.cfg
    echo -Fu~/.lazarus/lib/IDEIntf/units/\$fpctarget/qt/ >> ~/.fpc.cfg
  fi
  $lazbuild /usr/lib/lazarus/default/components/lazcontrols/lazcontrols.lpk $DC_ARCH -B
  $lazbuild /usr/lib/lazarus/default/ideintf/ideintf.lpk $DC_ARCH -B
  $lazbuild /usr/lib/lazarus/default/components/synedit/synedit.lpk $DC_ARCH -B
fi

# Build components
basedir=$(pwd)
cd components
$lazbuild chsdet/chsdet.lpk $DC_ARCH
$lazbuild CmdLine/cmdbox.lpk $DC_ARCH
$lazbuild dcpcrypt/dcpcrypt.lpk $DC_ARCH
$lazbuild doublecmd/doublecmd_common.lpk $DC_ARCH
$lazbuild KASToolBar/kascomp.lpk $DC_ARCH
$lazbuild viewer/viewerpackage.lpk $DC_ARCH
$lazbuild gifanim/pkg_gifanim.lpk $DC_ARCH
$lazbuild ZVDateTimeCtrls/zvdatetimectrls.lpk $DC_ARCH
cd $basedir
