echo "------------------------------------------"
echo "Server manually restarted"
echo ""
echo ""


while :
do
	killall bluetcl
	nodejs ../../bluenode.js $1 | tee -a server.log
	echo ""
	echo ""
	echo ""
	echo "     ** Server died!"
done
