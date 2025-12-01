onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib gpio_key_opt

do {wave.do}

view wave
view structure
view signals

do {gpio_key.udo}

run -all

quit -force
