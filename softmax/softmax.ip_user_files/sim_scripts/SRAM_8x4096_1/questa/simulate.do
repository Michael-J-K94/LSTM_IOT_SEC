onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib SRAM_8x4096_opt

do {wave.do}

view wave
view structure
view signals

do {SRAM_8x4096.udo}

run -all

quit -force
