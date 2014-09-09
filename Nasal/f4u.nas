var engine_count = 1;
var looptime = 0.2;
var emptyw = 8980;
var breakload = 8;
var breakspeed = 415;
var bendload = 7;
var engstat = props.globals.getNode("engines/engine[0]/running");
var fail_r = props.globals.getNode("controls/flight/controls-failure-roll");
var fail_d = props.globals.getNode("controls/flight/controls-failure-drag");

#var init = func {
#  main_loop();
#}

#var main_loop = func {

#	check_airframe();
#  settimer(main_loop, looptime);
#}





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

# setlistener("/sim/signals/fdm-initialized",init);
