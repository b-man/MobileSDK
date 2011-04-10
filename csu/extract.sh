#!/bin/sh

set -e

CSUNAME=Csu
CSUVERS=79
CSUFILE=${CSUNAME}-${CSUVERS}.tar.gz

DISTDIR=csu

TOPSRCDIR=`pwd`

if [ "`tar --help | grep -- --strip-components 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
elif [ "`tar --help | grep bsdtar 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
else
    TARSTRIP=--strip-path
fi

PATCHFILESDIR=${TOPSRCDIR}/patches

PATCHFILES="no_ctr1.10.6.diff"

if [ -d "${DISTDIR}" ]; then
    echo "${DISTDIR} already exists. Please move aside before running" 1>&2
    exit 1
fi

mkdir -p ${DISTDIR}
tar ${TARSTRIP}=1 -zxf ${CSUFILE} -C ${DISTDIR}

set +e

INTERACTIVE=0
echo "Applying patches"
for p in ${PATCHFILES}; do			
    dir=`dirname $p`
    if [ $INTERACTIVE -eq 1 ]; then
	read -p "Apply patch $p? " REPLY
    else
	echo "Applying patch $p"
    fi
    pushd ${DISTDIR}/$dir > /dev/null
    patch --backup --posix -p0 < ${PATCHFILESDIR}/$p
    if [ $? -ne 0 ]; then
	echo "There was a patch failure. Please manually merge and exit the sub-shell when done"
	$SHELL
	if [ $UPDATEPATCH -eq 1 ]; then
	    find . -type f | while read f; do
		if [ -f "$f.orig" ]; then
		    diff -u -N "$f.orig" "$f"
		fi
	    done > ${PATCHFILESDIR}/$p
	fi
    fi
    find . -type f -name \*.orig -exec rm -f "{}" \;
    popd > /dev/null
done

set -e

exit 0
