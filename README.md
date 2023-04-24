# Process high volume of data with an apex batch class batch wise

Usually processing high volume of data takes long time. To improve accuray and speed of processing below steps need to remember.


1) Do not add scope wise list of records inside execute method instead create a global map and process scope wise batch of records and reuse this map in finish method.
2) Always avoid nested for-loops inside execute method of batch class.
3) Avoid lists inside maps and adding items to lists inside maps. Instead maintain a number to size the list inside maps.
4) Use wrapper classes to hold data.
5) Use finish method to send email and other final tasks.

Process batchwise data in execute() like this, we are filling all batchwise data in a global map called **retailerIdServiceMgrLoginMap**
```
global Map<Id,Integer> retailerIdServiceMgrLoginMap=new Map<Id,Integer>();
global void execute(Database.BatchableContext BC, List<LoginHistory> scope) {        
  Map<String,LoginHistory> userUniqueLoginPerDayMap=new Map<String,LoginHistory>();       
  for(LoginHistory loginObj:scope){  
      if(loginObj.userId!=null && loginObj.LoginTime!=null){                
          String loginhistory_key=loginObj.userId+'_'+loginObj.LoginTime.day()+'_'+loginObj.LoginTime.month()+'_'+loginObj.LoginTime.year();
          // process unique login history entries only
          if(!userUniqueLoginPerDayMap.containsKey(loginhistory_key)){
              userUniqueLoginPerDayMap.put(loginhistory_key,loginObj);   
              system.debug('loginhistory_key:'+loginhistory_key);
              String userId=loginObj.userId; 
              // user has a primary position active in multiple stores, we need to fill related stores maps, break not possible
              for(Id storeId:retailerIds){ 
                  //Service Manager Logins
                  if(retailerIdServiceMgrMap.containsKey(storeId) && retailerIdServiceMgrMap.get(storeId).contains(userId)){
                      if(!retailerIdServiceMgrLoginMap.containsKey(storeId)){
                          retailerIdServiceMgrLoginMap.put(storeId,0);
                      }
                      Integer ServiceMgrLogins=retailerIdServiceMgrLoginMap.get(storeId)+1;
                      retailerIdServiceMgrLoginMap.put(storeId,ServiceMgrLogins);                            
                  }
            }
       }
   }
}
```

# Send CSV file attachment as an email with apex class

```
Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
blob csvBlob = Blob.valueOf(finalstr);
Date today=system.today();
Integer MM=today.month();
Integer DD=today.day();
Integer YYYY=today.year();
String finishday=String.valueOf(MM)+String.valueOf(DD)+String.valueOf(YYYY);
string csvname= 'Weekly average logins per managing jobs_'+finishday+'.csv';
system.debug('csvname:'+csvname);
csvAttc.setFileName(csvname);
csvAttc.setBody(csvBlob);

Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
String[] toAddresses = new list<string>();
String recipients=system.Label.DPM_Recipients_MetricsWeeklyAvgLogins+',';        
for(String recEmail:recipients.split(',')){
    toAddresses.add(recEmail);
}
String subject ='Retailer Managers weekly average logins KPI';
email.setSubject(subject);
email.setOrgWideEmailAddressId(owea.Id);
email.setToAddresses( toAddresses );
Date fromdate=system.today()-35;
Date todate=system.today();
email.setPlainTextBody('Please find attached the KPI that shows the weekly average logins of retailer managers for the period of "'+fromdate.format()+' to '+todate.format()+'"'+
                       '\nKPI provided by your VCUSA Digital DPM Team.'+
                       '\n\nThanks'+
                       '\n\nVCUSA Digital DPM Team'+
                       '\nVOLVO'
                      );
email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
```

