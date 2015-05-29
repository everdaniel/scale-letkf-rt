name = '850_temp'

convert = '/data/opt/ImageMagick/6.9.1-3/bin/convert'
pngquant = '/data/opt/pngquant/2.4.0/bin/pngquant'

'settime.gs'
rcl = sublin(result, 1)
tt = subwrd(rcl, 1)
tfilename = subwrd(rcl, 2)
tstring = subwrd(rcl, 3)
trun = subwrd(rcl, 4)
'setrgb.gs'

outf = 'out/'name'_'tfilename
'enable print 'outf'.gmf'


'set mpdset hires'
'set display color white'
'set map 1 1 3'
'set grid on 3 1'
'set xlopts 1 4 0.12'
'set ylopts 1 4 0.12'
*'set parea 0 11 0.8 7.8'
'c'
'set grads off'

*'set lon 85 155'
*'set lat 0 45'
'set lev 850'
'set xlint 10'
'set ylint 10'

'set gxout shaded'
'set clevs -1e9 70 80 90'
'set ccols 17 0 211 212 213'
'd const(rh, -1e10, -u)'
'cbarn.gs 0.8 0 5.5 0.7 0.8 1'

'set gxout barb'
'set ccolor 1'
'set cthick 3'
'set digsiz 0.042'
'd skip(u*1.94384,20);v*1.94384'

'set gxout contour'
'set clevs 3 9'
'set ccolor 201'
'set cthick 4'
'set cstyle 3'
'set clab off'
'd tk-273.15'
'set clevs -45 -39 -33 -27 -21 -15 -9 -3'
'set ccolor 203'
'set cthick 4'
'set cstyle 3'
'set clab off'
'd tk-273.15'
'set clevs 6 12 15 18 21 24 27 30 33 36 39 42 45 48'
'set ccolor 201'
'set cthick 4'
'set cstyle 3'
'set clab on'
'd tk-273.15'
'set clevs 0'
'set ccolor 202'
'set cthick 6'
'set cstyle 3'
'set clab on'
'd tk-273.15'
'set clevs -48 -42 -36 -30 -24 -18 -12 -6'
'set ccolor 203'
'set cthick 4'
'set cstyle 3'
'set clab on'
'd tk-273.15'


'set string 1 c 5'
'set strsiz 0.11 0.15'
'draw string 5.5 7.58 `1850 hPa RH (%) / Temp (C) / Wind (kts)  [ Run: `0'trun'`1 | VT: `0'tstring'`1 ]'

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

