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
IUSE="openrc systemd"
REQUIRED_USE="|| ( openrc systemd )"

RDEPEND="
	${PYTHON_DEPS}
	dev-python/fastapi[${PYTHON_USEDEP}]
	dev-python/uvicorn[${PYTHON_USEDEP}]
	dev-python/websockets[${PYTHON_USEDEP}]
	sys-apps/portage[${PYTHON_USEDEP}]
"

BDEPEND="
	${PYTHON_DEPS}
	dev-python/setuptools[${PYTHON_USEDEP}]
"

EGIT_CHECKOUT_DIR="${WORKDIR}/${P}"
S="${WORKDIR}/${P}/backend"

src_install() {
	distutils-r1_src_install

	dodoc "${EGIT_CHECKOUT_DIR}/README.md"
	insinto /usr/share/arbor/frontend
	doins -r "${EGIT_CHECKOUT_DIR}/frontend/alpine/."

	# OpenRC service
	use openrc && newinitd "${EGIT_CHECKOUT_DIR}/openrc/arbor-daemon" arbor-daemon
	use openrc && newinitd "${EGIT_CHECKOUT_DIR}/openrc/arbor"        arbor

	# systemd units
	use systemd && systemd_dounit "${EGIT_CHECKOUT_DIR}/systemd/arbor-daemon.service"
	use systemd && systemd_dounit "${EGIT_CHECKOUT_DIR}/systemd/arbor.service"

	# Config/setup helper
	insinto /usr/share/arbor
	doins "${EGIT_CHECKOUT_DIR}/config/setup.sh"
	fperms 0755 /usr/share/arbor/setup.sh
}

pkg_postinst() {
	elog "Arbor has been installed."
	elog ""
	elog "Run the first-time setup (creates user, TLS cert and token):"
	elog "  bash /usr/share/arbor/setup.sh"
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
