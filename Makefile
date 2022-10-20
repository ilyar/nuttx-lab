clean-all: clean-deps clean

clean-deps:
	rm -fr nuttxspace
	rm -fr .deps-ready

clean:
	rm -fr release

.deps-ready:
	bash script/toolchain.sh -s
	touch .deps-ready

release/stm32f746g-disc.bin: .deps-ready
	cd nuttxspace/nuttx && ./tools/configure.sh -l stm32f746g-disco:lvgl
	cd nuttxspace/nuttx && make
	mkdir -p release
	mv nuttxspace/nuttx/nuttx.bin release/stm32f746g-disc.bin
	mv nuttxspace/nuttx/nuttx.hex release/stm32f746g-disc.hex
	cd nuttxspace/nuttx && make distclean

release/nuttx: .deps-ready
	cd nuttxspace/nuttx && ./tools/configure.sh -l sim:lvgl
	cd nuttxspace/nuttx && make
	mkdir -p release
	mv nuttxspace/nuttx/nuttx release/nuttx
	cd nuttxspace/nuttx && make distclean

test: .deps-ready
	echo "not implement"

release: release/stm32f746g-disc.bin release/nuttx

nuttx-list:
	cd nuttxspace/nuttx && ./tools/configure.sh -L

lab:
	make -C src/ APPDIR=$(shell pwd)/nuttxspace/apps