var emptyw = 8980;
var breakload = 9;
var breakspeed = 415;
var bendload = 7;
var looptime = 0.2;
var flapoverspeed= 145;
var airspeed = props.globals.getNode("velocities/airspeed-kt");
var gload = props.globals.getNode("accelerations/pilot-g",1);
var weight = props.globals.getNode("yasim/gross-weight-lbs",1);
var flappos = props.globals.getNode("controls/flight/flaps",1);
var turn = props.globals.getNode("instrumentation/turn-indicator/indicated-turn-rate");
var fail_r = props.globals.getNode("controls/flight/controls-failure-roll");
var fail_d = props.globals.getNode("controls/flight/controls-failure-drag");
var gear0 = props.globals.getNode("controls/gear/gear[0]/gear-down");
var gear1 = props.globals.getNode("controls/gear/gear[1]/gear-down");
var gear2 = props.globals.getNode("controls/gear/gear[2]/gear-down");
var nofuel = props.globals.getNode("engines/engine[0]/out-of-fuel",1 );
var hitx = props.globals.getNode("combat/hit/hit_x",1 );
var hity = props.globals.getNode("combat/hit/hit_y",1 );
var hitz = props.globals.getNode("combat/hit/hit_z",1 );
var hitvalid = props.globals.getNode("combat/hit/valid",1 );


var init = func {

		settimer(main_loop, looptime);
}


var main_loop = func {
		check_airframe();

  	settimer(main_loop, looptime);
}


var check_airframe = func {
	var gl = gload.getValue();
	var gw = weight.getValue();
	var as = airspeed.getValue();
	var slip = turn.getValue();
	var fail = fail_r.getValue();
	var ow = gw - emptyw;

# check flap deployment and failure due to overspeed
	if ( flappos.getValue() > 0 ) {

				if (as > flapoverspeed) {
						setprop ("/sim/messages/copilot", "flaps overspeed!");
						var load = as - flapoverspeed;
						print (load*flappos.getValue());
						if (load * flappos.getValue() > 20 ) {
								if (flappos.getValue() >= 0.5 ) {
										flappos.setValue(0);
										flappos.setAttribute("writable",0);
										setprop ("/sim/failure/flaps", "1");
								}
						flappos.setValue(0);
						}
				}
		}

# check for excessive g-load or overspeed
		#print(gl, breakload - 0.0004 * ow );
	if (gl > (breakload - 0.0003 * ow) or (as > breakspeed)) {
		setprop ("/sim/messages/copilot", "Wing torn by excessive G-load!");
		if (slip < 0) {
			setprop ("sim/failure/left-wing-torn", "1");
			fail_r.setValue(1);
		} else {
			setprop ("sim/failure/right-wing-torn", "1");
			fail_r.setValue(-1);
		}
	}
	if (gl > (bendload - 0.0004 * ow)) {
		setprop ("/sim/messages/copilot", "Gear bent and stuck by excessive G-load!");
		if (slip < 0) {
			gear0.setAttribute("writable",0);
		} else {
			gear1.setAttribute("writable",0);
		}
	}		
}


var kill_engine = func {
	nofuel.setValue(1);
	nofuel.setAttribute("writable", 0);
#	interpolate ("/engines/engine[0]/fuel-press", 0, 1);
#	interpolate ("/engines/engine[0]/mp-osi", 0, 1.5);
	
}


var process_hit = func {
		var hit1x = hitx.getValue();
		var hit1y = hity.getValue();
		var hit1z = hitz.getValue();

		print ("hit X: ", hitx.getValue(), " hit_y: ", hity.getValue(), "hit_Z: ", hitz.getValue());
		var count = 0;
		var zone = 1;
		while ( zone > 0 ) {
				if ( hit1x >= hitZones[count][2] and hit1x <= hitZones[count][3] ) {
						setprop ("/sim/messages/copilot",  hitZones[count][0], " was hit!");
						}
				zone = hitZones[count][1];
				print (zone);
				count = count+1;
		}
	
}


# lower gear
setlistener("/controls/gear/gear-down", func(n) {
#		print (n.getValue());
		if (n.getValue() == "1") {
				gear0.setValue("true");
				gear1.setValue("true"); 
				gear2.setValue("true");
		} else {
				gear0.setValue("false");
				gear1.setValue("false"); 
				gear2.setValue("false");
		}
});

# check for propstrike
setlistener("/gear/gear[3]/compression-norm", func(n) {
		if (n.getValue() >=0.1 ) {
				kill_engine();
				print("Propeller strike!");
		}
});

setlistener("/sim/signals/fdm-initialized",init);
