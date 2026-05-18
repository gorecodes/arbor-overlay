# arbor-overlay

Gentoo overlay for [Arbor](https://github.com/gorecodes/Arbor) — a local web UI for managing Portage.

## Add the overlay

```bash
eselect repository add arbor-overlay git https://github.com/gorecodes/arbor-overlay.git
emaint sync -r arbor-overlay
```

## Install

Choose your init system via USE flag, then install:

```bash
echo 'app-admin/arbor systemd' >> /etc/portage/package.use/arbor   # or: openrc
ACCEPT_KEYWORDS="**" emerge app-admin/arbor
```

## First-time setup

After installation, run the setup script to create the system user, TLS certificate and access token:

```bash
bash /usr/share/arbor/setup.sh
```

Then start the services.

**OpenRC:**
```bash
rc-service arbor-daemon start
rc-service arbor start
```

To start at boot:
```bash
rc-update add arbor-daemon default
rc-update add arbor default
```

**systemd:**
```bash
systemctl enable --now arbor-daemon arbor
```

Arbor will be available at `https://localhost:8443`.
