#!/usr/bin/bash -ex

# source tarball is already extracted under app/
appdir=()
mapfile -t appdir < <(find app/ -maxdepth 1 -mindepth 1 -type d)
if [ ${#appdir[@]} -gt 1 ]; then
    echo "error: there must be only one extracted application directory, but here are" "${appdir[@]}"
    exit 1
fi
srcdir="${appdir[0]}/src"

dnf --disablerepo=fedora-cisco-openh264 update -y

dnf --setopt=deltarpm=0 \
    --setopt=install_weak_deps=false \
    --nodocs \
    install -y \
    python3-pip python3-setuptools gcc python3-devel mariadb-devel postgresql-devel

python3 -m venv venv
source ./venv/bin/activate

python3 -m pip install --no-cache-dir --disable-pip-version-check "${appdir[0]}"["${extra_requires}"]

mkdir templates
cp -r "${srcdir}"/templates/* templates/

# Volume directories
mkdir uploads nitrate-config data

mkdir static
echo "STATIC_ROOT = '/project/static'" >>"${srcdir}/tcms/settings/common.py"
export PYTHONPATH="${srcdir}/"
export NITRATE_DB_ENGINE=sqlite
export NITRATE_SECRET_KEY=some-key
python3 "${srcdir}/manage.py" collectstatic --settings=tcms.settings.product --noinput

deactivate

# Cleanup
dnf remove -y gcc
dnf clean all
rm -r app/
