var engine_count = 1;
var looptime = 0.2;
var emptyw = 8980;
var breakload = 8;
var breakspeed = 415;
var bendload = 7;
var cyltemp = props.globals.getNode("engines/engine[0]/cylinder-temp-degc");
var exhtempf = props.globals.getNode("engines/engine[0]/egt-degf");
var rpm = props.globals.getNode("engines/engine[0]/rpm");
var thrust = props.globals.getNode("engines/engine[0]/thrust-lbs",1);
var carbetemp = props.globals.getNode("engines/engine[0]/carburator-entry-temp-degc");
var manpress = props.globals.getNode("engines/engine[0]/mp-osi");
var engstat = props.globals.getNode("engines/engine[0]/running");
var oiltemp = props.globals.getNode("engines/engine[0]/oil-temperature-degf");
var blower = props.globals.getNode("controls/engines/engine[0]/boost");
var airspeed = props.globals.getNode("velocities/airspeed-kt");
var envtemp = props.globals.getNode("environment/temperature-degc");
var cowlflap = props.globals.getNode("controls/engines/engine[0]/cowl-flaps-norm");
var mixture = props.globals.getNode("controls/engines/engine[0]/mixture");
var viscosity = props.globals.getNode("engines/engine[0]/oil-visc");
var rstrain = props.globals.getNode("engines/engine[0]/rev-strain");
var oboost = props.globals.getNode("engines/engine[0]/boost-strain");
var nofuel = props.globals.getNode("engines/engine[0]/out-of-fuel",1 );
var gload = props.globals.getNode("accelerations/pilot-g",1);
var weight = props.globals.getNode("yasim/gross-weight-lbs",1);
var turn = props.globals.getNode("instrumentation/turn-indicator/indicated-turn-rate");
var fail_r = props.globals.getNode("controls/flight/controls-failure-roll");
var fail_d = props.globals.getNode("controls/flight/controls-failure-drag");

var init = func {
	var et0 = envtemp.getValue();
	#	print (et0);
	cyltemp.setDoubleValue (et0);
	
  if (getprop("/controls/engines/on-startup-running") == 1) {
		magicstart();
  }  
  settimer(main_loop, looptime);
}
var main_loop = func {
	if (engstat.getValue()){
		engine_update();
		fluid_update();
		check_engine();
	} else {
	#	cool_down();
	}
	check_airframe();
  settimer(main_loop, looptime);
}


var engine_update = func {
# if someone has suggestions to calculate engine parameters more realistic drop me a note
	var as = airspeed.getValue();
	var cf = cowlflap.getValue();
	var ct = cyltemp.getValue();
	var et0 = envtemp.getValue();
	var egt = exhtempf.getValue();
	var ob = oboost.getValue();
	var rs = rstrain.getValue();
	var thr = thrust.getValue();
	#var thr = getprop("engines/engine[0]/thrust-lbs"); # fixme: don't know why I have to do it this way
	var rpm0 = rpm.getValue();
	var mp = manpress.getValue();
	var mix = mixture.getValue();
	# calculate carburator entry temperature
	var cat = et0 + 0.6 * mp;
	#print ("CET: ",cat);
	carbetemp.setValue(cat);
	# summing up various parameters with a weighing factor
	var temp = 3 * cat + 0.3 * rpm0 + 0.5 * egt - 0.005 * as * as - 0.07* thr * (cf+0.1) -20 * mix ;
	#print ("Temp: ",temp,"Mix: ",mix);
	cyltemp.setDoubleValue (temp * 0.4);
}

var fluid_update = func {
	var otemp = oiltemp.getValue();
	var visc = viscosity.getValue();
	# print (otemp," ",visc);
	interpolate ("engines/engine[0]/oil-press", 8.2 - 2*visc, looptime);
	interpolate ("engines/engine[0]/oil-temp-calc", otemp *visc-70, looptime);
	if (visc < 1.0 ) {
		interpolate ("engines/engine[0]/oil-visc", visc + 0.002);

	}
}
var check_engine = func {
	var rs = rstrain.getValue();
	var ob = oboost.getValue();
	var rpm0 = rpm.getValue();
	var mp = manpress.getValue();
	#check for overrev
	if (rpm0 > 3100) {
		var rs0 = 0.01 * (rpm0 - 3100) * ( rpm0 - 3100);
		rstrain.setValue (rs + rs0);
		# print (rs0, " ",rs + rs0);
	}
	if (rs > 300000 ) {
		setprop("/engines/engine[0]/overrev", 1);
		kill_engine();
	}	
	#check for overboost
	if (mp > 55) {
		var ob0 = ( mp - 57)*(mp - 57);
		oboost.setValue (ob + ob0);
		# print (ob0, " ",ob + ob0);"engines/engine[0]/cylinder-temp-degc"
	}
	if (ob > 500 ) {
		setprop("/engines/engine[0]/overboost", 1);
		kill_engine();
	}
}

var check_airframe = func {
	var gl = gload.getValue();
	var gw = weight.getValue();
	var as = airspeed.getValue();
	var slip = turn.getValue();
	var fail = fail_r.getValue();
	var ow = gw - emptyw;
		#print(gl, breakload - 0.0004 * ow );
	if (gl > (breakload - 0.0003 * ow) or (as > breakspeed)) {
		print ("break");
		if (slip < 0) {
			setprop ("sim/systems/structural/left-wing-torn", "1");
			fail_r.setValue(1);
		} else {
			setprop ("sim/systems/structural/right-wing-torn", "1");
			fail_r.setValue(-1);
		}
	}
	if (gl > (bendload - 0.0004 * ow)) {
		print ("bend");
	}		
}

var cool_down = func {
	print ("cooling");
	var et0 = envtemp.getValue();
	interpolate ("engines/engine[0]/cylinder-temp-degc", et0, looptime);
	interpolate ("engines/engine[0]/oil-temp-calc", et0, looptime);
	interpolate ("engines/engine[0]/oil-visc" , 0, looptime);
}

var kill_engine = func {
	nofuel.setValue(1);
	nofuel.setAttribute("writable", 0);
	interpolate ("/engines/engine[0]/fuel-press", 0, 1);
	interpolate ("/engines/engine[0]/mp-osi", 0, 1.5);
}

var magicstart = func {
    setprop("/consumables/fuel/tank[0]/selected",1);
    setprop("/controls/engines/engine[0]/magnetos",3);
    setprop("/controls/engines/engine[0]/coolflap-auto",1);
    setprop("/controls/engines/engine[0]/radlever",1);
    setprop("/controls/engines/engine[0]/propeller-pitch",0.5);
    setprop("/engines/engine[0]/oil-visc",1);
    setprop("/engines/engine[0]/rpm",800);
    setprop("/engines/engine[0]/engine-running",1);
    setprop("/engines/engine[0]/out-of-fuel",0);
}

var toggle_canopy = func {
  
  if(getprop("/controls/canopy/position-norm") > 0) {
      canopy.close();
  } else {
      canopy.open();
  }
}

var toggle_wingfold = func {

	if (engstat.getValue()){
 	 if(getprop("/controls/wingfold/position-norm") > 0) {
	      wingfold.close();
				fail_d.setValue(0);
				fail_r.setValue(0);
 	 } else {
  	    wingfold.open();
				fail_d.setValue(1.0);
				fail_r.setValue(0.7);
  	}
	}
}

var open_cowlflaps = func {
	if (cowlflap.getValue() < 1.0){
		interpolate("controls/engines/engine[0]/cowl-flaps-norm",cowlflap.getValue() + 0.1,1);
	}
}
var close_cowlflaps = func {
	if (cowlflap.getValue() > 0.0){
		interpolate("controls/engines/engine[0]/cowl-flaps-norm",cowlflap.getValue() -0.1,1);
	}
}

var shift_blower_up = func {
	if (blower.getValue() <= 0.3){
		interpolate("controls/engines/engine[0]/boost", 0.75, 1);
	}
	else {
		interpolate("controls/engines/engine[0]/boost", 1.0, 1);
	}
}
var shift_blower_dn = func {
	if (blower.getValue() >= 1.0){
		interpolate("controls/engines/engine[0]/boost", 0.75, 1);
	}
	else {
		interpolate("controls/engines/engine[0]/boost", 0.3, 1);
	}
}


var toggle_tailhook = func {
  if(getprop("/controls/gear/tailhook/position-norm") > 0) {
      hook.close();
  } else {
      hook.open();
  }
}

    setlistener("/controls/fuel/switch-position", func(n) {
	position=n.getValue();
    setprop("/consumables/fuel/tank[0]/selected",0);
    setprop("/consumables/fuel/tank[1]/selected",0);
    setprop("/consumables/fuel/tank[2]/selected",0);
    setprop("/consumables/fuel/tank[3]/selected",0);
    setprop("/consumables/fuel/tank[4]/selected",0);
    setprop("/consumables/fuel/tank[5]/selected",0);
        if(position >= 0.0){
						print (position);

               setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);

    };
   },1);


aircraft.livery.init("Aircraft/F4U/Models/Liveries", "sim/model/livery/name");

var hook = aircraft.door.new ("/controls/gear/tailhook/",3);
var wingfold = aircraft.door.new ("/controls/wingfold/",15);
var canopy = aircraft.door.new ("/controls/canopy/",3);

var logo_dialog = gui.OverlaySelector.new("Select Logo", "Aircraft/Generic/Logos", "sim/model/logo/name", nil, "sim/multiplay/generic/string");

setlistener("/sim/signals/fdm-initialized",init);
