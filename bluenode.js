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
//app.use(express.limit('1mb'));

//var configjson = fs.readFileSync(__dirname + "/config.json");
var configjson = fs.readFileSync("config.json");
var config = JSON.parse(configjson);
var targets = config.targets;
var execslots = config.execslots; 
var exectimeout = config.exectimeout; 
var title = config.title;
var infolink = config.infolink;
var classkey = config.classkey;

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
	if ( h < 10 ) h = "0"+h;
	var m = now.getMinutes();
	if ( m < 10 ) m = "0"+m;
	var s = now.getSeconds();
	if ( s < 10 ) s = "0"+s;
	var ms = now.getMilliseconds();
	if ( ms < 10 ) ms = "00"+ms;
	else if ( ms < 100 ) ms = "0"+ms;
	return now.getFullYear()+"-"+mm+"-"+dd+" "+h+":"+m+":"+s+":"+ms;
}

function consolelog(msg) {
	console.log(formatteddate() + "] " + msg);
}


function checkSession(req) {
	if ( req.session.userid ) return true;
	return false;
}

function serveLogin(res) {
	res.sendFile(__dirname+"/login.html");
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
		curlog = curlog.replace(/(?:\t)/g, '&nbsp;&nbsp;&nbsp;&nbsp;');
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
	indextemplate = indextemplate.replace("{infolink}", "<a href='"+infolink+"'>Supplement material</a>");
	res.write(indextemplate);
	res.end();
}

app.get('/style.css', function(req,res) {
	res.sendFile(__dirname+"/style.css");
});
app.get('/login.html', function(req,res) {
	res.sendFile(__dirname+"/login.html");
});

app.get('/', function(req,res) {
	if ( checkSession(req) ) {
		//console.log("id " + req.session.userid );
		serveIndex(req, res, "");
	} else {
		var userid = req.query.userid;
		var key = req.query.key;


		if ( userid && users[userid] && users[userid] == key ) {
			req.session.userid = userid;
			serveIndex(req, res, "Logged in as " + userid);
			consolelog( "Login success: " + userid + " " + key );
		} else {
			serveLogin(res);
			var ip = req.headers['x-forwarded-for'] || 
				req.connection.remoteAddress || 
				req.socket.remoteAddress ||
				(req.connection.socket ? req.connection.socket.remoteAddress : null);
			consolelog( "Login failure: " + userid + " " + key + " from " + ip );
		}
	}
});

app.post('/', function(req,res) {
	var form = new formidable.IncomingForm();
	if (!checkSession(req)) {
		serveLogin(res);
		return;
	}

	var userid = req.session.userid;

	form.parse(req, function (err, fields, files) {
		var targetfilename = files.infile.name;
		consolelog("File upload "+ userid + " " + files.infile.name + " " + files.infile.size + " " + Object.keys(files).length + " - " + targetfilename + " " + Object.keys(fields).length);

		//console.log(util.inspect(files.infile));

		if ( !files.infile || !files.infile.name ) {
			serveIndex(req, res, "Invalid file/options" );
			return;
		}

		if ( files.infile.size > config.maxsize ) {
			fs.unlinkSync(files.infile.path);
			serveIndex(req, res, "Upload file too large! Incident logged" );
			consolelog("Large file upload request from "+userid+" " + files.infile.name + " " + files.infile.size);
			return;
		}
	
		var namematched = false;
		for ( var key in targets) {
			if ( targets[key] == files.infile.name ) {
				 namematched = true;
				 break;
			}
		}
		if ( !namematched ) {
			serveIndex(req, res, "Upload file not valid! ("+files.infile.name+") Incident logged" );
			consolelog("Invalid file upload request from "+userid+" " + files.infile.name + " " + files.infile.size);
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
	//execreqmap[userid].child.kill("SIGINT");
	process.kill(-execreqmap[userid].child.pid);

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
	if ( !fs.existsSync(targetdir) ) {
		fs.mkdirSync(targetdir);
	}
	if ( fs.existsSync(targetdir+logname) ) {
		var stats = fs.statSync(targetdir+logname);
		var mtime = stats.mtime.toString().replace(/ /g, "_");
		fs.renameSync(targetdir+logname, targetdir+logname+"."+mtime);
	}
	
	var timeStamp = Math.floor(Date.now());
	execreqmap[userid] = {"queuedtime":timeStamp};
	execreqqueue.splice(execreqqueue.indexOf(userid)); // check for multiple occurrence?
	execreqqueue.push(userid);
	
	fs.appendFileSync(targetdir+logname, formatteddate() + ' New exec request queued, current position: ' + execreqqueue.length + "\n");

	//serveMessage(res, "exec request queued");
	serveIndex(req, res, "Exec request queued!");
});

for ( var key in targets) {
	//console.log("requesting " + key + " " + targets[key]);
	app.get('/'+targets[key], function(req,res) {
		if ( !checkSession(req) ) {
			serveLogin(res);
			return;
		}
		//var fpath = __dirname+"/"+updir+req.session.userid+"/"+targets[key];
		var fpath = process.cwd()+"/"+updir+req.session.userid+req.url;
		res.sendFile(fpath);
	});
}
app.get('/'+logname, function(req,res) {
	//var fpath = __dirname+"/"+updir+req.session.userid+"/"+logname;
	if ( !checkSession(req) ) {
		serveLogin(res);
		return;
	}
	var fpath = process.cwd()+"/"+updir+req.session.userid+"/"+logname;
	res.sendFile(fpath);
});
app.get('/'+infolink, function(req,res) {
	//var fpath = __dirname+"/"+updir+req.session.userid+"/"+logname;
	res.sendFile(process.cwd()+"/"+infolink);
});

app.get('/adduser.html', function(req,res) {
	var newid = req.query.userid;
	var newkey = req.query.key;
	var ckey = req.query.ckey;
	if ( ckey && classkey && ckey == classkey ) {
		if ( newid && ! (newid in users) ) {
			users[newid] = newkey;
			let newusersjson = JSON.stringify(users, null, "\t");
			fs.writeFileSync('users.json', newusersjson);
			serveMessage(res, "User " + newid + " created!");
			
			consolelog("New user " + newid + " created");
		} else {
			serveMessage(res, "User " + newid + " already exists!");
			consolelog("Duplicate user " + newid + " creation attempt");
		}
	} else {
		serveMessage(res, "Class key incorrect!");
		consolelog("User creation attempt " + newid + " with wrong class key");
	}
	//serve
});

function checkPidAlive(pid) {
	if ( fs.existsSync("/proc/"+pid) ) return true;
	return false;
}

function pruneLongProc() {
	var now = Math.floor(Date.now());
	for (var uid in execreqmap) {
		if ( !execreqmap[uid].exectime ) continue;

		if (!checkPidAlive(execreqmap[uid].pid)) {
			consolelog("Process " + execreqmap[uid].pid + " done" );
			delete execreqmap[uid];
			var dtargetdir = updir+uid+'/';
			fs.appendFileSync(targetdir+logname, formatteddate() + ' Process finished\n');

			if ( cntinflight > 0 ) {
				cntinflight = cntinflight - 1;
			} else {
				consolelog("ERROR! proc exited after cntinflight == 0, "+uid+"\n");
			}
			continue;
		}

		var targetdir = updir+uid+'/';
		var stats = fs.statSync(targetdir+logname);
		if ( stats["size"] >= config.maxsize ) {
			process.kill(-execreqmap[uid].child.pid);
			
			consolelog("Process " + execreqmap[uid].pid + " from user " + uid + " killed due to output file size limiation of " + config.maxsize );
			delete execreqmap[uid];
			fs.appendFileSync(targetdir+logname, formatteddate() + ' Process killed due to output file size limit\n');
			if ( cntinflight > 0 ) {
				cntinflight = cntinflight - 1;
			} else {
				consolelog("ERROR! proc exited after cntinflight == 0, "+uid+"\n");
			}
			continue;
		}

		if ( now - execreqmap[uid].exectime < exectimeout*1000 ) continue;

		if (checkPidAlive(execreqmap[uid].pid)) {
			//execreqmap[uid].child.kill("SIGINT");
			process.kill(-execreqmap[uid].child.pid);

			consolelog("Process " + execreqmap[uid].pid + " from user " + uid + " killed due to timeout of " + exectimeout + " s" );
			delete execreqmap[uid];
			fs.appendFileSync(targetdir+logname, formatteddate() + ' Process killed due to timeout of '+exectimeout+'s\n');
			if ( cntinflight > 0 ) {
				cntinflight = cntinflight - 1;
			} else {
				consolelog("ERROR! proc exited after cntinflight == 0, "+uid+"\n");
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
		consolelog("ERROR! queue request exists but no queue map from user "+userid+"\n");
		return;
	}

	// copy src to uploads/userid
	//fs.copyFileSync("src", updir+userid+"/");
	childproc.execSync("rm -rf " + updir+userid+"/src");
	childproc.execSync("cp -r src " + updir+userid+"/");
	// copy exec.sh to uploads/userid/src
	fs.copyFileSync("exec.sh", updir+userid+"/src/exec.sh");
	// run exec at uploads/userid/src
	var child = childproc.spawn('bash', ["exec.sh"],{"cwd":updir+userid+"/src/", detached:true});
	child.stdout.on('data', function(data) {
		var stats = fs.statSync(targetdir+logname);
		if ( stats["size"] <= config.maxsize ) {
			fs.appendFileSync(targetdir+logname, "" + data );
		}
	});
	child.stderr.on('data', function(data) {
		var stats = fs.statSync(targetdir+logname);
		if ( stats["size"] <= config.maxsize ) {
			fs.appendFileSync(targetdir+logname, "" + data );
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

	consolelog("child pid created from user " + userid + " " + child.pid + " current inflight " + cntinflight );

	/*
	var child = childproc.exec('timeout 120 "exec.sh"', function (e, stdout, stderr) {
		//console.log("done!");
	});
	*/

	//console.log("!!");
}
setInterval(startNextExec, 500);

var port = 8000;
if ( process.argv.length > 2 ) {
	port = process.argv[2];
}

app.listen(port);

