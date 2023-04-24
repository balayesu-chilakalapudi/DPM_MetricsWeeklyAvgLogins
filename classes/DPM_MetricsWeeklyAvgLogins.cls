global class DPM_MetricsWeeklyAvgLogins implements Database.Batchable<sObject>,Database.Stateful,schedulable {
    
    global List<AccountWrapper> accountList=new List<AccountWrapper>();
    
    global Map<Id,Set<Id>> retailerIdOfficeMgrMap=new Map<Id,Set<Id>>();
    global Map<Id,Set<Id>> retailerIdOfficeMgrMapPRs=new Map<Id,Set<Id>>(); // person roles map
    
    global Map<Id,Integer> retailerIdOfficeMgrLoginMap=new Map<Id,Integer>();
    
    global Map<Id,Set<Id>> retailerIdServiceMgrMap=new Map<Id,Set<Id>>();
    global Map<Id,Set<Id>> retailerIdServiceMgrMapPRs=new Map<Id,Set<Id>>();
    
    global Map<Id,Integer> retailerIdServiceMgrLoginMap=new Map<Id,Integer>();
    
    global Map<Id,Set<Id>> retailerIdPartsMgrMap=new Map<Id,Set<Id>>();
    global Map<Id,Set<Id>> retailerIdPartsMgrMapPRs=new Map<Id,Set<Id>>();
    
    global Map<Id,Integer> retailerIdPartsMgrLoginMap=new Map<Id,Integer>();
    
    global Map<Id,Set<Id>> retailerIdNVSMgrMap=new Map<Id,Set<Id>>();
    global Map<Id,Set<Id>> retailerIdNVSMgrMapPRs=new Map<Id,Set<Id>>();
    
    global Map<Id,Integer> retailerIdNVSMgrLoginMap=new Map<Id,Integer>();
    
    global Map<Id,Set<Id>> retailerIdPOWMgrMap=new Map<Id,Set<Id>>();
    global Map<Id,Set<Id>> retailerIdPOWMgrMapPRs=new Map<Id,Set<Id>>();
    
    global Map<Id,Integer> retailerIdPOWMgrLoginMap=new Map<Id,Integer>();
    
    global Map<Id,Set<Id>> retailerIdFinanceMgrMap=new Map<Id,Set<Id>>();
    global Map<Id,Set<Id>> retailerIdFinanceMgrMapPRs=new Map<Id,Set<Id>>();
    
    global Map<Id,Integer> retailerIdFinanceMgrLoginMap=new Map<Id,Integer>();
    
    global Map<Id,Set<Id>> retailerIdGeneralMgrMap=new Map<Id,Set<Id>>();
    global Map<Id,Set<Id>> retailerIdGeneralMgrMapPRs=new Map<Id,Set<Id>>();
    
    global Map<Id,Integer> retailerIdGeneralMgrLoginMap=new Map<Id,Integer>();
    
    global Set<Id> retailerIds=new Set<Id>();
    
    global void execute(SchedulableContext sc){
        DPM_MetricsWeeklyAvgLogins batch=new DPM_MetricsWeeklyAvgLogins();        
        Id batchprocessid=Database.executeBatch(batch);         
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String retailer_recordtypeName='Retailer';
        Set<String> jobPositions=new Set<String>{'Office Manager','Finance Manager','Pre-owned Manager','New Vehicle Sales manager','Parts Manager','Service Manager','General Manager'};
            Set<String> countries=new Set<String>{'USA','CAN'};
                Set<Id> userIds=new Set<Id>();
        String personrole_query = 'select RE_Account__c,RE_Account__r.DPM_Global_Retailer_Code__c,RE_Account__r.Name,'+
            ' id,RE_User__c,RE_Employee_Position__c'+
            ' from RE_Person_Role__c'+
            ' WHERE RE_Position_Active__c=true'+
            ' AND RE_Employee_Position__c IN:jobPositions'+         
            ' AND RE_Pos_NonActive_Date__c=NULL'+
            ' AND RE_Psn_NonActive_Date__c=NULL'+            
            ' AND RE_Account__c!=NULL'+
            ' AND RE_Account__r.country__r.Name IN:countries'+
            ' AND RE_Account__r.Org_non_activated__c=null'+
            ' AND RE_Account__r.RecordType.Name=:retailer_recordtypeName'+
            ' AND RE_Account__r.DPM_Global_Retailer_Code__c!=NULL';       
        System.debug('personrole_query: '+personrole_query);
        List<RE_Person_Role__c> personRoles;
        try{
            personRoles=(List<RE_Person_Role__c>)Database.query(personrole_query);
        }catch(Exception ex){
            personRoles=new List<RE_Person_Role__c>();
            system.debug(ex);
        }
        
        Set<Id> dupIdfilter=new Set<Id>();
        for(RE_Person_Role__c personRole:personRoles){
            if(!dupIdfilter.contains(personRole.RE_Account__c)){                    
                accountList.add(new AccountWrapper(personRole.RE_Account__c,
                                                   personRole.RE_Account__r.DPM_Global_Retailer_Code__c,
                                                   personRole.RE_Account__r.Name));
                dupIdfilter.add(personRole.RE_Account__c);
            }
            retailerIds.add(personRole.RE_Account__c);          
            //collect all person role users to fetch login history of them
            if(personRole.RE_User__c!=null){
                userIds.add(personRole.RE_User__c);
            }                
            //Service Manager
            if(personRole.RE_Employee_Position__c.equals('Service Manager')){
                if(!retailerIdServiceMgrMap.containsKey(personRole.RE_Account__c)){
                    retailerIdServiceMgrMap.put(personRole.RE_Account__c,new Set<Id>());
                }
                if(personRole.RE_User__c!=null){
                	retailerIdServiceMgrMap.get(personRole.RE_Account__c).add(personRole.RE_User__c);
                }                
                if(!retailerIdServiceMgrMapPRs.containsKey(personRole.RE_Account__c)){
                    retailerIdServiceMgrMapPRs.put(personRole.RE_Account__c,new Set<Id>());
                }
                retailerIdServiceMgrMapPRs.get(personRole.RE_Account__c).add(personRole.Id);                
            }
            //Parts Manager
            if(personRole.RE_Employee_Position__c.equals('Parts Manager')){
                if(!retailerIdPartsMgrMap.containsKey(personRole.RE_Account__c)){
                    retailerIdPartsMgrMap.put(personRole.RE_Account__c,new Set<Id>());
                }
                if(personRole.RE_User__c!=null){
                	retailerIdPartsMgrMap.get(personRole.RE_Account__c).add(personRole.RE_User__c);
                }
                if(!retailerIdPartsMgrMapPRs.containsKey(personRole.RE_Account__c)){
                    retailerIdPartsMgrMapPRs.put(personRole.RE_Account__c,new Set<Id>());
                }
                retailerIdPartsMgrMapPRs.get(personRole.RE_Account__c).add(personRole.Id);
            }
            //Office Manager
            if(personRole.RE_Employee_Position__c.equals('Office Manager')){
                if(!retailerIdOfficeMgrMap.containsKey(personRole.RE_Account__c)){
                    retailerIdOfficeMgrMap.put(personRole.RE_Account__c,new Set<Id>());
                }
                if(personRole.RE_User__c!=null){
                retailerIdOfficeMgrMap.get(personRole.RE_Account__c).add(personRole.RE_User__c);
                }                
                if(!retailerIdOfficeMgrMapPRs.containsKey(personRole.RE_Account__c)){
                    retailerIdOfficeMgrMapPRs.put(personRole.RE_Account__c,new Set<Id>());
                }
                retailerIdOfficeMgrMapPRs.get(personRole.RE_Account__c).add(personRole.Id);                
            }
            //New Vehicle Sales manager
            if(personRole.RE_Employee_Position__c.equals('New Vehicle Sales manager')){
                if(!retailerIdNVSMgrMap.containsKey(personRole.RE_Account__c)){
                    retailerIdNVSMgrMap.put(personRole.RE_Account__c,new Set<Id>());
                }
                if(personRole.RE_User__c!=null){
                retailerIdNVSMgrMap.get(personRole.RE_Account__c).add(personRole.RE_User__c);
                }
                if(!retailerIdNVSMgrMapPRs.containsKey(personRole.RE_Account__c)){
                    retailerIdNVSMgrMapPRs.put(personRole.RE_Account__c,new Set<Id>());
                }
                retailerIdNVSMgrMapPRs.get(personRole.RE_Account__c).add(personRole.Id);                
            }
            //Pre-owned Manager
            if(personRole.RE_Employee_Position__c.equals('Pre-owned Manager')){
                if(!retailerIdPOWMgrMap.containsKey(personRole.RE_Account__c)){
                    retailerIdPOWMgrMap.put(personRole.RE_Account__c,new Set<Id>());
                }
                if(personRole.RE_User__c!=null){
                retailerIdPOWMgrMap.get(personRole.RE_Account__c).add(personRole.RE_User__c);
                }
                if(!retailerIdPOWMgrMapPRs.containsKey(personRole.RE_Account__c)){
                    retailerIdPOWMgrMapPRs.put(personRole.RE_Account__c,new Set<Id>());
                }
                retailerIdPOWMgrMapPRs.get(personRole.RE_Account__c).add(personRole.Id);                
            }
            //Finance Manager
            if(personRole.RE_Employee_Position__c.equals('Finance Manager')){
                if(!retailerIdFinanceMgrMap.containsKey(personRole.RE_Account__c)){
                    retailerIdFinanceMgrMap.put(personRole.RE_Account__c,new Set<Id>());
                }
                if(personRole.RE_User__c!=null){
                retailerIdFinanceMgrMap.get(personRole.RE_Account__c).add(personRole.RE_User__c);
                }
                if(!retailerIdFinanceMgrMapPRs.containsKey(personRole.RE_Account__c)){
                    retailerIdFinanceMgrMapPRs.put(personRole.RE_Account__c,new Set<Id>());
                }
                retailerIdFinanceMgrMapPRs.get(personRole.RE_Account__c).add(personRole.Id);
            }
            //General Manager
            if(personRole.RE_Employee_Position__c.equals('General Manager')){
                if(!retailerIdGeneralMgrMap.containsKey(personRole.RE_Account__c)){
                    retailerIdGeneralMgrMap.put(personRole.RE_Account__c,new Set<Id>());
                }
                if(personRole.RE_User__c!=null){
                retailerIdGeneralMgrMap.get(personRole.RE_Account__c).add(personRole.RE_User__c);
                }
                if(!retailerIdGeneralMgrMapPRs.containsKey(personRole.RE_Account__c)){
                    retailerIdGeneralMgrMapPRs.put(personRole.RE_Account__c,new Set<Id>());
                }
                retailerIdGeneralMgrMapPRs.get(personRole.RE_Account__c).add(personRole.Id);
            }
        }           
        //}
        
        String loginhistory_soql='';       
        
        system.debug('userIds:'+userIds);
        loginhistory_soql='SELECT Id, UserId, SourceIp, LoginUrl, Browser, Status, Application, LoginTime, LoginType, Platform, ApiType'+ 
            ' FROM LoginHistory'+            
            ' WHERE userId IN:userIds'+
            ' AND userId!=NULL'+
            ' AND LoginTime!=NULL'+
            ' AND LoginTime=LAST_N_DAYS:35 order by userId,loginTime';
        System.debug('loginhistory_soql:'+loginhistory_soql);
        
        return Database.getQueryLocator(loginhistory_soql);
        
    }
    global void execute(Database.BatchableContext BC, List<LoginHistory> scope) {
        // fill login history map
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
                        //Parts Manager Logins
                        else if(retailerIdPartsMgrMap.containsKey(storeId) && retailerIdPartsMgrMap.get(storeId).contains(userId)){
                            if(!retailerIdPartsMgrLoginMap.containsKey(storeId)){
                                retailerIdPartsMgrLoginMap.put(storeId,0);
                            }
                            Integer PartsMgrLogins=retailerIdPartsMgrLoginMap.get(storeId)+1;
                            retailerIdPartsMgrLoginMap.put(storeId,PartsMgrLogins);                         
                        }
                        //Office Manager Logins                
                        else if(retailerIdOfficeMgrMap.containsKey(storeId) && retailerIdOfficeMgrMap.get(storeId).contains(userId)){
                            if(!retailerIdOfficeMgrLoginMap.containsKey(storeId)){
                                retailerIdOfficeMgrLoginMap.put(storeId,0);
                            }
                            Integer OfficeMgrLogins=retailerIdOfficeMgrLoginMap.get(storeId)+1;
                            retailerIdOfficeMgrLoginMap.put(storeId,OfficeMgrLogins);
                        }
                        //New Vehicle Sales manager
                        else if(retailerIdNVSMgrMap.containsKey(storeId) && retailerIdNVSMgrMap.get(storeId).contains(userId)){
                            if(!retailerIdNVSMgrLoginMap.containsKey(storeId)){
                                retailerIdNVSMgrLoginMap.put(storeId,0);
                            }
                            Integer NVSMgrLogins=retailerIdNVSMgrLoginMap.get(storeId)+1;
                            retailerIdNVSMgrLoginMap.put(storeId,NVSMgrLogins);
                        }
                        //Pre-owned Manager
                        else if(retailerIdPOWMgrMap.containsKey(storeId) && retailerIdPOWMgrMap.get(storeId).contains(userId)){
                            if(!retailerIdPOWMgrLoginMap.containsKey(storeId)){
                                retailerIdPOWMgrLoginMap.put(storeId,0);
                            }
                            Integer POWMgrLogins=retailerIdPOWMgrLoginMap.get(storeId)+1;
                            retailerIdPOWMgrLoginMap.put(storeId,POWMgrLogins);
                        }
                        //Finance Manager
                        else if(retailerIdFinanceMgrMap.containsKey(storeId) && retailerIdFinanceMgrMap.get(storeId).contains(userId)){
                            if(!retailerIdFinanceMgrLoginMap.containsKey(storeId)){
                                retailerIdFinanceMgrLoginMap.put(storeId,0);
                            }
                            Integer FinanceMgrLogins=retailerIdFinanceMgrLoginMap.get(storeId)+1;
                            retailerIdFinanceMgrLoginMap.put(storeId,FinanceMgrLogins);
                        }
                        //General Manager
                        else if(retailerIdGeneralMgrMap.containsKey(storeId) && retailerIdGeneralMgrMap.get(storeId).contains(userId)){
                            if(!retailerIdGeneralMgrLoginMap.containsKey(storeId)){
                                retailerIdGeneralMgrLoginMap.put(storeId,0);
                            }
                            Integer GeneralMgrLogins=retailerIdGeneralMgrLoginMap.get(storeId)+1;
                            retailerIdGeneralMgrLoginMap.put(storeId,GeneralMgrLogins);
                        }
                    }                    
                }
            }
        }
    }   
    global void finish(Database.BatchableContext BC) { 
        sendReportEmail(accountList);
    }    
    public void scheduleMe(){       
        // System.schedule('DPM Weekly average logins per managing jobs_5-Feb-2023', '0 0 0 6 2 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        // System.schedule('DPM Weekly average logins per managing jobs_12-Mar-2023', '0 0 0 13 3 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_16-April-2023', '0 0 0 17 4 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_21-May-2023', '0 0 0 22 5 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_25-Jun-2023', '0 0 0 26 6 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_30-July-2023', '0 0 0 31 7 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_3-Sep-2023', '0 0 0 4 9 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_8-Oct-2023', '0 0 0 9 10 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_12-Nov-2023', '0 0 0 13 11 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_17-Dec-2023', '0 0 0 18 12 ? 2023',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_21-Jan-2024', '0 0 0 22 1 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_25-Feb-2024', '0 0 0 26 2 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_31-March-2024', '0 0 0 1 4 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_5-May-2024', '0 0 0 6 5 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_9-Jun-2024', '0 0 0 10 6 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_14-July-2024', '0 0 0 15 7 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_18-Aug-2024', '0 0 0 19 8 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_22-Sep-2024', '0 0 0 23 9 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_27-Oct-2024', '0 0 0 28 10 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_1-Dec-2024', '0 0 0 2 12 ? 2024',new DPM_MetricsWeeklyAvgLogins());
        System.schedule('DPM Weekly average logins per managing jobs_5-Jan-2025', '0 0 0 6 1 ? 2025',new DPM_MetricsWeeklyAvgLogins());
    }    
    
    public void sendReportEmail(List<AccountWrapper> accounts){
        //prepare csv file
        string header = 'Retail store ID, Retaile store name, # of Service Mngr, Service Mngr logins avg,'+
            +' # of Parts Mngr, Parts Mngr logins avg,'+
            +' # of New vehicles Sales Mngr, New vehicles Sales Mngr  logins avg,'+
            +' # of Pre-owned Mngr, Pre-owner Mngr  logins avg,'+
            +' # of Finance Mngr, Finance Mngr  logins avg,'+
            +' # of Office Mngr, Office Mngr logins avg,'+
            +' # of General Mngr, General Mngr logins avg\n';
        String finalstr=header;
        
        for(AccountWrapper store:accounts){
            ReportWrapper reportWrapObj=new ReportWrapper();
            reportWrapObj.RetailStoreID=store.DPM_Global_Retailer_Code;            
            String storeName=store.Name;
            if(storeName!=null &&
               storeName.contains(',')){
                   storeName=storeName.replace(',',' ');
               }
            reportWrapObj.RetaileStoreName=storeName;
            if(retailerIdServiceMgrMapPRs.containsKey(store.Id)){
                reportWrapObj.NumberOfServiceMngr=retailerIdServiceMgrMapPRs.get(store.Id).size();
            }
            if(retailerIdServiceMgrLoginMap.containsKey(store.Id)){
                Decimal ServiceMngrLogins=retailerIdServiceMgrLoginMap.get(store.Id);
               // Decimal ServiceMngrs=retailerIdServiceMgrMap.get(store.Id).size();
                reportWrapObj.ServiceMngrLoginsAvg=(ServiceMngrLogins/(5*reportWrapObj.NumberOfServiceMngr)).setScale(1);
            }
            if(retailerIdOfficeMgrMapPRs.containsKey(store.Id)){
                reportWrapObj.NumberOfOfficeMngr=retailerIdOfficeMgrMapPRs.get(store.Id).size();
            }
            if(retailerIdOfficeMgrLoginMap.containsKey(store.Id)){
                Decimal OfficeMngrLogins=retailerIdOfficeMgrLoginMap.get(store.Id);
               // Decimal OfficeMngrs=retailerIdOfficeMgrMap.get(store.Id).size();
                reportWrapObj.OfficeMngrLoginsAvg=(OfficeMngrLogins/(5*reportWrapObj.NumberOfOfficeMngr)).setScale(1);
            }
            if(retailerIdPartsMgrMapPRs.containsKey(store.Id)){
                reportWrapObj.NumberOfPartsMngr=retailerIdPartsMgrMapPRs.get(store.Id).size();
            }
            if(retailerIdPartsMgrLoginMap.containsKey(store.Id)){
                Decimal PartsMngrLogins=retailerIdPartsMgrLoginMap.get(store.Id);
                //Decimal PartsMngrs=retailerIdPartsMgrMap.get(store.Id).size();
                reportWrapObj.PartsMngrLoginsAvg=(PartsMngrLogins/(5*reportWrapObj.NumberOfPartsMngr)).setScale(1);
            }
            if(retailerIdNVSMgrMapPRs.containsKey(store.Id)){
                reportWrapObj.NumberOfNewVehiclesSalesMngr=retailerIdNVSMgrMapPRs.get(store.Id).size();
            }
            if(retailerIdNVSMgrLoginMap.containsKey(store.Id)){
                Decimal NewVehiclesSalesMngrLogins=retailerIdNVSMgrLoginMap.get(store.Id);
               // Decimal NewVehiclesSalesMngrs=retailerIdNVSMgrMap.get(store.Id).size();
                reportWrapObj.NewVehiclesSalesMngrLoginsAvg=(NewVehiclesSalesMngrLogins/(5*reportWrapObj.NumberOfNewVehiclesSalesMngr)).setScale(1);
            }
            if(retailerIdPOWMgrMapPRs.containsKey(store.Id)){
                reportWrapObj.NumberOfPreOwnedMngr=retailerIdPOWMgrMapPRs.get(store.Id).size();
            }
            if(retailerIdPOWMgrLoginMap.containsKey(store.Id)){
                Decimal PreOwnerMngrLogins=retailerIdPOWMgrLoginMap.get(store.Id);
                //Decimal PreOwnerMngrs=retailerIdPOWMgrMap.get(store.Id).size();
                reportWrapObj.PreOwnerMngrLoginsAvg=(PreOwnerMngrLogins/(5*reportWrapObj.NumberOfPreOwnedMngr)).setScale(1);
            }
            if(retailerIdFinanceMgrMapPRs.containsKey(store.Id)){
                reportWrapObj.NumberOfFinanceMngr=retailerIdFinanceMgrMapPRs.get(store.Id).size();
            }
            if(retailerIdFinanceMgrLoginMap.containsKey(store.Id)){
                Decimal FinanceMngrLogins=retailerIdFinanceMgrLoginMap.get(store.Id);
               // Decimal FinanceMngrs=retailerIdFinanceMgrMap.get(store.Id).size();
                reportWrapObj.FinanceMngrLoginsAvg=(FinanceMngrLogins/(5*reportWrapObj.NumberOfFinanceMngr)).setScale(1);
            }
            if(retailerIdGeneralMgrMapPRs.containsKey(store.Id)){
                reportWrapObj.NumberOfGeneralMngr=retailerIdGeneralMgrMapPRs.get(store.Id).size();
            }
            if(retailerIdGeneralMgrLoginMap.containsKey(store.Id)){
                Decimal GeneralMngrLogins=retailerIdGeneralMgrLoginMap.get(store.Id);
               // Decimal GeneralMngrs=retailerIdGeneralMgrMap.get(store.Id).size();
                reportWrapObj.GeneralMngrLoginsAvg=(GeneralMngrLogins/(5*reportWrapObj.NumberOfGeneralMngr)).setScale(1);           
            }
            
            string recordString = reportWrapObj.RetailStoreID+','+reportWrapObj.RetaileStoreName +
                ','+reportWrapObj.NumberOfServiceMngr+','+reportWrapObj.ServiceMngrLoginsAvg+
                ','+reportWrapObj.NumberOfPartsMngr+','+reportWrapObj.PartsMngrLoginsAvg+
                ','+reportWrapObj.NumberOfNewVehiclesSalesMngr+','+reportWrapObj.NewVehiclesSalesMngrLoginsAvg+
                ','+reportWrapObj.NumberOfPreOwnedMngr+','+reportWrapObj.PreOwnerMngrLoginsAvg+
                ','+reportWrapObj.NumberOfFinanceMngr+','+reportWrapObj.FinanceMngrLoginsAvg+
                ','+reportWrapObj.NumberOfOfficeMngr+','+reportWrapObj.OfficeMngrLoginsAvg+
                ','+reportWrapObj.NumberOfGeneralMngr+','+reportWrapObj.GeneralMngrLoginsAvg+
                '\n';
            finalstr = finalstr +recordString;
        } 
        
        OrgWideEmailAddress owea;
        try{
            owea=[SELECT Id FROM OrgWideEmailAddress WHERE Address = 'sfdc@volvocars.com' LIMIT 1];
        }catch(Exception ex){
            System.debug('sfdc email not set in OWD');
        }
        if(owea!=null){
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
        }
    }
    public class ReportWrapper{
        public String RetailStoreID;
        public String RetaileStoreName;
        public Integer NumberOfServiceMngr;
        public Decimal ServiceMngrLoginsAvg;
        public Integer NumberOfPartsMngr;
        public Decimal PartsMngrLoginsAvg;
        public Integer NumberOfNewVehiclesSalesMngr;
        public Decimal NewVehiclesSalesMngrLoginsAvg;
        public Integer NumberOfPreOwnedMngr;
        public Decimal PreOwnerMngrLoginsAvg;
        public Integer NumberOfFinanceMngr;
        public Decimal FinanceMngrLoginsAvg;
        public Integer NumberOfOfficeMngr;
        public Decimal OfficeMngrLoginsAvg;
        public Integer NumberOfGeneralMngr;
        public Decimal GeneralMngrLoginsAvg;
        public ReportWrapper(){
            NumberOfServiceMngr=0;
            ServiceMngrLoginsAvg=0;
            NumberOfPartsMngr=0;
            PartsMngrLoginsAvg=0;
            NumberOfNewVehiclesSalesMngr=0;
            NewVehiclesSalesMngrLoginsAvg=0;
            NumberOfPreOwnedMngr=0;
            PreOwnerMngrLoginsAvg=0;
            NumberOfFinanceMngr=0;
            NumberOfOfficeMngr=0;
            NumberOfGeneralMngr=0;
            GeneralMngrLoginsAvg=0;
            FinanceMngrLoginsAvg=0;
            OfficeMngrLoginsAvg=0;
        }
    }
    public class AccountWrapper{
        public String Id;
        public String DPM_Global_Retailer_Code;
        public String Name;
        public AccountWrapper(String p_Id,String p_DPM_Global_Retailer_Code,String p_Name){
            Id=p_Id;
            DPM_Global_Retailer_Code=p_DPM_Global_Retailer_Code;
            Name=p_Name;
        }
    }
}