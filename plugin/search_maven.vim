"
" Author: Zhang Li
"
if exists("g:loaded_search_maven") && g:loaded_search_maven
    finish
endif
let g:loaded_search_maven = 1

function! search_maven#SearchMaven(query)
python << endpython
if __name__ == "__main__":
    import sys
    import vim
    import urllib
    import json

    def select_candidate(candidates, pagesize=30):
        pass

    try:
        ## step-1: list groupid/artifactid by user query
        sys.stdout.write("fetching package lists from search.maven.org...\n")
        query = vim.eval("a:query")
        content_data = json.load(urllib.urlopen("http://search.maven.org/solrsearch/select?rows=999&q=" + urllib.quote(query)))
        if len(content_data["response"]["docs"]) < 1:
            raise Exception(" no candidates found.")

        candidates = []
        for index, doc in enumerate(content_data["response"]["docs"]):
            candidates.append({
                    "groupid":       doc["g"],
                    "artifactid":    doc["a"],
                    "latestversion": doc["latestVersion"],
            })
        try:
            npage = 0
            n = 0
            i = 0
            while npage * pagesize < len(candidates):
                for i in range(pagesize):
                    sys.stdout.write("candidate [%d]: %s: %s (latestVersion: %s)\n" % (
                            index,
                            candidates[i]["groupid"],
                            candidates[i]["artifactid"],
                            candidates[i]["latestversion"]))
            n = int(vim.eval("input('select one candidate, [n] for next page: ', '')"))
            vim.command("redraw!")
        except:
            raise Exception("invalid input.")
        groupid = candidates[n]["groupid"]
        artifactid = candidates[n]["artifactid"]

        ## step-2
        sys.stdout.write("fetching package versions of [%(groupid)s: %(artifactid)s] from search.maven.org...\n" % locals())
        query = 'g:"%(groupid)s" AND a:"%(artifactid)s"' % locals()
        content_data = json.load(urllib.urlopen("http://search.maven.org/solrsearch/select?rows=999&core=gav&q=" + urllib.quote(query)))
        content_data["response"]["docs"].sort(reverse=1, key=lambda _: _["v"])

        candidate_versions = []
        for index, doc in enumerate(content_data["response"]["docs"]):
            candidate_versions.append(doc["v"])
            sys.stdout.write("candidate version [%d]: %s\n" % (index, candidate_versions[-1]))

        try:
            n = 0
            n = int(vim.eval("input('select one candidate [0]: ', '')"))
            vim.command("redraw!")
        except:
            raise Exception("invalid input.")
        version = candidate_versions[n]

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
        sys.stdout.write('vim: already store to register ["@].')

    except Exception as e:
        vim.command("redraw!")
        raise e
endpython
endfunction
