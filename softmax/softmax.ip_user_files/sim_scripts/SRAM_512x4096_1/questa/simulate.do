onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib SRAM_512x4096_opt

do {wave.do}

view wave
view structure
view signals

do {SRAM_512x4096.udo}

run -all

quit -force
