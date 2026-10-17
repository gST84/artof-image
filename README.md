# ARTOF Raspberry Pi image

Builds a ready-to-flash SD card image of [ARTOF](https://artof-ilvo.github.io) for the **Raspberry Pi 4 and 5** (Raspberry Pi OS Lite 64-bit, Debian trixie), with [pi-gen](https://github.com/RPi-Distro/pi-gen).

The image installs ARTOF the same way `artof-core/install.sh` does on the robot:

- `artof-core` is compiled for ARM64 and installed in `/usr/bin` (`libsnap7.so` in `/usr/lib/ilvo`), with the default data in `/var/lib/ilvo`.
- `ilvo-robotics.service` runs `ilvo-system-manager`, which starts the processes and the addons (artof-system, node-red) as Docker containers.
- Redis (`redis-stack-server`) runs in Docker on port 6379.

The Docker images (Redis, artof-system, node-red) are stored in the image and loaded on the first boot, so ARTOF also works without internet.

## Using the image

1. Download `artof-*.img.xz` from the GitHub release or the workflow run's artifacts.
2. Flash it with [Raspberry Pi Imager](https://www.raspberrypi.com/software/): *Choose OS → Use custom*. In the OS customisation, set the user, password, Wi-Fi and enable SSH.
3. Boot the Pi. The first boot loads the Docker images and takes a few minutes longer.
4. Open `http://artof.local` (or the Pi's IP address) for the ARTOF web interface.

The default settings run the simulation (`pc.simulation.active`), so the interface works without a robot attached.

Check the first boot and the services with:

```bash
systemctl status artof-firstboot ilvo-robotics
journalctl -u ilvo-robotics -f
docker ps
```

## Building

### GitHub Actions (recommended)

Run the **Build Raspberry Pi image** workflow (*Actions → Run workflow*). By default it uses the forks `gST84/artof-core` and `gST84/artof-system` (`main`); the repositories and the artof-core branch can be changed when starting the workflow. It builds natively on an ARM64 runner and uploads the image as an artifact. Pushing a `v*` tag also attaches the image to a GitHub release.

### Locally

Needs Docker. On a non-ARM machine everything is emulated, which takes several hours.

```bash
./build.sh
```

By default it uses `../artof-core` and `../artof-system` (fallback when Docker Hub has no ARM64 artof-system image); override them with `ARTOF_CORE_SRC` and `ARTOF_SYSTEM_SRC`. The image ends up in `deploy/`.

## Layout

- `config` – pi-gen settings (hostname `artof`, Belgian keyboard, Europe/Brussels).
- `stage-artof/` – pi-gen stage on top of Raspberry Pi OS Lite:
  - `00-packages` – Docker, build tools and the artof-core dependencies.
  - `01-artof-core` – compiles and installs artof-core.
  - `02-artof-services` – Docker images, first-boot service and `ilvo-robotics.service`.
- `build.sh` – fetches pi-gen, adds the stage, the artof-core source and the Docker images, and runs `build-docker.sh`.
