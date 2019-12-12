while :
do
	killall bluetcl
	nodejs ../../bluenode.js | tee -a server.log
	echo ""
	echo ""
	echo ""
	echo "     ** Server died!"
done
