#!/usr/bin/env python2

import urllib
import urllib2
import json
import datetime

DEFAULT_TIMEOUT = 10

def search_maven(word):
    search_url = "http://search.maven.org/solrsearch/select?rows=10000&q=" + urllib.quote(word)
    search_response = json.load(urllib2.urlopen(search_url, timeout=DEFAULT_TIMEOUT))

    docs = []
    for doc in search_response["response"]["docs"]:
        docs.append(dict(
                group_id = doc["g"],
                artifact_id = doc["a"],
                latest_version = doc["latestVersion"],
                update_time = datetime.datetime.fromtimestamp(doc["timestamp"] / 1000).strftime("%m/%d/%Y")))
    return sorted(docs)


def search_maven_detail(group_id, artifact_id):
    search_filter = "g:%(group_id)s AND a:%(artifact_id)s" % locals()
    search_url = "http://search.maven.org/solrsearch/select?rows=10000&core=gav&q=" + urllib.quote(search_filter)
    search_response = json.load(urllib2.urlopen(search_url, timeout=DEFAULT_TIMEOUT))

    docs = []
    for doc in search_response["response"]["docs"]:
        docs.append(dict(
                id = doc["id"],
                group_id = doc["g"],
                artifact_id = doc["a"],
                version = doc["v"],
                update_time = datetime.datetime.fromtimestamp(doc["timestamp"] / 1000).strftime("%m/%d/%Y")))
    return sorted(docs, key = lambda doc: doc["version"], reverse=True)
