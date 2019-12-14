echo "------------------------------------------"
echo "Server manually restarted"
echo ""
echo ""


while :
do
	killall bluetcl
	nodejs ../../bluenode.js 60002 | tee -a server.log
	echo ""
	echo ""
	echo ""
	echo "     ** Server died!"
done
