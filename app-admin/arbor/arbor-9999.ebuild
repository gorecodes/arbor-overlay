# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11,12,13} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 git-r3

DESCRIPTION="Local Gentoo web UI for managing Portage"
HOMEPAGE="https://github.com/gorecodes/Arbor"

EGIT_REPO_URI="https://github.com/gorecodes/Arbor.git"
EGIT_BRANCH="main"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""

RDEPEND="
	${PYTHON_DEPS}
	dev-python/fastapi[${PYTHON_USEDEP}]
	dev-python/uvicorn[${PYTHON_USEDEP}]
	sys-apps/portage[${PYTHON_USEDEP}]
"

BDEPEND="
	${PYTHON_DEPS}
	dev-python/setuptools[${PYTHON_USEDEP}]
"

DOCS=( "${EGIT_CHECKOUT_DIR}/README.md" )

# git-r3 clones the full repo into EGIT_CHECKOUT_DIR (defaults to ${WORKDIR}/${P}).
# pyproject.toml lives in backend/, so S points there for distutils-r1.
# The frontend is still accessible at ${WORKDIR}/${P}/frontend/alpine/.
EGIT_CHECKOUT_DIR="${WORKDIR}/${P}"
S="${WORKDIR}/${P}/backend"

src_install() {
	distutils-r1_src_install

	# Frontend (static files — no build step needed)
	insinto /usr/share/arbor/frontend
	doins -r "${EGIT_CHECKOUT_DIR}/frontend/alpine/."

	# OpenRC services
	newinitd "${EGIT_CHECKOUT_DIR}/openrc/arbor-daemon" arbor-daemon
	newinitd "${EGIT_CHECKOUT_DIR}/openrc/arbor"        arbor

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
	elog "Then start the services:"
	elog "  rc-service arbor-daemon start"
	elog "  rc-service arbor start"
	elog ""
	elog "To start at boot:"
	elog "  rc-update add arbor-daemon default"
	elog "  rc-update add arbor default"
}
