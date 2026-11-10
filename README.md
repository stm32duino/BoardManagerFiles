# BoardManagerFiles
Storage for Arduino Boards Manager JSON and package files for the [STM32](https://github.com/stm32duino/Arduino_Core_STM32) and [STM8](https://github.com/stm32duino/Arduino_Core_STM8) cores support.

For more information see the [Wiki](https://github.com/stm32duino/Arduino_Core_STM32/wiki/). Mainly the [Getting Started page](https://github.com/stm32duino/Arduino_Core_STM32/wiki/Getting-Started).

## Usage

In the Arduino IDE, add the following URL to `File > Preferences > Additional boards manager URLs`, then install the package from `Tools > Board > Boards Manager`:

```
https://github.com/stm32duino/BoardManagerFiles/raw/main/package_stmicroelectronics_index.json
```

## Repository content

| Path | Description |
|------|-------------|
| `package_stmicroelectronics_index.json` | Boards Manager index for the STM32 core (`STMicroelectronics:stm32`) listing every released core version, with URL, checksum, size, boards and tools dependencies (xPack GCC, OpenOCD, CMSIS, STM32Tools, ...). |
| `STM32/packages/` | Archived legacy core packages (`*.tar.bz2`). Current releases are hosted on the [Arduino_Core_STM32 releases](https://github.com/stm32duino/Arduino_Core_STM32/releases) page. |
| `STM32/tools/` | Archived legacy `STM32Tools` packages (per OS). |
| `STM32/src/` | Sources and scripts used to generate the packages and index entries (see below). |
| `STM8/` | Boards Manager index (`package_stm8_index.json`), package and tools for the STM8 core. |

## Package generation

`STM32/src/` contains three git submodules:

* `Arduino_Core_STM32`: the STM32 core.
* `Arduino_Tools`: the `STM32Tools` upload and flashing tools.
* `stm32_svd`: the STM32 SVD files.

Initialize them with:

```sh
git submodule update --init
```

Each submodule must be checked out on the tag to release. From `STM32/src`, the `Makefile` builds the archives and generates the matching index entry from `templates/`:

```sh
make core        # STM32-<version>.tar.bz2          + package_STM32_<version>_index.json
make tools       # STM32Tools-<version>-{windows,linux,mac}.tar.bz2 + package_STM32Tools_<version>_index.json
make stm32_svd   # STM32_SVD-<version>.tar.bz2      + package_STM32_SVD_<version>_index.json
make all         # all of the above
make clean       # remove generated archives and index files
```

The version is taken from `git describe --tags` of each submodule. The `core` and `tools` archives are moved to `STM32/packages/` and `STM32/tools/`; the generated `package_*_index.json` files (ignored by git) provide the entries (version, URL, checksum, size, boards list) to be merged into `package_stmicroelectronics_index.json`.

## Troubleshooting

If you have any issue to download/use a package, you could [file an issue on Github](https://github.com/stm32duino/BoardManagerFiles/issues/new).

Or submit a topic on the [stm32duino forum](https://www.stm32duino.com/):

 * questions on the [STM32 Core](https://www.stm32duino.com/viewforum.php?f=35)

 * bugs/enhancements on the [STM core: Bugs and enhancements](https://www.stm32duino.com/viewforum.php?f=38)
