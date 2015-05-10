@RestResource(urlMapping='/punchclock/*')
global class PunchClockService{

    public static String clockIn = 'Clock In';
    public static String clockOut = 'Clock Out';

    @HttpGet
    global static String availableActions(){
        String findByField = RestContext.request.params.get('findByField');
        String fieldValue = RestContext.request.params.get('fieldValue');
        CKSW_BASE__Resource__c resource = getResourceBySpecifiedField(findByField,fieldValue);
        CKSW_BASE__Timesheet__c timesheet = getLastTimeSheetByResourceId(resource.Id);
        if(timesheet == null){
            return clockIn;
        }
        list<CKSW_BASE__Clock_Report__c> reportList = [Select Id, CKSW_BASE__Time__c, CKSW_BASE__Activity__c, CKSW_BASE__Timesheet__c
                                                FROM CKSW_BASE__Clock_Report__c
                                                WHERE CKSW_BASE__Timesheet__c =: timesheet.Id
                                                ORDER BY CKSW_BASE__Time__c DESC];
        if(reportList.isEmpty()){
            return clockIn;
        }
        if(reportList[0].CKSW_BASE__Activity__c == clockIn){
            return clockOut;
        }
        return clockIn;
    }

    @HttpPost
    global static Boolean action(String action,String findByField,String fieldValue){
        if(action != ClockAvailableActionsService.availableActions(findByField,fieldValue)){
            return false;
        }
        CKSW_BASE__Resource__c resource = getResourceBySpecifiedField(findByField,fieldValue);
        CKSW_BASE__Timesheet__c timesheet = getLastTimeSheetByResourceId(resource.Id);
        CKSW_BASE__Clock_Report__c newReport = new CKSW_BASE__Clock_Report__c(CKSW_BASE__Timesheet__c = timesheet.id, CKSW_BASE__Activity__c = action, CKSW_BASE__Time__c = Datetime.now());
        insert newReport;
        return true;
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
            return null;
        }
        return timesheetList[0];
    }

    public class NoResourceFoundException extends Exception{}
}