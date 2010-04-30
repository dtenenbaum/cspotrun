jQuery.noConflict();







var fb_lite = false;
try {
	if (firebug) {
		fb_lite = true;  
		firebug.d.console.cmd.log("initializing firebug logging");
	}
} catch(e) {
	// do nothing
}

function FG_fireDataEvent() {
  // events are documented in the Flanagan Javascript book
  var ev = document.createEvent("Events");
  // initEvent(eventType, canBubble, cancelable)
  ev.initEvent("gaggleDataEvent", true, false); 
  document.dispatchEvent(ev);
} 


function log(message) {
	if (fb_lite) {  
		console.log(message);
	} else {
		if (window.console) {
			console.log(message);
		} 
	}
	if (window.dump) {
	    dump(message + "\n");
	}
}                          
 
String.prototype.trim = function() {
	return this.replace(/^\s+|\s+$/g,"");
}
String.prototype.ltrim = function() {
	return this.replace(/^\s+/,"");
}
String.prototype.rtrim = function() {
	return this.replace(/\s+$/,"");
}                                                       


var blank = function(str) {
    return (str == undefined || str.trim() == "");
}

var f = function(str) {
    return jQuery("#" + str).val();
}


jQuery(document).ready(function() {
    
   jQuery("#email_input").focus();
   jQuery(".hide_me").hide();
   
   jQuery("#price").val(jQuery("#large_recommended_price").html());
   
   jQuery("#processor_type").change(function(){
      var id = (jQuery("#processor_type").val() == "m1.large") ? "#small_recommended_price" : "#large_recommended_price";
      jQuery("#price").val(jQuery(id).html());
   });
   
   jQuery("#more_info").hide();
   
   jQuery("#show_more_info").click(function(){
       jQuery("#more_info").show();
   });

   jQuery("#hide_more_info").click(function(){
       jQuery("#more_info").hide();
   });
   
   jQuery("#please_wait").hide();
   
  jQuery("#submit_job").submit(function(){
      log("in submit function");
      var usingRatios = false;
      var valid = true;
      var msg = "Invalid form submission!\n";
      if (blank(f("uploaded_file")) && blank(f("preinitialized_rdata_file"))) {
          valid = false;
          msg += "- You must upload either a ratios file or a preinitialized .RData file.\n";
      }
      if (!blank(f("uploaded_file")) && !blank(f("preinitialized_rdata_file"))) {
          valid = false;
          msg += "- You cannot upload both a ratios file and a preinitialized RData file.\n";
          
      }
      
      if (blank(f("uploaded_file"))) {
          usingRatios = false;
      } else {
          usingRatios = true;
      }
      
      // fields that are always required: job_name, num_instances, price(numeric), 
      if (blank(f("job_name")) || blank(f("num_instances")) || blank(f("price"))) {
          valid = false;
          msg += " - Some fields are blank!\n";
      }
      
      
      if (!usingRatios) {
          if(blank(f("k")) || blank(f("n_iter"))) {
              valid = false;
              msg += " - You must supply k and n.iter values!\n"
          }
      }
      
      log ("is form valid? " + valid);
      if (!valid) {
          alert(msg);
      }
      if(valid) { 
          jQuery("#please_wait").show();
          jQuery("#submit_new_job_button").attr("disabled","disabled");
      }
      
      
      return (valid);
   });

   
});