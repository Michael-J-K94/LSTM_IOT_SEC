onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib BRAM_128x2048_opt

do {wave.do}

view wave
view structure
view signals

do {BRAM_128x2048.udo}

run -all

quit -force
