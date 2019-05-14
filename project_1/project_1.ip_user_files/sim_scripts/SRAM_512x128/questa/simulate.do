onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib SRAM_512x128_opt

do {wave.do}

view wave
view structure
view signals

do {SRAM_512x128.udo}

run -all

quit -force
