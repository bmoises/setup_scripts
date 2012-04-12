#!/bin/sh
# Credit: https://gist.github.com/1075067
host=localhost:9200

curl -X DELETE "${host}/test"

curl -X PUT "${host}/test" -d '{
  "settings" : { "index" : { "number_of_shards" : 1, "number_of_replicas" : 0 }}
}'

curl -X GET "${host}/_cluster/health?wait_for_status=green&pretty=1&timeout=5s"

curl -X PUT "${host}/test/attachment/_mapping" -d '{
  "attachment" : {
    "properties" : {
      "file" : {
        "type" : "attachment",
        "fields" : {
          "title" : { "store" : "yes" },
          "file" : { "term_vector":"with_positions_offsets", "store":"yes" }
        }
      }
    }
  }
}'

curl -C - -O http://www.intersil.com/data/fn/fn6742.pdf

coded=`cat fn6742.pdf | perl -MMIME::Base64 -ne 'print encode_base64($_)'`
json="{\"file\":\"${coded}\"}"
echo "$json" > json.file
curl -X POST "${host}/test/attachment/" -d @json.file
echo

curl -XPOST "${host}/_refresh"

curl "${host}/_search?pretty=true" -d '{
  "fields" : ["title"],
  "query" : {
    "query_string" : {
      "query" : "amplifier"
    }
  },
  "highlight" : {
    "fields" : {
      "file" : {}
    }
  }
}'


#
# The following is output of the last search query:
#
#
#
#{
#  "took" : 6,
#  "timed_out" : false,
#  "_shards" : {
#    "total" : 1,
#    "successful" : 1,
#    "failed" : 0
#  },
#  "hits" : {
#    "total" : 1,
#    "max_score" : 0.005872132,
#    "hits" : [ {
#      "_index" : "test",
#      "_type" : "attachment",
#      "_id" : "UUaHJ6CfTOC3T2I4Kj_pXg",
#      "_score" : 0.005872132,
#      "fields" : {
#        "file.title" : "ISL99201"
#      },
#      "highlight" : {
#        "file" : [ "\nMono <em>Amplifier</em> • Filterless Class D with Efficiency > 86% at 400mW\nThe ISL99201 is a fully integrat", "\nmono <em>amplifier</em>. It is designed to maximize performance for \nmobile phone applications. The applicat" ]
#      }
#    } ]
#  }
#}
