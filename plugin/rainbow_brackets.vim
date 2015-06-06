"==============================================================================
"Script Title: rainbow parentheses improved
"Script Version: 3.3.3
"Author: luochen1990
"Last Edited: 2015 Jan 13
"Simple Configuration:
"	first, put "rainbow.vim"(this file) to dir vimfiles/plugin or vim73/plugin
"	second, add the follow sentences to your .vimrc or _vimrc :
"	 	let g:rainbow_active = 1
"	third, restart your vim and enjoy coding.
"Advanced Configuration:
"	an advanced configuration allows you to define what parentheses to use 
"	for each type of file . you can also determine the colors of your 
"	parentheses by this way (read file vim73/rgb.txt for all named colors).
"	READ THE SOURCE FILE FROM LINE 25 TO LINE 50 FOR EXAMPLE.
"User Command:
"	:RainbowBracketsToggle		--you can use it to toggle this plugin.
"==============================================================================

if exists('s:rainbow_brackets_loaded')
	finish
endif
let s:rainbown_brackets_loaded = 1
 
let s:rainbow_brackets_conf = {
\	'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick'],
\	'ctermfgs': ['lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'],
\	'operators': '_,_',
\	'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\	'separately': {
\		'*': {},
\		'tex': {
\			'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
\		},
\		'vim': {
\			'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
\		},
\		'xml': {
\			'parentheses': ['start=/\v\<\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'))?)*\>/ end=#</\z1># fold'],
\		},
\		'xhtml': {
\			'parentheses': ['start=/\v\<\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'))?)*\>/ end=#</\z1># fold'],
\		},
\		'html': {
\			'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
\		},
\		'php': {
\			'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold', 'start=/(/ end=/)/ containedin=@htmlPreproc contains=@phpClTop', 'start=/\[/ end=/\]/ containedin=@htmlPreproc contains=@phpClTop', 'start=/{/ end=/}/ containedin=@htmlPreproc contains=@phpClTop'],
\		},
\		'css': 0,
\	}
\}

func s:resolve_parenthesis(p)
	let ls = split(a:p, '\v%(%(start|step|end)\=(.)%(\1@!.)*\1[^ ]*|\w+%(\=[^ ]*)?) ?\zs', 0)
	let [paren, containedin, contains, op] = ['', '', 'TOP', '']
	for s in ls
		let [k, v] = [matchstr(s, '^[^=]\+\ze='), matchstr(s, '^[^=]\+=\zs.*')]
		if k == 'step'
			let op = v
		elseif k == 'contains'
			let contains = v
		elseif k == 'containedin'
			let containedin = v
		else
			let paren .= s
		endif
	endfor
	return [paren, containedin, contains, op]
endfunc

func rainbow_brackets#load()
	let conf = b:rainbow_brackets_conf
	let maxlvl = has('gui_running')? len(conf.guifgs) : len(conf.ctermfgs)
	for i in range(len(conf.parentheses))
		let p = conf.parentheses[i]
		if type(p) == type([])
			let op = len(p)==3? p[1] : has_key(conf, 'operators')? conf.operators : ''
			let conf.parentheses[i] = op != ''? printf('start=#%s# step=%s end=#%s#', p[0], op, p[-1]) : printf('start=#%s# end=#%s#', p[0], p[-1])
		endif
	endfor
	let def_rg = 'syn region %s matchgroup=%s containedin=%s contains=%s,@NoSpell %s'
	let def_op = 'syn match %s %s containedin=%s contained'

	call rainbow_brackets#clear()
	let b:rainbow_brackets_loaded = maxlvl
	for parenthesis_args in conf.parentheses
		let [paren, containedin, contains, op] = s:resolve_parenthesis(parenthesis_args)
		if op == '' |let op = conf.operators |endif
		for lvl in range(maxlvl)
			if op != '' |exe printf(def_op, 'rainbow_brackets_o'.lvl, op, 'rainbow_brackets_r'.lvl) |endif
			if lvl == 0
				if containedin == ''
					exe printf(def_rg, 'rainbow_brackets_r0', 'rainbow_brackets_p0', 'rainbow_brackets_r'.(maxlvl - 1), contains, paren)
				endif
			else
				exe printf(def_rg, 'rainbow_brackets_r'.lvl, 'rainbow_brackets_p'.lvl.(' contained'), 'rainbow_brackets_r'.((lvl + maxlvl - 1) % maxlvl), contains, paren)
			endif
		endfor
		if containedin != ''
			exe printf(def_rg, 'rainbow_brackets_r0', 'rainbow_brackets_p0 contained', containedin.',rainbow_brackets_r'.(maxlvl - 1), contains, paren)
		endif
	endfor
	call rainbow_brackets#show()
endfunc

func rainbow_brackets#clear()
	call rainbow_brackets#hide()
	if exists('b:rainbow_brackets_loaded')
		for each in range(b:rainbow_brackets_loaded)
			exe 'syn clear rainbow_brackets_r'.each
			exe 'syn clear rainbow_brackets_o'.each
		endfor
		unlet b:rainbow_brackets_loaded
	endif
endfunc

func rainbow_brackets#show()
	if exists('b:rainbow_brackets_loaded')
		let b:rainbow_brackets_visible = 1
		for id in range(b:rainbow_brackets_loaded)
			let ctermfg = b:rainbow_brackets_conf.ctermfgs[id % len(b:rainbow_brackets_conf.ctermfgs)]
			let guifg = b:rainbow_brackets_conf.guifgs[id % len(b:rainbow_brackets_conf.guifgs)]
			exe 'hi default rainbow_brackets_p'.id.' ctermfg='.ctermfg.' guifg='.guifg
			exe 'hi default rainbow_brackets_o'.id.' ctermfg='.ctermfg.' guifg='.guifg
		endfor
	endif
endfunc

func rainbow_brackets#hide()
	if exists('b:rainbow_brackets_visible')
		for each in range(b:rainbow_brackets_loaded)
			exe 'hi clear rainbow_brackets_p'.each
			exe 'hi clear rainbow_brackets_o'.each
		endfor
		unlet b:rainbow_brackets_visible
	endif
endfunc

func rainbow_brackets#toggle()
	if exists('b:rainbow_brackets_loaded')
		call rainbow_brackets#clear()
	else
		if exists('b:rainbow_brackets_conf')
			call rainbow_brackets#load()
		else
			call rainbow_brackets#hook()
		endif
	endif
endfunc

func rainbow_brackets#hook()
	let g_conf = extend(copy(s:rainbow_brackets_conf), exists('g:rainbow_brackets_conf')? g:rainbow_brackets_conf : {}) |unlet g_conf.separately
	if exists('g:rainbow_brackets_conf.separately') && has_key(g:rainbow_brackets_conf.separately, '*')
		let separately = copy(g:rainbow_brackets_conf.separately)
	else
		let separately = extend(copy(s:rainbow_brackets_conf.separately), exists('g:rainbow_brackets_conf.separately')? g:rainbow_brackets_conf.separately : {})
	endif
	let b_conf = has_key(separately, &ft)? separately[&ft] : separately['*']
	if type(b_conf) == type({})
		let b:rainbow_brackets_conf = extend(g_conf, b_conf)
		call rainbow_brackets#load()
	endif
endfunc

command! RainbowBracketsToggle call rainbow_brackets#toggle()
