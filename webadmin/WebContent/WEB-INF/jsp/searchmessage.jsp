<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@include file="/WEB-INF/jsp/common/taglibs.jsp"%>

<s:layout-render name="/WEB-INF/jsp/common/layoutmain.jsp" title="Message">
    <s:layout-component name="head">
        <link href="${contextPath}/css/jquery.treeTable.css" rel="stylesheet" type="text/css" />
        <link href="${contextPath}/css/jquery.datetimepicker.min.css" rel="stylesheet" type="text/css" />

        <!-- Hack to fix CSS spacing conflict between tablesorter and bootstrap -->
        <style type="text/css">
            .header div {
            	float: left;
            }
        </style>
    </s:layout-component>

    <s:layout-component name="body">
        <div>${actionBean.channelName} ( ${actionBean.channelId} ) </div>
        <div>
            <table style="width: 98%;">
            <tr>
              <td style="width:200px;">Start Time <input type="text" id="srch_begin_dtm" style="width:120px;"/></td>
              <td style="width:200px;">End Time <input type="text" id="srch_end_dtm" style="width:120px;"/></td>
              <td style="width:230px;">Text Search <input type="text" id="srch_text" style="width:150px;"/></td>
              <td style="width:120px;"><button id="btn_Reset">Reset</button>
                  <button id="btn_Search">Search</button>
              </td>
              <td>Page Size
                <select id="srch_limit">
                    <option value="10">10</option>
                    <option value="20">20</option>
                    <option value="30">30</option>
                    <option value="40">40</option>
                </select>
              </td>
              <td>
                 <div style="float:left; width:130px;">Page <input type="text" id="txt_pagenum" size="4"/> of </div>
                 <div style="float:left; width:20px;">/</div>
                 <div style="float:left; width:40px;" id="div_totalpage"></div>
                 <button id="btn_move" style="float:left;">Go</button>
                 <div style="float:left; width:80px;">Total Count : </div>
                 <div id="div_totalcount" style="float:left; width:40px;"></div>
                 <button id="btn_prev" style="float:left;"> &lt;&lt; </button>
                 <button id="btn_next" style="float:left;"> &gt;&gt; </button>
              </td>
            </tr>
            <tr>
              <td colspan="6">
                  <input type="checkbox" name="srch_status" value="received"/>RECEIVED
                  <input type="checkbox" name="srch_status" value="transformed"/>TRANSFORMED
                  <input type="checkbox" name="srch_status" value="filtered"/>FILTERED
                  <input type="checkbox" name="srch_status" value="queued"/>QUEUED
                  <input type="checkbox" name="srch_status" value="sent"/>SENT
                  <input type="checkbox" name="srch_status" value="error"/>ERROR
              </td>
            </tr>
            </table>
        </div>
        <table class="table table-striped table-bordered table-condensed tablesorter" style="width: 98%;" id="treeTable">
            <thead>
                <tr>
                    <th>Id</th>
                    <th>Connector</th>
                    <th>Status</th>
                    <th>Received Date</th>
                    <th>Response Date</th>
                    <th>Errors</th>
                    <c:forEach items="${actionBean.metaDataColumns}" var="mc" varStatus="status">
                    <th>${mc.name}</th>
                    </c:forEach>
                </tr>
            </thead>
            <tbody>
            </tbody>
        </table>
        <br/>
        <div style="width:100%;height:30px;" id="rdo_message_section">
        </div>
        <div id="div_msg_normal" style="display:;width:100%; height:370px;">
            <textarea id="txt_message" style="width:100%; height:370px;"></textarea>
        </div>
        <div id="div_msg_ext" style="display:none;width:100%;height:370px;">
            <div style="height:25px;">Status:</div>
            <div style="height:70px;">
                <textarea id="txt_message_status" style="width:100%; height:100px;"></textarea>
            </div>
            <div style="height:25px;">Response:</div>
            <div style="height:250px;">
                <textarea id="txt_message_response" style="width:100%; height:220px;"></textarea>
            </div>
        </div>
    </s:layout-component>

    <s:layout-component name="scripts">
        <script type="text/javascript" src="${contextPath}/js/jquery.treeTable.js"></script>
        <script type="text/javascript" src="${contextPath}/js/persist-min.js"></script>
        <script type="text/javascript" src="${contextPath}/js/jquery.tablesorter.min.js"></script>
        <script type="text/javascript" src="${contextPath}/js/jquery.tablesorter.widgets.min.js"></script>
        <script type="text/javascript" src="${contextPath}/js/jquery.datetimepicker.full.min.js"></script>

        <script type="text/javascript">
            var msgDetl;
            function getMessages() {
                var limit = $("#srch_limit").val();
                var pagenum = $("#txt_pagenum").val();
                var srch_begin_dtm = $("#srch_begin_dtm").val();
                var srch_end_dtm = $("#srch_end_dtm").val();
                var srch_text = encodeURI($("#srch_text").val());
                var chkObjs = $("input[name='srch_status']");
                var srch_filter = "";

                for(var i = 0; i < chkObjs.length; i++) {
                    var chkObj = chkObjs[i];
                    if (chkObj.checked) {
                        srch_filter += chkObj.value+",";
                    }
                }
                $.get("SearchMessage.action?getMessages&channelId=${actionBean.channelId}&limit="+limit+"&pagenum="+pagenum+"&srch_begin_dtm="+srch_begin_dtm+"&srch_end_dtm="+srch_end_dtm+"&srch_text="+srch_text+"&srch_filter="+srch_filter, function(resNode) {
                    var nodeIdx = 0;
                    var parentNode = "";
                    var nodes = resNode.list;
                    $("#div_totalcount").text(resNode.totalCount);
                    $("#txt_pagenum").val(resNode.pagenum);
                    var tmp0 = (resNode.totalCount*1) % limit;
                    var tmp1 = Math.floor((resNode.totalCount*1) / limit);
                    if (tmp0 > 0) tmp1 += 1;

                    $("#div_totalpage").text(tmp1);
                    $("#treeTable > tbody").empty();
                    for (var i = 0; i < nodes.length; i++) {

                        var nodeInf = "";
                        var className = "";
                        var childClassName = "";
                        if (nodes[i].nodeid == "0") {
                            nodeInf = "node-"+nodeIdx;
                            className = "parent";
                            parentNode = nodeInf;
                            nodeIdx++;
                        } else {
                            var tmp = nodes[i].connector.split(" ").join("_");
                            nodeInf = tmp+"-"+nodeIdx;
                            className = "child";
                            childClassName = "class=\"child-of-"+parentNode+" expand-child\"";
                        }

                        var trTag = "<tr id='"+nodeInf+"' "+childClassName+">";
                        trTag += "<td class='"+className+"'>"+nodes[i].id+"</td>";
                        trTag += "<td><a href='javascript:getMessage("+nodes[i].id+", "+nodes[i].metadataid+");'>"+nodes[i].connector+"</a></td>";
                        trTag += "<td>"+nodes[i].status+"</td>";
                        trTag += "<td>"+nodes[i].receivedate+"</td>";
                        trTag += "<td>"+nodes[i].responsedate+"</td>";
                        trTag += "<td>"+nodes[i].errors+"</td>";
                    <c:forEach items="${actionBean.metaDataColumns}" var="mc" varStatus="status">
                        trTag += "<td>"+(nodes[i].${mc.mappingName} == undefined ? "--" : nodes[i].${mc.mappingName})+"</td>";
                    </c:forEach>
                        trTag += "</tr>";

                        $("#treeTable > tbody").append(trTag);
                    }
                    msgDetl = {};
                    $("#treeTable").treeTable({
                        initialState : "collapsed",
                        clickableNodeNames : true,
                        persist : true
                    // Persist node expanded/collapsed state
                    });
                    $("#treeTable").tablesorter({
                        // Persist sorting state
                        widgets : [ "saveSort" ],

                        // Override tablesorter CSS to use bootstrap styling
                        cssHeader : "header",
                        cssAsc : "headerSortDown",
                        cssDesc : "headerSortUp"
                    });
                }, "json");
            }

            var rdoList = [
                  {"key":"Raw", "name":"Raw"}
                , {"key":"ProcessedRaw", "name":"ProcessedRaw"}
                , {"key":"Transformed", "name":"Transformed"}
                , {"key":"Encoded", "name":"Encoded"}
                , {"key":"Sent", "name":"Sent"}
                , {"key":"Response", "name":"Response"}
                , {"key":"Response Transformed", "name":"Response Transformed"}
                , {"key":"Processed Response", "name":"Processed Response"}
            ];

            function getMessage(messageId, metadataId) {
                $("#rdo_message_section").html("");
                $("#txt_message").val("");
                msgDetl = {};
                $.get("SearchMessage.action?getMessage&channelId=${actionBean.channelId}&messageId="+messageId+"&metadataId="+metadataId, function(nodeItem) {
                    msgDetl = nodeItem;
                    for(var i = 0; i < rdoList.length; i++) {
                        if (nodeItem[rdoList[i].key] != undefined) {
                            var checked = "";
                            if (i == 0) {
                                checked = "checked";
                                changeMessage(rdoList[i].key);
                            }
                            var inputTag = "<input type='radio' name='messagetype' onclick='changeMessage(this.value)' value='"+rdoList[i].key+"' "+checked+" style='width:30px;'>"+rdoList[i].name+"&nbsp;&nbsp;&nbsp;";
                            $("#rdo_message_section").append(inputTag);
                        }
                    }

                }, "json");
            }

            function changeMessage(stat) {
                var txtMsg = msgDetl[stat];
                if (stat != "Response" && stat != "Processed Response") {
                    $("#div_msg_normal").css("display", "");
                    $("#div_msg_ext").css("display", "none");
                    $("#txt_message").val("");
                    if (txtMsg != undefined) {
                        if (stat == "Sent") {
                            var parser = new DOMParser();
                            var xmlDoc = parser.parseFromString(txtMsg, "text/xml");
                            var contType = xmlDoc.getRootNode().childNodes[0].nodeName;

                            var writeMsg = "";
                            if (contType.indexOf("JavaScriptDispatcherProperties") > -1) {
                                writeMsg = "Script Executed";
                            } else if (contType.indexOf("WebServiceDispatcherProperties") > -1) {
                                var strWsdlUrl = getNodeValue(xmlDoc, "wsdlUrl");
                                var strService = getNodeValue(xmlDoc, "service");
                                var strPort    = getNodeValue(xmlDoc, "port");
                                var strLocationURI = getNodeValue(xmlDoc, "locationURI");
                                var strSoapAction = getNodeValue(xmlDoc, "soapAction");
                                var strEnvelope = getNodeValue(xmlDoc, "envelope");

                                writeMsg += "WSDL URL: "+strWsdlUrl+"\r\n";
                                writeMsg += "SERVICE: "+strService+"\r\n";
                                writeMsg += "PORT / ENDPOINT: "+strPort+"\r\n";
                                writeMsg += "LOCATION URI: "+strLocationURI+"\r\n";
                                writeMsg += "SOAP ACTION: "+strSoapAction+"\r\n";
                                writeMsg += "\r\n";
                                writeMsg += "[ATTACHMENTS]\r\n";
                                writeMsg += "\r\n";
                                writeMsg += "\r\n";
                                writeMsg += "[CONTENT]\r\n";
                                writeMsg += strEnvelope;
                            } else if (contType.indexOf("HttpDispatcherProperties") > -1) {
                                var strHost = getNodeValue(xmlDoc, "host");
                                var strMethod = getNodeValue(xmlDoc, "method");
                                var strContent = getNodeValue(xmlDoc, "content");
                                strContent = strContent.split("&#xd;").join("\r\n");
                                var headerChildNodes = xmlDoc.getElementsByTagName("headers")[0].childNodes;
                                var strHeaders = "";
                                for (var i = 0; i < headerChildNodes.length; i++) {
                                    if (headerChildNodes[i].nodeType == 1) {
                                        for(var j = 0; j < headerChildNodes[i].childNodes.length; j++) {
                                            var tmpChild = headerChildNodes[i].childNodes[j];
                                            if (tmpChild.nodeType == 1) {
                                                if (tmpChild.nodeName == "string") {
                                                   strHeaders += tmpChild.childNodes[0].nodeValue+": ";
                                                } else if (tmpChild.nodeName == "list") {
                                                   strHeaders += tmpChild.childNodes[1].childNodes[0].nodeValue+"\r\n";
                                                }
                                            }
                                        }
                                    }
                                }

                                var prameterChildNodes = xmlDoc.getElementsByTagName("parameters")[0].childNodes;
                                var strParameters = "";
                                for (var i = 0; i < prameterChildNodes.length; i++) {
                                    if (prameterChildNodes[i].nodeType == 1) {
                                        for(var j = 0; j < prameterChildNodes[i].childNodes.length; j++) {
                                            var tmpChild = prameterChildNodes[i].childNodes[j];
                                            if (tmpChild.nodeType == 1) {
                                                if (tmpChild.nodeName == "string") {
                                                   strParameters += tmpChild.childNodes[0].nodeValue+": ";
                                                } else if (tmpChild.nodeName == "list") {
                                                   strParameters += tmpChild.childNodes[1].childNodes[0].nodeValue+"\r\n";
                                                }
                                            }
                                        }
                                    }
                                }

                                writeMsg += "URL: "+strHost+"\r\n";
                                writeMsg += "METHOD: "+strMethod+"\r\n";
                                writeMsg += "\r\n";
                                writeMsg += "[HEADERS]\r\n";
                                writeMsg += strHeaders+"\r\n";
                                writeMsg += "\r\n";
                                writeMsg += "[PARAMETERS]\r\n";
                                writeMsg += strParameters+"\r\n";
                                writeMsg += "\r\n";
                                writeMsg += "[CONTENT]\r\n";
                                writeMsg += strContent+"\r\n";

                            }
                            $("#txt_message").val(writeMsg);
                        } else {
                            $("#txt_message").val(txtMsg);
                        }
                    }
                } else {
                    $("#div_msg_normal").css("display", "none");
                    $("#div_msg_ext").css("display", "");

                    if (stat == "Response" || stat == "Processed Response") {
                        var parser = new DOMParser();
                        var xmlDoc = parser.parseFromString(txtMsg, "text/html");
                        var strStatus = xmlDoc.getElementsByTagName("status")[0].innerText;
                        var strMessage = xmlDoc.getElementsByTagName("message")[0].innerText;

                        var strStatusMessage = null;
                        if (xmlDoc.getElementsByTagName("statusMessage")[0] != undefined) {
                            strStatusMessage = xmlDoc.getElementsByTagName("statusMessage")[0].innerText;
                        }

                        var strStatusComplete = strStatus;
                        if (strStatusMessage != null) {
                            strStatusComplete += " : "+strStatusMessage;
                        }

                        $("#txt_message_status").val(strStatusComplete);
                        $("#txt_message_response").val(strMessage);

                    }
                }
            }

            function getNodeValue(xmlDoc, nodeName) {
                var returnVal = "";
                try {
                    returnVal = xmlDoc.getElementsByTagName(nodeName)[0].childNodes[0].textContent;
                } catch(e) {
                }
                return returnVal;
            }
        </script>
        <!-- Hack to fix CSS extra arrow conflict between tablesorter and bootstrap -->
        <script type="text/javascript">
            $(document).ready(function() {
                $("#srch_begin_dtm").datetimepicker({ formatDate:'Y.d.m H:i', lang:'ko' });
                $("#srch_end_dtm").datetimepicker({ formatDate:"Y.d.m H:i", lang:"ko" });
                $("#btn_Reset").button().on("click", function(evt, ui) {
                    $("#srch_begin_dtm").val("");
                    $("#srch_end_dtm").val("");
                    $("#txt_pagenum").val("1");
                    var chkObjs = $("input[name='srch_status']");

                    for(var i = 0; i < chkObjs.length; i++) {
                        chkObjs[i].checked = false;
                    }
                    $("#rdo_message_section").html("");
                    $("#txt_message").val("");
                    $("#txt_message_status").val("");
                    $("#txt_message_response").val("");
                    getMessages();
                });
                $("#btn_Search").button().on("click", function(evt, ui) { getMessages(); });
                $("#btn_move").button().on("click", function(evt, ui) {
                    var currentpage = $("#txt_pagenum").val();
                    var lastpage = $("#div_totalpage").text();

                    if ( isNaN(currentpage) || (currentpage * 1) < 1
                      || isNaN(lastpage)  || (lastpage * 1) < currentpage) {
                        alert("이동할 수 없는 페이지 번호입니다.");
                    } else {
                        getMessages();
                    }
                });
                $("#btn_prev").button().on("click", function(evt, ui) {
                    var currentpage = $("#txt_pagenum").val();
                    if ( isNaN(currentpage) || (currentpage * 1) == 1) {
                        alert("페이지를 이동할 수 없습니다.");
                    } else {
                        $("#txt_pagenum").val((currentpage * 1) - 1);
                        getMessages();
                    }
                });
                $("#btn_next").button().on("click", function(evt, ui) {
                    var currentpage = $("#txt_pagenum").val();
                    var lastpage = $("#div_totalpage").text();
                    if ( isNaN(currentpage) || (currentpage * 1) == (lastpage * 1)) {
                        alert("페이지를 이동할 수 없습니다.");
                    } else {
                        $("#txt_pagenum").val((currentpage * 1) + 1);
                        getMessages();
                    }
                });
                $("#srch_limit").change(function() {
                    getMessages();
                });
                getMessages();
                $("#body table thead tr").removeAttr("class");
            });
        </script>
    </s:layout-component>
</s:layout-render>