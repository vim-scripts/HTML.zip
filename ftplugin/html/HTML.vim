" ---- Author & Copyright: ---------------------------------------------- {{{1
"
" Author: Christian J. Robinson <infynity@onewest.net>
" URL:    http://www.infynity.spodzone.com/vim/HTML.shtml
"
" Original Author: Doug Renze  (See below.)
"
" I am going to assume I can put this entirely under the GPL, as the original
" author used the phrase "freely-distributable and freely-modifiable".
"
" Original Copyright should probably go to Doug Renze, my changes and
" additions are Copyrighted by me, on the dates marked in the ChangeLog.
"
" ----------------------------------------------------------------------------
"
" This program is free software; you can redistribute it and/or modify it
" under the terms of the GNU General Public License as published by the Free
" Software Foundation; either version 2 of the License, or (at your option)
" any later version.
"
" This program is distributed in the hope that it will be useful, but WITHOUT
" ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
" FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
" more details.
"
" Comments, questions or bug reports can be sent to infynity@onewest.net
" Make sure to say that your message is regarding the HTML.vim macros.  Also,
" I wouldn't mind knowing how you got a copy.
"
" ---- Original Author's Notes: ----------------------------------------------
"
" HTML Macros
"        I wrote these HTML macros for my personal use.  They're
"        freely-distributable and freely-modifiable.
"
"        If you do make any major additions or changes, or even just
"        have a suggestion for improvement, feel free to let me
"        know.  I'd appreciate any suggestions.
"
"        Credit must go to Eric Tilton, Carl Steadman and Tyler
"        Jones for their excellent book "Web Weaving" which was
"        my primary source.
"
"        The home-page for this set of macros is currently
"        located at: http://www.avalon.net/~drenze/vi/HTML-macros.html
"
"        Doug Renze
"        http://www.avalon.net/~drenze/
"        mailto:drenze@avalon.net
"
" ---- TODO: ------------------------------------------------------------ {{{1
" - Under Win32, make a mapping call the user's default browser instead of
"   just ;ie?  (:silent!!start rundll32 url.dll,FileProtocolHandler <URL/File>)
" - ;ns mapping for Win32 with "start netscape ..." ?
" ----------------------------------------------------------------------- }}}1


" ---- Initialization: -------------------------------------------------- {{{1

if version < 600
  echoerr "HTML.vim no longer supports Vim versions prior to 6."
  finish
endif

if ! exists("b:did_html_mappings")
let b:did_html_mappings = 1

" Save cpoptions and remove some junk that will throw us off (reset at the end
" of the script):
let savecpo = &cpoptions
set cpoptions&vim

setlocal matchpairs+=<:>

function! SetIfUnset(var,val)
  execute "let varisset = exists(\"g:" . a:var . "\")"
  if (varisset == 0)
    if (a:val == "-")
      execute "let g:" . a:var . "= \"\""
    else
      execute "let g:" . a:var . "= a:val"
    endif
  endif
endfunction

command! -nargs=+ SetIfUnset call SetIfUnset(<f-args>)

SetIfUnset html_bgcolor     #FFFFFF
SetIfUnset html_textcolor   #000000
SetIfUnset html_linkcolor   #0000EE
SetIfUnset html_alinkcolor  #FF0000
SetIfUnset html_vlinkcolor  #990066
SetIfUnset html_tag_case    uppercase
" No way to know sensible defaults here so just make sure the
" variables are set:
SetIfUnset html_authorname  -
SetIfUnset html_authoremail -

function! HTMLencodeString(string)
  let out = ''
  let c   = 0
  let len = strlen(a:string)

  while c < len
    let out = out . '&#' . char2nr(a:string[c]) . ';'
    let c = c + 1
  endwhile

  return out
endfunction

" ----------------------------------------------------------------------------

" Define the HTML mappings with the appropriate case:
" Args:
"  1 - String:  Which map command to run.
"  2 - String:  LHS of the map.
"  3 - String:  RHS of the map.
"  4 - Integer: Optional, applies only to visual maps when filetype indenting
"                is on.
"               Don't use this argument for maps that enter insert mode!
"                1: re-selects the region, moves down a line, and re-indents.
"                2: re-selects the region and re-indents.
function! HTMLmap(cmd, map, arg, ...)

  let arg = HTMLconvertCase(a:arg)

  if a:cmd =~ '^v' && a:0 >= 1 && a:1 >= 1
    execute a:cmd . " <buffer> <silent> " . a:map . " " . arg
      \ . "m':call HTMLreIndent(line(\"'<\"), line(\"'>\"), " . a:1 . ")<CR>``"
  else
    execute a:cmd . " <buffer> <silent> " . a:map . " " . arg
  endif

endfunction

" Convert special regions in a string to the appropriate case determined by
" g:html_tag_case
" Args:
"  1 - String: The string with the regions to convert surrounded by [{...}].
" Return Value:
"  The converted string.
function! HTMLconvertCase(str)
  if (! exists('g:html_tag_case')) || g:html_tag_case =~? 'u\(pper\(case\)\?\)\?' || g:html_tag_case == ''
    let str = substitute(a:str, '\(\[{\|}\]\)', '', 'g')
  elseif g:html_tag_case =~? 'l\(ower\(case\)\?\)\?'
    let str = substitute(a:str, '\[{\(.\{-}\)}\]', '\L\1', 'g')
  else
    echohl WarningMsg
    echomsg "g:html_tag_case = '" . g:html_tag_case . "' invalid, overriding to 'upppercase'."
    echohl None
    let g:html_tag_case = 'uppercase'
    let str = HTMLconvertCase(a:str)
  endif
  return str
endfunction

" Re-indent a region.  (Usually called by HTMLmap.)
"  Nothing happens if filetype indenting isn't enabled.
" Args:
"  1 - Integer: Start of region.
"  2 - Integer: End of region.
"  3 - Integer: 1: Add an extra line below the region to re-indent.
"               *: Don't add an extra line.
function! HTMLreIndent(first, last, extraline)
  " To find out if filetype indenting is enabled:
  let save_register = @x
  redir @x | silent! filetype | redir END
  let filetype_output = @x
  let @x = save_register

  if filetype_output !~ "indent:ON"
    return
  endif

  " Make sure the range is in the proper order:
  if a:last >= a:first
    let firstline = a:first
    let lastline = a:last
  else
    let lastline = a:first
    let firstline = a:last
  endif

  " Make sure the full region to be re-indendted is included:
  if a:extraline == 1
    if firstline == lastline
      let lastline = lastline + 2
    else
      let lastline = lastline + 1
    endif
  endif

  exe firstline . ',' . lastline . 'norm =='
endfunction

" Make it convenient to use ; as "normal":
call HTMLmap("inoremap", ";;", ";")
call HTMLmap("vnoremap", ";;", ";")
call HTMLmap("nnoremap", ";;", ";")
" Allow hard tabs to be inserted:
call HTMLmap("inoremap", ";<tab>", "<tab>")

" Tab takes us to a (hopefully) reasonable next insert point:
call HTMLmap("inoremap", "<TAB>", "<C-O>:call HTMLnextInsertPoint('i')<CR>")
call HTMLmap("nnoremap", "<TAB>", ":call HTMLnextInsertPoint('n')<CR>")

function! HTMLnextInsertPoint(mode)
  let saveerrmsg = v:errmsg
  let v:errmsg = ""
  let byteoffset = line2byte(line(".")) + col(".") - 1

  " Tab in insert mode on the beginning of a closing tag jumps us to
  " after the tag:
  if a:mode == "i" && strpart(getline(line(".")), col(".") - 1, 2) == "</"
    normal %
    if col('.') == col('$') - 1
      startinsert!
    else
      normal l
    endif

    return
  endif

  normal 0

  " Running the search twice is inefficient, but it squelches error
  " messages and the second search puts my cursor where I need it...

  if search("<\\([^ <>]\\+\\)[^<>]*>\\(\\n *\\)\\{0,2}<\\/\\1>\\|<[^<>]*\"\"[^<>]*>","w") == 0
    silent execute ":go " . byteoffset
  else
    normal 0
    exe 'silent normal /<\([^ <>]\+\)[^<>]*>\(\n *\)\{0,2}<\/\1>\|<[^<>]*""[^<>]*>/;/>\(\n *\)\{0,2}<\|""/e' . "\<CR>"

    " Since matching open/close tags that spans lines is possible, it
    " might be necessary to position the cursor on a blank line:
    if getline('.') =~ "^ *<\\/[^<>]\\+>" && getline(line('.')-1) =~ "^ *$"
      normal k$
    endif

    call histdel('search', -1)
    let @/ = histget('search', -1)
  endif

  let v:errmsg = saveerrmsg

endfunction

" ----------------------------------------------------------------------------


" ---- General Markup Tags: --------------------------------------------- {{{1

"       SGML Doctype Command
"call HTMLmap("nnoremap", ";4", "1GO<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\"><ESC>``")

"       SGML Doctype Command -- Transitional (Looser)
"call HTMLmap("nnoremap", ";4", "\m'1GO<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"<CR> \"http://www.w3.org/TR/html4/loose.dtd\"><ESC>``")
call HTMLmap("nnoremap", ";4", ":call append(0, '<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"') \\\| call append(1, ' \"http://www.w3.org/TR/html4/loose.dtd\">')<CR>")

"       Content Type META tag
call HTMLmap("inoremap", ";ct", "<[{META HTTP-EQUIV}]=\"Content-Type\" [{CONTENT}]=\"text/html; charset=iso-8859-1\">")

"       Comment Tag
call HTMLmap("inoremap", ";cm", "<!--  --><ESC>Bhi")
" Visual mapping:
call HTMLmap("vnoremap", ";cm", "<ESC>`>a --><C-O>`<<!-- <ESC>", 2)

"       A HREF  Anchor Hyperlink        HTML 2.0
call HTMLmap("inoremap", ";ah", "<[{A HREF=\"\"></A}]><ESC>F\"i")
" Visual mappings:
call HTMLmap("vnoremap", ";ah", "<ESC>`>a</[{A}]><C-O>`<<[{A HREF}]=\"\"><C-O>F\"")
call HTMLmap("vnoremap", ";aH", "<ESC>`>a\"></[{A}]><C-O>`<<[{A HREF}]=\"<C-O>f<")

"       A HREF  Anchor Hyperlink, with TARGET=""
call HTMLmap("inoremap", ";at", "<[{A HREF=\"\" TARGET=\"\"></A}]><ESC>3F\"i")
" Visual mappings:
call HTMLmap("vnoremap", ";at", "<ESC>`>a</[{A}]><C-O>`<<[{A HREF=\"\" TARGET}]=\"\"><C-O>3F\"")
call HTMLmap("vnoremap", ";aT", "<ESC>`>a\" [{TARGET=\"\"></A}]><C-O>`<<[{A HREF}]=\"<C-O>3f\"")

"       A NAME  Named Anchor            HTML 2.0
call HTMLmap("inoremap", ";an", "<[{A NAME=\"\"></A}]><ESC>F\"i")
" Visual mappings:
call HTMLmap("vnoremap", ";an", "<ESC>`>a</[{A}]><C-O>`<<[{A NAME}]=\"\"><C-O>F\"")
call HTMLmap("vnoremap", ";aN", "<ESC>`>a\"></[{A}]><C-O>`<<[{A NAME}]=\"<C-O>f<")

"       ABBR  Abbreviation              HTML 4.0
call HTMLmap("inoremap", ";ab", "<[{ABBR TITLE=\"\"></ABBR}]><ESC>F\"i")
" Visual mappings:
call HTMLmap("vnoremap", ";ab", "<ESC>`>a</[{ABBR}]><C-O>`<<[{ABBR TITLE}]=\"\"><C-O>F\"")
call HTMLmap("vnoremap", ";aB", "<ESC>`>a\"></[{ABBR}]><C-O>`<<[{ABBR TITLE}]=\"<C-O>f<")

"       ACRONYM                         HTML 4.0
call HTMLmap("inoremap", ";ac", "<[{ACRONYM TITLE=\"\"></ACRONYM}]><ESC>F\"i")
" Visual mappings:
call HTMLmap("vnoremap", ";ac", "<ESC>`>a</[{ACRONYM}]><C-O>`<<[{ACRONYM TITLE}]=\"\"><C-O>F\"")
call HTMLmap("vnoremap", ";aC", "<ESC>`>a\"></[{ACRONYM}]><C-O>`<<[{ACRONYM TITLE}]=\"<C-O>f<")

"       ADDRESS                         HTML 2.0
call HTMLmap("inoremap", ";ad", "<[{ADDRESS></ADDRESS}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";ad", "<ESC>`>a</[{ADDRESS}]><C-O>`<<[{ADDRESS}]><ESC>", 2)

"       B       Boldfaced Text          HTML 2.0
call HTMLmap("inoremap", ";bo", "<[{B></B}]><ESC>hhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";bo", "<ESC>`>a</[{B}]><C-O>`<<[{B}]><ESC>", 2)

"       BASE                            HTML 2.0        HEADER
call HTMLmap("inoremap", ";bh", "<[{BASE HREF}]=\"\"><ESC>hi")
" Visual mapping:
call HTMLmap("vnoremap", ";bh", "<ESC>`>a\"><C-O>`<<[{BASE HREF}]=\"<ESC>", 2)

"       BIG                             HTML 3.0
call HTMLmap("inoremap", ";bi", "<[{BIG></BIG}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";bi", "<ESC>`>a</[{BIG}]><C-O>`<<[{BIG}]><ESC>")

"       BLOCKQUOTE                      HTML 2.0
call HTMLmap("inoremap", ";bl", "<[{BLOCKQUOTE}]><CR></[{BLOCKQUOTE}]><ESC>O")
" Visual mapping:
call HTMLmap("vnoremap", ";bl", "<ESC>`>a<CR></[{BLOCKQUOTE}]><C-O>`<<[{BLOCKQUOTE}]><CR><ESC>", 1)

"       BODY                            HTML 2.0
call HTMLmap("inoremap", ";bd", "<[{BODY}]><CR></[{BODY}]><ESC>O")
" Visual mapping:
call HTMLmap("vnoremap", ";bd", "<ESC>`>a<CR></[{BODY}]><C-O>`<<[{BODY}]><CR><ESC>", 1)

"       BR      Line break              HTML 2.0
call HTMLmap("inoremap", ";br", "<[{BR}]>")

"       CENTER                          NETSCAPE
call HTMLmap("inoremap", ";ce", "<[{CENTER></CENTER}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";ce", "<ESC>`>a</[{CENTER}]><C-O>`<<[{CENTER}]><ESC>", 2)

"       CITE                            HTML 2.0
call HTMLmap("inoremap", ";ci", "<[{CITE></CITE}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";ci", "<ESC>`>a</[{CITE}]><C-O>`<<[{CITE}]><ESC>", 2)

"       CODE                            HTML 2.0
call HTMLmap("inoremap", ";co", "<[{CODE></CODE}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";co", "<ESC>`>a</[{CODE}]><C-O>`<<[{CODE}]><ESC>", 2)

"       DEFINITION LIST COMPONENTS      HTML 2.0
"               DL      Definition List
"               DT      Definition Term
"               DD      Definition Body
call HTMLmap("inoremap", ";dl", "<[{DL}]><CR></[{DL}]><ESC>O")
" Visual mappings:
call HTMLmap("vnoremap", ";dl", "<ESC>`>a<CR></[{DL}]><C-O>`<<[{DL}]><CR><ESC>", 1)
call HTMLmap("inoremap", ";dt", "<[{DT}]>")
call HTMLmap("inoremap", ";dd", "<[{DD}]>")

"       DEL     Deleted Text            HTML 3.0
call HTMLmap("inoremap", ";de", "<lt>[{DEL></DEL}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";de", "<ESC>`>a</[{DEL}]><C-O>`<<lt>[{DEL}]><ESC>")

"       DFN     Defining Instance       HTML 3.0
call HTMLmap("inoremap", ";df", "<[{DFN></DFN}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";df", "<ESC>`>a</[{DFN}]><C-O>`<<[{DFN}]><ESC>", 2)

"       DIR     Directory List          HTML 3.0
"imap ;di <DIR><CR></DIR><ESC>O

"       DIV     Document Division       HTML 3.0
call HTMLmap("inoremap", ";dv", "<[{DIV}]><CR></[{DIV}]><ESC>O")
" Visual mapping:
call HTMLmap("vnoremap", ";dv", "<ESC>`>a<CR></[{DIV}]><C-O>`<<[{DIV}]><CR><ESC>", 1)

"       SPAN    Delimit Arbitrary Text  HTML 4.0
call HTMLmap("inoremap", ";sn", "<[{SPAN></SPAN}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";sn", "<ESC>`>a</[{SPAN}]><C-O>`<<[{SPAN}]><ESC>", 2)

"       EM      Emphasize               HTML 2.0
call HTMLmap("inoremap", ";em", "<[{EM></EM}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";em", "<ESC>`>a</[{EM}]><C-O>`<<[{EM}]><ESC>", 2)

"       FONT                            NETSCAPE
call HTMLmap("inoremap", ";fo", "<[{FONT SIZE=\"\"></FONT}]><ESC>F\"i")
call HTMLmap("inoremap", ";fc", "<[{FONT COLOR=\"\"></FONT}]><ESC>F\"i")
" Visual mappings:
call HTMLmap("vnoremap", ";fo", "<ESC>`>a</[{FONT}]><C-O>`<<[{FONT SIZE}]=\"\"><C-O>F\"")
call HTMLmap("vnoremap", ";fc", "<ESC>`>a</[{FONT}]><C-O>`<<[{FONT COLOR}]=\"\"><C-O>F\"")

"       HEADERS, LEVELS 1-6             HTML 2.0
call HTMLmap("inoremap", ";h1", "<[{H1 ALIGN=CENTER}]></[{H1}]><ESC>bhhi")
call HTMLmap("inoremap", ";h2", "<[{H2 ALIGN=CENTER}]></[{H2}]><ESC>bhhi")
call HTMLmap("inoremap", ";h3", "<[{H3 ALIGN=CENTER}]></[{H3}]><ESC>bhhi")
call HTMLmap("inoremap", ";h4", "<[{H4 ALIGN=CENTER}]></[{H4}]><ESC>bhhi")
call HTMLmap("inoremap", ";h5", "<[{H5 ALIGN=CENTER}]></[{H5}]><ESC>bhhi")
call HTMLmap("inoremap", ";h6", "<[{H6 ALIGN=CENTER}]></[{H6}]><ESC>bhhi")
" Visual mappings:
call HTMLmap("vnoremap", ";h1", "<ESC>`>a</[{H1}]><C-O>`<<[{H1 ALIGN=CENTER}]><ESC>", 2)
call HTMLmap("vnoremap", ";h2", "<ESC>`>a</[{H2}]><C-O>`<<[{H2 ALIGN=CENTER}]><ESC>", 2)
call HTMLmap("vnoremap", ";h3", "<ESC>`>a</[{H3}]><C-O>`<<[{H3 ALIGN=CENTER}]><ESC>", 2)
call HTMLmap("vnoremap", ";h4", "<ESC>`>a</[{H4}]><C-O>`<<[{H4 ALIGN=CENTER}]><ESC>", 2)
call HTMLmap("vnoremap", ";h5", "<ESC>`>a</[{H5}]><C-O>`<<[{H5 ALIGN=CENTER}]><ESC>", 2)
call HTMLmap("vnoremap", ";h6", "<ESC>`>a</[{H6}]><C-O>`<<[{H6 ALIGN=CENTER}]><ESC>", 2)

"       HEAD                            HTML 2.0
call HTMLmap("inoremap", ";he", "<[{HEAD}]><CR></[{HEAD}]><ESC>O")
" Visual mapping:
call HTMLmap("vnoremap", ";he", "<ESC>`>a<CR></[{HEAD}]><C-O>`<<[{HEAD}]><CR><ESC>", 1)

"       HR      Horizontal Rule         HTML 2.0 W/NETSCAPISM
call HTMLmap("inoremap", ";hr", "<[{HR WIDTH}]=\"75%\">")

"       HTML                            HTML 3.0
call HTMLmap("inoremap", ";ht", "<[{HTML}]><CR></[{HTML}]><ESC>O")
" Visual mapping:
call HTMLmap("vnoremap", ";ht", "<ESC>`>a<CR></[{HTML}]><C-O>`<<[{HTML}]><CR><ESC>", 1)

"       I       Italicized Text         HTML 2.0
call HTMLmap("inoremap", ";it", "<[{I></I}]><ESC>hhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";it", "<ESC>`>a</[{I}]><C-O>`<<[{I}]><ESC>", 2)

"       IMG     Image                   HTML 2.0
call HTMLmap("inoremap", ";im", "<[{IMG SRC=\"\" ALT}]=\"\"><ESC>Bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";im", "<ESC>`>a\"><C-O>`<<[{IMG SRC=\"\" ALT}]=\"<C-O>2F\"")

"       INS     Inserted Text           HTML 3.0
call HTMLmap("inoremap", ";in", "<lt>[{INS></INS}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";in", "<ESC>`>a</[{INS}]><C-O>`<<lt>[{INS}]><ESC>")

"       ISINDEX Identifies Index        HTML 2.0
call HTMLmap("inoremap", ";ii", "<[{ISINDEX}]>")

"       KBD     Keyboard Text           HTML 2.0
call HTMLmap("inoremap", ";kb", "<[{KBD></KBD}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";kb", "<ESC>`>a</[{KBD}]><C-O>`<<[{KBD}]><ESC>", 2)

"       LI      List Item               HTML 2.0
call HTMLmap("inoremap", ";li", "<[{LI}]>")

"       LINK                            HTML 2.0        HEADER
call HTMLmap("inoremap", ";lk", "<[{LINK HREF}]=\"\"><ESC>hi")
" Visual mapping:
call HTMLmap("vnoremap", ";lk", "<ESC>`>a\"><C-O>`<<[{LINK HREF}]=\"<ESC>")

"       LH      List Header             HTML 2.0
call HTMLmap("inoremap", ";lh", "<[{LH></LH}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";lh", "<ESC>`>a</[{LH}]><C-O>`<<[{LH}]><ESC>", 2)

"       MENU                            HTML 2.0
"imap ;mu <MENU><CR></MENU><ESC>O

"       META    Meta Information        HTML 2.0        HEADER
call HTMLmap("inoremap", ";me", "<[{META NAME=\"\" CONTENT}]=\"\"><ESC>Bhhi")
" Visual mappings:
call HTMLmap("vnoremap", ";me", "<ESC>`>a\" [{CONTENT}]=\"\"><C-O>`<<[{META NAME}]=\"<C-O>3f\"")
call HTMLmap("vnoremap", ";mE", "<ESC>`>a\"><C-O>`<<[{META NAME=\"\" CONTENT}]=\"<C-O>2F\"")

"       OL      Ordered List            HTML 3.0
call HTMLmap("inoremap", ";ol", "<[{OL}]><CR></[{OL}]><ESC>O")
" Visual mapping:
call HTMLmap("vnoremap", ";ol", "<ESC>`>a<CR></[{OL}]><C-O>`<<[{OL}]><CR><ESC>", 1)

"       P       Paragraph               HTML 3.0
call HTMLmap("inoremap", ";pp", "<[{P}]><CR></[{P}]><ESC>O")
" Visual mapping:
call HTMLmap("vnoremap", ";pp", "<ESC>`>a<CR></[{P}]><C-O>`<<[{P}]><CR><ESC>", 1)

"       PRE     Preformatted Text       HTML 2.0
call HTMLmap("inoremap", ";pr", "<[{PRE}]><CR></[{PRE}]><ESC>O")
" Visual mapping:
call HTMLmap("vnoremap", ";pr", "<ESC>`>a<CR></[{PRE}]><C-O>`<<[{PRE}]><CR><ESC>", 1)

"       Q       Quote                   HTML 3.0
call HTMLmap("inoremap", ";qu", "<[{Q></Q}]><ESC>hhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";qu", "<ESC>`>a</[{Q}]><C-O>`<<[{Q}]><ESC>")

"       S       Strikethrough           HTML 3.0
call HTMLmap("inoremap", ";sk", "<[{STRIKE></STRIKE}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";sk", "<ESC>`>a</[{STRIKE}]><C-O>`<<[{STRIKE}]><ESC>", 2)

"       SAMP    Sample Text             HTML 2.0
call HTMLmap("inoremap", ";sa", "<[{SAMP></SAMP}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";sa", "<ESC>`>a</[{SAMP}]><C-O>`<<[{SAMP}]><ESC>", 2)

"       SMALL   Small Text              HTML 3.0
call HTMLmap("inoremap", ";sm", "<[{SMALL></SMALL}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";sm", "<ESC>`>a</[{SMALL}]><C-O>`<<[{SMALL}]><ESC>")

"       STRONG                          HTML 2.0
call HTMLmap("inoremap", ";st", "<[{STRONG></STRONG}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";st", "<ESC>`>a</[{STRONG}]><C-O>`<<[{STRONG}]><ESC>", 2)

"       STYLE                           HTML 4.0        HEADER
call HTMLmap("inoremap", ";cs", "<[{STYLE TYPE}]=\"text/css\"><CR><!--  --><CR></[{STYLE}]><ESC>k0Ela")
" Visual mapping:
call HTMLmap("vnoremap", ";cs", "<ESC>`>a<CR> --><CR></[{STYLE}]><C-O>`<<[{STYLE TYPE}]=\"text/css\"><CR><!--<CR><ESC>", 1)

"       Linked CSS stylesheet
call HTMLmap("inoremap", ";ls", "<[{LINK REL}]=\"stylesheet\" [{TYPE}]=\"text/css\" [{HREF}]=\"\"><ESC>F\"i")
" Visual mapping:
call HTMLmap("vnoremap", ";ls", "<ESC>`>a\"><C-O>`<<[{LINK REL}]=\"stylesheet\" [{TYPE}]=\"text/css\" [{HREF}]=\"<ESC>", 2)

"       SUB     Subscript               HTML 3.0
call HTMLmap("inoremap", ";sb", "<[{SUB></SUB}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";sb", "<ESC>`>a</[{SUB}]><C-O>`<<[{SUB}]><ESC>", 2)

"       SUP     Superscript             HTML 3.0
call HTMLmap("inoremap", ";sp", "<[{SUP></SUP}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";sp", "<ESC>`>a</[{SUP}]><C-O>`<<[{SUP}]><ESC>", 2)

"       TITLE                           HTML 2.0        HEADER
call HTMLmap("inoremap", ";ti", "<[{TITLE></TITLE}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";ti", "<ESC>`>a</[{TITLE}]><C-O>`<<[{TITLE}]><ESC>", 2)

"       TT      Teletype Text (monospaced)      HTML 2.0
call HTMLmap("inoremap", ";tt", "<[{TT></TT}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";tt", "<ESC>`>a</[{TT}]><C-O>`<<[{TT}]><ESC>", 2)

"       U       Underlined Text         HTML 2.0
call HTMLmap("inoremap", ";un", "<[{U></U}]><ESC>hhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";un", "<ESC>`>a</[{U}]><C-O>`<<[{U}]><ESC>", 2)

"       UL      Unordered List          HTML 2.0
call HTMLmap("inoremap", ";ul", "<[{UL}]><CR></[{UL}]><ESC>O")
" Visual mapping:
call HTMLmap("vnoremap", ";ul", "<ESC>`>a<CR></[{UL}]><C-O>`<<[{UL}]><CR><ESC>", 1)

"       VAR     Variable                HTML 3.0
call HTMLmap("inoremap", ";va", "<[{VAR></VAR}]><ESC>bhhi")
" Visual mapping:
call HTMLmap("vnoremap", ";va", "<ESC>`>a</[{VAR}]><C-O>`<<[{VAR}]><ESC>", 2)

"       JavaScript
call HTMLmap("inoremap", ";js", "<[{SCRIPT TYPE}]=\"text/javascript\" [{LANGUAGE}]=\"javascript\"><CR><!--<CR>// --><CR></[{SCRIPT}]><ESC>kO")

"       EMBED
call HTMLmap("inoremap", ";eb", "<[{EMBED SRC=\"\" WIDTH=\"\" HEIGHT}]=\"\"><CR><[{NOEMBED></NOEMBED}]><ESC>k0f\"li")

" Table stuff:
call HTMLmap("inoremap", ";ca", "<[{CAPTION></CAPTION}]><ESC>bhhi")
call HTMLmap("inoremap", ";ta", "<[{TABLE}]><CR></[{TABLE}]><ESC>O")
call HTMLmap("inoremap", ";tr", "<[{TR}]><CR></[{TR}]><ESC>O")
call HTMLmap("inoremap", ";td", "<[{TD}]><CR></[{TD}]><ESC>O")
call HTMLmap("inoremap", ";th", "<[{TH></TH}]><ESC>bhhi")
" Visual mappings:
call HTMLmap("vnoremap", ";ca", "<ESC>`>a<CR></[{CAPTION}]><C-O>`<<[{CAPTION}]><CR><ESC>", 1)
call HTMLmap("vnoremap", ";ta", "<ESC>`>a<CR></[{TABLE}]><C-O>`<<[{TABLE}]><CR><ESC>", 1)
call HTMLmap("vnoremap", ";tr", "<ESC>`>a<CR></[{TR}]><C-O>`<<[{TR}]><CR><ESC>", 1)
call HTMLmap("vnoremap", ";td", "<ESC>`>a<CR></[{TD}]><C-O>`<<[{TD}]><CR><ESC>", 1)
call HTMLmap("vnoremap", ";th", "<ESC>`>a</[{TH}]><C-O>`<<[{TH}]><ESC>", 2)

" Interactively generate a table of Rows x Columns:
call HTMLmap("nnoremap", ";ta", ":call HTMLgenerateTable()<CR>")

function! HTMLgenerateTable()
    let byteoffset = line2byte(line(".")) + col(".") - 1

    let rows    = inputdialog("Number of rows: ") + 0
    let columns = inputdialog("Number of columns: ") + 0

    if (! (rows > 0 && columns > 0))
        echo "Rows and columns must be integers."
        return
    endif

    let border = inputdialog("Border width of table [none]: ") + 0

    let r = 0
    let c = 0

    if (border)
        exe HTMLconvertCase("normal o<[{TABLE BORDER}]=" . border . ">\<ESC>")
    else
        exe HTMLconvertCase("normal o<[{TABLE}]>\<ESC>")
    endif

    while r < rows
        let r = r + 1
        let c = 0

        exe HTMLconvertCase("normal o<[{TR}]>\<ESC>")

        while c < columns
            let c = c + 1
            exe HTMLconvertCase("normal o<[{TD}]>\<CR></[{TD}]>\<ESC>")
        endwhile

        exe HTMLconvertCase("normal o</[{TR}]>\<ESC>")

    endwhile

    exe HTMLconvertCase("normal o</[{TABLE}]>\<ESC>")

    if byteoffset == -1
      go 1
    else
      execute ":go " . byteoffset
    endif

    normal jjj^

endfunction

" Frames stuff:
call HTMLmap("inoremap", ";fs", "<[{FRAMESET ROWS=\"\" COLS}]=\"\"><CR></[{FRAMESET}]><ESC>BBhhi")
call HTMLmap("inoremap", ";fr", "<[{FRAME SRC}]=\"\"><ESC>hi")
call HTMLmap("inoremap", ";nf", "<[{NOFRAMES}]><CR></[{NOFRAMES}]><ESC>O")
" Visual mappings:
call HTMLmap("vnoremap", ";fs", "<ESC>`>a<CR></[{FRAMESET}]><C-O>`<<[{FRAMESET ROWS=\"\" COLS}]=\"\"><CR><ESC>k0f\"l")
call HTMLmap("vnoremap", ";fr", "<ESC>`>a\"><C-O>`<<[{FRAME SRC=\"<ESC>")
call HTMLmap("vnoremap", ";nf", "<ESC>`>a<CR></[{NOFRAMES}]><C-O>`<<[{NOFRAMES}]><CR><ESC>", 1)

"       IFRAME  Inline Frame            HTML 4.0
call HTMLmap("inoremap", ";if", "<[{IFRAME SRC}]=\"\"><CR></[{IFRAME}]><ESC>Bblli")
" Visual mapping:
call HTMLmap("vnoremap", ";if", "<ESC>`>a<CR></[{IFRAME}]><C-O>`<<[{IFRAME SRC}]=\"\"><CR><ESC>k0f\"l")

" Forms stuff:
call HTMLmap("inoremap", ";fm", "<[{FORM ACTION}]=\"\"><CR></[{FORM}]><ESC>k0f\"li")
call HTMLmap("inoremap", ";bu", "<[{INPUT TYPE=BUTTON NAME=\"\" VALUE}]=\"\"><ESC>BF\"i")
call HTMLmap("inoremap", ";ch", "<[{INPUT TYPE=CHECKBOX NAME=\"\" VALUE}]=\"\"><ESC>BF\"i")
call HTMLmap("inoremap", ";ra", "<[{INPUT TYPE=RADIO NAME=\"\" VALUE}]=\"\"><ESC>BF\"i")
call HTMLmap("inoremap", ";hi", "<[{INPUT TYPE=HIDDEN NAME=\"\" VALUE}]=\"\"><ESC>BF\"i")
call HTMLmap("inoremap", ";pa", "<[{INPUT TYPE=PASSWORD NAME=\"\" VALUE}]=\"\"><ESC>BF\"i")
call HTMLmap("inoremap", ";te", "<[{INPUT TYPE=TEXT NAME=\"\" VALUE=\"\" SIZE}]=20><ESC>BF\"i")
call HTMLmap("inoremap", ";se", "<[{SELECT NAME}]=\"\"><CR></[{SELECT}]><ESC>O")
call HTMLmap("inoremap", ";ms", "<[{SELECT NAME=\"\" MULTIPLE}]><CR></[{SELECT}]><ESC>O")
call HTMLmap("inoremap", ";op", "<[{OPTION}]>")
call HTMLmap("inoremap", ";og", "<[{OPTGROUP LABEL}]=\"\"><CR></[{OPTGROUP}]><ESC>k0f\"li")
call HTMLmap("inoremap", ";tx", "<[{TEXTAREA NAME=\"\" ROWS=10 COLS}]=50><CR></[{TEXTAREA}]><ESC>k0f\"li")
call HTMLmap("inoremap", ";su", "<[{INPUT TYPE=SUBMIT VALUE}]=\"Submit\">")
call HTMLmap("inoremap", ";re", "<[{INPUT TYPE=RESET VALUE}]=\"Reset\">")
call HTMLmap("inoremap", ";la", "<[{LABEL FOR=\"\"></LABEL}]><C-O>F\"")
" Visual mappings:
call HTMLmap("vnoremap", ";fm", "<ESC>`>a<CR></[{FORM}]><C-O>`<<[{FORM ACTION}]=\"\"><CR><ESC>k0f\"l", 1)
call HTMLmap("vnoremap", ";bu", "<ESC>`>a\"><C-O>`<<[{INPUT TYPE=BUTTON NAME=\"\" VALUE}]=\"<ESC>0f\"l")
call HTMLmap("vnoremap", ";ch", "<ESC>`>a\"><C-O>`<<[{INPUT TYPE=CHECKBOX NAME=\"\" VALUE}]=\"<ESC>0f\"l")
call HTMLmap("vnoremap", ";ra", "<ESC>`>a\"><C-O>`<<[{INPUT TYPE=RADIO NAME=\"\" VALUE}]=\"<ESC>0f\"l")
call HTMLmap("vnoremap", ";hi", "<ESC>`>a\"><C-O>`<<[{INPUT TYPE=HIDDEN NAME=\"\" VALUE}]=\"<ESC>0f\"l")
call HTMLmap("vnoremap", ";pa", "<ESC>`>a\"><C-O>`<<[{INPUT TYPE=PASSWORD NAME=\"\" VALUE}]=\"<ESC>0f\"l")
call HTMLmap("vnoremap", ";te", "<ESC>`>a\" [{SIZE}]=20><C-O>`<<[{INPUT TYPE=TEXT NAME=\"\" VALUE}]=\"<ESC>0f\"l")
call HTMLmap("vnoremap", ";se", "<ESC>`>a<CR></[{SELECT}]><C-O>`<<[{SELECT NAME}]=\"\"><CR><ESC>k0f\"l", 1)
call HTMLmap("vnoremap", ";ms", "<ESC>`>a<CR></[{SELECT}]><C-O>`<<[{SELECT NAME=\"\" MULTIPLE}]><CR><ESC>k0f\"l", 1)
call HTMLmap("vnoremap", ";og", "<ESC>`>a<CR></[{OPTGROUP}]><C-O>`<<[{OPTGROUP LABEL}]=\"\"><CR><ESC>k0f\"l", 1)
call HTMLmap("vnoremap", ";tx", "<ESC>`>a<CR></[{TEXTAREA}]><C-O>`<<[{TEXTAREA NAME=\"\" ROWS=10 COLS}]=50><CR><ESC>k0f\"l", 1)
call HTMLmap("vnoremap", ";la", "<ESC>`>a</[{LABEL}]><C-O>`<<[{LABEL FOR}]=\"\"><C-O>F\"")
call HTMLmap("vnoremap", ";lA", "<ESC>`>a\"></[{LABEL}]><C-O>`<<[{LABEL FOR}]=\"<C-O>f<")

" ----------------------------------------------------------------------------


" ---- Special Characters (Character Entities): ------------------------- {{{1
call HTMLmap("inoremap", "&&", "&amp;")
call HTMLmap("inoremap", "&cO", "&copy;")
call HTMLmap("inoremap", "&rO", "&reg;")
call HTMLmap("inoremap", "&tm", "&trade;")
call HTMLmap("inoremap", "&'", "&quot;")
call HTMLmap("inoremap", "&<", "&lt;")
call HTMLmap("inoremap", "&>", "&gt;")
call HTMLmap("inoremap", "&<space>", "&nbsp;")
call HTMLmap("inoremap", ";<space>", "&nbsp;")
call HTMLmap("inoremap", "&#", "&pound;")
call HTMLmap("inoremap", "&Y=", "&yen;")
call HTMLmap("inoremap", "&c\\|", "&cent;")
call HTMLmap("inoremap", "&A`", "&Agrave;")
call HTMLmap("inoremap", "&A'", "&Aacute;")
call HTMLmap("inoremap", "&A^", "&Acirc;")
call HTMLmap("inoremap", "&A~", "&Atilde;")
call HTMLmap("inoremap", "&A\"", "&Auml;")
call HTMLmap("inoremap", "&Ao", "&Aring;")
call HTMLmap("inoremap", "&AE", "&AElig;")
call HTMLmap("inoremap", "&C,", "&Ccedil;")
call HTMLmap("inoremap", "&E`", "&Egrave;")
call HTMLmap("inoremap", "&E'", "&Eacute;")
call HTMLmap("inoremap", "&E^", "&Ecirc;")
call HTMLmap("inoremap", "&E\"", "&Euml;")
call HTMLmap("inoremap", "&I`", "&Igrave;")
call HTMLmap("inoremap", "&I'", "&Iacute;")
call HTMLmap("inoremap", "&I^", "&Icirc;")
call HTMLmap("inoremap", "&I\"", "&Iuml;")
call HTMLmap("inoremap", "&N~", "&Ntilde;")
call HTMLmap("inoremap", "&O`", "&Ograve;")
call HTMLmap("inoremap", "&O'", "&Oacute;")
call HTMLmap("inoremap", "&O^", "&Ocirc;")
call HTMLmap("inoremap", "&O~", "&Otilde;")
call HTMLmap("inoremap", "&O\"", "&Ouml;")
call HTMLmap("inoremap", "&O/", "&Oslash;")
call HTMLmap("inoremap", "&U`", "&Ugrave;")
call HTMLmap("inoremap", "&U'", "&Uacute;")
call HTMLmap("inoremap", "&U^", "&Ucirc;")
call HTMLmap("inoremap", "&U\"", "&Uuml;")
call HTMLmap("inoremap", "&Y'", "&Yacute;")
call HTMLmap("inoremap", "&a`", "&agrave;")
call HTMLmap("inoremap", "&a'", "&aacute;")
call HTMLmap("inoremap", "&a^", "&acirc;")
call HTMLmap("inoremap", "&a~", "&atilde;")
call HTMLmap("inoremap", "&a\"", "&auml;")
call HTMLmap("inoremap", "&ao", "&aring;")
call HTMLmap("inoremap", "&ae", "&aelig;")
call HTMLmap("inoremap", "&c,", "&ccedil;")
call HTMLmap("inoremap", "&e`", "&egrave;")
call HTMLmap("inoremap", "&e'", "&eacute;")
call HTMLmap("inoremap", "&e^", "&ecirc;")
call HTMLmap("inoremap", "&e\"", "&euml;")
call HTMLmap("inoremap", "&i`", "&igrave;")
call HTMLmap("inoremap", "&i'", "&iacute;")
call HTMLmap("inoremap", "&i^", "&icirc;")
call HTMLmap("inoremap", "&i\"", "&iuml;")
call HTMLmap("inoremap", "&n~", "&ntilde;")
call HTMLmap("inoremap", "&o`", "&ograve;")
call HTMLmap("inoremap", "&o'", "&oacute;")
call HTMLmap("inoremap", "&o^", "&ocirc;")
call HTMLmap("inoremap", "&o~", "&otilde;")
call HTMLmap("inoremap", "&o\"", "&ouml;")
call HTMLmap("inoremap", "&x", "&times;")
call HTMLmap("inoremap", "&u`", "&ugrave;")
call HTMLmap("inoremap", "&u'", "&uacute;")
call HTMLmap("inoremap", "&u^", "&ucirc;")
call HTMLmap("inoremap", "&u\"", "&uuml;")
call HTMLmap("inoremap", "&y'", "&yacute;")
call HTMLmap("inoremap", "&y\"", "&yuml;")
call HTMLmap("inoremap", "&2<", "&laquo;")
call HTMLmap("inoremap", "&2>", "&raquo;")
call HTMLmap("inoremap", "&\"", "&uml;")
call HTMLmap("inoremap", "&/", "&divide;")
call HTMLmap("inoremap", "&o/", "&oslash;")
call HTMLmap("inoremap", "&!", "&iexcl;")
call HTMLmap("inoremap", "&?", "&iquest;")
call HTMLmap("inoremap", "&de", "&deg;")
call HTMLmap("inoremap", "&mu", "&micro;")
call HTMLmap("inoremap", "&pa", "&para;")
call HTMLmap("inoremap", "&.", "&middot;")
call HTMLmap("inoremap", "&14", "&frac14;")
call HTMLmap("inoremap", "&12", "&frac12;")
call HTMLmap("inoremap", "&34", "&frac34;")
" ----------------------------------------------------------------------------

" ---- Template Creation Stuff: ----------------------------------------- {{{1
call HTMLmap("nnoremap", ";html", ":if (HTMLtemplate()) \\| startinsert \\| endif<CR>")

" Determine whether to insert the HTML template:
" Args:
"  None
" Return Value:
"  0 - The cursor is not on an insert point.
"  1 - The cursor is on an insert point.
function! HTMLtemplate()
  if (line('$') == 1 && getline(1) == "")
    return HTMLtemplate2()
  else
    let YesNoOverwrite = confirm("Non-empty file.\nInsert template anyway?", "&Yes\n&No\n&Overwrite", 2, "W")
    if (YesNoOverwrite == 1)
      return HTMLtemplate2()
    elseif (YesNoOverwrite == 3)
      execute "1,$delete"
      return HTMLtemplate2()
    endif
  endif
  return 0
endfunction

let s:internal_html_template=
  \"<[{HTML}]>\n" .
  \" <[{HEAD}]>\n\n" .
  \"  <[{TITLE></TITLE}]>\n\n" .
  \"  <[{META NAME}]=\"Generator\" [{CONTENT}]=\"vim (Vi IMproved editor; http://www.vim.org/)\">\n" .
  \"  <[{META NAME}]=\"Author\" [{CONTENT}]=\"%authorname%\">\n" .
  \"  <[{META NAME}]=\"Copyright\" [{CONTENT}]=\"Copyright (C) %date% %authorname%\">\n" .
  \"  <[{LINK REV}]=\"made\" [{HREF}]=\"mailto:%authoremail%\">\n\n" .
  \" </[{HEAD}]>\n" .
  \" <[{BODY BGCOLOR}]=\"%bgcolor%\"" .
    \" [{TEXT}]=\"%textcolor%\"" .
    \" [{LINK}]=\"%linkcolor%\"" .
    \" [{ALINK}]=\"%alinkcolor%\"" .
    \" [{VLINK}]=\"%vlinkcolor%\">\n\n" .
  \"  <[{H1 ALIGN=CENTER></H1}]>\n\n" .
  \"  <[{P}]>\n" .
  \"  </[{P}]>\n\n" .
  \"  <[{HR WIDTH}]=\"75%\">\n\n" .
  \"  <[{P}]>\n" .
  \"  Last Modified: <[{I}]>%date%</[{I}]>\n" .
  \"  </[{P}]>\n\n" .
  \"  <[{ADDRESS}]>\n" .
  \"   <[{A HREF}]=\"mailto:%authoremail%\">%authorname%&lt;%authoremail%&gt;</[{A}]>\n" .
  \"  </[{ADDRESS}]>\n" .
  \" </[{BODY}]>\n" .
  \"</[{HTML}]>"

let s:internal_html_template = HTMLconvertCase(s:internal_html_template)

" Actually insert the HTML template:
" Args:
"  None
" Return Value:
"  0 - The cursor is not on an insert point.
"  1 - The cursor is on an insert point.
function! HTMLtemplate2()

  if g:html_authoremail != ''
    let g:html_authoremail_encoded = HTMLencodeString(g:html_authoremail)
  else
    let g:html_authoremail_encoded = ''
  endif

  if (! exists('g:html_template')) || g:html_template == ""
      0put =s:internal_html_template
  else
    if filereadable(expand(g:html_template))
      execute "0read " . g:html_template
    else
      echohl ErrorMsg
      echomsg "Unable to insert template file: " . g:html_template
      echomsg "Either it doesn't exist or it isn't readable."
      echohl None
      return 0
    endif
  endif

  if getline('$') =~ '^\s*$'
    $delete
  endif

  " Replace the various tokens with appropriate values:
  silent! %s/\C%authorname%/\=g:html_authorname/g
  silent! %s/\C%authoremail%/\=g:html_authoremail/g
  silent! %s/\C%bgcolor%/\=g:html_bgcolor/g
  silent! %s/\C%textcolor%/\=g:html_textcolor/g
  silent! %s/\C%linkcolor%/\=g:html_linkcolor/g
  silent! %s/\C%alinkcolor%/\=g:html_alinkcolor/g
  silent! %s/\C%vlinkcolor%/\=g:html_vlinkcolor/g
  silent! %s/\C%date%/\=strftime('%B %d, %Y')/g

  go 1

  call HTMLnextInsertPoint('n')
  if getline('.')[col('.') - 2] . getline('.')[col('.') - 1] == '><'
        \ || (getline('.') =~ '^\s*$' && line('.') != 1)
    return 1
  else
    return 0
  endif

endfunction
" ----------------------------------------------------------------------------

" ---- Browser Remote Controls: ----------------------------------------- {{{1
if (has("unix"))
  if !exists("*LaunchBrowser")
    runtime! browser_launcher.vim
  endif

  " Mozilla: View current file, starting Netscape if it's not running:
  call HTMLmap("nnoremap", ";mo", ":call LaunchBrowser(3,0)<CR>")
  " Mozilla: Open a new window, and view the current file:
  call HTMLmap("nnoremap", ";nmo", ":call LaunchBrowser(3,1)<CR>")
  " Mozilla: Open a new tab, and view the current file:
  call HTMLmap("nnoremap", ";tmo", ":call LaunchBrowser(3,2)<CR>")

  " Netscape: View current file, starting Netscape if it's not running:
  call HTMLmap("nnoremap", ";ns", ":call LaunchBrowser(0,0)<CR>")
  " Netscape: Open a new window, and view the current file:
  call HTMLmap("nnoremap", ";nns", ":call LaunchBrowser(0,1)<CR>")

  " Opera: View current file, starting Opera if it's not running:
  call HTMLmap("nnoremap", ";oa", ":call LaunchBrowser(1,0)<CR>")
  " Opera: View current file in a new window, starting Opera if it's not running:
  call HTMLmap("nnoremap", ";noa", ":call LaunchBrowser(1,1)<CR>")
  " Opera: Open a new tab, and view the current file:
  call HTMLmap("nnoremap", ";toa", ":call LaunchBrowser(1,2)<CR>")

  " Lynx:  (This happens anyway if there's no DISPLAY environmental variable.)
  call HTMLmap("nnoremap",";ly",":call LaunchBrowser(2,0)<CR>")
  " Lynx in an xterm:      (This happens regardless if you're in the Vim GUI.)
  call HTMLmap("nnoremap", ";nly", ":call LaunchBrowser(2,1)<CR>")
elseif (has("win32"))
  " Internet Explorer:
  "SetIfUnset html_internet_explorer C:\program\ files\internet\ explorer\iexplore
  "function! HTMLstartExplorer(file)
  "  if executable(g:html_internet_explorer)
  "    exe '!start ' g:html_internet_explorer . ' ' . a:file
  "  else
  "    exe '!start explorer ' . a:file
  "  endif
  "endfunction
  "call HTMLmap("nnoremap", ";ie", ":call HTMLstartExplorer(expand('%:p'))<CR>")

  " This assumes that IE is installed and the file explorer will become IE
  " when given an URL to open:
  call HTMLmap("nnoremap", ";ie", ":exe '!start explorer ' . expand('%:p')<CR>")
endif

endif " ! exists("b:did_html_mappings")
" ----------------------------------------------------------------------------

" ---- ToolBar Buttons: ------------------------------------------------- {{{1
if ! has("gui_running")
  augroup HTMLplugin
  au!
  execute 'autocmd GUIEnter * source ' . expand('<sfile>:p')
  augroup END
elseif exists("did_html_menus")
  if &filetype ==? "html"
    amenu enable HTML
    amenu enable ToolBar.*
  endif
else

if (! exists('g:no_html_toolbar')) && (has("toolbar") || has("win32") || has("gui_gtk")
  \ || (v:version >= 600 && (has("gui_athena") || has("gui_motif") || has("gui_photon"))))

  set guioptions+=T

  " A kluge to overcome a problem with the GTK2 interface:
  command! -nargs=+ HTMLtmenu call HTMLtmenu(<f-args>)
  function! HTMLtmenu(icon, level, menu, tip)
    if has('gui_gtk2' && v:version <= 602 && ! has('patch240'))
      exe 'tmenu icon=' . a:icon . ' ' . a:level . ' ' . a:menu . ' ' . a:tip
    else
      exe 'tmenu ' . a:level . ' ' . a:menu . ' ' . a:tip
    endif
  endfunction

  "tunmenu ToolBar
  unmenu ToolBar
  unmenu! ToolBar

  tmenu 1.10          ToolBar.Open      Open file
  amenu 1.10          ToolBar.Open      :browse e<CR>
  tmenu 1.20          ToolBar.Save      Save current file
  amenu 1.20          ToolBar.Save      :w<CR>
  tmenu 1.30          ToolBar.SaveAll   Save all files
  amenu 1.30          ToolBar.SaveAll   :wa<CR>

   menu 1.50          ToolBar.-sep1-    <nul>

  HTMLtmenu Template  1.60  ToolBar.Template  Create\ Template
  amenu               1.60  ToolBar.Template  ;html

   menu               1.65  ToolBar.-sep2-    <nul>

  HTMLtmenu Paragraph 1.70  ToolBar.Paragraph Create\ Paragraph
  imenu               1.70  ToolBar.Paragraph ;pp
  vmenu               1.70  ToolBar.Paragraph ;pp
  nmenu               1.70  ToolBar.Paragraph i;pp
  HTMLtmenu Break     1.80  ToolBar.Break     Line\ Break
  imenu               1.80  ToolBar.Break     ;br
  vmenu               1.80  ToolBar.Break     ;br
  nmenu               1.80  ToolBar.Break     i;br

   menu               1.85  ToolBar.-sep3-    <nul>

  HTMLtmenu Link      1.90  ToolBar.Link      Create\ Hyperlink
  imenu               1.90  ToolBar.Link      ;ah
  vmenu               1.90  ToolBar.Link      ;ah
  nmenu               1.90  ToolBar.Link      i;ah
  HTMLtmenu Target    1.100 ToolBar.Target    Create\ Target\ (Named\ Anchor)
  imenu               1.100 ToolBar.Target    ;an
  vmenu               1.100 ToolBar.Target    ;an
  nmenu               1.100 ToolBar.Target    i;an
  HTMLtmenu Image     1.110 ToolBar.Image     Insert\ Image
  imenu               1.110 ToolBar.Image     ;im
  vmenu               1.110 ToolBar.Image     ;im
  nmenu               1.110 ToolBar.Image     i;im

   menu               1.115 ToolBar.-sep4-    <nul>

  HTMLtmenu Hline     1.120 ToolBar.Hline     Create\ Horizontal\ Rule
  imenu               1.120 ToolBar.Hline     ;hr
  nmenu               1.120 ToolBar.Hline     i;hr

   menu               1.125 ToolBar.-sep5-    <nul>

  HTMLtmenu Table     1.130 ToolBar.Table     Create\ Table
  imenu               1.130 ToolBar.Table     <ESC>;ta
  nmenu               1.130 ToolBar.Table     ;ta

   menu               1.135 ToolBar.-sep6-    <nul>

  HTMLtmenu Blist     1.140 ToolBar.Blist     Create\ Bullet\ List
  imenu               1.140 ToolBar.Blist     ;ul;li
  vmenu               1.140 ToolBar.Blist     ;uli;li<ESC>
  nmenu               1.140 ToolBar.Blist     i;ul;li
  HTMLtmenu Nlist     1.150 ToolBar.Nlist     Create\ Numbered\ List
  imenu               1.150 ToolBar.Nlist     ;ol;li
  vmenu               1.150 ToolBar.Nlist     ;oli;li<ESC>
  nmenu               1.150 ToolBar.Nlist     i;ol;li
  HTMLtmenu Litem     1.160 ToolBar.Litem     Add\ List\ Item
  imenu               1.160 ToolBar.Litem     ;li
  nmenu               1.160 ToolBar.Litem     i;li

   menu               1.165 ToolBar.-sep7-    <nul>

  HTMLtmenu Bold      1.170 ToolBar.Bold      Bold
  imenu               1.170 ToolBar.Bold      ;bo
  vmenu               1.170 ToolBar.Bold      ;bo
  nmenu               1.170 ToolBar.Bold      i;bo
  HTMLtmenu Italic    1.180 ToolBar.Italic    Italic
  imenu               1.180 ToolBar.Italic    ;it
  vmenu               1.180 ToolBar.Italic    ;it
  nmenu               1.180 ToolBar.Italic    i;it
  HTMLtmenu Underline 1.190 ToolBar.Underline Underline
  imenu               1.190 ToolBar.Underline ;un
  vmenu               1.190 ToolBar.Underline ;un
  nmenu               1.190 ToolBar.Underline i;un

   menu               1.195 ToolBar.-sep8-    <nul>

  tmenu               1.200 ToolBar.Cut       Cut to clipboard
  vmenu               1.200 ToolBar.Cut       "*x
  tmenu               1.210 ToolBar.Copy      Copy to clipboard
  vmenu               1.210 ToolBar.Copy      "*y
  tmenu               1.220 ToolBar.Paste     Paste from Clipboard
  nmenu               1.220 ToolBar.Paste     i<C-R>*<Esc>
  vmenu               1.220 ToolBar.Paste     "-xi<C-R>*<Esc>
  menu!               1.220 ToolBar.Paste     <C-R>*

   menu               1.225 ToolBar.-sep9-    <nul>

  tmenu               1.230 ToolBar.Find      Find...
  tmenu               1.240 ToolBar.Replace   Find & Replace

  if has("win32") || has("win16") || has("gui_gtk") || has("gui_motif")
    amenu 1.250 ToolBar.Find    :promptfind<CR>
    vunmenu     ToolBar.Find
    vmenu       ToolBar.Find    y:promptfind <C-R>"<CR>
    amenu 1.260 ToolBar.Replace :promptrepl<CR>
    vunmenu     ToolBar.Replace
    vmenu       ToolBar.Replace y:promptrepl <C-R>"<CR>
  else
    amenu 1.250 ToolBar.Find    /
    amenu 1.260 ToolBar.Replace :%s/
    vunmenu     ToolBar.Replace
    vmenu       ToolBar.Replace :s/
  endif


  if exists("*LaunchBrowser")
    amenu 1.500 ToolBar.-sep50-  <nul>

    HTMLtmenu Mozilla  1.510 ToolBar.Mozilla  Launch\ Mozilla\ on\ Current\ File
    amenu              1.510 ToolBar.Mozilla  ;mo
    HTMLtmenu Netscape 1.520 ToolBar.Netscape Launch\ Netscape\ on\ Current\ File
    amenu              1.520 ToolBar.Netscape ;ns
    HTMLtmenu Opera    1.530 ToolBar.Opera    Launch\ Opera\ on\ Current\ File
    amenu              1.530 ToolBar.Opera    ;oa
    HTMLtmenu Lynx     1.540 ToolBar.Lynx     Launch\ Lynx\ on\ Current\ File
    amenu              1.540 ToolBar.Lynx     ;ly
  elseif maparg(';ie', 'n') != ""
    amenu 1.500 ToolBar.-sep50-  <nul>

    tmenu 1.510 ToolBar.IE Launch Internet Explorer on Current File
    amenu 1.510 ToolBar.IE ;ie
  endif

  amenu 1.998 ToolBar.-sep99-   <nul>
  tmenu 1.999 ToolBar.Help      HTML Help
  amenu 1.999 ToolBar.Help      :help HTML<CR>

  delcommand HTMLtmenu
  delfunction HTMLtmenu

  let did_html_toolbar = 1
endif  " (! exists('g:no_html_toolbar')) && (has("toolbar") || has("win32") [...]
" ----------------------------------------------------------------------------

" ---- Menu Items: ------------------------------------------------------ {{{1

augroup HTML_menu_autos
au!
autocmd BufLeave,BufWinLeave *
 \ if &filetype ==? "html" |
   \ amenu disable HTML |
   \ if exists('g:did_html_toolbar') |
   \ amenu disable ToolBar.* |
   \ amenu enable ToolBar.Open |
   \ amenu enable ToolBar.Save |
   \ amenu enable ToolBar.SaveAll |
   \ amenu enable ToolBar.Cut |
   \ amenu enable ToolBar.Copy |
   \ amenu enable ToolBar.Paste |
   \ amenu enable ToolBar.Find |
   \ amenu enable ToolBar.Replace |
   \ endif |
 \ endif
autocmd BufEnter,BufWinEnter *
 \ if &filetype ==? "html" |
   \ amenu enable HTML |
   \ amenu enable ToolBar.* |
 \ endif
augroup END

amenu HTM&L.Template<tab>;html                 ;html

if exists("*LaunchBrowser")
  amenu HTML.Preview.Mozilla<tab>;mo                   ;mo
  amenu HTML.Preview.Mozilla\ (New\ Window)<tab>;nmo   ;nmo
  amenu HTML.Preview.Mozilla\ (New\ Tab)<tab>;tmo      ;tmo
  amenu HTML.Preview.-sep1-                            <nop>
  amenu HTML.Preview.Netscape<tab>;ns                  ;ns
  amenu HTML.Preview.Netscape\ (New\ Window)<tab>;nns  ;nns
  amenu HTML.Preview.-sep2-                            <nop>
  amenu HTML.Preview.Opera<tab>;oa                     ;oa
  amenu HTML.Preview.Opera\ (New\ Window)<tab>;noa     ;noa
  amenu HTML.Preview.-sep3-                            <nop>
  amenu HTML.Preview.Lynx<tab>;ly                      ;ly
elseif maparg(';ie', 'n') != ""
  amenu HTML.Preview.Internet\ Explorer<tab>;ie        ;ie
endif

 menu HTML.-sep1-                              <nul>

" Character Entities menu:   {{{2

let b:save_encoding=&encoding
let &encoding='latin1'

imenu HTML.Character\ Entities.Ampersand<tab>\&\&                  &&
imenu HTML.Character\ Entities.Greaterthan\ (>)<tab>\&>            &>
imenu HTML.Character\ Entities.Lessthan\ (<)<tab>\&<               &<
imenu HTML.Character\ Entities.Space\ (nonbreaking\)<tab>\&<space> &<space>
imenu HTML.Character\ Entities.Quotation\ mark\ (")<tab>\&'        &'
 menu HTML.Character\ Entities.-sep1- <nul>
imenu HTML.Character\ Entities.Cent\ (¢)<tab>\&c\|                 &c\|
imenu HTML.Character\ Entities.Pound\ (£)<tab>\&#                  &#
imenu HTML.Character\ Entities.Yen\ (¥)<tab>\&Y=                   &Y=
imenu HTML.Character\ Entities.Left\ Angle\ Quote\ («)<tab>\&2<    &2<
imenu HTML.Character\ Entities.Right\ Angle\ Quote\ (»)<tab>\&2>   &2>
imenu HTML.Character\ Entities.Copyright\ (©)<tab>\&cO             &cO
imenu HTML.Character\ Entities.Registered\ (®)<tab>\&rO            &rO
imenu HTML.Character\ Entities.Trademark\ (TM)<tab>\&tm            &tm
imenu HTML.Character\ Entities.Multiply\ (×)<tab>\&x               &x
imenu HTML.Character\ Entities.Divide\ (÷)<tab>\&/                 &/
imenu HTML.Character\ Entities.Inverted\ Exlamation\ (¡)<tab>\&!   &!
imenu HTML.Character\ Entities.Inverted\ Question\ (¿)<tab>\&?     &?
imenu HTML.Character\ Entities.Degree\ (°)<tab>\&de                &de
imenu HTML.Character\ Entities.Micro/Greek\ mu\ (µ)<tab>\&mu       &mu
imenu HTML.Character\ Entities.Paragraph\ (¶)<tab>\&pa             &pa
imenu HTML.Character\ Entities.Middle\ Dot\ (·)<tab>\&\.           &.
imenu HTML.Character\ Entities.One\ Quarter\ (¼)<tab>\&14          &14
imenu HTML.Character\ Entities.One\ Half\ (½)<tab>\&12             &12
imenu HTML.Character\ Entities.Three\ Quarters\ (¾)<tab>\&34       &34
imenu HTML.Character\ Entities.-sep2- <nul>
imenu HTML.Character\ Entities.Graves.A-grave\ (À)<tab>\&A` &A`
imenu HTML.Character\ Entities.Graves.a-grave\ (à)<tab>\&a` &a`
imenu HTML.Character\ Entities.Graves.E-grave\ (È)<tab>\&E` &E`
imenu HTML.Character\ Entities.Graves.e-grave\ (è)<tab>\&e` &e`
imenu HTML.Character\ Entities.Graves.I-grave\ (Ì)<tab>\&I` &I`
imenu HTML.Character\ Entities.Graves.i-grave\ (ì)<tab>\&i` &i`
imenu HTML.Character\ Entities.Graves.O-grave\ (Ò)<tab>\&O` &O`
imenu HTML.Character\ Entities.Graves.o-grave\ (ò)<tab>\&o` &o`
imenu HTML.Character\ Entities.Graves.U-grave\ (Ù)<tab>\&U` &U`
imenu HTML.Character\ Entities.Graves.u-grave\ (ù)<tab>\&u` &u`
imenu HTML.Character\ Entities.Acutes.A-acute\ (Á)<tab>\&A' &A'
imenu HTML.Character\ Entities.Acutes.a-acute\ (á)<tab>\&a' &a'
imenu HTML.Character\ Entities.Acutes.E-acute\ (É)<tab>\&E' &E'
imenu HTML.Character\ Entities.Acutes.e-acute\ (é)<tab>\&e' &e'
imenu HTML.Character\ Entities.Acutes.I-acute\ (Í)<tab>\&I' &I'
imenu HTML.Character\ Entities.Acutes.i-acute\ (í)<tab>\&i' &i'
imenu HTML.Character\ Entities.Acutes.O-acute\ (Ó)<tab>\&O' &O'
imenu HTML.Character\ Entities.Acutes.o-acute\ (ó)<tab>\&o' &o'
imenu HTML.Character\ Entities.Acutes.U-acute\ (Ú)<tab>\&U' &U'
imenu HTML.Character\ Entities.Acutes.u-acute\ (ú)<tab>\&u' &u'
imenu HTML.Character\ Entities.Acutes.Y-acute\ (Ý)<tab>\&Y' &Y'
imenu HTML.Character\ Entities.Acutes.y-acute\ (ý)<tab>\&y' &y'
imenu HTML.Character\ Entities.Tildes.A-tilde\ (Ã)<tab>\&A~ &A~
imenu HTML.Character\ Entities.Tildes.a-tilde\ (ã)<tab>\&a~ &a~
imenu HTML.Character\ Entities.Tildes.N-tilde\ (Ñ)<tab>\&N~ &N~
imenu HTML.Character\ Entities.Tildes.n-tilde\ (ñ)<tab>\&n~ &n~
imenu HTML.Character\ Entities.Tildes.O-tilde\ (Õ)<tab>\&O~ &O~
imenu HTML.Character\ Entities.Tildes.o-tilde\ (õ)<tab>\&o~ &o~
imenu HTML.Character\ Entities.Circumflexes.A-circumflex\ (Â)<tab>\&A^ &A^
imenu HTML.Character\ Entities.Circumflexes.a-circumflex\ (â)<tab>\&a^ &a^
imenu HTML.Character\ Entities.Circumflexes.E-circumflex\ (Ê)<tab>\&E^ &E^
imenu HTML.Character\ Entities.Circumflexes.e-circumflex\ (ê)<tab>\&e^ &e^
imenu HTML.Character\ Entities.Circumflexes.I-circumflex\ (Î)<tab>\&I^ &I^
imenu HTML.Character\ Entities.Circumflexes.i-circumflex\ (î)<tab>\&i^ &i^
imenu HTML.Character\ Entities.Circumflexes.O-circumflex\ (Ô)<tab>\&O^ &O^
imenu HTML.Character\ Entities.Circumflexes.o-circumflex\ (ô)<tab>\&o^ &o^
imenu HTML.Character\ Entities.Circumflexes.U-circumflex\ (Û)<tab>\&U^ &U^
imenu HTML.Character\ Entities.Circumflexes.u-circumflex\ (û)<tab>\&u^ &u^
imenu HTML.Character\ Entities.Umlauts.A-umlaut\ (Ä)<tab>\&A" &A"
imenu HTML.Character\ Entities.Umlauts.a-umlaut\ (ä)<tab>\&a" &a"
imenu HTML.Character\ Entities.Umlauts.E-umlaut\ (Ë)<tab>\&E" &E"
imenu HTML.Character\ Entities.Umlauts.e-umlaut\ (ë)<tab>\&e" &e"
imenu HTML.Character\ Entities.Umlauts.I-umlaut\ (Ï)<tab>\&I" &I"
imenu HTML.Character\ Entities.Umlauts.i-umlaut\ (ï)<tab>\&i" &i"
imenu HTML.Character\ Entities.Umlauts.O-umlaut\ (Ö)<tab>\&O" &O"
imenu HTML.Character\ Entities.Umlauts.o-umlaut\ (ö)<tab>\&o" &o"
imenu HTML.Character\ Entities.Umlauts.U-umlaut\ (Ü)<tab>\&U" &U"
imenu HTML.Character\ Entities.Umlauts.u-umlaut\ (ü)<tab>\&u" &u"
imenu HTML.Character\ Entities.Umlauts.y-umlaut\ (ÿ)<tab>\&y" &y"
imenu HTML.Character\ Entities.Umlauts.Umlaut\ (¨)<tab>\&"    &"
imenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..A-ring\ (Å)<tab>\&Ao      &Ao
imenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..a-ring\ (å)<tab>\&ao      &ao
imenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..AE-ligature\ (Æ)<tab>\&AE &AE
imenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..ae-ligature\ (æ)<tab>\&ae &ae
imenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..C-cedilla\ (Ç)<tab>\&C,   &C,
imenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..c-cedilla\ (ç)<tab>\&c,   &c,
imenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..O-slash\ (Ø)<tab>\&O/     &O/
imenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..o-slash\ (ø)<tab>\&o/     &o/
" Normal mode versions of the above.  If you change the above, it's usually
" easier to just delete it yank the above, paste it, and run a pair of
" substitute commands.
nmenu HTML.Character\ Entities.Ampersand<tab>\&\&                  i&&<ESC>
nmenu HTML.Character\ Entities.Greaterthan\ (>)<tab>\&>            i&><ESC>
nmenu HTML.Character\ Entities.Lessthan\ (<)<tab>\&<               i&<<ESC>
nmenu HTML.Character\ Entities.Space\ (nonbreaking\)<tab>\&<space> i&<space><ESC>
nmenu HTML.Character\ Entities.Quotation\ mark\ (")<tab>\&'        i&'<ESC>
nmenu HTML.Character\ Entities.Cent\ (¢)<tab>\&c\|                 i&c\|<ESC>
nmenu HTML.Character\ Entities.Pound\ (£)<tab>\&#                  i&#<ESC>
nmenu HTML.Character\ Entities.Yen\ (¥)<tab>\&Y=                   i&Y=<ESC>
nmenu HTML.Character\ Entities.Left\ Angle\ Quote\ («)<tab>\&2<    i&2<<ESC>
nmenu HTML.Character\ Entities.Right\ Angle\ Quote\ (»)<tab>\&2>   i&2><ESC>
nmenu HTML.Character\ Entities.Copyright\ (©)<tab>\&cO             i&cO<ESC>
nmenu HTML.Character\ Entities.Registered\ (®)<tab>\&rO            i&rO<ESC>
nmenu HTML.Character\ Entities.Trademark\ (TM)<tab>\&tm            i&tm<ESC>
nmenu HTML.Character\ Entities.Multiply\ (×)<tab>\&x               i&x<ESC>
nmenu HTML.Character\ Entities.Divide\ (÷)<tab>\&/                 i&/<ESC>
nmenu HTML.Character\ Entities.Inverted\ Exlamation\ (¡)<tab>\&!   i&!<ESC>
nmenu HTML.Character\ Entities.Inverted\ Question\ (¿)<tab>\&?     i&?<ESC>
nmenu HTML.Character\ Entities.Degree\ (°)<tab>\&de                i&de<ESC>
nmenu HTML.Character\ Entities.Micro/Greek\ mu\ (µ)<tab>\&mu       i&mu<ESC>
nmenu HTML.Character\ Entities.Paragraph\ (¶)<tab>\&pa             i&pa<ESC>
nmenu HTML.Character\ Entities.Middle\ Dot\ (·)<tab>\&\.           i&.<ESC>
nmenu HTML.Character\ Entities.One\ Quarter\ (¼)<tab>\&14          i&14<ESC>
nmenu HTML.Character\ Entities.One\ Half\ (½)<tab>\&12             i&12<ESC>
nmenu HTML.Character\ Entities.Three\ Quarters\ (¾)<tab>\&34       i&34<ESC>
nmenu HTML.Character\ Entities.Graves.A-grave\ (À)<tab>\&A` i&A`<ESC>
nmenu HTML.Character\ Entities.Graves.a-grave\ (à)<tab>\&a` i&a`<ESC>
nmenu HTML.Character\ Entities.Graves.E-grave\ (È)<tab>\&E` i&E`<ESC>
nmenu HTML.Character\ Entities.Graves.e-grave\ (è)<tab>\&e` i&e`<ESC>
nmenu HTML.Character\ Entities.Graves.I-grave\ (Ì)<tab>\&I` i&I`<ESC>
nmenu HTML.Character\ Entities.Graves.i-grave\ (ì)<tab>\&i` i&i`<ESC>
nmenu HTML.Character\ Entities.Graves.O-grave\ (Ò)<tab>\&O` i&O`<ESC>
nmenu HTML.Character\ Entities.Graves.o-grave\ (ò)<tab>\&o` i&o`<ESC>
nmenu HTML.Character\ Entities.Graves.U-grave\ (Ù)<tab>\&U` i&U`<ESC>
nmenu HTML.Character\ Entities.Graves.u-grave\ (ù)<tab>\&u` i&u`<ESC>
nmenu HTML.Character\ Entities.Acutes.A-acute\ (Á)<tab>\&A' i&A'<ESC>
nmenu HTML.Character\ Entities.Acutes.a-acute\ (á)<tab>\&a' i&a'<ESC>
nmenu HTML.Character\ Entities.Acutes.E-acute\ (É)<tab>\&E' i&E'<ESC>
nmenu HTML.Character\ Entities.Acutes.e-acute\ (é)<tab>\&e' i&e'<ESC>
nmenu HTML.Character\ Entities.Acutes.I-acute\ (Í)<tab>\&I' i&I'<ESC>
nmenu HTML.Character\ Entities.Acutes.i-acute\ (í)<tab>\&i' i&i'<ESC>
nmenu HTML.Character\ Entities.Acutes.O-acute\ (Ó)<tab>\&O' i&O'<ESC>
nmenu HTML.Character\ Entities.Acutes.o-acute\ (ó)<tab>\&o' i&o'<ESC>
nmenu HTML.Character\ Entities.Acutes.U-acute\ (Ú)<tab>\&U' i&U'<ESC>
nmenu HTML.Character\ Entities.Acutes.u-acute\ (ú)<tab>\&u' i&u'<ESC>
nmenu HTML.Character\ Entities.Acutes.Y-acute\ (Ý)<tab>\&Y' i&Y'<ESC>
nmenu HTML.Character\ Entities.Acutes.y-acute\ (ý)<tab>\&y' i&y'<ESC>
nmenu HTML.Character\ Entities.Tildes.A-tilde\ (Ã)<tab>\&A~ i&A~<ESC>
nmenu HTML.Character\ Entities.Tildes.a-tilde\ (ã)<tab>\&a~ i&a~<ESC>
nmenu HTML.Character\ Entities.Tildes.N-tilde\ (Ñ)<tab>\&N~ i&N~<ESC>
nmenu HTML.Character\ Entities.Tildes.n-tilde\ (ñ)<tab>\&n~ i&n~<ESC>
nmenu HTML.Character\ Entities.Tildes.O-tilde\ (Õ)<tab>\&O~ i&O~<ESC>
nmenu HTML.Character\ Entities.Tildes.o-tilde\ (õ)<tab>\&o~ i&o~<ESC>
nmenu HTML.Character\ Entities.Circumflexes.A-circumflex\ (Â)<tab>\&A^ i&A^<ESC>
nmenu HTML.Character\ Entities.Circumflexes.a-circumflex\ (â)<tab>\&a^ i&a^<ESC>
nmenu HTML.Character\ Entities.Circumflexes.E-circumflex\ (Ê)<tab>\&E^ i&E^<ESC>
nmenu HTML.Character\ Entities.Circumflexes.e-circumflex\ (ê)<tab>\&e^ i&e^<ESC>
nmenu HTML.Character\ Entities.Circumflexes.I-circumflex\ (Î)<tab>\&I^ i&I^<ESC>
nmenu HTML.Character\ Entities.Circumflexes.i-circumflex\ (î)<tab>\&i^ i&i^<ESC>
nmenu HTML.Character\ Entities.Circumflexes.O-circumflex\ (Ô)<tab>\&O^ i&O^<ESC>
nmenu HTML.Character\ Entities.Circumflexes.o-circumflex\ (ô)<tab>\&o^ i&o^<ESC>
nmenu HTML.Character\ Entities.Circumflexes.U-circumflex\ (Û)<tab>\&U^ i&U^<ESC>
nmenu HTML.Character\ Entities.Circumflexes.u-circumflex\ (û)<tab>\&u^ i&u^<ESC>
nmenu HTML.Character\ Entities.Umlauts.A-umlaut\ (Ä)<tab>\&A" i&A"<ESC>
nmenu HTML.Character\ Entities.Umlauts.a-umlaut\ (ä)<tab>\&a" i&a"<ESC>
nmenu HTML.Character\ Entities.Umlauts.E-umlaut\ (Ë)<tab>\&E" i&E"<ESC>
nmenu HTML.Character\ Entities.Umlauts.e-umlaut\ (ë)<tab>\&e" i&e"<ESC>
nmenu HTML.Character\ Entities.Umlauts.I-umlaut\ (Ï)<tab>\&I" i&I"<ESC>
nmenu HTML.Character\ Entities.Umlauts.i-umlaut\ (ï)<tab>\&i" i&i"<ESC>
nmenu HTML.Character\ Entities.Umlauts.O-umlaut\ (Ö)<tab>\&O" i&O"<ESC>
nmenu HTML.Character\ Entities.Umlauts.o-umlaut\ (ö)<tab>\&o" i&o"<ESC>
nmenu HTML.Character\ Entities.Umlauts.U-umlaut\ (Ü)<tab>\&U" i&U"<ESC>
nmenu HTML.Character\ Entities.Umlauts.u-umlaut\ (ü)<tab>\&u" i&u"<ESC>
nmenu HTML.Character\ Entities.Umlauts.y-umlaut\ (ÿ)<tab>\&y" i&y"<ESC>
nmenu HTML.Character\ Entities.Umlauts.Umlaut\ (¨)<tab>\&"    i&"<ESC>
nmenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..A-ring\ (Å)<tab>\&Ao      i&Ao<ESC>
nmenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..a-ring\ (å)<tab>\&ao      i&ao<ESC>
nmenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..AE-ligature\ (Æ)<tab>\&AE i&AE<ESC>
nmenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..ae-ligature\ (æ)<tab>\&ae i&ae<ESC>
nmenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..C-cedilla\ (Ç)<tab>\&C,   i&C,<ESC>
nmenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..c-cedilla\ (ç)<tab>\&c,   i&c,<ESC>
nmenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..O-slash\ (Ø)<tab>\&O/     i&O/<ESC>
nmenu HTML.Character\ Entities.\ \ \ \ \ \ \ etc\.\.\..o-slash\ (ø)<tab>\&o/     i&o/<ESC>

let &encoding=b:save_encoding
unlet b:save_encoding

" Colors menu:   {{{2

nmenu HTML.Colors.&A.AliceBlue<TAB>(#F0F8FF)            i#F0F8FF<ESC>
nmenu HTML.Colors.&A.AntiqueWhite<TAB>(#FAEBD7)         i#FAEBD7<ESC>
nmenu HTML.Colors.&A.Aqua<TAB>(#00FFFF)                 i#00FFFF<ESC>
nmenu HTML.Colors.&A.Aquamarine<TAB>(#7FFFD4)           i#7FFFD4<ESC>
nmenu HTML.Colors.&A.Azure<TAB>(#F0FFFF)                i#F0FFFF<ESC>

nmenu HTML.Colors.&B.Beige<TAB>(#F5F5DC)                i#F5F5DC<ESC>
nmenu HTML.Colors.&B.Bisque<TAB>(#FFE4C4)               i#FFE4C4<ESC>
nmenu HTML.Colors.&B.Black<TAB>(#000000)                i#000000<ESC>
nmenu HTML.Colors.&B.BlanchedAlmond<TAB>(#FFEBCD)       i#FFEBCD<ESC>
nmenu HTML.Colors.&B.Blue<TAB>(#0000FF)                 i#0000FF<ESC>
nmenu HTML.Colors.&B.BlueViolet<TAB>(#8A2BE2)           i#8A2BE2<ESC>
nmenu HTML.Colors.&B.Brown<TAB>(#A52A2A)                i#A52A2A<ESC>
nmenu HTML.Colors.&B.Burlywood<TAB>(#DEB887)            i#DEB887<ESC>

nmenu HTML.Colors.&C.CadetBlue<TAB>(#5F9EA0)            i#5F9EA0<ESC>
nmenu HTML.Colors.&C.Chartreuse<TAB>(#7FFF00)           i#7FFF00<ESC>
nmenu HTML.Colors.&C.Chocolate<TAB>(#D2691E)            i#D2691E<ESC>
nmenu HTML.Colors.&C.Coral<TAB>(#FF7F50)                i#FF7F50<ESC>
nmenu HTML.Colors.&C.CornflowerBlue<TAB>(#6495ED)       i#6495ED<ESC>
nmenu HTML.Colors.&C.Cornsilk<TAB>(#FFF8DC)             i#FFF8DC<ESC>
nmenu HTML.Colors.&C.Crimson<TAB>(#DC143C)              i#DC143C<ESC>
nmenu HTML.Colors.&C.Cyan<TAB>(#00FFFF)                 i#00FFFF<ESC>

nmenu HTML.Colors.&D.DarkBlue<TAB>(#00008B)             i#00008B<ESC>
nmenu HTML.Colors.&D.DarkCyan<TAB>(#008B8B)             i#008B8B<ESC>
nmenu HTML.Colors.&D.DarkGoldenrod<TAB>(#B8860B)        i#B8860B<ESC>
nmenu HTML.Colors.&D.DarkGray<TAB>(#A9A9A9)             i#A9A9A9<ESC>
nmenu HTML.Colors.&D.DarkGreen<TAB>(#006400)            i#006400<ESC>
nmenu HTML.Colors.&D.DarkKhaki<TAB>(#BDB76B)            i#BDB76B<ESC>
nmenu HTML.Colors.&D.DarkMagenta<TAB>(#8B008B)          i#8B008B<ESC>
nmenu HTML.Colors.&D.DarkOliveGreen<TAB>(#556B2F)       i#556B2F<ESC>
nmenu HTML.Colors.&D.DarkOrange<TAB>(#FF8C00)           i#FF8C00<ESC>
nmenu HTML.Colors.&D.DarkOrchid<TAB>(#9932CC)           i#9932CC<ESC>
nmenu HTML.Colors.&D.DarkRed<TAB>(#8B0000)              i#8B0000<ESC>
nmenu HTML.Colors.&D.DarkSalmon<TAB>(#E9967A)           i#E9967A<ESC>
nmenu HTML.Colors.&D.DarkSeagreen<TAB>(#8FBC8F)         i#8FBC8F<ESC>
nmenu HTML.Colors.&D.DarkSlateBlue<TAB>(#483D8B)        i#483D8B<ESC>
nmenu HTML.Colors.&D.DarkSlateGray<TAB>(#2F4F4F)        i#2F4F4F<ESC>
nmenu HTML.Colors.&D.DarkTurquoise<TAB>(#00CED1)        i#00CED1<ESC>
nmenu HTML.Colors.&D.DarkViolet<TAB>(#9400D3)           i#9400D3<ESC>
nmenu HTML.Colors.&D.DeepPink<TAB>(#FF1493)             i#FF1493<ESC>
nmenu HTML.Colors.&D.DeepSkyblue<TAB>(#00BFFF)          i#00BFFF<ESC>
nmenu HTML.Colors.&D.DimGray<TAB>(#696969)              i#696969<ESC>
nmenu HTML.Colors.&D.Dodgerblue<TAB>(#1E90FF)           i#1E90FF<ESC>

nmenu HTML.Colors.&F.Firebrick<TAB>(#B22222)            i#B22222<ESC>
nmenu HTML.Colors.&F.FloralWhite<TAB>(#FFFAF0)          i#FFFAF0<ESC>
nmenu HTML.Colors.&F.ForestGreen<TAB>(#228B22)          i#228B22<ESC>
nmenu HTML.Colors.&F.Fuchsia<TAB>(#FF00FF)              i#FF00FF<ESC>

nmenu HTML.Colors.&G.Gainsboro<TAB>(#DCDCDC)            i#DCDCDC<ESC>
nmenu HTML.Colors.&G.GhostWhite<TAB>(#F8F8FF)           i#F8F8FF<ESC>
nmenu HTML.Colors.&G.Gold<TAB>(#FFD700)                 i#FFD700<ESC>
nmenu HTML.Colors.&G.Goldenrod<TAB>(#DAA520)            i#DAA520<ESC>
nmenu HTML.Colors.&G.Gray<TAB>(#808080)                 i#808080<ESC>
nmenu HTML.Colors.&G.Green<TAB>(#008000)                i#008000<ESC>
nmenu HTML.Colors.&G.GreenYellow<TAB>(#ADFF2F)          i#ADFF2F<ESC>

nmenu HTML.Colors.&H-K.Honeydew<TAB>(#F0FFF0)           i#F0FFF0<ESC>
nmenu HTML.Colors.&H-K.HotPink<TAB>(#FF69B4)            i#FF69B4<ESC>
nmenu HTML.Colors.&H-K.IndianRed<TAB>(#CD5C5C)          i#CD5C5C<ESC>
nmenu HTML.Colors.&H-K.Indigo<TAB>(#4B0082)             i#4B0082<ESC>
nmenu HTML.Colors.&H-K.Ivory<TAB>(#FFFFF0)              i#FFFFF0<ESC>
nmenu HTML.Colors.&H-K.Khaki<TAB>(#F0E68C)              i#F0E68C<ESC>

nmenu HTML.Colors.&L.Lavender<TAB>(#E6E6FA)             i#E6E6FA<ESC>
nmenu HTML.Colors.&L.LavenderBlush<TAB>(#FFF0F5)        i#FFF0F5<ESC>
nmenu HTML.Colors.&L.LawnGreen<TAB>(#7CFC00)            i#7CFC00<ESC>
nmenu HTML.Colors.&L.LemonChiffon<TAB>(#FFFACD)         i#FFFACD<ESC>
nmenu HTML.Colors.&L.LightBlue<TAB>(#ADD8E6)            i#ADD8E6<ESC>
nmenu HTML.Colors.&L.LightCoral<TAB>(#F08080)           i#F08080<ESC>
nmenu HTML.Colors.&L.LightCyan<TAB>(#E0FFFF)            i#E0FFFF<ESC>
nmenu HTML.Colors.&L.LightGoldenrodYellow<TAB>(#FAFAD2) i#FAFAD2<ESC>
nmenu HTML.Colors.&L.LightGreen<TAB>(#90EE90)           i#90EE90<ESC>
nmenu HTML.Colors.&L.LightGrey<TAB>(#D3D3D3)            i#D3D3D3<ESC>
nmenu HTML.Colors.&L.LightPink<TAB>(#FFB6C1)            i#FFB6C1<ESC>
nmenu HTML.Colors.&L.LightSalmon<TAB>(#FFA07A)          i#FFA07A<ESC>
nmenu HTML.Colors.&L.LightSeaGreen<TAB>(#20B2AA)        i#20B2AA<ESC>
nmenu HTML.Colors.&L.LightSkyBlue<TAB>(#87CEFA)         i#87CEFA<ESC>
nmenu HTML.Colors.&L.LightSlaTegray<TAB>(#778899)       i#778899<ESC>
nmenu HTML.Colors.&L.LightSteelBlue<TAB>(#B0C4DE)       i#B0C4DE<ESC>
nmenu HTML.Colors.&L.LightYellow<TAB>(#FFFFE0)          i#FFFFE0<ESC>
nmenu HTML.Colors.&L.Lime<TAB>(#00FF00)                 i#00FF00<ESC>
nmenu HTML.Colors.&L.LimeGreen<TAB>(#32CD32)            i#32CD32<ESC>
nmenu HTML.Colors.&L.Linen<TAB>(#FAF0E6)                i#FAF0E6<ESC>

nmenu HTML.Colors.&M.Magenta<TAB>(#FF00FF)              i#FF00FF<ESC>
nmenu HTML.Colors.&M.Maroon<TAB>(#800000)               i#800000<ESC>
nmenu HTML.Colors.&M.MediumAquamarine<TAB>(#66CDAA)     i#66CDAA<ESC>
nmenu HTML.Colors.&M.MediumBlue<TAB>(#0000CD)           i#0000CD<ESC>
nmenu HTML.Colors.&M.MediumOrchid<TAB>(#BA55D3)         i#BA55D3<ESC>
nmenu HTML.Colors.&M.MediumPurple<TAB>(#9370DB)         i#9370DB<ESC>
nmenu HTML.Colors.&M.MediumSeaGreen<TAB>(#3CB371)       i#3CB371<ESC>
nmenu HTML.Colors.&M.MediumSlateBlue<TAB>(#7B68EE)      i#7B68EE<ESC>
nmenu HTML.Colors.&M.MediumSpringGreen<TAB>(#00FA9A)    i#00FA9A<ESC>
nmenu HTML.Colors.&M.MediumTurquoise<TAB>(#48D1CC)      i#48D1CC<ESC>
nmenu HTML.Colors.&M.MediumVioletRed<TAB>(#C71585)      i#C71585<ESC>
nmenu HTML.Colors.&M.MidnightBlue<TAB>(#191970)         i#191970<ESC>
nmenu HTML.Colors.&M.Mintcream<TAB>(#F5FFFA)            i#F5FFFA<ESC>
nmenu HTML.Colors.&M.Mistyrose<TAB>(#FFE4E1)            i#FFE4E1<ESC>
nmenu HTML.Colors.&M.Moccasin<TAB>(#FFE4B5)             i#FFE4B5<ESC>

nmenu HTML.Colors.&N.NavajoWhite<TAB>(#FFDEAD)          i#FFDEAD<ESC>
nmenu HTML.Colors.&N.Navy<TAB>(#000080)                 i#000080<ESC>

nmenu HTML.Colors.&O.OldLace<TAB>(#FDF5E6)              i#FDF5E6<ESC>
nmenu HTML.Colors.&O.Olive<TAB>(#808000)                i#808000<ESC>
nmenu HTML.Colors.&O.OliveDrab<TAB>(#6B8E23)            i#6B8E23<ESC>
nmenu HTML.Colors.&O.Orange<TAB>(#FFA500)               i#FFA500<ESC>
nmenu HTML.Colors.&O.OrangeRed<TAB>(#FF4500)            i#FF4500<ESC>
nmenu HTML.Colors.&O.Orchid<TAB>(#DA70D6)               i#DA70D6<ESC>

nmenu HTML.Colors.&P.PaleGoldenrod<TAB>(#EEE8AA)        i#EEE8AA<ESC>
nmenu HTML.Colors.&P.PaleGreen<TAB>(#98FB98)            i#98FB98<ESC>
nmenu HTML.Colors.&P.PaleTurquoise<TAB>(#AFEEEE)        i#AFEEEE<ESC>
nmenu HTML.Colors.&P.PaleVioletred<TAB>(#DB7093)        i#DB7093<ESC>
nmenu HTML.Colors.&P.Papayawhip<TAB>(#FFEFD5)           i#FFEFD5<ESC>
nmenu HTML.Colors.&P.Peachpuff<TAB>(#FFDAB9)            i#FFDAB9<ESC>
nmenu HTML.Colors.&P.Peru<TAB>(#CD853F)                 i#CD853F<ESC>
nmenu HTML.Colors.&P.Pink<TAB>(#FFC0CB)                 i#FFC0CB<ESC>
nmenu HTML.Colors.&P.Plum<TAB>(#DDA0DD)                 i#DDA0DD<ESC>
nmenu HTML.Colors.&P.PowderBlue<TAB>(#B0E0E6)           i#B0E0E6<ESC>
nmenu HTML.Colors.&P.Purple<TAB>(#800080)               i#800080<ESC>

nmenu HTML.Colors.&R.Red<TAB>(#FF0000)                  i#FF0000<ESC>
nmenu HTML.Colors.&R.RosyBrown<TAB>(#BC8F8F)            i#BC8F8F<ESC>
nmenu HTML.Colors.&R.RoyalBlue<TAB>(#4169E1)            i#4169E1<ESC>

nmenu HTML.Colors.&S.SaddleBrown<TAB>(#8B4513)          i#8B4513<ESC>
nmenu HTML.Colors.&S.Salmon<TAB>(#FA8072)               i#FA8072<ESC>
nmenu HTML.Colors.&S.SandyBrown<TAB>(#F4A460)           i#F4A460<ESC>
nmenu HTML.Colors.&S.SeaGreen<TAB>(#2E8B57)             i#2E8B57<ESC>
nmenu HTML.Colors.&S.Seashell<TAB>(#FFF5EE)             i#FFF5EE<ESC>
nmenu HTML.Colors.&S.Sienna<TAB>(#A0522D)               i#A0522D<ESC>
nmenu HTML.Colors.&S.Silver<TAB>(#C0C0C0)               i#C0C0C0<ESC>
nmenu HTML.Colors.&S.SkyBlue<TAB>(#87CEEB)              i#87CEEB<ESC>
nmenu HTML.Colors.&S.SlateBlue<TAB>(#6A5ACD)            i#6A5ACD<ESC>
nmenu HTML.Colors.&S.SlateGray<TAB>(#708090)            i#708090<ESC>
nmenu HTML.Colors.&S.Snow<TAB>(#FFFAFA)                 i#FFFAFA<ESC>
nmenu HTML.Colors.&S.SpringGreen<TAB>(#00FF7F)          i#00FF7F<ESC>
nmenu HTML.Colors.&S.SteelBlue<TAB>(#4682B4)            i#4682B4<ESC>

nmenu HTML.Colors.&T-Z.Tan<TAB>(#D2B48C)                i#D2B48C<ESC>
nmenu HTML.Colors.&T-Z.Teal<TAB>(#008080)               i#008080<ESC>
nmenu HTML.Colors.&T-Z.Thistle<TAB>(#D8BFD8)            i#D8BFD8<ESC>
nmenu HTML.Colors.&T-Z.Tomato<TAB>(#FF6347)             i#FF6347<ESC>
nmenu HTML.Colors.&T-Z.Turquoise<TAB>(#40E0D0)          i#40E0D0<ESC>
nmenu HTML.Colors.&T-Z.Violet<TAB>(#EE82EE)             i#EE82EE<ESC>


imenu HTML.Colors.&A.AliceBlue<TAB>(#F0F8FF)            #F0F8FF
imenu HTML.Colors.&A.AntiqueWhite<TAB>(#FAEBD7)         #FAEBD7
imenu HTML.Colors.&A.Aqua<TAB>(#00FFFF)                 #00FFFF
imenu HTML.Colors.&A.Aquamarine<TAB>(#7FFFD4)           #7FFFD4
imenu HTML.Colors.&A.Azure<TAB>(#F0FFFF)                #F0FFFF

imenu HTML.Colors.&B.Beige<TAB>(#F5F5DC)                #F5F5DC
imenu HTML.Colors.&B.Bisque<TAB>(#FFE4C4)               #FFE4C4
imenu HTML.Colors.&B.Black<TAB>(#000000)                #000000
imenu HTML.Colors.&B.BlanchedAlmond<TAB>(#FFEBCD)       #FFEBCD
imenu HTML.Colors.&B.Blue<TAB>(#0000FF)                 #0000FF
imenu HTML.Colors.&B.BlueViolet<TAB>(#8A2BE2)           #8A2BE2
imenu HTML.Colors.&B.Brown<TAB>(#A52A2A)                #A52A2A
imenu HTML.Colors.&B.Burlywood<TAB>(#DEB887)            #DEB887

imenu HTML.Colors.&C.CadetBlue<TAB>(#5F9EA0)            #5F9EA0
imenu HTML.Colors.&C.Chartreuse<TAB>(#7FFF00)           #7FFF00
imenu HTML.Colors.&C.Chocolate<TAB>(#D2691E)            #D2691E
imenu HTML.Colors.&C.Coral<TAB>(#FF7F50)                #FF7F50
imenu HTML.Colors.&C.CornflowerBlue<TAB>(#6495ED)       #6495ED
imenu HTML.Colors.&C.Cornsilk<TAB>(#FFF8DC)             #FFF8DC
imenu HTML.Colors.&C.Crimson<TAB>(#DC143C)              #DC143C
imenu HTML.Colors.&C.Cyan<TAB>(#00FFFF)                 #00FFFF

imenu HTML.Colors.&D.DarkBlue<TAB>(#00008B)             #00008B
imenu HTML.Colors.&D.DarkCyan<TAB>(#008B8B)             #008B8B
imenu HTML.Colors.&D.DarkGoldenrod<TAB>(#B8860B)        #B8860B
imenu HTML.Colors.&D.DarkGray<TAB>(#A9A9A9)             #A9A9A9
imenu HTML.Colors.&D.DarkGreen<TAB>(#006400)            #006400
imenu HTML.Colors.&D.DarkKhaki<TAB>(#BDB76B)            #BDB76B
imenu HTML.Colors.&D.DarkMagenta<TAB>(#8B008B)          #8B008B
imenu HTML.Colors.&D.DarkOliveGreen<TAB>(#556B2F)       #556B2F
imenu HTML.Colors.&D.DarkOrange<TAB>(#FF8C00)           #FF8C00
imenu HTML.Colors.&D.DarkOrchid<TAB>(#9932CC)           #9932CC
imenu HTML.Colors.&D.DarkRed<TAB>(#8B0000)              #8B0000
imenu HTML.Colors.&D.DarkSalmon<TAB>(#E9967A)           #E9967A
imenu HTML.Colors.&D.DarkSeagreen<TAB>(#8FBC8F)         #8FBC8F
imenu HTML.Colors.&D.DarkSlateBlue<TAB>(#483D8B)        #483D8B
imenu HTML.Colors.&D.DarkSlateGray<TAB>(#2F4F4F)        #2F4F4F
imenu HTML.Colors.&D.DarkTurquoise<TAB>(#00CED1)        #00CED1
imenu HTML.Colors.&D.DarkViolet<TAB>(#9400D3)           #9400D3
imenu HTML.Colors.&D.DeepPink<TAB>(#FF1493)             #FF1493
imenu HTML.Colors.&D.DeepSkyblue<TAB>(#00BFFF)          #00BFFF
imenu HTML.Colors.&D.DimGray<TAB>(#696969)              #696969
imenu HTML.Colors.&D.Dodgerblue<TAB>(#1E90FF)           #1E90FF

imenu HTML.Colors.&F.Firebrick<TAB>(#B22222)            #B22222
imenu HTML.Colors.&F.FloralWhite<TAB>(#FFFAF0)          #FFFAF0
imenu HTML.Colors.&F.ForestGreen<TAB>(#228B22)          #228B22
imenu HTML.Colors.&F.Fuchsia<TAB>(#FF00FF)              #FF00FF

imenu HTML.Colors.&G.Gainsboro<TAB>(#DCDCDC)            #DCDCDC
imenu HTML.Colors.&G.GhostWhite<TAB>(#F8F8FF)           #F8F8FF
imenu HTML.Colors.&G.Gold<TAB>(#FFD700)                 #FFD700
imenu HTML.Colors.&G.Goldenrod<TAB>(#DAA520)            #DAA520
imenu HTML.Colors.&G.Gray<TAB>(#808080)                 #808080
imenu HTML.Colors.&G.Green<TAB>(#008000)                #008000
imenu HTML.Colors.&G.GreenYellow<TAB>(#ADFF2F)          #ADFF2F

imenu HTML.Colors.&H-K.Honeydew<TAB>(#F0FFF0)           #F0FFF0
imenu HTML.Colors.&H-K.HotPink<TAB>(#FF69B4)            #FF69B4
imenu HTML.Colors.&H-K.IndianRed<TAB>(#CD5C5C)          #CD5C5C
imenu HTML.Colors.&H-K.Indigo<TAB>(#4B0082)             #4B0082
imenu HTML.Colors.&H-K.Ivory<TAB>(#FFFFF0)              #FFFFF0
imenu HTML.Colors.&H-K.Khaki<TAB>(#F0E68C)              #F0E68C

imenu HTML.Colors.&L.Lavender<TAB>(#E6E6FA)             #E6E6FA
imenu HTML.Colors.&L.LavenderBlush<TAB>(#FFF0F5)        #FFF0F5
imenu HTML.Colors.&L.LawnGreen<TAB>(#7CFC00)            #7CFC00
imenu HTML.Colors.&L.LemonChiffon<TAB>(#FFFACD)         #FFFACD
imenu HTML.Colors.&L.LightBlue<TAB>(#ADD8E6)            #ADD8E6
imenu HTML.Colors.&L.LightCoral<TAB>(#F08080)           #F08080
imenu HTML.Colors.&L.LightCyan<TAB>(#E0FFFF)            #E0FFFF
imenu HTML.Colors.&L.LightGoldenrodYellow<TAB>(#FAFAD2) #FAFAD2
imenu HTML.Colors.&L.LightGreen<TAB>(#90EE90)           #90EE90
imenu HTML.Colors.&L.LightGrey<TAB>(#D3D3D3)            #D3D3D3
imenu HTML.Colors.&L.LightPink<TAB>(#FFB6C1)            #FFB6C1
imenu HTML.Colors.&L.LightSalmon<TAB>(#FFA07A)          #FFA07A
imenu HTML.Colors.&L.LightSeaGreen<TAB>(#20B2AA)        #20B2AA
imenu HTML.Colors.&L.LightSkyBlue<TAB>(#87CEFA)         #87CEFA
imenu HTML.Colors.&L.LightSlaTegray<TAB>(#778899)       #778899
imenu HTML.Colors.&L.LightSteelBlue<TAB>(#B0C4DE)       #B0C4DE
imenu HTML.Colors.&L.LightYellow<TAB>(#FFFFE0)          #FFFFE0
imenu HTML.Colors.&L.Lime<TAB>(#00FF00)                 #00FF00
imenu HTML.Colors.&L.LimeGreen<TAB>(#32CD32)            #32CD32
imenu HTML.Colors.&L.Linen<TAB>(#FAF0E6)                #FAF0E6

imenu HTML.Colors.&M.Magenta<TAB>(#FF00FF)              #FF00FF
imenu HTML.Colors.&M.Maroon<TAB>(#800000)               #800000
imenu HTML.Colors.&M.MediumAquamarine<TAB>(#66CDAA)     #66CDAA
imenu HTML.Colors.&M.MediumBlue<TAB>(#0000CD)           #0000CD
imenu HTML.Colors.&M.MediumOrchid<TAB>(#BA55D3)         #BA55D3
imenu HTML.Colors.&M.MediumPurple<TAB>(#9370DB)         #9370DB
imenu HTML.Colors.&M.MediumSeaGreen<TAB>(#3CB371)       #3CB371
imenu HTML.Colors.&M.MediumSlateBlue<TAB>(#7B68EE)      #7B68EE
imenu HTML.Colors.&M.MediumSpringGreen<TAB>(#00FA9A)    #00FA9A
imenu HTML.Colors.&M.MediumTurquoise<TAB>(#48D1CC)      #48D1CC
imenu HTML.Colors.&M.MediumVioletRed<TAB>(#C71585)      #C71585
imenu HTML.Colors.&M.MidnightBlue<TAB>(#191970)         #191970
imenu HTML.Colors.&M.Mintcream<TAB>(#F5FFFA)            #F5FFFA
imenu HTML.Colors.&M.Mistyrose<TAB>(#FFE4E1)            #FFE4E1
imenu HTML.Colors.&M.Moccasin<TAB>(#FFE4B5)             #FFE4B5

imenu HTML.Colors.&N.NavajoWhite<TAB>(#FFDEAD)          #FFDEAD
imenu HTML.Colors.&N.Navy<TAB>(#000080)                 #000080

imenu HTML.Colors.&O.OldLace<TAB>(#FDF5E6)              #FDF5E6
imenu HTML.Colors.&O.Olive<TAB>(#808000)                #808000
imenu HTML.Colors.&O.OliveDrab<TAB>(#6B8E23)            #6B8E23
imenu HTML.Colors.&O.Orange<TAB>(#FFA500)               #FFA500
imenu HTML.Colors.&O.OrangeRed<TAB>(#FF4500)            #FF4500
imenu HTML.Colors.&O.Orchid<TAB>(#DA70D6)               #DA70D6

imenu HTML.Colors.&P.PaleGoldenrod<TAB>(#EEE8AA)        #EEE8AA
imenu HTML.Colors.&P.PaleGreen<TAB>(#98FB98)            #98FB98
imenu HTML.Colors.&P.PaleTurquoise<TAB>(#AFEEEE)        #AFEEEE
imenu HTML.Colors.&P.PaleVioletred<TAB>(#DB7093)        #DB7093
imenu HTML.Colors.&P.Papayawhip<TAB>(#FFEFD5)           #FFEFD5
imenu HTML.Colors.&P.Peachpuff<TAB>(#FFDAB9)            #FFDAB9
imenu HTML.Colors.&P.Peru<TAB>(#CD853F)                 #CD853F
imenu HTML.Colors.&P.Pink<TAB>(#FFC0CB)                 #FFC0CB
imenu HTML.Colors.&P.Plum<TAB>(#DDA0DD)                 #DDA0DD
imenu HTML.Colors.&P.PowderBlue<TAB>(#B0E0E6)           #B0E0E6
imenu HTML.Colors.&P.Purple<TAB>(#800080)               #800080

imenu HTML.Colors.&R.Red<TAB>(#FF0000)                  #FF0000
imenu HTML.Colors.&R.RosyBrown<TAB>(#BC8F8F)            #BC8F8F
imenu HTML.Colors.&R.RoyalBlue<TAB>(#4169E1)            #4169E1

imenu HTML.Colors.&S.SaddleBrown<TAB>(#8B4513)          #8B4513
imenu HTML.Colors.&S.Salmon<TAB>(#FA8072)               #FA8072
imenu HTML.Colors.&S.SandyBrown<TAB>(#F4A460)           #F4A460
imenu HTML.Colors.&S.SeaGreen<TAB>(#2E8B57)             #2E8B57
imenu HTML.Colors.&S.Seashell<TAB>(#FFF5EE)             #FFF5EE
imenu HTML.Colors.&S.Sienna<TAB>(#A0522D)               #A0522D
imenu HTML.Colors.&S.Silver<TAB>(#C0C0C0)               #C0C0C0
imenu HTML.Colors.&S.SkyBlue<TAB>(#87CEEB)              #87CEEB
imenu HTML.Colors.&S.SlateBlue<TAB>(#6A5ACD)            #6A5ACD
imenu HTML.Colors.&S.SlateGray<TAB>(#708090)            #708090
imenu HTML.Colors.&S.Snow<TAB>(#FFFAFA)                 #FFFAFA
imenu HTML.Colors.&S.SpringGreen<TAB>(#00FF7F)          #00FF7F
imenu HTML.Colors.&S.SteelBlue<TAB>(#4682B4)            #4682B4

imenu HTML.Colors.&T-Z.Tan<TAB>(#D2B48C)                #D2B48C
imenu HTML.Colors.&T-Z.Teal<TAB>(#008080)               #008080
imenu HTML.Colors.&T-Z.Thistle<TAB>(#D8BFD8)            #D8BFD8
imenu HTML.Colors.&T-Z.Tomato<TAB>(#FF6347)             #FF6347
imenu HTML.Colors.&T-Z.Turquoise<TAB>(#40E0D0)          #40E0D0
imenu HTML.Colors.&T-Z.Violet<TAB>(#EE82EE)             #EE82EE

" Font Styles menu:   {{{2

imenu HTML.Font\ Styles.Bold<tab>;bo           ;bo
vmenu HTML.Font\ Styles.Bold<tab>;bo           ;bo
nmenu HTML.Font\ Styles.Bold<tab>;bo           i;bo
imenu HTML.Font\ Styles.Italics<tab>;it        ;it
vmenu HTML.Font\ Styles.Italics<tab>;it        ;it
nmenu HTML.Font\ Styles.Italics<tab>;it        i;it
imenu HTML.Font\ Styles.Underline<tab>;un      ;un
vmenu HTML.Font\ Styles.Underline<tab>;un      ;un
nmenu HTML.Font\ Styles.Underline<tab>;un      i;un
imenu HTML.Font\ Styles.Big<tab>;bi            ;bi
vmenu HTML.Font\ Styles.Big<tab>;bi            ;bi
nmenu HTML.Font\ Styles.Big<tab>;bi            i;bi
imenu HTML.Font\ Styles.Small<tab>;sm          ;sm
vmenu HTML.Font\ Styles.Small<tab>;sm          ;sm
nmenu HTML.Font\ Styles.Small<tab>;sm          i;sm
 menu HTML.Font\ Styles.-sep1-                 <nul>
imenu HTML.Font\ Styles.Font\ Size<tab>;fo     ;fo
vmenu HTML.Font\ Styles.Font\ Size<tab>;fo     ;fo
nmenu HTML.Font\ Styles.Font\ Size<tab>;fo     i;fo
imenu HTML.Font\ Styles.Font\ Color<tab>;fc    ;fc
vmenu HTML.Font\ Styles.Font\ Color<tab>;fc    ;fc
nmenu HTML.Font\ Styles.Font\ Color<tab>;fc    i;fc
 menu HTML.Font\ Styles.-sep2-                 <nul>
imenu HTML.Font\ Styles.CITE<tab>;ci           ;ci
vmenu HTML.Font\ Styles.CITE<tab>;ci           ;ci
nmenu HTML.Font\ Styles.CITE<tab>;ci           i;ci
imenu HTML.Font\ Styles.CODE<tab>;co           ;co
vmenu HTML.Font\ Styles.CODE<tab>;co           ;co
nmenu HTML.Font\ Styles.CODE<tab>;co           i;co
imenu HTML.Font\ Styles.Inserted\ Text<tab>;in ;in
vmenu HTML.Font\ Styles.Inserted\ Text<tab>;in ;in
nmenu HTML.Font\ Styles.Inserted\ Text<tab>;in i;in
imenu HTML.Font\ Styles.Deleted\ Text<tab>;de  ;de
vmenu HTML.Font\ Styles.Deleted\ Text<tab>;de  ;de
nmenu HTML.Font\ Styles.Deleted\ Text<tab>;de  i;de
imenu HTML.Font\ Styles.Emphasize<tab>;em      ;em
vmenu HTML.Font\ Styles.Emphasize<tab>;em      ;em
nmenu HTML.Font\ Styles.Emphasize<tab>;em      i;em
imenu HTML.Font\ Styles.Keyboard\ Text<tab>;kb ;kb
vmenu HTML.Font\ Styles.Keyboard\ Text<tab>;kb ;kb
nmenu HTML.Font\ Styles.Keyboard\ Text<tab>;kb i;kb
imenu HTML.Font\ Styles.Sample\ Text<tab>;sa   ;sa
vmenu HTML.Font\ Styles.Sample\ Text<tab>;sa   ;sa
nmenu HTML.Font\ Styles.Sample\ Text<tab>;sa   i;sa
imenu HTML.Font\ Styles.Strikethrough<tab>;sk  ;sk
vmenu HTML.Font\ Styles.Strikethrough<tab>;sk  ;sk
nmenu HTML.Font\ Styles.Strikethrough<tab>;sk  i;sk
imenu HTML.Font\ Styles.STRONG<tab>;st         ;st
vmenu HTML.Font\ Styles.STRONG<tab>;st         ;st
nmenu HTML.Font\ Styles.STRONG<tab>;st         i;st
imenu HTML.Font\ Styles.Subscript<tab>;sb      ;sb
vmenu HTML.Font\ Styles.Subscript<tab>;sb      ;sb
nmenu HTML.Font\ Styles.Subscript<tab>;sb      i;sb
imenu HTML.Font\ Styles.Superscript<tab>;sp    ;sp
vmenu HTML.Font\ Styles.Superscript<tab>;sp    ;sp
nmenu HTML.Font\ Styles.Superscript<tab>;sp    i;sp
imenu HTML.Font\ Styles.Teletype\ Text<tab>;tt ;tt
vmenu HTML.Font\ Styles.Teletype\ Text<tab>;tt ;tt
nmenu HTML.Font\ Styles.Teletype\ Text<tab>;tt i;tt
imenu HTML.Font\ Styles.Variable<tab>;va       ;va
vmenu HTML.Font\ Styles.Variable<tab>;va       ;va
nmenu HTML.Font\ Styles.Variable<tab>;va       i;va


" Frames menu:   {{{2

imenu HTML.Frames.FRAMESET<tab>;fs             ;fs
vmenu HTML.Frames.FRAMESET<tab>;fs             ;fs
nmenu HTML.Frames.FRAMESET<tab>;fs             i;fs
imenu HTML.Frames.FRAME<tab>;fr                ;fr
vmenu HTML.Frames.FRAME<tab>;fr                ;fr
nmenu HTML.Frames.FRAME<tab>;fr                i;fr
imenu HTML.Frames.NOFRAMES<tab>;nf             ;nf
vmenu HTML.Frames.NOFRAMES<tab>;nf             ;nf
nmenu HTML.Frames.NOFRAMES<tab>;nf             i;nf
imenu HTML.Frames.IFRAME<tab>;if               ;if
vmenu HTML.Frames.IFRAME<tab>;if               ;if
nmenu HTML.Frames.IFRAME<tab>;if               i;if


" Headers menu:   {{{2

imenu HTML.Headers.Header\ Level\ 1<tab>;h1    ;h1
imenu HTML.Headers.Header\ Level\ 2<tab>;h2    ;h2
imenu HTML.Headers.Header\ Level\ 3<tab>;h3    ;h3
imenu HTML.Headers.Header\ Level\ 4<tab>;h4    ;h4
imenu HTML.Headers.Header\ Level\ 5<tab>;h5    ;h5
imenu HTML.Headers.Header\ Level\ 6<tab>;h6    ;h6
vmenu HTML.Headers.Header\ Level\ 1<tab>;h1    ;h1
vmenu HTML.Headers.Header\ Level\ 2<tab>;h2    ;h2
vmenu HTML.Headers.Header\ Level\ 3<tab>;h3    ;h3
vmenu HTML.Headers.Header\ Level\ 4<tab>;h4    ;h4
vmenu HTML.Headers.Header\ Level\ 5<tab>;h5    ;h5
vmenu HTML.Headers.Header\ Level\ 6<tab>;h6    ;h6
nmenu HTML.Headers.Header\ Level\ 1<tab>;h1    i;h1
nmenu HTML.Headers.Header\ Level\ 2<tab>;h2    i;h2
nmenu HTML.Headers.Header\ Level\ 3<tab>;h3    i;h3
nmenu HTML.Headers.Header\ Level\ 4<tab>;h4    i;h4
nmenu HTML.Headers.Header\ Level\ 5<tab>;h5    i;h5
nmenu HTML.Headers.Header\ Level\ 6<tab>;h6    i;h6


" Lists menu:   {{{2

imenu HTML.Lists.Ordered\ List<tab>;ol         ;ol
vmenu HTML.Lists.Ordered\ List<tab>;ol         ;ol
nmenu HTML.Lists.Ordered\ List<tab>;ol         i;ol
imenu HTML.Lists.Unordered\ List<tab>;ul       ;ul
vmenu HTML.Lists.Unordered\ List<tab>;ul       ;ul
nmenu HTML.Lists.Unordered\ List<tab>;ul       i;ul
imenu HTML.Lists.List\ Item<tab>;li            ;li
nmenu HTML.Lists.List\ Item<tab>;li            i;li
imenu HTML.Lists.List\ Header<tab>;lh          ;lh
vmenu HTML.Lists.List\ Header<tab>;lh          ;lh
nmenu HTML.Lists.List\ Header<tab>;lh          i;lh
 menu HTML.Lists.-sep1-                        <nul>
imenu HTML.Lists.Definition\ List<tab>;dl      ;dl
vmenu HTML.Lists.Definition\ List<tab>;dl      ;dl
nmenu HTML.Lists.Definition\ List<tab>;dl      i;dl
imenu HTML.Lists.Definition\ Term<tab>;dt      ;dt
nmenu HTML.Lists.Definition\ Term<tab>;dt      i;dt
imenu HTML.Lists.Definition\ Body<tab>;dd      ;dd
nmenu HTML.Lists.Definition\ Body<tab>;dd      i;dd


" Tables menu:   {{{2

nmenu HTML.Tables.Interactive\ Table<tab>;ta   ;ta
imenu HTML.Tables.TABLE<tab>;ta                ;ta
vmenu HTML.Tables.TABLE<tab>;ta                ;ta
"nmenu HTML.Tables.TABLE<tab>;ta                i;ta
imenu HTML.Tables.Row<TAB>;tr                  ;tr
vmenu HTML.Tables.Row<TAB>;tr                  ;tr
nmenu HTML.Tables.Row<TAB>;tr                  i;tr
imenu HTML.Tables.Data<tab>;td                 ;td
vmenu HTML.Tables.Data<tab>;td                 ;td
nmenu HTML.Tables.Data<tab>;td                 i;td
imenu HTML.Tables.CAPTION<tab>;ca              ;ca
vmenu HTML.Tables.CAPTION<tab>;ca              ;ca
nmenu HTML.Tables.CAPTION<tab>;ca              i;ca
imenu HTML.Tables.Header<tab>;th               ;th
vmenu HTML.Tables.Header<tab>;th               ;th
nmenu HTML.Tables.Header<tab>;th               i;th


" Forms menu:   {{{2

imenu HTML.Forms.FORM<TAB>;fm                  ;fm
vmenu HTML.Forms.FORM<TAB>;fm                  ;fm
nmenu HTML.Forms.FORM<TAB>;fm                  i;fm
imenu HTML.Forms.BUTTON<TAB>;bu                ;bu
vmenu HTML.Forms.BUTTON<TAB>;bu                ;bu
nmenu HTML.Forms.BUTTON<TAB>;bu                i;bu
imenu HTML.Forms.CHECKBOX<TAB>;ch              ;ch
vmenu HTML.Forms.CHECKBOX<TAB>;ch              ;ch
nmenu HTML.Forms.CHECKBOX<TAB>;ch              i;ch
imenu HTML.Forms.RADIO<TAB>;ra                 ;ra
vmenu HTML.Forms.RADIO<TAB>;ra                 ;ra
nmenu HTML.Forms.RADIO<TAB>;ra                 i;ra
imenu HTML.Forms.HIDDEN<TAB>;hi                ;hi
vmenu HTML.Forms.HIDDEN<TAB>;hi                ;hi
nmenu HTML.Forms.HIDDEN<TAB>;hi                i;hi
imenu HTML.Forms.PASSWORD<TAB>;pa              ;pa
vmenu HTML.Forms.PASSWORD<TAB>;pa              ;pa
nmenu HTML.Forms.PASSWORD<TAB>;pa              i;pa
imenu HTML.Forms.TEXT<TAB>;te                  ;te
vmenu HTML.Forms.TEXT<TAB>;te                  ;te
nmenu HTML.Forms.TEXT<TAB>;te                  i;te
imenu HTML.Forms.SELECT<TAB>;se                ;se
vmenu HTML.Forms.SELECT<TAB>;se                ;se
nmenu HTML.Forms.SELECT<TAB>;se                i;se
imenu HTML.Forms.SELECT\ MULTIPLE<TAB>;ms      ;ms
vmenu HTML.Forms.SELECT\ MULTIPLE<TAB>;ms      ;ms
nmenu HTML.Forms.SELECT\ MULTIPLE<TAB>;ms      i;ms
imenu HTML.Forms.OPTION<TAB>;op                ;op
vmenu HTML.Forms.OPTION<TAB>;op                <ESC>a;op
nmenu HTML.Forms.OPTION<TAB>;op                i;op
imenu HTML.Forms.OPTGROUP<TAB>;og              ;og
vmenu HTML.Forms.OPTGROUP<TAB>;og              ;og
nmenu HTML.Forms.OPTGROUP<TAB>;og              i;og
imenu HTML.Forms.TEXTAREA<TAB>;tx              ;tx
vmenu HTML.Forms.TEXTAREA<TAB>;tx              ;tx
nmenu HTML.Forms.TEXTAREA<TAB>;tx              i;tx
imenu HTML.Forms.SUBMIT<TAB>;su                ;su
vmenu HTML.Forms.SUBMIT<TAB>;su                <ESC>a;su
nmenu HTML.Forms.SUBMIT<TAB>;su                a;su
imenu HTML.Forms.RESET<TAB>;re                 ;re
vmenu HTML.Forms.RESET<TAB>;re                 <ESC>a;re
nmenu HTML.Forms.RESET<TAB>;re                 a;re
imenu HTML.Forms.LABEL<TAB>;la                 ;la
vmenu HTML.Forms.LABEL<TAB>;la                 ;la
nmenu HTML.Forms.LABEL<TAB>;la                 a;la

" }}}2

 menu HTML.-sep2-                              <nul>

imenu HTML.BODY<tab>;bd                        ;bd
vmenu HTML.BODY<tab>;bd                        ;bd
nmenu HTML.BODY<tab>;bd                        i;bd
imenu HTML.CENTER<tab>;ce                      ;ce
vmenu HTML.CENTER<tab>;ce                      ;ce
nmenu HTML.CENTER<tab>;ce                      i;ce
imenu HTML.Comment<tab>;cm                     ;cm
vmenu HTML.Comment<tab>;cm                     ;cm
nmenu HTML.Comment<tab>;cm                     i;cm
imenu HTML.HEAD<tab>;he                        ;he
vmenu HTML.HEAD<tab>;he                        ;he
nmenu HTML.HEAD<tab>;he                        i;he
imenu HTML.Horizontal\ Rule<tab>;hr            ;hr
nmenu HTML.Horizontal\ Rule<tab>;hr            i;hr
imenu HTML.HTML<tab>;ht                        ;ht
vmenu HTML.HTML<tab>;ht                        ;ht
nmenu HTML.HTML<tab>;ht                        i;ht
imenu HTML.Hyperlink<tab>;ah                   ;ah
vmenu HTML.Hyperlink<tab>;ah                   ;ah
nmenu HTML.Hyperlink<tab>;ah                   i;ah
imenu HTML.Inline\ Image<tab>;im               ;im
vmenu HTML.Inline\ Image<tab>;im               ;im
nmenu HTML.Inline\ Image<tab>;im               i;im
imenu HTML.Line\ Break<tab>;br                 ;br
nmenu HTML.Line\ Break<tab>;br                 i;br
imenu HTML.Named\ Anchor<tab>;an               ;an
vmenu HTML.Named\ Anchor<tab>;an               ;an
nmenu HTML.Named\ Anchor<tab>;an               i;an
imenu HTML.Paragraph<tab>;pp                   ;pp
vmenu HTML.Paragraph<tab>;pp                   ;pp
nmenu HTML.Paragraph<tab>;pp                   i;pp
imenu HTML.Preformatted\ Text<tab>;pr          ;pr
vmenu HTML.Preformatted\ Text<tab>;pr          ;pr
nmenu HTML.Preformatted\ Text<tab>;pr          i;pr
imenu HTML.TITLE<tab>;ti                       ;ti
vmenu HTML.TITLE<tab>;ti                       ;ti
nmenu HTML.TITLE<tab>;ti                       i;ti

imenu HTML.More\.\.\..ADDRESS<tab>;ad             ;ad
vmenu HTML.More\.\.\..ADDRESS<tab>;ad             ;ad
nmenu HTML.More\.\.\..ADDRESS<tab>;ad             i;ad
imenu HTML.More\.\.\..BASE\ HREF<tab>;bh          ;bh
vmenu HTML.More\.\.\..BASE\ HREF<tab>;bh          ;bh
nmenu HTML.More\.\.\..BASE\ HREF<tab>;bh          i;bh
imenu HTML.More\.\.\..BLOCKQUTE<tab>;bl           ;bl
vmenu HTML.More\.\.\..BLOCKQUTE<tab>;bl           ;bl
nmenu HTML.More\.\.\..BLOCKQUTE<tab>;bl           i;bl
imenu HTML.More\.\.\..Defining\ Instance<tab>;df  ;df
vmenu HTML.More\.\.\..Defining\ Instance<tab>;df  ;df
nmenu HTML.More\.\.\..Defining\ Instance<tab>;df  i;df
imenu HTML.More\.\.\..Document\ Division<tab>;dv  ;dv
vmenu HTML.More\.\.\..Document\ Division<tab>;dv  ;dv
nmenu HTML.More\.\.\..Document\ Division<tab>;dv  i;dv
imenu HTML.More\.\.\..EMBED<tab>;eb               ;eb
nmenu HTML.More\.\.\..EMBED<tab>;eb               i;eb
imenu HTML.More\.\.\..ISINDEX<tab>;ii             ;ii
nmenu HTML.More\.\.\..ISINDEX<tab>;ii             i;ii
imenu HTML.More\.\.\..JavaScript<tab>;js          ;js
nmenu HTML.More\.\.\..JavaScript<tab>;js          i;js
imenu HTML.More\.\.\..LINK\ HREF<tab>;lk          ;lk
vmenu HTML.More\.\.\..LINK\ HREF<tab>;lk          ;lk
nmenu HTML.More\.\.\..LINK\ HREF<tab>;lk          i;lk
imenu HTML.More\.\.\..Linked\ CSS<tab>;ls         ;ls
vmenu HTML.More\.\.\..Linked\ CSS<tab>;ls         ;ls
nmenu HTML.More\.\.\..Linked\ CSS<tab>;ls         i;ls
imenu HTML.More\.\.\..META<tab>;me                ;me
vmenu HTML.More\.\.\..META<tab>;me                ;me
nmenu HTML.More\.\.\..META<tab>;me                i;me
imenu HTML.More\.\.\..Quoted\ Text<tab>;qu        ;qu
vmenu HTML.More\.\.\..Quoted\ Text<tab>;qu        ;qu
nmenu HTML.More\.\.\..Quoted\ Text<tab>;qu        i;qu
imenu HTML.More\.\.\..SPAN<tab>;sn                ;sn
vmenu HTML.More\.\.\..SPAN<tab>;sn                ;sn
nmenu HTML.More\.\.\..SPAN<tab>;sn                i;sn
imenu HTML.More\.\.\..STYLE<tab>;cs               ;cs
vmenu HTML.More\.\.\..STYLE<tab>;cs               ;cs
nmenu HTML.More\.\.\..STYLE<tab>;cs               i;cs

let did_html_menus = 1
endif  " ! has("gui_running"))
" ---------------------------------------------------------------------------

" ---- Clean Up: -------------------------------------------------------- {{{1
" Restore cpoptions:
let &cpoptions = savecpo

" vim:ts=2:sw=2:expandtab:tw=78:fo=croq2:comments=b\:\":
" vim600:fdm=marker:fdc=3:cms=\ "\ %s:
