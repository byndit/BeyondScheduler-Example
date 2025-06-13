codeunit 50321 "BIT EMP Blocked Times" implements "BYD SDL IScheduler Special Times"
{
    procedure OnLoadSpecialTimes(StartDateTime: DateTime; EndDateTime: DateTime; Resources: List of [RecordId]; var SchedulerSpecialTime: Record "BYD SDL Scheduler Special Time");
    var
        BaseCalendar: Record "Base Calendar";
        CompanyInformation: Record "Company Information";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CalendarMgmt: Codeunit "Calendar Management";
        Resourceid: RecordId;
        FreeDay: Boolean;
        EndDate: Date;
        StartDate: Date;
        TempDate: Date;
        FullDay: Time;
        MidNight: Time;
    begin
        StartDate := DT2Date(StartDateTime);
        TempDate := StartDate;
        EndDate := DT2Date(EndDateTime);

        MidNight := 000000T;
        FullDay := 235959T;

        CompanyInformation.SetLoadFields("Base Calendar Code");
        CompanyInformation.Get();
        CompanyInformation.TestField("Base Calendar Code");
        BaseCalendar.Get(CompanyInformation."Base Calendar Code");
        CalendarMgmt.SetSource(CompanyInformation, CustomizedCalendarChange);

        repeat
            FreeDay := CalendarMgmt.IsNonworkingDay(TempDate, CustomizedCalendarChange);
            if FreeDay then
                foreach Resourceid in Resources do
                    InsertBlockedTime(CreateDateTime(TempDate, MidNight), CreateDateTime(TempDate, FullDay), Resourceid, SchedulerSpecialTime);
            TempDate += 1;
        until TempDate > EndDate;

        //foreach Resourceid in Resources do
        //    InsertBlockedTime(CreateDateTime(DT2Date(StartDateTime), 120000T), CreateDateTime(DT2Date(StartDateTime), 130000T), Resourceid, SchedulerBlockedTime);
    end;

    local procedure InsertBlockedTime(StartDateTime: DateTime; EndDateTime: DateTime; Resourceid: RecordId; var SchedulerSpecialTime: Record "BYD SDL Scheduler Special Time");
    begin
        if not SchedulerSpecialTime.Get(Resourceid, StartDateTime, EndDateTime) then begin
            SchedulerSpecialTime.Init();
            SchedulerSpecialTime."Starting Date-Time" := StartDateTime;
            SchedulerSpecialTime."Ending Date-Time" := EndDateTime;
            SchedulerSpecialTime."Resource ID" := Resourceid;
            SchedulerSpecialTime.isBlocked := true;
            SchedulerSpecialTime.Insert();
        end;
    end;
}