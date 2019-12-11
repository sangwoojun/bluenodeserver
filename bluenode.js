var http = require('http');
var express = require('express');
var session = require('express-session');
var formidable = require('formidable');
var childproc = require('child_process');
var fs = require('fs');
var util = require('util');

var logname = "exec.log";
var updir = "uploaded/";

var app = express();
app.use(session({secret:"cs152_invys", resave:false, saveUninitialized:false}));

//var configjson = fs.readFileSync(__dirname + "/config.json");
var configjson = fs.readFileSync("config.json");
var config = JSON.parse(configjson);
var targets = config.targets;
var execslots = config.execslots; 
var exectimeout = config.exectimeout; 
var title = config.title;
var infolink = config.infolink;

//var usersjson = fs.readFileSync(__dirname + "/users.json");
var usersjson = fs.readFileSync("users.json");
var users = JSON.parse(usersjson);

var execreqmap = {};
var execreqqueue = [];
var cntinflight = 0;

if (!fs.existsSync(updir)) {
	fs.mkdirSync(updir);
}

function formatteddate() {
	var now = new Date();
	var mm = now.getMonth()+1;
	if ( mm < 10 ) mm = "0"+mm;
	var dd = now.getDate();
	if ( dd < 10 ) dd = "0"+dd;
	var h = now.getHours();
	var m = now.getMinutes();
	var s = now.getSeconds();
	var ms = now.getMilliseconds();
	return now.getFullYear()+"-"+mm+"-"+dd+" "+h+":"+m+":"+s+":"+ms;
}


function checkSession(req) {
	if ( req.session.userid ) return true;
	return false;
}

function serveMessage(res, msg) {
	var msgtemplate = fs.readFileSync(__dirname + "/message.html").toString();
	msgtemplate = msgtemplate.replace("{message}", msg);
	res.write(msgtemplate);
	res.end();
}

function serveIndex(req, res, curmsg) {
	var targetsel = "";
	var curtarget = "<ul>\n";
	var curlog = "";
	var username = req.session.userid;
	if ( !curmsg ) curmsg = "None";

	//var targetdir = __dirname + '/'+updir+req.session.userid+'/';
	var targetdir = updir+req.session.userid+'/';

	for ( var key in targets) {
		targetsel = targetsel + "<option value="+key+">"+targets[key]+"</option>\n";
		var fpath = targetdir+targets[key];
		if ( fs.existsSync(fpath) ) {
			curtarget = curtarget + "<li> <a href='"+targets[key]+"'>"+targets[key]+"</a><br>\n";
		} else {
			curtarget = curtarget + "<li>" + targets[key] + " not uploaded!<br>\n";
		}
	}
	curtarget = curtarget + "</ul>\n";
	
	if ( fs.existsSync(targetdir+logname) ) {
		curlog = fs.readFileSync(targetdir+logname).toString().replace(/(?:\r\n|\r|\n)/g, '<br>');
	} else {
		curlog = "<em>Output log does not exist</em>\n";
	}
	//console.log(targetsel);
	
	var indextemplate = fs.readFileSync(__dirname + "/index.html").toString();
	indextemplate = indextemplate.replace("{targets}", targetsel);
	indextemplate = indextemplate.replace("{curmsg}", curmsg);
	indextemplate = indextemplate.replace("{current}", curtarget);
	indextemplate = indextemplate.replace("{curlog}", curlog);
	indextemplate = indextemplate.replace("{username}", username);
	indextemplate = indextemplate.replace("{title}", title);
	indextemplate = indextemplate.replace("{infolink}", "<a href='"+infolink+"'>about this page</a>");
	res.write(indextemplate);
	res.end();
}

app.get('/style.css', function(req,res) {
	res.sendFile(__dirname+"/style.css");
});

app.get('/', function(req,res) {
	if ( req.session.userid ) {
		//console.log("id " + req.session.userid );
		serveIndex(req, res, "");
	} else {
		var userid = req.query.userid;
		var key = req.query.key;


		if ( userid && users[userid] && users[userid] == key ) {
			req.session.userid = userid;
			serveIndex(req, res, "Logged in as " + userid);
			console.log( "Login success: " + userid + " " + key );
		} else {
			res.write("User id key mismatch");
			res.end();
			console.log( "Login failure: " + userid + " " + key );
		}
	}
});

app.post('/', function(req,res) {
	var form = new formidable.IncomingForm();
	if (!checkSession(req)) {
		res.write("Logged out -- please re-log in");
		res.end();
		return;
	}

	form.parse(req, function (err, fields, files) {
		var targetfilename = targets[fields.target];
		console.log(">> "+Object.keys(files).length + " - " + targetfilename + ", " + Object.keys(fields).length);

		//console.log(util.inspect(files.infile));

		if ( !files.infile || !files.infile.name || !targetfilename ) {
			serveIndex(req, res, "Invalid file/options" );
			return;
		}

		var oldpath = files.infile.path;
		//var targetdir = __dirname + '/'+updir+req.session.userid+'/';
		var targetdir = updir+req.session.userid+'/';
		var newpath = targetdir + targetfilename;

		if (!fs.existsSync(targetdir)) {
			fs.mkdirSync(targetdir);
		}

		if ( fs.existsSync(newpath) ) {
			var stats = fs.statSync(newpath);
			var mtime = stats.mtime.toString().replace(/ /g, "_");
			fs.renameSync(newpath, newpath+"."+mtime);
		}

		fs.renameSync(oldpath, newpath);

		serveIndex(req, res, "File uploaded " + files.infile.name + " to " + targetfilename);
	});
});

app.get('/logout.html', function(req,res) {
	console.log( "User " + req.session.userid + " logged out" );
	req.session.destroy();
	serveMessage(res, "Logged out!");
});

app.get('/abort.html', function(req,res) {
	if (!checkSession(req)) {
		res.write("Logged out -- please re-log in");
		res.end();
		return;
	}
	var userid = req.session.userid;
	if ( !execreqmap[userid] || !checkPidAlive(execreqmap[userid].pid) ) {
		serveMessage(res, "No process to abort!" );
		return;
	}
	execreqmap[userid].child.kill("SIGINT");

	console.log("Process " + execreqmap[userid].pid + " from user " + userid + " killed" );
	delete execreqmap[userid];
		
	serveMessage(res, "Process aborted" );

	if ( cntinflight > 0 ) {
		cntinflight = cntinflight - 1;
	} else {
		console.log("ERROR! proc exited after cntinflight == 0\n");
	}
	
	var targetdir = updir+req.session.userid+'/';
	fs.appendFileSync(targetdir+logname, formatteddate() + ' Process aborted\n');
});

app.get('/exec.html', function(req,res) {
	if (!checkSession(req)) {
		res.write("Logged out -- please re-log in");
		res.end();
		return;
	}
	var userid = req.session.userid;

	if ( execreqmap[userid] ) {
		serveMessage(res, "user " + userid + " already has a pending exec request " + execreqmap[userid].pid);
		return;
	}

	
	var targetdir = updir+req.session.userid+'/';
	if ( fs.existsSync(targetdir+logname) ) {
		var stats = fs.statSync(targetdir+logname);
		var mtime = stats.mtime.toString().replace(/ /g, "_");
		fs.renameSync(targetdir+logname, targetdir+"."+logname+mtime);
	}
	
	var timeStamp = Math.floor(Date.now());
	execreqmap[userid] = {"queuedtime":timeStamp};
	execreqqueue.splice(execreqqueue.indexOf(userid)); // check for multiple occurrence?
	execreqqueue.push(userid);
	
	fs.appendFileSync(targetdir+logname, formatteddate() + ' New exec request queued, current position: ' + execreqqueue.length + "\n");

	serveMessage(res, "exec request queued");
});

for ( var key in targets) {
	//console.log("requesting " + key + " " + targets[key]);
	app.get('/'+targets[key], function(req,res) {
		//var fpath = __dirname+"/"+updir+req.session.userid+"/"+targets[key];
		var fpath = process.cwd()+"/"+updir+req.session.userid+req.url;
		res.sendFile(fpath);
	});
}
app.get('/'+logname, function(req,res) {
	//var fpath = __dirname+"/"+updir+req.session.userid+"/"+logname;
	var fpath = updir+req.session.userid+"/"+logname;
	res.sendFile(fpath);
});

function checkPidAlive(pid) {
	if ( fs.existsSync("/proc/"+pid) ) return true;
	return false;
}

function pruneLongProc() {
	var now = Math.floor(Date.now());
	for (var uid in execreqmap) {
		if ( now - execreqmap[uid].exectime < exectimeout*1000 ) continue;

		if (checkPidAlive(execreqmap[uid].pid)) {
			execreqmap[uid].child.kill("SIGINT");

			console.log("Process " + execreqmap[uid].pid + " from user " + uid + " killed due to timeout of " + exectimeout + " s" );
			delete execreqmap[uid];
			var targetdir = updir+uid+'/';
			fs.appendFileSync(targetdir+logname, formatteddate() + ' Process killed due to timeout of '+exectimeout+'s\n');
			if ( cntinflight > 0 ) {
				cntinflight = cntinflight - 1;
			} else {
				console.log("ERROR! proc exited after cntinflight == 0\n");
			}
		}
	}
}

function startNextExec() {
	pruneLongProc();

	if ( cntinflight >= execslots ) return;
	if ( execreqqueue.length < 1 ) return;

	var userid = execreqqueue.shift();
	var targetdir = updir+userid+'/';
	if ( !execreqmap[userid] ) {
		fs.appendFileSync(targetdir+logname, formatteddate() + ' env error! queue request exists but no queue map\n');
		console.log("ERROR! queue request exists but no queue map\n");
		return;
	}

	// copy src to uploads/userid
	//fs.copyFileSync("src", updir+userid+"/");
	childproc.execSync("cp -r src " + updir+userid+"/");
	// copy exec.sh to uploads/userid/src
	fs.copyFileSync("exec.sh", updir+userid+"/src/exec.sh");
	// run exec at uploads/userid/src
	var child = childproc.exec('bash exec.sh >> ../'+logname+' 2>&1',{"cwd":updir+userid+"/src/"}, function (e, stdout, stderr) {
		for (var uid in execreqmap) {
			if (!checkPidAlive(execreqmap[uid].pid)) {
				console.log("Process " + execreqmap[uid].pid + " done" );
				delete execreqmap[uid];
				var dtargetdir = updir+uid+'/';
				fs.appendFileSync(targetdir+logname, formatteddate() + ' Process finished\n');

				if ( cntinflight > 0 ) {
					cntinflight = cntinflight - 1;
				} else {
					console.log("ERROR! proc exited after cntinflight == 0\n");
				}
			}
		}
	});
	// save timestamp to map
	var timeStamp = Math.floor(Date.now());
	execreqmap[userid].exectime  = timeStamp;
	execreqmap[userid].child  = child;
	execreqmap[userid].pid  = child.pid;

	// append to log
	fs.appendFileSync(targetdir+logname, formatteddate() + ' exec process started!\n');

	cntinflight = cntinflight + 1;

	console.log("child pid created " + child.pid + " current inflight " + cntinflight );

	/*
	var child = childproc.exec('timeout 120 "exec.sh"', function (e, stdout, stderr) {
		//console.log("done!");
	});
	*/

	//console.log("!!");
}
setInterval(startNextExec, 500);

app.listen(8000);
