onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib BRAM_16x512_opt

do {wave.do}

view wave
view structure
view signals

do {BRAM_16x512.udo}

run -all

quit -force
