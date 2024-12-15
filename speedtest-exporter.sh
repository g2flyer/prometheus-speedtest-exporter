#!/bin/bash

SPEEDTEST="/usr/local/bin/speedtest"
SPEEDTEST_COMMON_OPTS="--progress=no --accept-license --accept-gdpr -f tsv"

# printMetric name description type value server_id
function printMetric {
    metric_name=$1
    metric_desc=$2
    metric_type=$3
    metric_value=$4
    server_id=$5
    server_name=$6

    echo "# HELP ${metric_name} ${metric_desc}"
    echo "# TYPE ${metric_name} ${metric_type}"
    if [ -z "${server_id}" ]
    then
        echo "${metric_name} ${metric_value}"
    else
        echo "${metric_name}{server_id=\"$server_id\", server_name=\"$server_name\"} ${metric_value}"
    fi
}

function speed_test {
        server_id=$1
        if [ ! -z "$server_id" ]
        then
	    SPEEDTEST_EXTRA_OPTS=" --server-id $server_id)"
        fi 

	# for headers, see '${SPEEDTEST} ${SPEEDTEST_COMMON_OPTS} --output-header'
	# for version 1.2.0.84 it will be (with tabs turned into newlines)
        #  1. server name
	#  2. server id
	#  3. idle latency
	#  4. idle jitter
	#  5. packet loss
	#  6. download
	#  7. upload
	#  8. download bytes
	#  9. upload bytes
	# 10. share url
	# 11. download server count
	# 12. download latency
	# 13. download latency jitter
	# 14. download latency low
	# 15. download latency high
	# 16. upload latency
	# 17. upload latency jitter
	# 18. upload latency low
	# 29. upload latency high
	# 20. idle latency low
	# 21. idle latency high
        while IFS=$'\t' read -r servername serverid latency jitter packetloss download upload downloadedbytes uploadedbytes share_url downloadservercount downloadlatency downloadlatencyjitter downloadlatencylow downloadlatencyhigh uploadlatency uploadlatencyjitter uploadlatencylow uploadlatencyhigh idlelatencylow uploadlatencyhigh; do
            printMetric "speedtest_latency_milliseconds" "Latency" "gauge" "$latency" "$serverid" "$servername"
            printMetric "speedtest_jittter_milliseconds" "Jitter" "gauge" "$jitter" "$serverid" "$servername"
            printMetric "speedtest_packet_loss_percentage" "Packet loss" "gauge" "$packetloss" "$serverid" "$servername"
            printMetric "speedtest_download_bytes_per_seconds" "Download Speed" "gauge" "$download" "$serverid" "$servername"
            printMetric "speedtest_upload_bytes_per_seconds" "Upload Speed" "gauge" "$upload" "$serverid" "$servername"
            printMetric "speedtest_downloaded_bytes" "Downloaded Bytes" "gauge" "$downloadedbytes" "$serverid" "$servername"
            printMetric "speedtest_uploaded_bytes" "Uploaded Bytes" "gauge" "$uploadedbytes" "$serverid" "$servername"
	    # share_url
	    # downloadservercount
            printMetric "speedtest_download_latency_milliseconds" "Download Latency" "gauge" "$downloadlatency" "$serverid" "$servername"
            printMetric "speedtest_download_jitter_milliseconds" "Download Jitter" "gauge" "$downloadlatencyjitter" "$serverid" "$servername"
	    # downloadlatencylow
	    # downloadlatencyhigh
            printMetric "speedtest_upload_latency_milliseconds" "Upload Latency" "gauge" "$uploadlatency" "$serverid" "$servername"
            printMetric "speedtest_upload_jitter_milliseconds" "Upload Jitter" "gauge" "$uploadlatencyjitter" "$serverid" "$servername"
	    # uploadlatencylow
	    # uploadlatencyhigh
	    # idlelatencylow
	    # uploadlatencyhigh

        done < <(${SPEEDTEST} ${SPEEDTEST_COMMON_OPTS} ${SPEEDTEST_EXTRA_OPTS})
}


if [ -z "$server_ids" ]
then
        speed_test
else
    IFS=',' read -ra server_id_array <<< "$server_ids"
    for server_id in "${server_id_array[@]}"
    do
        speed_test "${server_id}"
    done
fi
