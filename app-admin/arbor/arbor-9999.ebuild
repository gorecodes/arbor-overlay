# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11,12,13} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 git-r3 systemd

DESCRIPTION="Local Gentoo web UI for managing Portage"
HOMEPAGE="https://github.com/gorecodes/Arbor"

EGIT_REPO_URI="https://github.com/gorecodes/Arbor.git"
EGIT_BRANCH="main"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="apparmor logrotate openrc systemd"
REQUIRED_USE="|| ( openrc systemd )"

RDEPEND="
	${PYTHON_DEPS}
	dev-python/defusedxml[${PYTHON_USEDEP}]
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

EGIT_CHECKOUT_DIR="${WORKDIR}/${P}"
S="${WORKDIR}/${P}/backend"

src_install() {
	distutils-r1_src_install

	local _arbor="${WORKDIR}/${P}"

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
	elog "Arbor (live) installed."
	elog ""
	elog "Run first-time setup (system user, dirs, IPC key, owner account):"
	elog "  bash /usr/share/arbor/setup.sh"
	elog ""
	elog "--- Process hardening ---"
	elog "  The init scripts apply no_new_privs and a reduced capability bounding"
	elog "  set when setpriv is available (USE=setpriv on sys-apps/util-linux)."
	elog "  Without setpriv the services start with a warning but no capability drop."
	elog "    USE=setpriv emerge sys-apps/util-linux"
	elog ""
	if use logrotate; then
		elog "--- Log rotation ---"
		elog "  /etc/logrotate.d/arbor installed: daily, 10 MB threshold, 14 rotations."
		elog ""
	fi
	if use apparmor; then
		ewarn "--- AppArmor profiles (UNTESTED) ---"
		ewarn "  Installed to /etc/apparmor.d/ but NOT tested end-to-end."
		ewarn "  Start in complain mode before enforcing:"
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
