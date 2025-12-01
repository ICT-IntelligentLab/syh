onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib gpio_interrupt_opt

do {wave.do}

view wave
view structure
view signals

do {gpio_interrupt.udo}

run -all

quit -force
