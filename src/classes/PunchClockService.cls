@RestResource(urlMapping='/punchclock/*')
global class PunchClockService{

    
    public static String clockIn = 'Clock In';
    public static String clockOut = 'Clock Out';
    public static String lunch = 'Lunch Break';
    public static String backToWork = 'Back to Work';
    
    @HttpGet
    global static List<String> availableActionsService(){
        String findByField = RestContext.request.params.get('findByField');
        String fieldValue = RestContext.request.params.get('fieldValue');
        return availableActions(findByField,fieldValue);
    }
    
    private static List<String> availableActions(String findByField,String fieldValue){
        CKSW_BASE__Resource__c resource = getResourceBySpecifiedField(findByField,fieldValue);
        CKSW_BASE__Timesheet__c timesheet = getLastTimeSheetByResourceId(resource.Id);
        if(timesheet == null){
            return new List<String>{clockIn};
        }
        list<CKSW_BASE__Clock_Report__c> reportList = [Select Id, CKSW_BASE__Time__c, CKSW_BASE__Activity__c, CKSW_BASE__Timesheet__c
                                                FROM CKSW_BASE__Clock_Report__c 
                                                WHERE CKSW_BASE__Timesheet__c =: timesheet.Id
                                                ORDER BY CKSW_BASE__Time__c DESC];
        return getAvailableActivitiesByCurrentClockReport(reportList[0]);
    }
    
    @HttpPost
    global static Boolean action(String action,String findByField,String fieldValue){
        if(!isAvailableAction(action,findByField,fieldValue)){
            return false;
        }
        CKSW_BASE__Resource__c resource = getResourceBySpecifiedField(findByField,fieldValue);
        CKSW_BASE__Timesheet__c timesheet = getLastTimeSheetByResourceId(resource.Id);
        CKSW_BASE__Clock_Report__c newReport = new CKSW_BASE__Clock_Report__c(CKSW_BASE__Timesheet__c = timesheet.id, CKSW_BASE__Activity__c = action, CKSW_BASE__Time__c = Datetime.now());
        insert newReport;
        return true;
    }
    
    private static Boolean isAvailableAction(String action,String findByField,String fieldValue){
        for(String availableAction : availableActions(findByField,fieldValue)){
            if(availableAction == action){
                return true;
            }
        }
        return false;
    }

    private static List<string> getAvailableActivitiesByCurrentClockReport(CKSW_BASE__Clock_Report__c i_ClockReport){
        List<string> results = new List<string>();
        
        if (i_ClockReport == null){
            results.add(clockIn);
        }
        else if (i_ClockReport.CKSW_BASE__Activity__c == clockIn){
            results.add(clockOut);
            results.add(lunch);
        }
        else if (i_ClockReport.CKSW_BASE__Activity__c == clockOut){
            results.add(clockIn);
        }
        else if (i_ClockReport.CKSW_BASE__Activity__c == lunch){
            results.add(backToWork);
        }
        else if (i_ClockReport.CKSW_BASE__Activity__c == backToWork){
            results.add(clockOut);
            results.add(lunch);
        }
        
        return results;
    }

    public static CKSW_BASE__Resource__c getResourceBySpecifiedField(String findByField,String fieldValue){
        try{
            CKSW_BASE__Resource__c res = Database.query('Select Id From CKSW_BASE__Resource__c where ' + findByField + ' =: fieldValue limit 1');
            return res;
        }catch(Exception e){
            throw new NoResourceFoundException();
        }
    }

    public static CKSW_BASE__Timesheet__c getLastTimeSheetByResourceId(Id resourceId){
        list<CKSW_BASE__Timesheet__c> timesheetList = [SELECT Id, CKSW_BASE__Employee__c, CKSW_BASE__Date__c
                                    FROM CKSW_BASE__Timesheet__c
                                    WHERE CKSW_BASE__Employee__c = :resourceId
                                    order by CKSW_BASE__Date__c desc Limit 1];
        if(timesheetList.isEmpty()){
            return createNewTimesheetForResource(resourceId);
        }
        return timesheetList[0];
    }

    public class NoResourceFoundException extends Exception{}
    
    private static CKSW_BASE__Timesheet__c createNewTimesheetForResource(Id resourceId)
    {
            
        Datetime datetimeToCreate;
        Time settingsTime = Time.newInstance(0, 0, 0, 0);
        
        if (settingsTime < datetime.now().time())
            datetimeToCreate = datetime.newInstance(date.today(), settingsTime);
        else
            datetimeToCreate = datetime.newInstance(date.today().addDays(-1), settingsTime);
        
        CKSW_BASE__Timesheet__c newTimesheet = new CKSW_BASE__Timesheet__c(CKSW_BASE__Date__c = datetimeToCreate, CKSW_BASE__Status__c = 'In Progress', CKSW_BASE__Employee__c = resourceId);
        
        insert newTimesheet;
        return newTimesheet;
    }
}
