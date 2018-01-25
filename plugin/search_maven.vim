"
" Author: Zhang Li
"
if exists("g:loaded_search_maven") && g:loaded_search_maven
    finish
endif
let g:loaded_search_maven = 1

"
" commands
"
command! -nargs=1 SearchMaven :call s:SearchMaven(<f-args>)
command! -nargs=1 SearchMavenShort :call s:SearchMavenShort(<f-args>)


"
" functions
"
let s:search_maven_script_path = expand('<sfile>:p:h')
let s:search_maven_script_loaded = 0
function! s:LoadSearchMavenScript()
    python import sys
    python sys.path.append(vim.eval("s:search_maven_script_path"))
    python from search_maven import search_maven
    python from search_maven import search_maven_detail
    let s:search_maven_script_loaded = 1
endfunction

function! s:SearchMavenImpl(query)
    call s:LoadSearchMavenScript()

    " fetch artifacts
    python artifact_results = search_maven(vim.eval("a:query"))
    python vim.command("let artifact_results = pyeval('artifact_results')")
    let id = 1
    for doc in artifact_results
        echo '[' . id . '] ' . doc.group_id . ':' . doc.artifact_id . ' (update: ' . doc.update_time . ')'
        let id += 1
    endfor

    " select artifact
    let selected_id = str2nr(input('select artifact: '))
    redraw!
    if selected_id <= 0 || selected_id - 1 >= len(artifact_results)
        throw 'invalid id: ' . selected_id
    endif
    let selected_doc = artifact_results[selected_id - 1]

    " fetch version
    python version_results = search_maven_detail(vim.eval("selected_doc.group_id"), vim.eval("selected_doc.artifact_id"))
    python vim.command("let version_results = pyeval('version_results')")

    let id = 1
    for doc in version_results
        echo '[' . id . '] ' . doc.version . ' (update: ' . doc.update_time . ')'
        let id += 1
    endfor

    " select version
    let selected_id = str2nr(input('select artifact: '))
    redraw!
    if selected_id <= 0 || selected_id - 1 >= len(version_results)
        throw 'invalid id: ' . selected_id
    endif
    let selected_doc = version_results[selected_id - 1]
    return selected_doc
endfunction

function! s:SearchMaven(query)
    let doc = s:SearchMavenImpl(a:query)
    python << endpython
if "startpython":
    output_code = ""
    output_code = output_code + "<dependency>\n"
    output_code = output_code + "    <groupId>%(group_id)s</groupId>\n"
    output_code = output_code + "    <artifactId>%(artifact_id)s</artifactId>\n"
    output_code = output_code + "    <version>%(version)s</version>\n"
    output_code = output_code + "</dependency>\n"
    output_code %= vim.eval("doc")
    vim.command("let @@ = pyeval('output_code')")
    sys.stdout.write(output_code + "\n")
    sys.stdout.write('vim-search-maven: already store to register ["@].\n')
endpython
endfunction

function! s:SearchMavenShort(query)
    let doc = s:SearchMavenImpl(a:query)
    python << endpython
if "startpython":
    output_code = "%(group_id)s:%(artifact_id)s:%(version)s" % vim.eval("doc")
    vim.command("let @@ = pyeval('output_code')")
    sys.stdout.write(output_code + "\n")
    sys.stdout.write('vim-search-maven: already store to register ["@].\n')
endpython
endfunction
