

toggle_canopy = func {
  if(getprop("/controls/canopy/canopy-pos-norm") > 0) {
    interpolate("/controls/canopy/canopy-pos-norm", 0, 3);
  } else {
    interpolate("/controls/canopy/canopy-pos-norm", 1, 3);
  }
}

toggle_cowlflaps = func {
  if(getprop("/controls/engines/engine[0]/cowl-flaps-norm") > 0) {
    interpolate("/controls/engines/engine[0]/cowl-flaps-norm", 0, 3);
  } else {
    interpolate("/controls/engines/engine[0]/cowl-flaps-norm", 1, 3);
  }
}
toggle_tailhook = func {
  if(getprop("/controls/gear/tailhook/pos-norm") > 0) {
    interpolate("/controls/gear/tailhook/pos-norm", 0, 3);
  } else {
    interpolate("/controls/gear/tailhook/pos-norm", 1, 3);
  }
}


fire_wgr = func {
  rcount=getprop("/sim/weight[1]/weight-lb");
  if(rcount > 20){
    if(rcount == 270)  {
     setprop("/controls/armament/wgr", 1)
     } 
  setprop("sim/weight[1]/weight-lb", rcount - 250.0);
  setprop("sim/weight[2]/weight-lb", rcount - 250.0);
  }
}


