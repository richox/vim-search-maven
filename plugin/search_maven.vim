"
" Author: Zhang Li
"
if exists("g:loaded_search_maven") && g:loaded_search_maven
    finish
endif
let g:loaded_search_maven = 1

"
"
" commands
"
"
command! -nargs=1 SearchMaven :call s:SearchMaven(<f-args>)

"
"
" functions
"
"
python class UserInterrupt:pass

function! s:SearchMaven(query)
python << endpython
if __name__ == "__main__":
    import socket
    socket.setdefaulttimeout(15)
    import sys
    import vim
    import urllib
    import json

    def select_candidate(candidates, pagesize=50):
        userinput = ""
        try:
            vim.command("redraw!")
            sys.stdout.writelines(map(lambda _: "candidates[%d]: %s" % _, enumerate(candidates[:pagesize])))
            userinput = vim.eval("input('select one candidate, [Enter] for next page: ', '')")
            if userinput == "":
                return pagesize + select_candidate(candidates[pagesize:])
            return int(userinput)
        except:
            if userinput != "":
                raise KeyboardInterrupt("invalid input: " + userinput)
        finally:
            vim.command("redraw!")
        return None

    try:
        ## step-1: list groupid/artifactid by user query
        sys.stdout.write("fetching package lists from search.maven.org...\n")
        query = vim.eval("a:query")
        content_data = json.load(urllib.urlopen("http://search.maven.org/solrsearch/select?rows=999&q=" + urllib.quote(query)))

        candidates = []
        candidates_menu = []
        for doc in sorted(content_data["response"]["docs"], key=lambda _: _["g"] + "." + _["a"]):
            candidates.append({
                    "groupid":       doc["g"],
                    "artifactid":    doc["a"],
                    "latestversion": doc["latestVersion"],
            })
            if not candidates[-1]["artifactid"].startswith(query):
                candidates.pop()
                continue
            candidates_menu.append("%s: %s\n" % (candidates[-1]["groupid"], candidates[-1]["artifactid"]))

        if len(candidates_menu) == 0:
            vim.command("""echo "No candidates."\n""")
            raise UserInterrupt()
        n = select_candidate(candidates_menu)
        if n == None:
            raise UserInterrupt()
        groupid = candidates[n]["groupid"]
        artifactid = candidates[n]["artifactid"]

        ## step-2
        sys.stdout.write("fetching package versions of [%(groupid)s: %(artifactid)s] from search.maven.org...\n" % locals())
        query = 'g:"%(groupid)s" AND a:"%(artifactid)s"' % locals()
        content_data = json.load(urllib.urlopen("http://search.maven.org/solrsearch/select?rows=999&core=gav&q=" + urllib.quote(query)))

        candidate_versions_menu = sorted(map(lambda _: "%(v)s\n" % _, content_data["response"]["docs"]), reverse=1)
        if len(candidate_versions_menu) == 0:
            vim.command("""echo "No candidate versions."\n""")
            raise UserInterrupt()
        n = select_candidate(candidate_versions_menu)
        if n == None:
            raise UserInterrupt()
        version = candidate_versions_menu[n]
        version = version.strip()

        ## step-3
        output_code = ""
        output_code = output_code + "<dependency>\n"
        output_code = output_code + "    <groupId>%(groupid)s</groupId>\n"
        output_code = output_code + "    <artifactId>%(artifactid)s</artifactId>\n"
        output_code = output_code + "    <version>%(version)s</version>\n"
        output_code = output_code + "</dependency>\n"
        output_code %= locals()

        vim.command("let @@=pyeval('output_code')")
        sys.stdout.write(output_code)
        sys.stdout.write('vim-javautil-search-maven: already store to register ["@].\n')

    except KeyboardInterrupt, e:
        vim.command("""echo "Interrupted: %s"\n""" % e.message)

    except UserInterrupt, e:
        vim.command("""echo "Interrupted."\n""")
        pass

    except Exception, e:
        vim.command("redraw!")
        raise e
endpython
endfunction
