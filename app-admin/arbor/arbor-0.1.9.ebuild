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
IUSE="openrc systemd"
REQUIRED_USE="|| ( openrc systemd )"

RDEPEND="
	${PYTHON_DEPS}
	dev-python/fastapi[${PYTHON_USEDEP}]
	dev-python/qrcode[${PYTHON_USEDEP}]
	dev-python/uvicorn[${PYTHON_USEDEP}]
	dev-python/websockets[${PYTHON_USEDEP}]
	sys-apps/portage[${PYTHON_USEDEP}]
"

BDEPEND="
	${PYTHON_DEPS}
	dev-python/setuptools[${PYTHON_USEDEP}]
"

S="${WORKDIR}/Arbor-${PV}/backend"

src_install() {
	distutils-r1_src_install

	dodoc "${WORKDIR}/Arbor-${PV}/README.md"
	insinto /usr/share/arbor/frontend
	doins -r "${WORKDIR}/Arbor-${PV}/frontend/alpine/."

	use openrc && newinitd "${WORKDIR}/Arbor-${PV}/openrc/arbor-daemon" arbor-daemon
	use openrc && newinitd "${WORKDIR}/Arbor-${PV}/openrc/arbor" arbor

	use systemd && systemd_dounit "${WORKDIR}/Arbor-${PV}/systemd/arbor-daemon.service"
	use systemd && systemd_dounit "${WORKDIR}/Arbor-${PV}/systemd/arbor.service"

	insinto /usr/share/arbor
	doins "${WORKDIR}/Arbor-${PV}/config/setup.sh"
	fperms 0755 /usr/share/arbor/setup.sh
}

pkg_postinst() {
	elog "Arbor has been installed."
	elog ""
	elog "Run the first-time setup to bootstrap the initial local owner user:"
	elog "  bash /usr/share/arbor/setup.sh"
	elog ""
	elog "Important changes in this release:"
	elog "  - local-first bootstrap now defaults to plain HTTP on 127.0.0.1:8443"
	elog "  - /etc/arbor/arbor.env now uses ARBOR_TLS=0 by default"
	elog "  - Arbor no longer generates a self-signed cert during setup"
	elog "  - enable ARBOR_TLS=1 only when you want Arbor itself to serve HTTPS"
	elog "  - rerun setup.sh after install/upgrade so owner bootstrap and runtime files are refreshed"
	elog ""
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
