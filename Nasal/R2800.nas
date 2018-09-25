var engine_count = 1;
var looptime = 0.2;
var cyltemp = props.globals.getNode("engines/engine[0]/cylinder-temp-degc");
var exhtempf = props.globals.getNode("engines/engine[0]/egt-degf");
var rpm = props.globals.getNode("engines/engine[0]/rpm");
var thrust = props.globals.getNode("engines/engine[0]/thrust-lbs",1);
var carbetemp = props.globals.getNode("engines/engine[0]/carburator-entry-temp-degc");
var manpress = props.globals.getNode("engines/engine[0]/mp-osi");
var engstat = props.globals.getNode("engines/engine[0]/running");
var oiltemp = props.globals.getNode("engines/engine[0]/oil-temperature-degf");
var airspeed = props.globals.getNode("velocities/airspeed-kt");
var envtemp = props.globals.getNode("environment/temperature-degc");
var cowlflap = props.globals.getNode("controls/engines/engine[0]/cowl-flaps-norm");
var mixture = props.globals.getNode("controls/engines/engine[0]/mixture");
var mixture0 = props.globals.getNode("controls/engines/engine[0]/mixture0");
var viscosity = props.globals.getNode("engines/engine[0]/oil-visc");
var rstrain = props.globals.getNode("engines/engine[0]/rev-strain");
var oboost = props.globals.getNode("engines/engine[0]/boost-strain");
var nofuel = props.globals.getNode("engines/engine[0]/out-of-fuel",1 );
var gload = props.globals.getNode("accelerations/pilot-g",1);


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
#	print ("engstat: ", engstat.getValue());
	engine_update();
	fluid_update();
	check_engine();
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
        var cat = et0;
        if (engstat.getBoolValue ()) {
		cat += 0.6 * mp;
        }
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
                setprop ("/sim/messages/copilot", "Engine died due to excessive RPM!");
		setprop("/engines/engine[0]/overrev", 1);
		failure.kill_engine();
	}	
	#check for overboost
	if (mp > 55) {
		var ob0 = ( mp - 57)*(mp - 57);
		oboost.setValue (ob + ob0);
		# print (ob0, " ",ob + ob0);"engines/engine[0]/cylinder-temp-degc"
	}
	if (ob > 500 ) {
		setprop("/engines/engine[0]/overboost", 1);
                setprop ("/sim/messages/copilot", "Engine died due to excessive manifold pressure!");
		failure.kill_engine();
	}
	if ( gload.getValue() < -0.3 ) {
			print ("cutout!");
			if (mixture0.getValue() == 0 ){
					mixture0.setValue( mixture.getValue() );
					mixture.setValue(0);
			}
	} else {
			if (mixture0.getValue() != 0 ) {
					mixture.setValue( mixture0.getValue() );
					mixture0.setValue(0);
			}
	}		
}


var magicstart = func {
    setprop("/consumables/fuel/tank[0]/selected",1);
    setprop("/controls/engines/engine[0]/magnetos",3);
    setprop("/engines/engine[0]/oil-visc",1);
    setprop("/engines/engine[0]/rpm",800);
    setprop("/engines/engine[0]/running",1);
    setprop("/engines/engine[0]/out-of-fuel",0);
}

setlistener("/sim/signals/fdm-initialized",init);

var boost = props.globals.getNode ("controls/engines/engine/boost");
var shift_boost_up = func {
print ("Shift boost up");
	if (boost.getValue() <= 0.3){
		boost.setValue(0.7);
	}
	else {
		boost.setValue(1.0);
	}
}
var shift_boost_down = func {
print ("Shift boost down");
	if (boost.getValue() >= 1.0){
		boost.setValue(0.75);
	}
	else {
		boost.setValue(0.3);
	}
}
