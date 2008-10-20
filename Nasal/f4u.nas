var engine_count = 1;


var init = func {
  if (getprop("/controls/engines/on-startup-running") == 1) {
		magicstart();
	setprop ("instrumentation/altimeter/pressure-alt-ft",10);
  }  
   main_loop();
}
var main_loop = func {

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

toggle_cowlflaps = func {
  if(getprop("/controls/engines/engine[0]/cowl-flaps-norm") > 0) {
    interpolate("/controls/engines/engine[0]/cowl-flaps-norm", 0, 3);
  } else {
    interpolate("/controls/engines/engine[0]/cowl-flaps-norm", 1, 3);
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
