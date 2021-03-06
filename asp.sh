#!/bin/bash

# Jared Still - Pythian
# still@pythian.com jkstill@gmail.com
# 2017-07-20

# asp - another sar processor

# tested on Red Hat Enterprise Linux Server release 6.6 (Santiago)
# also tested on Linux Mint

help() {

	cat <<-EOF

	  $0 
	    -s source-dir 
	    -d dest-dir 
	    -p pretty print Disk Device Names
	
	  Note: only use -p if running on the same system where sar files are generated
	  otherwise the names printed will be incorrect         	
	EOF
	
	echo
}

diskPrettyPrintOpts=' -j ID -p '
sarDiskOpts=''


# variables can be set to identify multiple sets of copied sar files
sarSrcDir='/var/log/sa' # RedHat, CentOS ...
#sarSrcDir='/var/log/sysstat' # Debian, Ubuntu ...

sarDstDir="sar-csv"

csvConvertCmd=" sed -e 's/;/,/g' "


while getopts s:d:hp arg
do
	case $arg in
		d) sarDstDir=$OPTARG;;
		s) sarSrcDir=$OPTARG;;
		p) sarDiskOpts=$diskPrettyPrintOpts;;
		h) help; exit 0;;
		*) help; exit 1;;
	esac
done


cat << EOF

Source: $sarSrcDir
  Dest: $sarDstDir

EOF

#exit


mkdir -p $sarDstDir || {

	echo 
	echo Failed to create $sarDstDir
	echo
	exit 1

}

echo "lastSaDirEl: $lastSaDirEl"


# sar options
# -d activity per block device
  # -j LABEL: use label for device if possible. eg. sentryoraredo01 rather than /dev/dm-3
# -b IO and transfer rates
# -q load
# -u cpu
# -r memory utilization
# -R memory
# -B paging
# -S swap space utilization
# -W swap stats
# -n network
# -v kernel filesystem stats
# -w  context switches and task creation
# break up network into a separate file for each option
# not all options available depending on sar version
# for disk "-d" you may want one of ID, LABEL, PATH or UUID - check the output and the sar docs
# Update for -d: if performed on a server other than the one where the sar files originated
#                the LABEL/PATH/UUID/ID will be set from the matching device on the current system
#                so the default will be to not translate device names
# The same goes for the -p option - it will take device names from the local system
# 
#sarDestOptions=( '-d -j ID -p' '-b' '-q' '-u ALL' '-r' '-R' '-B' '-S' '-W' '-n DEV' '-n EDEV' '-n NFS' '-n NFSD' '-n SOCK' '-n IP' '-n EIP' '-n ICMP' '-n EICMP' '-n TCP' '-n ETCP' '-n UDP' '-v' '-w')
sarDestOptions=( "-d ${sarDiskOpts} " '-b' '-q' '-u ALL' '-r' '-R' '-B' '-S' '-W' '-n DEV' '-n EDEV' '-n NFS' '-n NFSD' '-n SOCK' '-n IP' '-n EIP' '-n ICMP' '-n EICMP' '-n TCP' '-n ETCP' '-n UDP' '-v' '-w')

#sarDestFiles=( sar-disk.csv sar-io.csv sar-load.csv sar-cpu.csv sar-mem-utilization.csv sar-mem.csv sar-paging.csv sar-swap-utilization.csv sar-swap-stats.csv sar-network.csv sar-kernel-fs.csv sar-context.csv)
sarDestFiles=( sar-disk.csv sar-io.csv sar-load.csv sar-cpu.csv sar-mem-utilization.csv sar-mem.csv sar-paging.csv sar-swap-utilization.csv sar-swap-stats.csv sar-net-dev.csv sar-net-ede.csv sar-net-nfs.csv sar-net-nfsd.csv sar-net-sock.csv sar-net-ip.csv sar-net-eip.csv sar-net-icmp.csv sar-net-eicmp.csv sar-net-tcp.csv sar-net-etcp.csv sar-net-udp.csv sar-kernel-fs.csv sar-context.csv)

lastSarOptEl=${#sarDestOptions[@]}
echo "lastSarOptEl: $lastSarOptEl"

#while [[ $i -lt ${#x[@]} ]]; do echo ${x[$i]}; (( i++ )); done;

# initialize files with header row
i=0
while [[ $i -lt $lastSarOptEl ]]
do
	CMD="sadf -d -- ${sarDestOptions[$i]}  | head -1 | $csvConvertCmd > ${sarDstDir}/${sarDestFiles[$i]} "
	echo CMD: $CMD
	eval $CMD
	#sadf -d -- ${sarDestOptions[$i]}  | head -1 | $csvConvertCmd > ${sarDstDir}/${sarDestFiles[$i]}
	echo "################"
	(( i++ ))
done

#exit

#for sarFiles in ${sarSrcDirs[$currentEl]}/sa??
for sarFiles in $(ls -1dtar ${sarSrcDir}/sa??)
do
	for sadfFile in $sarFiles
	do

		#echo CurrentEl: $currentEl
		# sadf options
		# -t is for local timestamp
		# -d : database semi-colon delimited output

		echo Processing File: $sadfFile

		i=0
		while [[ $i -lt $lastSarOptEl ]]
		do
			CMD="sadf -d -- ${sarDestOptions[$i]} $sadfFile | tail -n +2 | $csvConvertCmd  >> ${sarDstDir}/${sarDestFiles[$i]}"
			echo CMD: $CMD
			eval $CMD
			if [[ $? -ne 0 ]]; then
				echo "#############################################
				echo "## CMD Failed"
				echo "## $CMD"
				echo "#############################################

			fi
			(( i++ ))
		done

	done
done


echo
echo Processing complete 
echo 
echo files located in $sarDstDir
echo 


# show the files created
i=0
while [[ $i -lt $lastSarOptEl ]]
do
	ls -ld ${sarDstDir}/${sarDestFiles[$i]} 
	(( i++ ))
done


