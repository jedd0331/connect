/*
 * Copyright (c) Mirth Corporation. All rights reserved.
 * 
 * http://www.mirthcorp.com
 * 
 * The software in this package is published under the terms of the MPL license a copy of which has
 * been included with this distribution in the LICENSE.txt file.
 */

package com.mirth.connect.webadmin.action;

import com.mirth.connect.client.core.Client;
import com.mirth.connect.client.core.ClientException;
import com.mirth.connect.donkey.model.channel.MetaDataColumn;
import com.mirth.connect.donkey.model.message.ConnectorMessage;
import com.mirth.connect.donkey.model.message.Message;
import com.mirth.connect.donkey.model.message.MessageContent;
import com.mirth.connect.donkey.model.message.Status;
import com.mirth.connect.model.LoginStatus;
import com.mirth.connect.model.filters.MessageFilter;
import com.mirth.connect.webadmin.utils.Constants;
import net.sourceforge.stripes.action.DefaultHandler;
import net.sourceforge.stripes.action.ForwardResolution;
import net.sourceforge.stripes.action.Resolution;
import net.sourceforge.stripes.action.StreamingResolution;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

import javax.servlet.http.HttpServletRequest;
import java.net.URLDecoder;
import java.text.SimpleDateFormat;
import java.util.*;

public class SearchMessageActionBean extends BaseActionBean {
    private String channelId = "";
    private String channelName = "";
    private List<MetaDataColumn> metaDataColumns;

    @DefaultHandler
    public Resolution list() {
        Client client = getContext().getClient();

        if (client != null) {
            // Put message Status enums into scope for statistics map key retrieval 
            HttpServletRequest request = getContext().getRequest();
            for (Status status : Status.values()) {
                request.setAttribute(status.toString(), status);
            }
            channelId = getContext().getRequest().getParameter("channelId");
            try {
                metaDataColumns = client.getMetaDataColumns(channelId);
                channelName = client.getChannelIdsAndNames().get(channelId);

            } catch (ClientException e) {
                throw new RuntimeException(e);
            }
        }
        return new ForwardResolution(Constants.SEARCH_MESSAGE_JSP);
    }

    public Resolution getMessages() {
        JSONObject hashMap = new JSONObject();
        JSONArray jsonArray = new JSONArray();
        Client client = getContext().getClient();
        channelId = getContext().getRequest().getParameter("channelId");
        getContext().getResponse().setCharacterEncoding("UTF-8");
        String pLimit = getContext().getRequest().getParameter("limit");
        String pPageNum = getContext().getRequest().getParameter("pagenum");
        String srchBegin = getContext().getRequest().getParameter("srch_begin_dtm");
        String srchEnd = getContext().getRequest().getParameter("srch_end_dtm");
        String srchText = getContext().getRequest().getParameter("srch_text");
        String srchFilter = getContext().getRequest().getParameter("srch_filter");
        long messageCnt = 0;

        int limit = pLimit.isEmpty() ? 20 : Integer.parseInt(pLimit);
        int pagenum = pPageNum.isEmpty() ? 1 : Integer.parseInt(pPageNum);
        if (client != null) {
            try {
                MessageFilter msgFilter = new MessageFilter();
                if (!srchFilter.isEmpty()) {
                    Set<Status> filterKey = new HashSet<>();
                    String[] arrFilter = srchFilter.split(",");
                    for(int i = 0; i < arrFilter.length; i++) {
                        if (arrFilter[i].equals("received")) {
                            filterKey.add(Status.RECEIVED);
                        } else if (arrFilter[i].equals("transformed")) {
                            filterKey.add(Status.TRANSFORMED);
                        } else if (arrFilter[i].equals("filtered")) {
                            filterKey.add(Status.FILTERED);
                        } else if (arrFilter[i].equals("queued")) {
                            filterKey.add(Status.QUEUED);
                        } else if (arrFilter[i].equals("sent")) {
                            filterKey.add(Status.SENT);
                        } else if (arrFilter[i].equals("error")) {
                            filterKey.add(Status.ERROR);
                        }
                    }
                    msgFilter.setStatuses(filterKey);
                }
                if (!srchBegin.isEmpty()) {
                    Calendar calBegin = Calendar.getInstance();
                    int sy = Integer.parseInt(srchBegin.substring(0,4));
                    int sm = Integer.parseInt(srchBegin.substring(5,7)) - 1;
                    int sd = Integer.parseInt(srchBegin.substring(8, 10));
                    int sh = Integer.parseInt(srchBegin.substring(11, 13));
                    int smm = Integer.parseInt(srchBegin.substring(14, 16));
                    calBegin.set(sy, sm, sd, sh, smm);
                    msgFilter.setStartDate(calBegin);

                    if (srchEnd.isEmpty()) {
                        msgFilter.setEndDate(calBegin);
                    } else {
                        Calendar calEnd = Calendar.getInstance();
                        sy = Integer.parseInt(srchEnd.substring(0,4));
                        sm = Integer.parseInt(srchEnd.substring(5,7)) - 1;
                        sd = Integer.parseInt(srchEnd.substring(8, 10));
                        sh = Integer.parseInt(srchEnd.substring(11, 13));
                        smm = Integer.parseInt(srchEnd.substring(14, 16));
                        calEnd.set(sy, sm, sd, sh, smm);
                        msgFilter.setEndDate(calEnd);
                    }
                }
                if (!srchText.isEmpty()) {
                    msgFilter.setTextSearch(URLDecoder.decode(srchText));
                }

                SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
                messageCnt = client.getMessageCount(channelId, msgFilter);

                int offset = (pagenum - 1) * limit;
                List<Message> messageList = client.getMessages(channelId, msgFilter, false, offset, limit);

                for(int i = 0; i < messageList.size(); i++) {
                    Map<Integer, ConnectorMessage> msgObj = messageList.get(i).getConnectorMessages();
                    final int aa = 0;
                    msgObj.forEach((key, value) -> {
                        HashMap<String, String> hashTmp = new HashMap<>();
                        hashTmp.put("nodeid", String.valueOf(key));
                        hashTmp.put("id", String.valueOf(value.getMessageId()));
                        hashTmp.put("metadataid", String.valueOf(value.getMetaDataId()));
                        hashTmp.put("connector", value.getConnectorName());
                        hashTmp.put("status", value.getStatus().name());
                        hashTmp.put("receivedate", value.getReceivedDate() == null ? "--" : dateFormat.format(value.getReceivedDate().getTime()));
                        hashTmp.put("responsedate", value.getResponseDate() == null ? "--" : dateFormat.format(value.getResponseDate().getTime()));

                        int errCd = value.getErrorCode();
                        String errNm = "";
                        switch(errCd) {
                            case 0 :
                                errNm = "--";
                                break;
                            case 1 :
                                errNm = "Processing";
                                break;
                            case 2:
                                errNm = "PostProcessor";
                                break;
                            case 3:
                                errNm = "ResponseError";
                                break;
                            default:
                                break;
                        }

                        hashTmp.put("errors", errNm);
                        if (value.getMetaDataMap() != null) {
                            value.getMetaDataMap().forEach((key0, value0) -> {
                                String tmpValue0 = "--";
                                if (value0 != null) {
                                    tmpValue0 = value0.toString();
                                }
                                hashTmp.put(key0.toLowerCase(), tmpValue0);
                            });
                        }
                        jsonArray.add(hashTmp);
                    });
                }
            } catch (ClientException e) {
            }
        }

        hashMap.put("list", jsonArray);
        hashMap.put("totalCount", messageCnt);
        hashMap.put("pagenum", pagenum);

        return new StreamingResolution("application/json", hashMap.toString());
    }

    public Resolution getMessage() {
        JSONObject jsonObject = new JSONObject();
        Client client = getContext().getClient();
        channelId = getContext().getRequest().getParameter("channelId");
        String messageId = getContext().getRequest().getParameter("messageId");
        String metadataId = getContext().getRequest().getParameter("metadataId");
        getContext().getResponse().setCharacterEncoding("UTF-8");
        if (client != null) {
            try {
                ArrayList<Integer> metaDataIds = new ArrayList<>();
                metaDataIds.add(Integer.parseInt(metadataId));
                Message msg = client.getMessageContent(channelId, Long.parseLong(messageId), metaDataIds);
                HashMap<String, HashMap<String, String>> resHashMap = new HashMap<>();
                msg.getConnectorMessages().forEach((key0, value0) -> {
                    MessageContent msgRaw = value0.getRaw();
                    MessageContent msgProcessedRaw = value0.getProcessedRaw();
                    MessageContent msgTransformed = value0.getTransformed();
                    MessageContent msgEncoded = value0.getEncoded();
                    MessageContent msgSent = value0.getSent();
                    MessageContent msgResponse = value0.getResponse();
                    MessageContent msgResponseTransformed = value0.getResponseTransformed();
                    MessageContent msgProcessedResponse = value0.getProcessedResponse();

                    if (msgRaw != null) {
                        jsonObject.put(msgRaw.getContentType(), msgRaw.getContent());
                    }
                    if (msgTransformed != null) {
                        jsonObject.put(msgTransformed.getContentType(), msgTransformed.getContent());
                    }
                    if (msgEncoded != null) {
                        jsonObject.put(msgEncoded.getContentType(), msgEncoded.getContent());
                    }
                    if (msgSent != null) {
                        jsonObject.put(msgSent.getContentType(), msgSent.getContent());
                    }
                    if (msgResponse != null) {
                        jsonObject.put(msgResponse.getContentType(), msgResponse.getContent());
                    }
                    if (msgResponseTransformed != null) {
                        jsonObject.put(msgResponseTransformed.getContentType(), msgResponseTransformed.getContent());
                    }
                    if (msgProcessedResponse != null) {
                        jsonObject.put(msgProcessedResponse.getContentType(), msgProcessedResponse.getContent());
                    }
                    if (msgProcessedRaw != null) {
                        jsonObject.put(msgProcessedRaw.getContentType(), msgProcessedRaw.getContent());
                    }
                });
            } catch (ClientException e) {
                System.err.println(e.getMessage());
            }
        }
        return new StreamingResolution("application/json", jsonObject.toString());
    }

    // Getters & Setters
    public String getChannelId() { return channelId; }
    public String getChannelName() { return channelName; }
    public List<MetaDataColumn> getMetaDataColumns() { return metaDataColumns; }

}