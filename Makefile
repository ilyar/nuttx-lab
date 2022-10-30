version=$(shell TZ=UTC date +'%y%m%d.%H%M')
ROOT_PATH=$(shell pwd)

clean-all: clean-deps clean

clean-deps:
	rm -fr nuttxspace
	rm -fr .deps-ready

clean:
	rm -fr release
	make -C nuttxspace/nuttx distclean

.deps-ready:
	bash script/toolchain.sh -s
	rm -fr nuttxspace/apps/examples/lvgldemo
	ln -s ${ROOT_PATH}/src ${ROOT_PATH}/nuttxspace/apps/examples/lvgldemo
	touch .deps-ready

release/stm32f746g-disc.bin: .deps-ready
	nuttxspace/nuttx/tools/configure.sh -l stm32f746g-disco:lvgl
	cp config/stm32f746g-disco.config nuttxspace/nuttx/.config
	make -C nuttxspace/nuttx
	mkdir -p release
	mv nuttxspace/nuttx/nuttx.bin release/stm32f746g-disc.bin
	mv nuttxspace/nuttx/nuttx.hex release/stm32f746g-disc.hex
	make -C nuttxspace/nuttx distclean

release/sim-linux: release .deps-ready
	nuttxspace/nuttx/tools/configure.sh -l sim:lvgl
	cp config/sim-linux.config nuttxspace/nuttx/.config
	make -C nuttxspace/nuttx
	mkdir -p release
	mv nuttxspace/nuttx/nuttx release/sim-linux
	make -C nuttxspace/nuttx distclean

test: .deps-ready
	echo "not implement"

release: release/stm32f746g-disc.bin release/sim-linux

nuttx-list:
	cd nuttxspace/nuttx && ./tools/configure.sh -L

version:
	git tag ${version}
	git push origin ${version}
