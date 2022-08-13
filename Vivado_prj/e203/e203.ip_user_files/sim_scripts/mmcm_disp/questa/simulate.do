onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib mmcm_disp_opt

do {wave.do}

view wave
view structure
view signals

do {mmcm_disp.udo}

run -all

quit -force
