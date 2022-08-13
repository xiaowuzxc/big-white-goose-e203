onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+mmcm_disp -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.mmcm_disp xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {mmcm_disp.udo}

run -all

endsim

quit -force
