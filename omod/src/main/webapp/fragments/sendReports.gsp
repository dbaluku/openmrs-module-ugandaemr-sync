<%
    def breadcrumbMiddle = breadcrumbOverride ?: '';
%>
<style type="text/css">
#blurred
{
    display : none;
}
#blurred.show
{
    display : block;
    position : fixed;
    z-index: 100;
    background-image : url('http://loadinggif.com/images/image-selection/3.gif');
    background-color:#666;
    opacity : 0.4;
    background-repeat : no-repeat;
    background-position : center;
    left : 0;
    bottom : 0;
    right : 0;
    top : 0;
}

#loader {
    position: absolute;
    top: 50%;
    left: 50%;
    margin: -50px 0px 0px -50px;
}
.grey {
    background-color:#c7c5c5 !important;
}

/* Tooltip container */
.tooltips {
    position: relative;
    display: inline-block;
}

/* Tooltip text */
.tooltips .tooltiptext {
    visibility: hidden;
    left: 0;
    top: 110%;
    width: 200px;
    background-color:#c7c5c5;
    color: #000000;
    text-align: center;
    padding: 5px 0;
    border-radius: 6px;
    text-wrap: none !important;
    position: absolute;
    z-index: 1
}

/* Show the tooltip text when you mouse over the tooltip container */
.tooltips:hover .tooltiptext {
    visibility: visible;
}
</style>
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;}
.tg td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
    overflow:hidden;padding:10px 5px;word-break:normal;}
.tg th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
    font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg .tg-wdya{background-color:#D9D9D9;color:#7030A0;text-align:center;vertical-align:middle}
.tg .tg-qnnl{background-color:#F8FFF9;text-align:center;vertical-align:top}
.tg .tg-8y2u{background-color:#F8FFF9;text-align:right;vertical-align:top}
.tg .tg-o4ah{background-color:#D9D9D9;text-align:center;vertical-align:middle}
.tg .tg-ogju{background-color:#E6F1FF;text-align:center;vertical-align:top}
.tg .tg-9j11{background-color:#D9D9D9;text-align:left;vertical-align:middle}
.tg .tg-0lax{text-align:left;vertical-align:top}
.tg .tg-zlip{background-color:#F8FFF9;text-align:left;vertical-align:top}
.tg .tg-wboj{background-color:#E6F1FF;text-align:right;vertical-align:top}
</style>
<script type="text/javascript">
    var breadcrumbs = [
        { icon: "icon-home", link: '/' + OPENMRS_CONTEXT_PATH + '/index.htm' },
        { label: "${ ui.message("coreapps.app.systemAdministration.label")}", link: '/' + OPENMRS_CONTEXT_PATH + '/coreapps/systemadministration/systemAdministration.page'},
        { label: "UgandaEMR Sync", link: '/' + OPENMRS_CONTEXT_PATH + '/ugandaemrsync/ugandaemrsync.page'},
        { label: "Send Reports"}
    ];

    var previewBody;
    var uuid;
    var merUuids;
    var hmisUuids;

    function clearDisplayReport(){
        jq("#display-report").empty();
        jq('#submit-button').empty();
    }

    function sendData(jsonData) {
        var url = "/ws/rest/v1/sendreport?uuid="+uuid;
        jq.ajax({
            contentType: "application/json",
            url:'/' + OPENMRS_CONTEXT_PATH + url,
            type: "POST",
            data: JSON.stringify(jsonData),
            dataType:'json',

            beforeSend : function()
            {
                jq("div#blurred").addClass('show');
                jq("#loader").show();
            },
            success: function (data) {
                var response = data;
                if (data.status === "success") {
                    jq().toastmessage('showSuccessToast', response.message);
                    clearDisplayReport();
                } else {
                    jq().toastmessage('showErrorToast', response.message);
                }
                jq("#loader").hide();
                jq("div#blurred").removeClass('show');
            }
        });
    }
    jq(document).ready(function () {
        previewBody = ${previewBody};
        uuid ="${reportuuid}";
        merUuids ="${mer_uuids}";
        hmisUuids ="${hmis_uuids}";
        jq("#loader").hide();
        jq("#loading").hide();
        jq("#submit-button").css('display', 'none');
        jq("#surge-report").css('display', 'none');
        var errorMessage = jq('#errorMessage').val();

        if(errorMessage!==""){
            jq().toastmessage('showNoticeToast', errorMessage);
        }

        jq('#sendData').click(function(){
            var finalData = previewBody.json;
            sendData(finalData);
        });

        jq('#run-button').click(function(){
            jq("#loading").show();
        });

        jq('#run-a-report').click(function(){
            jq("#loading").hide();
        });

       if(previewBody!=null && uuid!=null){
           jq("#display-report").append(previewBody.html);
           jq('#submit-button').show();
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
<div>
    <button id="run-a-report" type="button" style="font-size: 25px" class="confirm" data-toggle="modal"
            data-target="#run-report"  data-whatever="@mdo"> Run a report</button>
</div>
<div class="row">

    <div class="col-md-12">
        <div id="loader">
            <img src="/openmrs/ms/uiframework/resource/uicommons/images/spinner.gif">
            <h1 style="color: aqua">Sending...</h1>
        </div>
        <div id="display-report" style="overflow-y:scroll;">
            <div class='modal-header'><label style="text-align: center"><h1> ${report_title}</h1></label>
            </div></div>
            <div id="submit-button">
                <p></p><span id="sendData" class="button confirm right"> Submit </span>
            </div>
            <div id="blurred">
            </div>

    </div>
</div>

<div class="modal fade" id="run-report" tabindex="-1" role="dialog"
     aria-labelledby="addEditSyncTaskTypeModelLabel"
     aria-hidden="true">
    <div class="modal-dialog  modal-md" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="addEditSyncTaskTypeModelLabel">Run the Report</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div id="loading">
                <img src="/openmrs/ms/uiframework/resource/uicommons/images/spinner.gif">
                <span>Running...</span>
            </div>
            <div>
                <form method="post" id="sendReports">
                    <fieldset>
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
                            <button id="run-button" type="submit" class="confirm right" ng-class="{disabled: submitting}" ng-disabled="submitting">
                                <i class="icon-play"></i>
                                Run
                            </button>
                        </span>

                    </fieldset>
                    <input type="hidden" name="errorMessage" id="errorMessage" value="${errorMessage}">
                </form>
            </div>
        </div>
    </div>
</div>
