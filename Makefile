version=$(shell TZ=UTC date +'%y%m%d.%H%M')
ROOT_PATH=$(shell pwd)

clean-all: clean-deps
	rm -fr .env-ready

clean-deps: clean
	rm -fr nuttxspace

clean:
	rm -fr release
	make -C nuttxspace/nuttx distclean

nuttxspace: .env-ready
	bash script/toolchain.sh -d
	rm -fr nuttxspace/apps/examples/lvgldemo
	ln -s ${ROOT_PATH}/src ${ROOT_PATH}/nuttxspace/apps/examples/lvgldemo

.env-ready:
	bash script/toolchain.sh -s
	touch .env-ready

release:
	mkdir -p release

release/stm32f746g-disc.bin: release nuttxspace
	nuttxspace/nuttx/tools/configure.sh -l stm32f746g-disco:lvgl
	cp config/stm32f746g-disco.config nuttxspace/nuttx/.config
	make -C nuttxspace/nuttx
	mv nuttxspace/nuttx/nuttx.bin release/stm32f746g-disc.bin
	mv nuttxspace/nuttx/nuttx.hex release/stm32f746g-disc.hex
	make -C nuttxspace/nuttx distclean

release/sim-linux: release nuttxspace
	nuttxspace/nuttx/tools/configure.sh -l sim:lvgl
	cp config/sim-linux.config nuttxspace/nuttx/.config
	make -C nuttxspace/nuttx
	mv nuttxspace/nuttx/nuttx release/sim-linux
	make -C nuttxspace/nuttx distclean

release/sim-win: release nuttxspace
	nuttxspace/nuttx/tools/configure.sh -c sim:lvgl
	cp config/sim-cygwin.config nuttxspace/nuttx/.config
	make -C nuttxspace/nuttx
	mv nuttxspace/nuttx/nuttx release/sim-win
	make -C nuttxspace/nuttx distclean

release/sim-macos: release nuttxspace
	nuttxspace/nuttx/tools/configure.sh -m sim:lvgl
	cp config/sim-macos.config nuttxspace/nuttx/.config
	make -C nuttxspace/nuttx
	mv nuttxspace/nuttx/nuttx release/sim-win
	make -C nuttxspace/nuttx distclean

test: nuttxspace
	echo "not implement"

build: release/stm32f746g-disc.bin release/sim-linux

nuttx-list:
	cd nuttxspace/nuttx && ./tools/configure.sh -L

version:
	git tag ${version}
	git push origin ${version}
