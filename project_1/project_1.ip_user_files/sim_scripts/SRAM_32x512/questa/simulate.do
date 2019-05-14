onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib SRAM_32x512_opt

do {wave.do}

view wave
view structure
view signals

do {SRAM_32x512.udo}

run -all

quit -force
