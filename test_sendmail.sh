#!/usr/bin/ksh
##########################################################################
#	usage: rsh to all tester to execute a sendmail script to check whether	
#		check mail function is usable. Must be probe account so can't
#		remove and touch /var/mail/chkmail. So make this file setuid so 
#		that chkmail account can execute this script and do it itself.
#
#	version 1.0
#	author: Jiang Nan
#
##########################################################################
#      add timeout to kill inactive rsh           
#      add $teser into 2& to show more info with error message
#      author: LiuZX 
#      2016-3-24
#########################################################################
HOSTLIST="/exec/apps/bin/fablots/bin/host.list"
# MAIL_LIST="b39753@freescale.com"
SCRIPT_DIR="/exec/apps/tools/checksendmail/"
PATH=$PATH:/usr/sbin
PLATFORMS="ltk mst j750 cat flex 971 dts ltx a5 ink 93k t47"
#PLATFORMS="ltk t47"
alias echo='echo -e'

timeout(){
#echo "timer"
        waitsec="1 2 3 4 5"
for i in $waitsec
do
        sleep 1
        pid=`ps a|grep "$command"|grep -v "grep" | awk '{print $1}'`
        if [ "$pid" == "" ]
        then
        	return
        fi
done
kill -9 $pid
#echo "kill $command $pid"
}


echo ""
echo "Script will execute on all following platforms:(93K hp unix can't query hostid by command hostid)"
echo "    $PLATFORMS"
echo ""
for plat in $PLATFORMS
do
	echo "$plat\n"
	testers=`grep $plat $HOSTLIST | awk '{print $1}' | grep -v '-' | sort `
	for tester in $testers
	do
		echo "-- execute on tester: $tester -------------------------------------"
		anykey=`/exec/apps/tools/ping $tester | grep alive`
		if [ "X$anykey" != "X" ]
		then
			exec 9>&2
			command="rsh ${tester} "/exec/apps/tools/checksendmail/testsendmail.pl""
#			command="rsh ${tester} "/exec/apps/test.pl""
			timeout&
			exec 2>./.temp_log
			echo "">&2
			echo "$tester\n"
			if [ $plat == "t47" ]
			then
				$command $tester
			else
				$command
			#	rsh $tester /exec/apps/tools/checksendmail/testsendmail.pl
			fi
			exec 2>&9
			if [ -f ./.temp_log ]
			then
				msg=$(cat ./.temp_log)
				if [ "$msg" != "" ];then
        				echo "$tester:$msg">&2
				#       rm -r ./.temp_log
				fi
			fi
		else
			echo "$tester is not active!\n"
		fi
	done
done
