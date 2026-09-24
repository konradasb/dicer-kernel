# dicer-kernel

The guest kernel for [Dicer](https://github.com/konradasb/dicer): Linux from
[kernel.org](https://www.kernel.org), configured to boot under Cloud
Hypervisor and Firecracker, with what Dicer's guests need.

## Using it

Import it into Dicer from the latest
[release](https://github.com/konradasb/dicer-kernel/releases/latest), with the
checksum from its `SHA256SUMS`:

```console
$ sudo dicer kernel import linux-6.18 --arch x86_64 \
    --url https://github.com/konradasb/dicer-kernel/releases/download/v6.18.53-1/vmlinux-x86_64 \
    --sha256 <vmlinux-x86_64's checksum>
```

On arm64, use `--arch aarch64` and `Image-arm64`.

## What it is

- **Source:** the kernel.org release in [`kernel.env`](kernel.env), checked
  against its SHA-256.
- **Configuration:** [Cloud Hypervisor's](https://github.com/cloud-hypervisor/linux),
  in [`configs/`](configs), which boots under both hypervisors, with
  [`dicer.config`](dicer.config) on top: EROFS, overlayfs, vsock, netfilter and
  bridging for containers inside guests, and `/proc/config.gz`. The build fails
  if any of `dicer.config` does not make it into the kernel.

Each release carries the kernels, their final configurations, the kernel's
source, and `SHA256SUMS`, signed with cosign by the release workflow.

## Verifying a release

```console
cosign verify-blob SHA256SUMS \
  --bundle SHA256SUMS.sigstore.json \
  --certificate-identity https://github.com/konradasb/dicer-kernel/.github/workflows/build.yaml@refs/tags/v6.18.53-1 \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
sha256sum --check --ignore-missing SHA256SUMS
```

## Building

On Linux, for the machine's own architecture:

```console
./build.sh x86_64 out   # or arm64
```

It needs `bc`, `bison`, `flex`, `libelf-dev`, `libssl-dev` and a C toolchain.

## Releasing

A release is tagged `v<kernel version>-<build>`: `v6.18.53-1`, then
`v6.18.53-2` for a new build of the same kernel, such as a configuration
change.

1. Update `kernel.env` to the new kernel.org release and its SHA-256 from
   [`sha256sums.asc`](https://cdn.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc),
   or change `dicer.config`.
2. Merge it once CI has built both architectures.
3. Tag `main` and push the tag. The workflow builds, signs and publishes the
   release.
4. Point Dicer's documentation and install script at the new release.

Follow the kernel's long-term releases, and update when a new one is out.

## Licence

The scripts and workflow here are MIT licensed; see [LICENSE](LICENSE). The
kernel, and the configurations in `configs/`, which come from its source tree,
are GPL-2.0, as the kernel's source attached to each release says.
