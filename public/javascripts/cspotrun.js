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


var priceHistoryUrl = "http://cloudexchange.org/charts/us-east-1.linux.INSTANCE_TYPE.html";

jQuery(document).ready(function() {
    
   jQuery("#email_input").focus();
   jQuery(".hide_me").hide();
   
   
   
   jQuery("#price").val(jQuery("#large_recommended_price").html());

   jQuery("#pricing_history").attr("href", priceHistoryUrl.replace("INSTANCE_TYPE", jQuery("#processor_type").val()));
   
   jQuery("#processor_type").change(function(){
      var id = (jQuery("#processor_type").val() == "m1.large") ? "#small_recommended_price" : "#large_recommended_price";
      jQuery("#price").val(jQuery(id).html());
      jQuery("#pricing_history").attr("href", priceHistoryUrl.replace("INSTANCE_TYPE", jQuery("#processor_type").val()));
   });
   
   
   
   jQuery("#data_source").change(function(){
      jQuery(".if_rdata").toggle();
      jQuery(".if_ratios").toggle();
      var val = jQuery("#data_source").val();
      if (val == "rdata") {
          jQuery("#uploaded_file").val("")
      } else {
          jQuery("#preinitialized_rdata_file").val("");
      }
   });
   
   
   jQuery("#show_more_info").click(function(){
       jQuery("#more_info").show();
   });

   jQuery("#hide_more_info").click(function(){
       jQuery("#more_info").hide();
   });
   
   
   jQuery("#show_pre_run_script_info").click(function(){
       jQuery("#pre_run_script_info").show();
   });
   
   jQuery("#hide_pre_run_script_info").click(function(){
       jQuery("#pre_run_script_info").hide();
   })
   
   jQuery(".if_ratios").hide();
   
  jQuery("#submit_job").submit(function(){
      log("in submit function");
      
      
      
      var usingRatios = (jQuery("#data_source").val() == "ratios");
      
      var valid = true;
      var msg = "Invalid form submission!\n";
      if (blank(f("uploaded_file")) && blank(f("preinitialized_rdata_file"))) {
          valid = false;
          msg += "- You must upload a data file.\n";
      }
      if (!blank(f("uploaded_file")) && !blank(f("preinitialized_rdata_file"))) {
          valid = false;
          msg += "- You cannot upload both a ratios file and a preinitialized RData file.\n";
          
      }
      
      // fields that are always required: job_name, num_instances, price(numeric), 
      if (blank(f("job_name")) || blank(f("num_instances")) || blank(f("price"))) {
          valid = false;
          msg += " - Some fields are blank!\n";
      }
      
      
      if (usingRatios) {
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

          /*
          var u1 = jQuery("#u1").html();
          var u2 = jQuery("#u2").html();

          log("u1 = " + u1);
          log("u2 = " + u2);
          
          log("v1="+jQuery("#preinitialized_rdata_file").val());
          log("v2="+jQuery("#pre_run_script").val());

          //jQuery("#u1").html(u2);
          //jQuery("#u2").html(u1);
          
          return false;
          
          */
      }
      
      
      
      return (valid);
   });

   
});