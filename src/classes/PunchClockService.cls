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
        return getAvailableActions(timesheet.Id);
    }

    @HttpPost
    global static Boolean action(String action,String findByField,String fieldValue){
        system.debug('YBY action');
            system.debug('YBY 1');
        CKSW_BASE__Resource__c resource = getResourceBySpecifiedField(findByField,fieldValue);
            system.debug('YBY 2');
        CKSW_BASE__Timesheet__c timesheet = getLastTimeSheetByResourceId(resource.Id);
        
        if(action != getAvailableActions(timesheet.Id)){
            return false;
        }
            system.debug('YBY 3');
        CKSW_BASE__Clock_Report__c newReport = new CKSW_BASE__Clock_Report__c(CKSW_BASE__Timesheet__c = timesheet.id, CKSW_BASE__Activity__c = action, CKSW_BASE__Time__c = Datetime.now());
            system.debug('YBY 4');
        insert newReport;
            system.debug('YBY 5');
        return true;
    }

    private static String getAvailableActions(Id timesheetId){
        list<CKSW_BASE__Clock_Report__c> reportList = [Select Id, CKSW_BASE__Time__c, CKSW_BASE__Activity__c, CKSW_BASE__Timesheet__c
                                                FROM CKSW_BASE__Clock_Report__c
                                                WHERE CKSW_BASE__Timesheet__c =: timesheetId
                                                ORDER BY CKSW_BASE__Time__c DESC];
        if(reportList.isEmpty()){
            return clockIn;
        }
        if(reportList[0].CKSW_BASE__Activity__c == clockIn){
            return clockOut;
        }
        return clockIn;
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
        if (!DML_CustomExtension.isDMLAllowed(new CKSW_BASE__Timesheet__c(), new Set<String> {Constants.TIMESHEET_DATE_PROPERTY,Constants.TIMESHEET_STATUS_PROPERTY,Constants.TIMESHEET_EMPLOYEE_PROPERTY}, DML_CustomExtension.DMLActions.a_insert))
            return null;
            
        Datetime datetimeToCreate;
        list<string> settingsTimeList = CustomSettings.timesheetStartDay.split(':');
        Time settingsTime = Time.newInstance(Integer.valueOf(settingsTimeList[0]), Integer.valueOf(settingsTimeList[1]), 0, 0);
        
        if (settingsTime < datetime.now().time())
            datetimeToCreate = datetime.newInstance(date.today(), settingsTime);
        else
            datetimeToCreate = datetime.newInstance(date.today().addDays(-1), settingsTime);
        
        CKSW_BASE__Timesheet__c newTimesheet = new CKSW_BASE__Timesheet__c(CKSW_BASE__Date__c = datetimeToCreate, CKSW_BASE__Status__c = 'In Progress', CKSW_BASE__Employee__c = resourceId);
        
        system.debug('newTimesheet - ' + newTimesheet);

        insert newTimesheet;
        return newTimesheet;
    }
}
