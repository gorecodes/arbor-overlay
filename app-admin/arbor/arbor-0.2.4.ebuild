# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11,12,13} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 systemd

DESCRIPTION="Local Gentoo web UI for managing Portage"
HOMEPAGE="https://github.com/gorecodes/Arbor"
SRC_URI="https://github.com/gorecodes/Arbor/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"
IUSE="apparmor logrotate openrc systemd"
REQUIRED_USE="|| ( openrc systemd )"

RDEPEND="
	${PYTHON_DEPS}
	dev-python/fastapi[${PYTHON_USEDEP}]
	dev-python/qrcode[${PYTHON_USEDEP}]
	dev-python/uvicorn[${PYTHON_USEDEP}]
	dev-python/websockets[${PYTHON_USEDEP}]
	sys-apps/portage[${PYTHON_USEDEP}]
	logrotate? ( app-admin/logrotate )
	apparmor? ( app-admin/apparmor )
"

BDEPEND="
	${PYTHON_DEPS}
	dev-python/setuptools[${PYTHON_USEDEP}]
"

S="${WORKDIR}/Arbor-${PV}/backend"

src_install() {
	distutils-r1_src_install

	local _arbor="${WORKDIR}/Arbor-${PV}"

	dodoc "${_arbor}/README.md"

	insinto /usr/share/arbor/frontend
	doins -r "${_arbor}/frontend/alpine/."

	# OpenRC init scripts
	if use openrc; then
		newinitd "${_arbor}/openrc/arbor-daemon" arbor-daemon
		newinitd "${_arbor}/openrc/arbor" arbor
	fi

	# systemd units
	if use systemd; then
		systemd_dounit "${_arbor}/systemd/arbor-daemon.service"
		systemd_dounit "${_arbor}/systemd/arbor.service"
	fi

	# First-time setup helper
	insinto /usr/share/arbor
	doins "${_arbor}/config/setup.sh"
	fperms 0755 /usr/share/arbor/setup.sh

	# Log rotation (optional — requires app-admin/logrotate)
	if use logrotate; then
		insinto /etc/logrotate.d
		newins "${_arbor}/config/logrotate.d/arbor" arbor
	fi

	# AppArmor draft profiles (optional, UNTESTED — see pkg_postinst)
	if use apparmor; then
		insinto /etc/apparmor.d
		doins "${_arbor}/apparmor/usr.bin.arbor"
		doins "${_arbor}/apparmor/usr.bin.arbor-daemon"
	fi
}

pkg_postinst() {
	elog "Arbor ${PV} installed."
	elog ""
	elog "Run first-time setup (system user, dirs, IPC key, owner account):"
	elog "  bash /usr/share/arbor/setup.sh"
	elog ""
	elog "--- What's new in v0.2.4 ---"
	elog "  No breaking changes or config migrations required."
	elog ""
	elog "  - Install view: ETA badge with confidence indicator (green = from build"
	elog "    history, yellow = partial estimate, grey = no data)."
	elog "  - Autounmask: now handles USE flag changes in addition to keywords;"
	elog "    writes to package.use/arbor-accepted automatically."
	elog ""
	elog "--- Process hardening ---"
	elog "  The init scripts apply no_new_privs and a reduced capability bounding"
	elog "  set when setpriv is available. setpriv requires USE=setpriv on"
	elog "  sys-apps/util-linux (not always set by default on Gentoo)."
	elog "  Without setpriv the services start with a warning but no capability drop."
	elog "  To enable full hardening:"
	elog "    USE=setpriv emerge sys-apps/util-linux"
	elog ""
	if use logrotate; then
		elog "--- Log rotation ---"
		elog "  /etc/logrotate.d/arbor installed: daily rotation, 10 MB threshold,"
		elog "  14 generations kept, gzip + delaycompress."
		elog ""
	fi
	if use apparmor; then
		ewarn "--- AppArmor profiles (UNTESTED) ---"
		ewarn "  Profiles installed to /etc/apparmor.d/ but have NOT been tested"
		ewarn "  end-to-end against a full emerge workflow. Do not enforce in"
		ewarn "  production without verifying on a test machine first."
		ewarn "  Start in complain mode:"
		ewarn "    aa-complain /etc/apparmor.d/usr.bin.arbor-daemon"
		ewarn "    aa-complain /etc/apparmor.d/usr.bin.arbor"
		ewarn ""
	fi
	if use systemd; then
		elog "Start the services:"
		elog "  systemctl enable --now arbor-daemon arbor"
	else
		elog "Start the services:"
		elog "  rc-service arbor-daemon start && rc-service arbor start"
		elog ""
		elog "To start at boot:"
		elog "  rc-update add arbor-daemon default && rc-update add arbor default"
	fi
}
