  setlistener("sim/model/aircraft/impact/gun", func(n) {
    var impact = n.getValue();
    var solid = getprop(impact ~ "/material/solid");
    
    if (solid) {
#      var long = getprop(impact ~ "/impact/longitude-deg");    
#      var lat = getprop(impact ~ "/impact/latitude-deg");
			setprop("sim/model/aircraft/impact/splash",0);
    }
		else {
			setprop("sim/model/aircraft/impact/splash",1);
		}
  });

var fire_MG = func {
 if (getprop("/controls/armament/master-arm") == 1)  {
     setprop("/controls/armament/trigger", 1);
     } 
}
var stop_MG = func {
     setprop("/controls/armament/trigger", 0); 
}

