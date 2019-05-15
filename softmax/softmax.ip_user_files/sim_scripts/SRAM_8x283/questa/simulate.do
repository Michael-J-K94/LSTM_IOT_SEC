onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib SRAM_8x283_opt

do {wave.do}

view wave
view structure
view signals

do {SRAM_8x283.udo}

run -all

quit -force