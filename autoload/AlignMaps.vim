" AlignMaps.vim : support functions for AlignMaps
"   Author: Charles E. Campbell
"     Date: Apr 24, 2023
"  Version: 46h	ASTRO-ONLY
" Copyright:    Copyright (C) 2020 Charles E. Campbell {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               Align.vim is provided *as is* and comes with no warranty
"               of any kind, either expressed or implied. By using this
"               plugin, you agree that in no event will the copyright
"               holder be liable for any damages resulting from the use
"redraw!|call DechoSep()|call inputsave()|call input("Press <cr> to continue")|call inputrestore()
" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_AlignMaps")
 finish
endif
let g:loaded_AlignMaps= "v46h"
let s:keepcpo         = &cpo
set cpo&vim

" ---------------------------------------------------------------------
" Debugging Support:
"if !exists("g:loaded_Decho")              " Decho
" runtime plugin/Decho.vim                 " Decho
"endif                                     " Decho
"if !exists("g:loaded_cecutil")            " Decho
" runtime AsNeeded/cecutil.vim             " Decho
"endif                                     " Decho
"DechoTabOn
"call Decho("AlignMaps loaded")

" =====================================================================
" Functions: {{{1

" ---------------------------------------------------------------------
" AlignMaps#WrapperStart: {{{2
fun! AlignMaps#WrapperStart(vis) range
"  call Dfunc("AlignMaps#WrapperStart(vis=".a:vis.")")

  if a:vis
   keepj norm! '<ma'>
  endif

  if line("'y") == 0 || line("'z") == 0 || !exists("s:alignmaps_wrapcnt") || s:alignmaps_wrapcnt <= 0
"   call Decho("wrapper initialization")
   let s:alignmaps_wrapcnt    = 1
   let s:alignmaps_keepgd     = &gdefault
   let s:alignmaps_keepsearch = @/
   let s:alignmaps_keepch     = &ch
   let s:alignmaps_keepmy     = SaveMark("'y")
   let s:alignmaps_keepmz     = SaveMark("'z")
   let s:alignmaps_posn       = SaveWinPosn(0)
   if has("folding")
    let s:foldlevel            = &foldlevel
    norm! zR
   endif
   " set up fencepost blank line : appends a line after current line, then current line is incremented
   put =''
   if line("'a") == 0
	echoerr "Need to set mark-a or use visual-line mode (V)"
"  call Dret("AlignMaps#WrapperStart : alignmaps_wrapcnt=".s:alignmaps_wrapcnt." my=".line("'y")." mz=".line("'z"))
	return
   endif
   keepj norm! mz'a
   " set up fencepost blank line : prepends a line before 'a, cursor moves to new blank line
   put! =''
   ky
   let s:alignmaps_zline = line("'z")
   exe "keepj 'y,'zs/@/ÿ/ge"
  else
"   call Decho("embedded wrapper")
   let s:alignmaps_wrapcnt    = s:alignmaps_wrapcnt + 1
   keepj norm! 'yjma'zk
  endif

  " change some settings to align-standard values
  set nogd
  set ch=2
  AlignPush
  keepj norm! 'zk
"  call Dret("AlignMaps#WrapperStart : alignmaps_wrapcnt=".s:alignmaps_wrapcnt." my=".line("'y")." mz=".line("'z"))
endfun

" ---------------------------------------------------------------------
" AlignMaps#WrapperEnd:	{{{2
fun! AlignMaps#WrapperEnd() range
"  call Dfunc("AlignMaps#WrapperEnd() alignmaps_wrapcnt=".s:alignmaps_wrapcnt." my=".line("'y")." mz=".line("'z"))

  " remove trailing white space introduced by whatever in the modification zone
  keepj 'y,'zs/ \+$//e

  " restore AlignCtrl settings
  AlignPop

  let s:alignmaps_wrapcnt= s:alignmaps_wrapcnt - 1
  if s:alignmaps_wrapcnt <= 0
   " initial wrapper ending
   exe "keepj 'y,'zs/ÿ/@/ge"

   " if the 'z line hasn't moved, then go ahead and restore window position
   let zstationary= s:alignmaps_zline == line("'z")

   " remove fencepost blank lines.
   " restore 'a
   keepj norm! 'yjmakdd'zdd

   " restore folding prior to restoring position in window
   if has("folding")
    let &foldlevel = s:foldlevel
	sil! norm! zCzv
   endif

   " restore original 'y, 'z, and window positioning
   if exists("s:alignmaps_posn")
	call RestoreMark(s:alignmaps_keepmy)
	call RestoreMark(s:alignmaps_keepmz)
	if zstationary > 0
	 call RestoreWinPosn(s:alignmaps_posn)
" "    call Decho("restored window positioning")
	endif
   endif

   " restoration of options
   let &gd = s:alignmaps_keepgd
   let &ch = s:alignmaps_keepch
   let @/  = s:alignmaps_keepsearch

   " remove script variables
   unlet s:alignmaps_keepch
   unlet s:alignmaps_keepsearch
   unlet s:alignmaps_keepmy
   unlet s:alignmaps_keepmz
   unlet s:alignmaps_keepgd
   unlet s:alignmaps_posn
  endif

"  call Dret("AlignMaps#WrapperEnd : alignmaps_wrapcnt=".s:alignmaps_wrapcnt." my=".line("'y")." mz=".line("'z"))
endfun

" ---------------------------------------------------------------------
" AlignMaps#StdAlign: some semi-standard align calls {{{2
fun! AlignMaps#StdAlign(mode,...) range
"  call Dfunc("AlignMaps#StdAlign(mode=".a:mode.")")
  if a:0 == 2
   let alignchar= a:1
  else
   let alignchar= '@'
  endif
  if     a:mode == 1
   " align on @
"   call Decho("align on @")
   exe "AlignCtrl mIp1P1=l ".alignchar
   'a,.Align
  elseif a:mode == 2
   " align on @, retaining all initial white space on each line
"   call Decho("align on @, retaining all initial white space on each line")
   exe "AlignCtrl mWp1P1=l ".alignchar
   'a,.Align
  elseif a:mode == 3
   " like mode 2, but ignore /* */-style comments
"   call Decho("like mode 2, but ignore /* */-style comments")
   AlignCtrl v ^\s*/[/*]
   exe "AlignCtrl mWp1P1=l ".alignchar
   'a,.Align
  else
   echoerr "(AlignMaps) AlignMaps#StdAlign doesn't support mode#".a:mode
  endif
"  call Dret("AlignMaps#StdAlign")
endfun

" ---------------------------------------------------------------------
" AlignMaps#CharJoiner: joins lines which end in the given character (spaces {{{2
"             at end are ignored)
fun! AlignMaps#CharJoiner(chr)
"  call Dfunc("AlignMaps#CharJoiner(chr=".a:chr.")")
  let aline = line("'a")
  let rep   = line(".") - aline
  while rep > 0
  	keepj norm! 'a
  	while match(getline(aline),a:chr . "\s*$") != -1 && rep >= 0
  	  " while = at end-of-line, delete it and join with next
  	  keepj norm! 'a$
  	  j!
  	  let rep = rep - 1
  	endwhile
  	" update rep(eat) count
  	let rep = rep - 1
  	if rep <= 0
  	  " terminate loop if at end-of-block
  	  break
  	endif
  	" prepare for next line
  	keepj norm! jma
  	let aline = line("'a")
  endwhile
"  call Dret("AlignMaps#CharJoiner")
endfun

" ---------------------------------------------------------------------
" AlignMaps#Equals: supports \t= and \T= {{{2
fun! AlignMaps#Equals() range
"  call Dfunc("AlignMaps#Equals()")
  keepj 'a,'zs/\s\+\([.*/+\-%|&\~^]\==\)/ \1/e
  keepj 'a,'zs@ \+\([.*/+\-%|&\~^]\)=@\1=@ge
  keepj 'a,'zs/==/\="\<Char-0x0f>\<Char-0x0f>"/ge
  keepj 'a,'zs/\([!<>:]\)=/\=submatch(1)."\<Char-0x0f>"/ge
  keepj norm g'zk
  AlignCtrl mIp1P1=l =
  AlignCtrl g =
  keepj 'a,'z-1Align
  keepj 'a,'z-1s@\([.*/%|&\~^!=]\)\( \+\)=@\2\1=@ge
  keepj 'a,'z-1s@[^+\-]\zs\([+\-]\)\( \+\)=@\2\1=@ge
  keepj 'a,'z-1s/\( \+\);/;\1/ge
  if &ft == "c" || &ft == "cpp"
"   call Decho("exception for ".&ft)
   keepj 'a,'z-1v/^\s*\/[*/]/s/\/[*/]/@&@/e
   keepj 'a,'z-1v/^\s*\/[*/]/s/\*\//@&/e
   if exists("g:mapleader")
    exe "keepj norm 'zk"
    call AlignMaps#StdAlign(1)
   else
    exe "keepj norm 'zk"
    call AlignMaps#StdAlign(1)
   endif
   keepj 'y,'zs/^\(\s*\) @/\1/e
  endif
  keepj 'a,'z-1s/\%x0f/=/ge
  keepj 'y,'zs/ @//eg
"  call Dret("AlignMaps#Equals")
endfun

" ---------------------------------------------------------------------
" AlignMaps#Afnc: useful for splitting one-line function beginnings {{{2
"            into one line per argument format
fun! AlignMaps#Afnc()
"  call Dfunc("AlignMaps#Afnc()")

  " keep display quiet
  let chkeep = &l:ch
  let gdkeep = &l:gd
  let wwkeep = &l:ww
  let vekeep = &ve
  setlocal ch=2 nogd ww=b,s,<,>,[,]
  set ve=

  " will use marks y,z ; save current values
  let makeep = SaveMark("'a")
  let mykeep = SaveMark("'y")
  let mzkeep = SaveMark("'z")

  " Find beginning of function -- be careful to skip over comments
"  call Decho("find beginning of function (skip comments)")
  let cmmntid  = synIDtrans(hlID("Comment"))
  let stringid = synIDtrans(hlID("String"))
  exe "keepj norm! ]]"
  while search(")","bW") != 0
"   call Decho("..searching for ): line=".line(".")." col=".col("."))
   let parenid= synIDtrans(synID(line("."),col("."),1))
   if parenid != cmmntid && parenid != stringid
   	break
   endif
  endwhile
"  call Decho("beginning of function found: line#".line("."))
  keepj norm! %my
  keepj s/(\s*\(\S\)/(\r  \1/e
  exe "keepj norm! `y%"
  keepj s/)\s*\(\/[*/]\)/)\r\1/e
  exe "keepj norm! `y%mz"
  keepj 'y,'zs/\s\+$//e
  keepj 'y,'zs/^\s\+//e
  keepj 'y+1,'zs/^/  /

  " insert newline after every comma only one parenthesis deep
"  call Decho("insert newline after every comma only one parenthesis deep")
  exe "sil! keepj norm! `y\<right>h"
  let parens   = 1
  let cmmnt    = 0
  let cmmntline= -1
  while parens >= 1
   exe "keepj norm! ma \"ay`a\<right>"
"   call Decho("..parens=".parens." cmmnt=".cmmnt." cmmntline=".cmmntline." line(.)=".line(".").":".col(".")." @a<".@a."> line<".getline(".").">")
   if @a == "("
    let parens= parens + 1
   elseif @a == ")"
    let parens= parens - 1

   " comment bypass:  /* ... */  or //...
   elseif cmmnt == 0 && @a == '/'
    let cmmnt= 1
   elseif cmmnt == 1
	if @a == '/'
	 let cmmnt    = 2   " //...
	 let cmmntline= line(".")
	elseif @a == '*'
	 let cmmnt= 3   " /*...
	else
	 let cmmnt= 0
	endif
   elseif cmmnt == 2 && line(".") != cmmntline
	let cmmnt    = 0
	let cmmntline= -1
   elseif cmmnt == 3 && @a == '*'
	let cmmnt= 4
   elseif cmmnt == 4
	if @a == '/'
	 let cmmnt= 0   " ...*/
	elseif @a != '*'
	 let cmmnt= 3
	endif

   elseif @a == "," && parens == 1 && cmmnt == 0
	exe "keepj norm! i\<CR>\<Esc>"
   endif
  endwhile
"  call Decho("done inserting newline after every comma")
  sil! keepj norm! `y%mz%
  sil! keepj 'y,'zg/^\s*$/d

  " perform substitutes to mark fields for Align
"  call Decho("perform substitutes to mark fields for Align")
  sil! keepj 'y+1,'zv/^\//s/^\s\+\(\S\)/  \1/e
  sil! keepj 'y+1,'zv/^\//s/\(\S\)\s\+/\1 /eg
  sil! keepj 'y+1,'zv/^\//s/\* \+/*/ge
  sil! keepj 'y+1,'zv/^\//s/\w\zs\s*\*/ */ge
  "                                                 func
  "                    ws  <- declaration   ->    <-ptr  ->   <-var->    <-[array][]    ->   <-glop->      <-end->
  sil! keepj 'y+1,'zv/^\//s/^\s*\(\(\K\k*\s*\)\+\)\s\+\([(*]*\)\s*\(\K\k*\)\s*\(\(\[.\{-}]\)*\)\s*\(.\{-}\)\=\s*\([,)]\)\s*$/  \1@#\3@\4\5@\7\8/e
  sil! keepj 'y+1,'z+1g/^\s*\/[*/]/norm! kJ
  sil! keepj 'y+1,'z+1s%/[*/]%@&@%ge
  sil! keepj 'y+1,'z+1s%*/%@&%ge
  AlignCtrl mIp0P0=l @
  sil! keepj 'y+1,'zAlign
  sil! keepj 'y,'zs%@\(/[*/]\)@%\t\1 %e
  sil! keepj 'y,'zs%@\*/% */%e
  sil! keepj 'y,'zs/@\([,)]\)/\1/
  sil! keepj 'y,'zs/@/ /
  AlignCtrl mIlrp0P0= # @
  sil! keepj 'y+1,'zAlign
  sil! keepj 'y+1,'zs/#/ /
  sil! keepj 'y+1,'zs/@//
  sil! keepj 'y+1,'zs/\(\s\+\)\([,)]\)/\2\1/e
  sil! keepj 'y,'zs/)\s\+(/)(/ge

  ") (needed to ignore closing parenthesese above)
  norm! 'yma'z
  norm \acom

  " Restore
"  call Decho("Restore marks a y z  and options ch gd ww ve")
  call RestoreMark(makeep)
  call RestoreMark(mykeep)
  call RestoreMark(mzkeep)
  let &l:ch= chkeep
  let &l:gd= gdkeep
  let &l:ww= wwkeep
  let &ve= vekeep

"  call Dret("AlignMaps#Afnc")
endfun

" ---------------------------------------------------------------------
"  AlignMaps#FixMultiDec: converts a   type arg,arg,arg;   line to multiple lines {{{2
fun! AlignMaps#FixMultiDec()
"  call Dfunc("AlignMaps#FixMultiDec()")

  " save register x
  let xkeep   = @x
  let curline = getline(".")
"  call Decho("curline<".curline.">")

  let @x=substitute(curline,'^\(\s*[a-zA-Z_ \t][a-zA-Z0-9<>_ \t]*\)\s\+[(*]*\h.*$','\1','')
"  call Decho("@x<".@x.">")

  " transform line
  exe 'keepj s/,/;\r'.@x.' /ge'

  "restore register x
  let @x= xkeep

"  call Dret("AlignMaps#FixMultiDec : my=".line("'y")." mz=".line("'z"))
endfun

" ---------------------------------------------------------------------
" AlignMaps#AlignMapsClean: this function removes the AlignMaps plugin {{{2
fun! AlignMaps#AlignMapsClean()
"  call Dfunc("AlignMaps#AlignMapsClean()")
  for home in split(&rtp,',') + ['']
"   call Decho("considering home<".home.">")
   if isdirectory(home)
	if filereadable(home."/autoload/AlignMaps.vim")
"	 call Decho("deleting ".home."/autoload/AlignMaps.vim")
	 call delete(home."/autoload/AlignMaps.vim")
	endif
	if filereadable(home."/plugin/AlignMapsPlugin.vim")
"	 call Decho("deleting ".home."/plugin/AlignMapsPlugin.vim")
	 call delete(home."/plugin/AlignMapsPlugin.vim")
	endif
   endif
  endfor
"  call Dret("AlignMaps#AlignMapsClean")
endfun

" ---------------------------------------------------------------------
" AlignMaps#Vis: interfaces with visual maps {{{2
fun! AlignMaps#Vis(nmapname) range
"  call Dfunc("AlignMaps#VisCall(nmapname<".a:nmapname.">) ".a:firstline.",".a:lastline)

  let amark= SaveMark("a")
  exe a:firstline
  ka
  exe a:lastline

"  call Decho("exe norm ".g:Align_mapleader.a:nmapname)
  exe " norm ".g:Align_mapleader.a:nmapname

  call RestoreMark(amark)
"  call Dret("AlignMaps#VisCall")
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
