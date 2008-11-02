var engine_count = 1;
var looptime =0.2;
var cyltemp = props.globals.getNode("engines/engine[0]/cylinder-temp-degc");
var exhtempf = props.globals.getNode("engines/engine[0]/egt-degf");
var rpm = props.globals.getNode("engines/engine[0]/rpm");
# var thrust = props.globals.getNode("engines/engine[0]/thrust-lbs");
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
	}
  settimer(main_loop, looptime);
}


var engine_update = func {
# if someone has suggestions to calculate engine parameters more realistic drop me a note
	var as = airspeed.getValue();
	var cf = cowlflap.getValue();
	var ct = cyltemp.getValue();
	var et0 = envtemp.getValue();
	var egt = exhtempf.getValue();
	#	var thr = thrust.getValue();
	var thr = getprop("engines/engine[0]/thrust-lbs"); # fixme: don't know why I have to do it this way
	var rpm0 = rpm.getValue();
	var mp = manpress.getValue();
	var mix = mixture.getValue();
	# calculate carburator entry temperature
	var cat = et0 + 0.6 * mp;
	#print ("CET: ",cat);
	carbetemp.setValue(cat);
	# summing up various parameters with a weighing factor
	var temp = 3 * cat + 0.08 * rpm0 + 0.1 * egt - 0.04* as - 0.01* thr * (cf+0.1) -20 * mix ;
	#print ("Temp: ",temp,"Mix: ",mix);
	cyltemp.setDoubleValue (temp * 0.85);
}

var fluid_update = func {
	var otemp = oiltemp.getValue();
	var visc = viscosity.getValue();
	# print (otemp," ",visc);
	interpolate ("engines/engine[0]/oil-press", 8.2 - 2*visc, looptime);
	interpolate ("engines/engine[0]/oil-temp-calc", otemp *visc-70, looptime);
	if (visc < 1.0 ) {
		setprop("engines/engine[0]/oil-visc", visc + 0.002);

	}
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
  canopy = aircraft.door.new ("/controls/canopy/",3);
  if(getprop("/controls/canopy/position-norm") > 0) {
      canopy.close();
  } else {
      canopy.open();
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
  hook = aircraft.door.new ("/controls/gear/tailhook/",3);
  if(getprop("/controls/gear/tailhook/position-norm") > 0) {
      hook.close();
  } else {

      hook.open();
  }
}

aircraft.livery.init("Aircraft/F4U/Models/Liveries", "sim/model/livery/name");

var logo_dialog = gui.OverlaySelector.new("Select Logo", "Aircraft/F4U/Models/logos", "sim/model/logo/name", nil, "sim/multiplay/generic/string");

setlistener("/sim/signals/fdm-initialized",init);
