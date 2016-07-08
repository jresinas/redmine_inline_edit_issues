$(document).ready(function() {
    // Avoid autofocus
    $(function(){
        $('input').blur();
    });

    $(function() {
        $('#inline_edit_form td input, #inline_edit_form td select').each(function() {
            $.data(this, 'default', this.value);
        }).css("color", "black").focus(function() {
            if (!$.data(this, 'edited')) {
                // Change form inputs to red.
                if (!$(this).is(":checkbox")){
                    $(this).css({"color" : "red"});
                }
            }
        }).change(function() {
            var curValue = getCurrentValue(this);
            var defValue = getDefaultValue($(this));
            var editedVal = (curValue != defValue);
            $.data(this, 'edited', editedVal);
            if($(this).is(":checkbox")){
               if (editedVal){
                  $(this).parent().addClass('has_background');
               }else{
                   $(this).parent().removeClass('has_background');
               }
            }
        }).blur(function() {
            if (!$.data(this, 'edited')) {
                this.value = $.data(this, 'default');
                $(this).css("color", "black");
            }
        }).hover(function() {
            if (!($(this).is(":checkbox"))) {
                var originalValue = getDefaultValue($(this)) || "--BLANK--";
                displayOriginalValue($(this), originalValue);
            }
        }, function() {
            $('#field_original_value').html(" ");
            $('#field_original').hide();
        });
    });
    
    
    // Reset Everything...
    $('#inline_edit_reset').click(function() {
        $('#inline_edit_form')[0].reset();
        calcAllGroupEstimatedHours();
        calcTotalEstimatedHours();
        $('#inline_edit_form td input, #inline_edit_form td select').css("color", "black").each(function() {
            $.data(this, 'edited', false);
            if($(this).is(":checkbox")){
               $(this).parent().removeClass('has_background');
            }
        });
    });

    // Calculate Total Estimated Hours
    function calcTotalEstimatedHours() {
        var total = 0.0;
        $('[id$=_estimated_hours]').each(function() {
            total += parseFloat($(this).val()) || 0;
        });

        var result = total.toFixed(2);
        $('td#total-estimated_hours').html(result);
    }

    // Re-calculate group totals for all groups... useful for a reset
    function calcAllGroupEstimatedHours() {
        var previousGroupName = "";

        // Loop through only the estimated hours columns that have a grouping
        $('td[class*="estimated_hours group_"]').each(function() {
            var myClass = $(this).attr('class');
            var groupPos = myClass.search("group");
            if (groupPos >= 0) {
                var groupName = myClass.substr(groupPos);
                if (groupName != previousGroupName) {
                    calcGroupEstimatedHours(groupName);
                    previousGroupName = groupName;
                }
            }
        });
    }

    function calcCurrentGroupEstimatedHours(element) {
        // get this group name by looking at the class names of the parent element
        var myClass = element.parent().attr('class');
        var groupPos = myClass.search("group");

        // continue only if there is a grouping
        if (groupPos >= 0) {
            var groupName = myClass.substr(groupPos);
            calcGroupEstimatedHours(groupName);
        }
    }

    function calcGroupEstimatedHours(groupName) {
        // loop through all elements in this group and sum the Estimated Hours
        var loopName = "td.estimated_hours." + groupName;
        var groupTotal = 0.0;
        $(loopName).each(function() {
            groupTotal += parseFloat($(this).children().val()) || 0;
        });
        //alert(groupTotal);

        // Update the Estimated Hours Total for this group
        var groupTotalId = groupName + "_total_estimated_hours";
        //alert(groupTotalId);
        var result = groupTotal.toFixed(2);
        $('td#' + groupTotalId).html(result);
    }

    // If user changes an estimated hours input,
    // update totals and group totals
    $('td.estimated_hours input').change(function() {
        calcCurrentGroupEstimatedHours($(this));
        calcTotalEstimatedHours();
    });

    // On hover, display the field's default (original) value
    function displayOriginalValue(element, originalValue) {
        var pos = element.position();
        var width = element.outerWidth();
        $('#field_original_value').html(originalValue);
        $('#field_original').css({
            position : "absolute",
            top : pos.top + "px",
            left : (pos.left + width) + "px"
        }).show();
    }

    function getCurrentValue(el){
       if ($(el).is(":checkbox")){
           var currentValue = $(el).is(":checked") ? "True" : "False";
       }else{
          var currentValue = $("option:selected", el).text() || el.value;
       }
       return currentValue;
    }
    
    

    function getDefaultValue(element) {
        if (element.is(":checkbox")){
           var originalValue = element.prop("defaultChecked") ? "True" : "False";
        }else{
           var originalValue = element.prop("defaultValue") || element.find('option[selected]').text();
        }
        return originalValue;
    }
    

    // handle changes from the datepicker	
    if(window.datepickerOptions) {
        window.datepickerOptions.onSelect = function() {
            var curValue = getCurrentValue(this);
            var defValue = getDefaultValue($(this));
            if (curValue != defValue) {
                $(this).css({"color" : "red"});
                $.data(this, 'edited', true);
            } else {
                $(this).css({"color" : "black"});
                $.data(this, 'edited', false);
            }
        }; 
    }

});
