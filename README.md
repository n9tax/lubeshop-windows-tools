# lubeshop-windows-tools

Prebuilt **native Windows (x86_64)** binaries for the Unix disk-image tools that
[The Lube Shop](https://github.com/n9tax/lubeshop) drives but which have no Windows
package. The app's installer (`WinSource::Bundle` in `crates/gwm-core/src/tools.rs`)
downloads the zips published here into `%LOCALAPPDATA%\lubeshop\bin`.

This repo is **public** so those downloads work anonymously — the main lubeshop
repo is private, and GitHub requires auth to fetch private-repo release assets.

## What's here

| Zip | Tools | Built from |
|-----|-------|------------|
| `cpmtools-win64.zip` | `cpmls`, `cpmcp`, `cpmrm`, `mkfs.cpm` + `diskdefs` | cpmtools 2.23 vs libdsk 1.5.22 |
| `mtools-win64.zip` | `mdir`, `mcopy`, `mdel`, `mformat` (argv[0] copies of one static `mtools.exe`) | mtools 4.0.49 |

Binaries are statically linked (import only system DLLs — no mingw runtime to ship)
and cross-compiled on Linux with mingw-w64. The recipe is
[`build-cpmtools-win64.sh`](build-cpmtools-win64.sh); the [`build`](.github/workflows/build.yml)
workflow runs it and uploads to the **`windows-tools`** release (stable download
URLs). Trigger it manually or by pushing a `v*` tag.
