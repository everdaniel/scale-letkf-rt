name = 'sfc_temp'

convert = '/data/opt/ImageMagick/6.9.1-3/bin/convert'
pngquant = '/data/opt/pngquant/2.4.0/bin/pngquant'

'settime.gs'
rcl = sublin(result, 1)
tt = subwrd(rcl, 1)
tfilename = subwrd(rcl, 2)
tstring = subwrd(rcl, 3)
trun = subwrd(rcl, 4)
'setrgb_2.gs'

outf = 'out/'name'_'tfilename
'enable print 'outf'.gmf'


'set mpdset hires'
'set display color white'
'set map 22 1 3'
'set grid on 3 1'
'set xlopts 1 4 0.12'
'set ylopts 1 4 0.12'
*'set parea 0 11 0.8 7.8'
'c'
'set grads off'

*'set lon 85 155'
*'set lat 0 45'
'set z 1'
'set xlint 10'
'set ylint 10'

'set gxout shaded'
'set clevs -1e9 -21 -18 -15 -12 -9 -6 -3 0 3 6 9 12 15 18 21 24 27 30 33 36 39'
'set ccols 17 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61'
'd const(tsfc-273.15, -1e10, -u)'
'cbarn.gs 0.8 0 5.5 0.7 0.8 1'

'set gxout contour'
'set cint 9'
'set ccolor 16'
'set cthick 2'
'set clopts 1'
'set cstyle 1'
'set clab masked'
'd tsfc-273.15'


'set string 1 c 5'
'set strsiz 0.11 0.15'
'draw string 5.5 7.58 `1Sfc skin temp (C)  [ Run: `0'trun'`1 | VT: `0'tstring'`1 ]'

'print'
'disable print'

'!gxeps -cR -i 'outf'.gmf'
'!'convert' -density 400x382 -trim +antialias +matte 'outf'.eps 'outf'_tmp.png'
'!'convert' -resize 25% 'outf'_tmp.png 'outf'_tmp2.png'
*'!'convert' -resize 25% 'outf'_tmp.png 'outf'.gif'
'!'pngquant' --force --quality 60-75 'outf'_tmp2.png -o 'outf'.png'
'!rm -f 'outf'.gmf'
'!rm -f 'outf'_tmp.png'
'!rm -f 'outf'_tmp2.png'
*'!rm -f 'outf'_tmp.gif'

