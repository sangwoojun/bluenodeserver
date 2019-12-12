echo "------------------------------------------"
echo "Server manually restarted"
echo ""
echo ""


while :
do
	killall bluetcl
	nodejs ../../bluenode.js | tee -a server.log
	echo ""
	echo ""
	echo ""
	echo "     ** Server died!"
done
