if exists('g:loaded_ZFVimIM_sbzr')
    finish
endif
let g:loaded_ZFVimIM_sbzr = 1

let s:sbzr_labels = ['', '1', '2', '3', '4', '5']
let s:sbzr_seen_freq = {}
let s:sbzr_seen_counter = 0
let s:sbzr_label_pending = {}

function! s:apply_sbzr_settings() abort
    let g:ZFVimIM_labelList = copy(s:sbzr_labels)
    let g:ZFVimIM_pumheight = len(s:sbzr_labels)
    " 不限制候选词总数，允许翻页（pumheight 限制显示数量为6）
    let g:ZFVimIM_candidateLimit = 0
    " matchLimit 设为负数表示精确匹配的数量限制
    if !exists('g:ZFVimIM_matchLimit')
        let g:ZFVimIM_matchLimit = 2000
    endif
    let g:ZFVimIM_matchLimit = 0 - abs(g:ZFVimIM_matchLimit)
    " 设置 freeScroll 模式，允许自由滚动和翻页
    let g:ZFVimIM_freeScroll = 1
    let g:ZFVimIM_sbzr_mode = 1
endfunction

function! ZFVimIM_sbzr_key(key)
    return ZFVimIME_input(a:key)
endfunction

" SBZR 翻页处理函数
function! ZFVimIM_sbzr_pageUp(key)
    return ZFVimIME_pageUp(a:key)
endfunction

function! ZFVimIM_sbzr_pageDown(key)
    return ZFVimIME_pageDown(a:key)
endfunction

function! s:apply_sbzr_keymaps()
    " 映射字母键
    for key in split('abcdefghijklmnopqrstuvwxyz', '\zs')
        execute 'lnoremap <buffer><expr><silent> ' . key . ' ZFVimIM_sbzr_key("' . key . '")'
    endfor
    " 对齐当前 Rime：Space 选第一个，1-5 选第 2-6 个候选
    execute 'lnoremap <buffer><expr><silent> 1 ZFVimIME_label(2, "1")'
    execute 'lnoremap <buffer><expr><silent> 2 ZFVimIME_label(3, "2")'
    execute 'lnoremap <buffer><expr><silent> 3 ZFVimIME_label(4, "3")'
    execute 'lnoremap <buffer><expr><silent> 4 ZFVimIME_label(5, "4")'
    execute 'lnoremap <buffer><expr><silent> 5 ZFVimIME_label(6, "5")'
    execute 'lnoremap <buffer><expr><silent> <Tab> ZFVimIME_tabNext("\<tab>")'
    execute 'lnoremap <buffer><expr><silent> <S-Tab> ZFVimIME_tabPrev("\<s-tab>")'
    execute 'lnoremap <buffer><expr><silent> <Space> ZFVimIME_space("\<space>")'
    " 映射翻页键：, 和 .
    execute 'lnoremap <buffer><expr><silent> , ZFVimIM_sbzr_pageUp(",")'
    execute 'lnoremap <buffer><expr><silent> . ZFVimIM_sbzr_pageDown(".")'
    " 映射左右箭头键
    execute 'lnoremap <buffer><expr><silent> <Left> ZFVimIM_sbzr_pageUp("<Left>")'
    execute 'lnoremap <buffer><expr><silent> <Right> ZFVimIM_sbzr_pageDown("<Right>")'
endfunction

call s:apply_sbzr_settings()

augroup ZFVimIM_sbzr_augroup
    autocmd!
    autocmd User ZFVimIM_event_OnStart call s:apply_sbzr_settings()
    autocmd User ZFVimIM_event_OnEnable call s:apply_sbzr_settings() | call s:apply_sbzr_keymaps()
augroup END

function! s:ensure_label_list() abort
    if !exists('g:ZFVimIM_labelList') || empty(g:ZFVimIM_labelList)
        let g:ZFVimIM_labelList = copy(s:sbzr_labels)
    endif
endfunction

function! s:sbzr_updateCandidates() abort
    if !exists('*ZFVimIM_core_api')
        return
    endif
    call s:ensure_label_list()
    let defaultPumheight = ZFVimIM_core_api('default_pumheight')
    if &pumheight <= 0 || &pumheight < defaultPumheight
        execute 'set pumheight=' . defaultPumheight
    endif
    let pageSize = &pumheight
    let keyboard = ZFVimIM_core_api('get_keyboard')
    let lastKeyboard = ZFVimIM_core_api('get_last_keyboard')
    let matchList = ZFVimIM_core_api('get_match_list')
    let keyboardChanged = (keyboard !=# lastKeyboard)
    let needRefresh = keyboardChanged || empty(matchList)
    if !empty(s:sbzr_label_pending)
        let pendingKey = get(s:sbzr_label_pending, 'key', '')
        if pendingKey !=# keyboard || s:sbzr_hasExactKey(keyboard)
            let s:sbzr_label_pending = {}
        endif
    endif
    if needRefresh
        let matchLimit = get(g:, 'ZFVimIM_matchLimit', 0)
        if matchLimit == 0
            let matchLimit = -2000
        endif
        let resultList = ZFVimIM_complete(keyboard, {
                    \ 'match': matchLimit,
                    \ 'sentence': 0,
                    \ 'crossDb': 0,
                    \ 'predict': 0,
                    \ })
        if !empty(s:sbzr_label_pending)
            let pendingKey = get(s:sbzr_label_pending, 'key', '')
            if pendingKey ==# keyboard && !s:sbzr_hasExactKey(keyboard)
                let pendingWord = get(s:sbzr_label_pending, 'word', '')
                let pendingDbId = get(s:sbzr_label_pending, 'dbId', 0)
                if !empty(pendingWord)
                    let resultList = [{
                                \ 'dbId' : pendingDbId,
                                \ 'len' : len(keyboard),
                                \ 'word' : pendingWord,
                                \ 'key' : keyboard,
                                \ 'type' : 'match',
                                \ 'hint' : 1,
                                \ }]
                    let s:sbzr_label_pending = {}
                endif
            endif
        endif
        let resultList = ZFVimIM_core_api('apply_candidate_limit', resultList)
        call ZFVimIM_core_api('set_full_result_list', resultList)
        call ZFVimIM_core_api('set_match_list', resultList)
        call ZFVimIM_core_api('set_loaded_result_count', len(resultList))
        call ZFVimIM_core_api('set_page', 0)
    elseif ZFVimIM_core_api('get_pageup_pagedown') != 0 && pageSize > 0
        let page = ZFVimIM_core_api('get_page')
        let delta = ZFVimIM_core_api('get_pageup_pagedown')
        let page += delta
        let currentList = ZFVimIM_core_api('get_match_list')
        if !empty(currentList)
            let maxPage = (len(currentList) - 1) / pageSize
            if page > maxPage
                let page = maxPage
            endif
        endif
        if page < 0
            let page = 0
        endif
        call ZFVimIM_core_api('set_page', page)
    endif
    call ZFVimIM_core_api('set_pageup_pagedown', 0)
    call ZFVimIM_core_api('set_has_full_results', 1)
    call ZFVimIM_core_api('set_last_keyboard', keyboard)
    let skipFew = get(g:, 'ZFVimIM_skipFloatWhenFew', 0)
    let matchList = ZFVimIM_core_api('get_match_list')
    if skipFew > 0 && len(matchList) <= skipFew
        call ZFVimIM_core_api('float_close')
        doautocmd User ZFVimIM_event_OnUpdateOmni_sbzr
        return
    endif
    if empty(matchList)
        let hintItems = s:sbzrHintItems(keyboard, &pumheight)
        if !empty(hintItems)
            call ZFVimIM_core_api('float_render', hintItems)
            doautocmd User ZFVimIM_event_OnUpdateOmni_sbzr
            return
        endif
    endif
    call ZFVimIM_core_api('float_render', ZFVimIM_core_api('cur_page'))
    doautocmd User ZFVimIM_event_OnUpdateOmni_sbzr
endfunction

function! s:sbzrHintItems(key, limit) abort
    if empty(a:key)
        return []
    endif
    if !exists('g:ZFVimIM_db') || empty(g:ZFVimIM_db)
        return []
    endif
    if g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
        return []
    endif
    let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
    if empty(db) || !has_key(db, 'dbMap')
        return []
    endif
    let c = a:key[0]
    if !has_key(db['dbMap'], c)
        return []
    endif
    let bucket = db['dbMap'][c]
    let limit = a:limit > 0 ? a:limit : 6
    let ret = []
    let idx = ZFVimIM_dbSearch(db, c, '^' . a:key, 0)
    if idx < 0
        return []
    endif
    let bestWord = ''
    let bestKey = ''
    let bestLen = 0
    while idx < len(bucket) && len(ret) < limit
        let item = ZFVimIM_dbItemDecode(bucket[idx])
        let k = get(item, 'key', '')
        if k !~# '^' . a:key
            break
        endif
        if k !=# a:key
            let wordList = get(item, 'wordList', [])
            if !empty(wordList)
                let word = wordList[0]
                for w in wordList
                    if strchars(w) < strchars(word)
                        let word = w
                    endif
                endfor
                if bestLen == 0 || strchars(word) < bestLen
                    let bestWord = word
                    let bestKey = k
                    let bestLen = strchars(word)
                    if bestLen == 1
                        break
                    endif
                endif
            endif
        endif
        let idx += 1
    endwhile
    if !empty(bestWord)
        call add(ret, {
                    \ 'dbId' : get(db, 'dbId', 0),
                    \ 'len' : len(a:key),
                    \ 'word' : bestWord,
                    \ 'displayWord' : bestWord,
                    \ 'key' : bestKey,
                    \ 'type' : 'match',
                    \ 'hint' : 1,
                    \ })
    endif
    return ret
endfunction

function! s:sbzr_hasLongerKey(prefix) abort
    if empty(a:prefix)
        return 0
    endif
    if !exists('g:ZFVimIM_db') || empty(g:ZFVimIM_db)
        return 0
    endif
    if g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
        return 0
    endif
    let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
    if empty(db) || !has_key(db, 'dbMap')
        return 0
    endif
    let c = a:prefix[0]
    if !has_key(db['dbMap'], c)
        return 0
    endif
    let bucket = db['dbMap'][c]
    let idx = ZFVimIM_dbSearch(db, c, '^' . a:prefix, 0)
    if idx < 0
        return 0
    endif
    while idx < len(bucket)
        let item = ZFVimIM_dbItemDecode(bucket[idx])
        let k = get(item, 'key', '')
        if k !~# '^' . a:prefix
            break
        endif
        if k !=# a:prefix
            return 1
        endif
        let idx += 1
    endwhile
    return 0
endfunction

function! s:sbzr_hasExactKey(key) abort
    if empty(a:key)
        return 0
    endif
    if !exists('g:ZFVimIM_db') || empty(g:ZFVimIM_db)
        return 0
    endif
    if g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
        return 0
    endif
    let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
    if empty(db) || !has_key(db, 'dbMap')
        return 0
    endif
    let c = a:key[0]
    if !has_key(db['dbMap'], c)
        return 0
    endif
    let idx = ZFVimIM_dbSearch(db, c, '^' . a:key . g:ZFVimIM_KEY_S_MAIN, 0)
    return idx >= 0
endfunction

function! s:hook_update_candidates_debounced() abort
    call ZFVimIM_core_api('call_update_candidates')
    return 1
endfunction

function! s:hook_update_candidates() abort
    call s:sbzr_updateCandidates()
    return 1
endfunction

function! s:hook_tab_move(direction) abort
    return 0
endfunction

function! s:hook_record_word_usage(key, word) abort
    let entry = a:key . "\t" . a:word
    let s:sbzr_seen_counter += 1
    let s:sbzr_seen_freq[entry] = s:sbzr_seen_counter
endfunction

function! s:hook_word_frequency_override(key, word) abort
    let entry = a:key . "\t" . a:word
    let seen = get(s:sbzr_seen_freq, entry, 0)
    if seen > 0
        return 1000000 + seen
    endif
    return v:null
endfunction

function! s:sbzr_sortByFrequency(item1, item2) abort
    if !has_key(a:item1, 'freq')
        let a:item1['freq'] = ZFVimIM_getWordFrequency(get(a:item1, 'key', ''), get(a:item1, 'word', ''))
    endif
    if !has_key(a:item2, 'freq')
        let a:item2['freq'] = ZFVimIM_getWordFrequency(get(a:item2, 'key', ''), get(a:item2, 'word', ''))
    endif
    let freq1 = a:item1['freq']
    let freq2 = a:item2['freq']
    if freq1 > freq2
        return -1
    elseif freq1 < freq2
        return 1
    endif
    return 0
endfunction

function! s:hook_complete_add_candidates(ret, singleChars, multiChars, matchLimit) abort
    let allCandidates = copy(a:singleChars) + copy(a:multiChars)
    if len(allCandidates) > 1
        call sort(allCandidates, function('s:sbzr_sortByFrequency'))
    endif
    let remainingLimit = a:matchLimit
    let wordIndex = 0
    while wordIndex < len(allCandidates) && remainingLimit > 0
        call add(a:ret, allCandidates[wordIndex])
        let wordIndex += 1
        let remainingLimit -= 1
    endwhile
    return remainingLimit
endfunction

function! s:hook_complete_sort_frequency_priority(ret) abort
    if len(a:ret) > 1
        call sort(a:ret, function('s:sbzr_sortByFrequency'))
    endif
    return 1
endfunction

function! s:hook_complete_force_combo(key, ret) abort
    return 0
endfunction

function! s:register_hooks() abort
    if !exists('*ZFVimIM_registerHook')
        return
    endif
    call ZFVimIM_registerHook('update_candidates_debounced', function('s:hook_update_candidates_debounced'))
    call ZFVimIM_registerHook('update_candidates', function('s:hook_update_candidates'))
    call ZFVimIM_registerHook('tab_move', function('s:hook_tab_move'))
    call ZFVimIM_registerHook('record_word_usage', function('s:hook_record_word_usage'))
    call ZFVimIM_registerHook('word_frequency_override', function('s:hook_word_frequency_override'))
    call ZFVimIM_registerHook('complete_add_candidates', function('s:hook_complete_add_candidates'))
    call ZFVimIM_registerHook('complete_sort_frequency_priority', function('s:hook_complete_sort_frequency_priority'))
    call ZFVimIM_registerHook('complete_force_combo', function('s:hook_complete_force_combo'))
endfunction

call s:register_hooks()
