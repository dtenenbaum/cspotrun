jQuery.noConflict();

jQuery(document).ready(function() {
   jQuery(".hide_me").hide();
   
   jQuery("#price").val(jQuery("#small_recommended_price").html());
   
   jQuery("#processor_type").change(function(){
      var id = (jQuery("#processor_type").val() == "m1.large") ? "#small_recommended_price" : "#large_recommended_price";
      jQuery("#price").val(jQuery(id).html());
   });
   
});