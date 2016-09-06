name = 'sfc_aprcp'

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
'set z 1'
'set xlint 10'
'set ylint 10'

'set gxout shaded'
'set clevs -1e9 0.1 1 3 6 10 15 25 40 60 80 100 120 150 200 300'
'set ccols 17 0 190 191 192 193 181 182 183 184 185 186 187 188 195 196 197'
if (tt = 1)
  'd const(rain-1e8, -1e10, -u)'
else
  'd const((sum(rain+snow,t=2,t='tt'))*21600, -1e10, -u)'
endif
'cbarn.gs 0.8 0 5.5 0.7 0.8 1'


'set string 1 c 5'
'set strsiz 0.11 0.15'
'draw string 5.5 7.58 `1Accu precip (mm)  [ Run: `0'trun'`1 | VT: `0'tstring'`1 ]'

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

