<%
    def breadcrumbMiddle = breadcrumbOverride ?: '';
%>
<script type="text/javascript">
    var breadcrumbs = [
        { icon: "icon-home", link: '/' + OPENMRS_CONTEXT_PATH + '/index.htm' },
        { label: "${ ui.message("coreapps.app.systemAdministration.label")}", link: '/' + OPENMRS_CONTEXT_PATH + '/coreapps/systemadministration/systemAdministration.page'},
        { label: "UgandaEMR Sync", link: '/' + OPENMRS_CONTEXT_PATH + '/ugandaemrsync/ugandaemrsync.page'},
        { label: "Send Reports"}
    ];

    var previewBody;
    var uuid;

    function clearDisplayReport(){
        jq("#display-report").empty();
        jq('#submit-button').empty();
    }
    function displayReport(report){
        var reportDataString="";
        var tableHeader = "<table><thead><tr><th>Indicator</th><th>Data Element</th><th>Value</th></thead><tbody>";
        var tableFooter = "</tbody></table>";

        jq.each(report.group, function (index, rowValue) {
            var indicatorCode="";
            var total_Display_Name="";
            var dataValueToDisplay = "";
            dataValueToDisplay += "<tr>";

                indicatorCode = rowValue.code.coding[0].code;
                total_Display_Name = rowValue.stratifier[0].code[0].coding[0].display;
                var total_Display_Value = rowValue.measureScore.value;
                var disaggregated_rows = rowValue.stratifier[0].stratum;

            var rowspanAttribute="rowspan= \""+disaggregated_rows.length+"\"";

            jq.each(disaggregated_rows,function(key,obj){
                var row_displayValue = obj.measureScore.value;
                var row_displayName="";
                if(typeof obj.value !== "undefined"){
                    row_displayName = obj.value.coding[0].display;

                }else{
                    var componentObject = obj.component;
                    if(componentObject.length>0){
                        for(var j=0; j < componentObject.length;j++){
                            var displayName =  componentObject[j].code.coding[0].code +"<span>:</span> "+ componentObject[j].value.coding[0].display + "<br/>" ;
                            row_displayName = row_displayName + displayName
                        }
                    }
                }
                dataValueToDisplay += "<tr>";
                if(key==0){
                    dataValueToDisplay += "<th " + rowspanAttribute+ " width='20%'>"+ indicatorCode + "<br/>" +total_Display_Name +"</th>";
                }
                dataValueToDisplay += "<td>" +row_displayName +"</td>";
                dataValueToDisplay += "<td>" +row_displayValue + "</td>";
                dataValueToDisplay += "</tr>";
            });

            reportDataString += dataValueToDisplay;
        });

        jq("#display-report").append(tableHeader + reportDataString + tableFooter);
        jq('#submit-button').show();


    }

    function sendPayLoadInPortionsWithIndicators(dataObject,chunkSize){
        var objectsToSend =[];
        var groupArrayLength = dataObject.group.length;

        if(groupArrayLength % chunkSize===0){
            dataObject = stripDisplayAttributes(dataObject);
            var myArray = dataObject.group;

            var setNumber = groupArrayLength/chunkSize;
            for (var i=0,len=myArray.length; i<len; i+=chunkSize){
                var slicedArray = myArray.slice(i,i+chunkSize);
                delete dataObject.group;
                var reportObject =Object.assign({},dataObject);
                reportObject.group =  myArray.slice(i,i+chunkSize);
                objectsToSend.push(reportObject);
            }
        }
        return objectsToSend;
    }

    function stripDisplayAttributes(dataObject){
        var arrayLength = dataObject.group.length;
        if(arrayLength > 0){
            var myArray = dataObject.group;

            for (var i=0; i < myArray.length; i++) {
                var myObject = myArray[i];
                var attr1 = myObject.code.coding;
                attr1 = attr1.map(u=>({"code":u.code}));
                myArray[i].code.coding=attr1;

                var attr2 = myObject.stratifier[0];
                var attr2Child =attr2.code
                if(attr2Child.length>0){
                    for(var x=0; x < attr2Child.length;x++){
                        var myObject = attr2Child[x];
                        var child = myObject.coding;
                        child = child.map(u =>({"code":u.code}));
                        attr2Child[x].coding = child;
                    }
                }
                myArray[i].stratifier[0].code=attr2Child;


                var attr2Child1 =attr2.stratum;
                if(attr2Child1.length>0){
                    for(var k=0; k < attr2Child1.length;k++){
                        var myObject = attr2Child1[k];
                        if(typeof myObject.value == "undefined"){
                            var componentObject = myObject.component
                            if(componentObject.length>0){
                                for(var j=0; j < componentObject.length;j++){
                                    var child = componentObject[j].value.coding;
                                    child = child.map(u =>({"code":u.code}));
                                    attr2Child1[k].component[j].value.coding = child;
                                }

                            }


                        }else{
                            var child = myObject.value.coding;
                            child = child.map(u =>({"code":u.code}));
                            attr2Child1[k].value.coding = child;
                        }

                    }
                }
                myArray[i].stratifier[0].stratum=attr2Child1;

            }
            dataObject.group = []
            dataObject.group= myArray;
        }
        return dataObject;

    }

    function post(url, dataObject) {
        jq("#loader").show();
        return jq.ajax({
            method: 'POST',
            url: url,
            data: jQuery.param(dataObject),
            headers: {'Content-Type': 'application/json; charset=utf-8'}
        });
    }

    function sendData(jsonData,urlEndPoint) {

        jq.ajax({
            url:'${ui.actionLink("ugandaemrsync","sendReports","sendData")}',
            type: "POST",
            data: {body:jsonData,
                    uuid:urlEndPoint},
            dataType:'json',

            beforeSend : function()
            {
                jq("#loader").show();
            },
            success: function (data) {
                var response = data;
                console.log(response);
                if (data.status === "success") {
                    jq().toastmessage('showSuccessToast', response.message);
                    clearDisplayReport();
                } else {
                    jq().toastmessage('showErrorToast', response.message);
                }
                jq("#loader").hide();
            }
        });
    }
    jq(document).ready(function () {
        previewBody =${previewBody};
        uuid ="${reportuuid}";

        jq("#loader").hide();
        jq("#submit-button").css('display', 'none');
        var errorMessage = jq('#errorMessage').val();

        if(errorMessage!==""){
            jq().toastmessage('showNoticeToast', errorMessage);
        }

        jq('#sendData').click(function(){
            previewBody = stripDisplayAttributes(previewBody);
            var data = sendPayLoadInPortionsWithIndicators(previewBody,3);
            // data = JSON.stringify(previewBody,null,0);
             data = JSON.stringify(data);
            sendData(data,uuid);
        });

       if(previewBody!=null){
           displayReport(previewBody);
       }
    });
</script>


<div>
    <label style="text-align: center"><h1>Send EMR Reports to DHIS2 </h1></label>

</div>

<%
    def renderingOptions = reportDefinitions
            .collect {
                [ value: it.uuid, label: ui.message(it.name) ]
            }
%>
<div class="row">
    <div class="col-md-4">
        <form method="post" id="sendReports">
            <fieldset>
                <legend> Run the Report</legend>
                ${ui.includeFragment("uicommons","field/dropDown",[
                        formFieldName: "reportDefinition",
                        label: "Report",
                        hideEmptyLabel: false,
                        options: renderingOptions

                ])}

                ${ ui.includeFragment("uicommons", "field/datetimepicker", [
                        formFieldName: "startDate",
                        label: "StartDate",
                        useTime: false,
                        defaultDate: ""
                ])}
                ${ ui.includeFragment("uicommons", "field/datetimepicker", [
                        formFieldName: "endDate",
                        label: "EndDate",
                        useTime: false,
                        defaultDate: ""
                ])}

                <p></p>
                <span>
                    <button type="submit" class="confirm right" ng-class="{disabled: submitting}" ng-disabled="submitting">
                        <i class="icon-play"></i>
                        Run
                    </button>
                </span>

            </fieldset>
            <input type="hidden" name="errorMessage" id="errorMessage" value="${errorMessage}">
        </form>
    </div>
    <div class="col-md-8">
        <div id="loader">
            <img src="/openmrs/ms/uiframework/resource/uicommons/images/spinner.gif">
        </div>
        <div id="display-report" style="height:500px;overflow-y:scroll;">
            <div class='modal-header'> <label style="text-align: center"><h1> ${report_title}</h1></label></div>
        </div>
        <div id="submit-button">
            <p></p><span id="sendData"  class="button confirm right"> Submit </span>
        </div>
    </div>

</div>


