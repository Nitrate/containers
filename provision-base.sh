#!/usr/bin/bash -ex

dnf update -y
dnf --setopt=deltarpm=0 --setopt=install_weak_deps=false --nodocs install -y \
    python3-pip python3-setuptools gcc python3-devel mariadb-devel postgresql-devel

python3 -m venv venv

pybin=./venv/bin/python3
# source tarball is already extracted under app/ with name nitrate-tcms-<version>
appdir=$(echo app/nitrate-tcms-*)
srcdir="$appdir/src"

"$pybin" -m pip install --no-cache-dir --disable-pip-version-check "$appdir"["${extra_requires}"]

mkdir templates
cp -r "${srcdir}"/templates/* templates/

# Volume directories
mkdir uploads nitrate-config data

mkdir static
echo "STATIC_ROOT = '/project/static'" >>"${srcdir}/tcms/settings/common.py"
export PYTHONPATH="${srcdir}/"
export NITRATE_DB_ENGINE=sqlite
export NITRATE_SECRET_KEY=some-key
"$pybin" "${srcdir}/manage.py" collectstatic --settings=tcms.settings.product --noinput

# Cleanup
dnf remove -y gcc
dnf clean all
rm -r app/
