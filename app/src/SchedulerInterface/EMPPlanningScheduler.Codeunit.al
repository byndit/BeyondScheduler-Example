codeunit 50322 "BIT EMP Planning Scheduler" implements "BYD SDL IScheduler Core", "BYD SDL IScheduler Filters", "BYD SDL IScheduler Click Event", "BYD SDL IScheduler Click TimeRange", "BYD SDL IScheduler Move Event", "BYD SDL IScheduler Resize Event", "BYD SDL IScheduler Delete Event", "BYD SDL IScheduler Unscheduled Events"
{
    Permissions =
        tabledata employee = RIMD,
        tabledata "BIT Employee Planning" = RIMD,
        tabledata "Customer" = RIMD;

    procedure OnInit(Scheduler: ControlAddIn "BYD SDL Scheduler");
    begin
    end;

    procedure OnLoadEvents(StartDateTime: DateTime; EndDateTime: DateTime; Resources: List of [RecordId]; var SchedulerEvent: Record "BYD SDL Scheduler Event");
    var
        EmployeePlanning: Record "BIT Employee Planning";
    begin
        EmployeePlanning.SetFilter("From Date", '<=%1', EndDateTime);
        EmployeePlanning.SetFilter("To Date", '>=%1', StartDateTime);
        if EmployeePlanning.FindSet() then
            repeat
                GenerateEvent(SchedulerEvent, EmployeePlanning);
            until EmployeePlanning.Next() = 0;
    end;

    procedure OnLoadResources(var SchedulerResource: Record "BYD SDL Scheduler Resource");
    var
        Employee: Record Employee;
    begin
        Employee.SetRange(Status, Employee.Status::Active);
        if Employee.FindSet() then
            repeat
                SchedulerResource.Init();
                SchedulerResource.ID := Employee.RecordId;
                SchedulerResource.Name := Employee."First Name" + ' ' + Employee."Last Name";
                SchedulerResource.Insert();
            until Employee.Next() = 0;
    end;

    procedure OnEventClicked(EventID: RecordId);
    var
        EmployeePlanning: Record "BIT Employee Planning";
        EmployeePlanning2: Record "BIT Employee Planning";
        Employee: Record Employee;
        EmployeePlanningCard: Page "BIT Employee Planning Card";
    begin
        If EmployeePlanning.Get(EventID) then begin
            Employee.SetLoadFields("No.");
            Employee.Get(EmployeePlanning."Employee No.");
            if not IsAdmin() and (not CanSchedule(Employee.RecordId())) then
                exit;

            EmployeePlanning.SetRecFilter();
            EmployeePlanningCard.SetRec(EmployeePlanning);
            EmployeePlanningCard.SetRecord(EmployeePlanning);
            EmployeePlanningCard.SetTableView("EmployeePlanning");
            EmployeePlanningCard.LookupMode(true);
            if EmployeePlanningCard.RunModal() = Action::LookupOK then begin
                EmployeePlanningCard.GetRecord(EmployeePlanning2);
                EmployeePlanning.Description := EmployeePlanning2.Description;
                EmployeePlanning.Comment := EmployeePlanning2.Comment;
                EmployeePlanning."Customer No." := EmployeePlanning2."Customer No.";
                EmployeePlanning.Modify();
            end;
        end;
    end;

    procedure OnEventMove(EventID: RecordId; StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId): Record "BYD SDL Scheduler Event";
    var
        EmployeePlanning: Record "BIT Employee Planning";
        SchedulerEvent: Record "BYD SDL Scheduler Event";
        Customer: Record "Customer";
        Employee: Record Employee;
    begin
        if not CanSchedule(ResourceId) then
            Error(CannotScheduleLbl);

        case EventID.TableNo of
            Database::"BIT Employee Planning":
                begin
                    if not EmployeePlanning.Get(EventID) then
                        exit;
                    Employee.Get(EmployeePlanning."Employee No.");
                    if not CanSchedule(Employee.RecordId) then
                        Error(CannotScheduleLbl);

                    Employee.Get(ResourceId);
                    EmployeePlanning."Employee No." := Employee."No.";
                    EmployeePlanning."From Date" := StartDateTime;
                    EmployeePlanning."To Date" := EndDateTime;
                    if EmployeePlanning.Quantity = 4 then begin
                        EmployeePlanning."To Date" := EmployeePlanning."From Date";
                        if DT2Time(StartDateTime) >= 120000T then
                            EndDateTime := EmployeePlanning."To Date";
                    end;
                    EmployeePlanning.Modify(true);
                end;
            Database::"Customer":
                begin
                    if not Customer.Get(EventID) then
                        exit;
                    Customer.SetRecFilter();
                    EmployeePlanning."Customer No." := Customer."No.";
                    Employee.Get(ResourceId);
                    EmployeePlanning."Employee No." := Employee."No.";
                    EmployeePlanning."From Date" := StartDateTime;
                    EmployeePlanning."To Date" := EndDateTime;
                    EmployeePlanning.Insert(true);
                end;
        end;
        GenerateEvent(SchedulerEvent, EmployeePlanning);
        SetDateTimeQuantity(SchedulerEvent, EmployeePlanning, StartDateTime, EndDateTime);
        EmployeePlanning.Modify();
        SchedulerEvent.Modify();
        exit(SchedulerEvent);
    end;

    procedure GetFilters(var Filters: Record "BYD SDL Scheduler Filter");
    begin
    end;

    procedure SetSelectedFilter(FilterKey: Text);
    begin
        CurrentSchedulerFilter := FilterKey;
    end;

    procedure SetInitialFilter(FilterKey: Text);
    begin
        InitialSchedulerFilter := FilterKey;
    end;

    procedure OnLoadUnScheduledEvents(var SchedulerEvent: Record "BYD SDL Scheduler Event");
    var
        Customer: Record "Customer";
    begin
        LoadUnScheduledEvents(Customer, SchedulerEvent);
    end;

    local procedure LoadUnScheduledEvents(var Customer: Record "Customer"; var SchedulerEvent: Record "BYD SDL Scheduler Event")
    begin
        Customer.SetRange("BIT Schedule to Planning Board", true);
        if Customer.FindSet() then
            repeat
                SchedulerEvent.Init();
                SchedulerEvent.ID := Customer.RecordId();
                SchedulerEvent.Text := StrSubstNo(UnSchedulerPlaceholderLbl, Customer."No.", Customer.Name, Customer."Name 2");
                SchedulerEvent."Background Color" := Customer."BIT Hex Color";
                SchedulerEvent.Duration := 8 * 60 * 60;
                SchedulerEvent.Insert();
            until Customer.Next() = 0;
    end;

    procedure OnEventDelete(EventID: RecordId): Boolean
    var
        EmployeePlanning: Record "BIT Employee Planning";
        Customer: Record "Customer";
        Employee: Record Employee;
        EventDeleted: Boolean;
    begin
        if not EmployeePlanning.Get(EventID) then
            exit;

        Employee.SetLoadFields("No.");
        Employee.Get(EmployeePlanning."Employee No.");
        Customer.Get(EmployeePlanning."Customer No.");

        EventDeleted := EmployeePlanning.Delete(true);
        exit(EventDeleted);
    end;

    procedure OnEventResize(EventID: RecordId; StartDateTime: DateTime; EndDateTime: DateTime): Record "BYD SDL Scheduler Event"
    var
        EmployeePlanning: Record "BIT Employee Planning";
        SchedulerEvent: Record "BYD SDL Scheduler Event";
        employee: Record Employee;
    begin
        EmployeePlanning.Get(EventID);
        employee.SetLoadFields("No.");
        employee.Get(EmployeePlanning."Employee No.");

        if not CanSchedule(employee.RecordId) then
            Error(CannotScheduleLbl);

        GenerateEvent(SchedulerEvent, EmployeePlanning);
        SetDateTimeQuantity(SchedulerEvent, EmployeePlanning, StartDateTime, EndDateTime);
        EmployeePlanning.Modify();
        SchedulerEvent.Modify();
        exit(SchedulerEvent);
    end;

    local procedure SetDateTimeQuantity(var SchedulerEvent: Record "BYD SDL Scheduler Event"; var EmployeePlanning: Record "BIT Employee Planning"; StartDateTime: DateTime; EndDateTime: DateTime)
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        NoOfDays: Integer;
        TimeDelta: Integer;
    begin
        EmployeePlanning.Quantity := 8;

        Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
        Calendar.SetRange("Period Start", DT2Date(StartDateTime), DT2Date(EndDateTime));
        NoOfDays := Calendar.Count();

        Calendar."Period Start" := DT2Date(StartDateTime);
        Calendar."Period End" := DT2Date(EndDateTime);
        PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Day);

        case true of
            NoOfDays <= 1:
                begin
                    TimeDelta := EndDateTime - StartDateTime;
                    if TimeDelta <= (4 * 60 * 60 * 1000) then
                        EmployeePlanning.Quantity := 4;
                    if TimeDelta > (4 * 60 * 60 * 1000) then
                        EmployeePlanning.Quantity := 8;
                    case EmployeePlanning.Quantity of
                        4:
                            begin
                                Clear(EmployeePlanning."Afternoon");
                                EmployeePlanning."Afternoon" := DT2Time(StartDateTime) >= 120000T;
                                if EmployeePlanning."Afternoon" then begin
                                    SchedulerEvent."Starting Date-Time" := CreateDateTime(DT2Date(StartDateTime), 130000T);
                                    SchedulerEvent."Ending Date-Time" := CreateDateTime(DT2Date(EndDateTime), 170000T);
                                end else begin
                                    SchedulerEvent."Starting Date-Time" := CreateDateTime(DT2Date(StartDateTime), 080000T);
                                    SchedulerEvent."Ending Date-Time" := CreateDateTime(DT2Date(EndDateTime), 120000T);
                                end;
                            end;
                        8:
                            begin
                                SchedulerEvent."Starting Date-Time" := CreateDateTime(DT2Date(StartDateTime), 080000T);
                                SchedulerEvent."Ending Date-Time" := CreateDateTime(DT2Date(EndDateTime), 170000T);
                            end;
                    end;
                end;
            NoOfDays > 1:
                begin
                    SchedulerEvent."Starting Date-Time" := CreateDateTime(DT2Date(StartDateTime), 080000T);
                    SchedulerEvent."Ending Date-Time" := CreateDateTime(DT2Date(EndDateTime), 170000T);
                    EmployeePlanning.Quantity *= Calendar.Count;
                end;
        end;
        EmployeePlanning."Quantity (Base)" := EmployeePlanning.Quantity;
        EmployeePlanning."From Date" := SchedulerEvent."Starting Date-Time";
        EmployeePlanning."To Date" := SchedulerEvent."Ending Date-Time";
    end;

    local procedure SetTime(var SchedulerEvent: Record "BYD SDL Scheduler Event"; EmployeePlanning: Record "BIT Employee Planning")
    begin
        if (EmployeePlanning.Quantity > 4) and (EmployeePlanning.Quantity < 8) then
            EmployeePlanning.Quantity := 8;
        if (EmployeePlanning.Quantity > 0) and (EmployeePlanning.Quantity < 4) then
            EmployeePlanning.Quantity := 4;
        case true of
            EmployeePlanning.Quantity = 8, EmployeePlanning.Quantity = 0, ((EmployeePlanning.Quantity mod 8) = 0):
                begin
                    SchedulerEvent."Starting Date-Time" := CreateDateTime(dt2date(EmployeePlanning."From Date"), 080000T);
                    SchedulerEvent."Ending Date-Time" := CreateDateTime(dt2date(EmployeePlanning."To Date"), 170000T);
                end;
            EmployeePlanning.Quantity = 4:
                case true of
                    EmployeePlanning."Afternoon":
                        begin
                            SchedulerEvent."Starting Date-Time" := CreateDateTime(dt2date(EmployeePlanning."From Date"), 130000T);
                            SchedulerEvent."Ending Date-Time" := CreateDateTime(dt2date(EmployeePlanning."To Date"), 170000T);
                        end;
                    not EmployeePlanning."Afternoon":
                        begin
                            SchedulerEvent."Starting Date-Time" := CreateDateTime(dt2date(EmployeePlanning."From Date"), 080000T);
                            SchedulerEvent."Ending Date-Time" := CreateDateTime(dt2date(EmployeePlanning."To Date"), 120000T);
                        end;
                end;
        end;
    end;

    procedure OnTimeRangeClicked(StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId): Record "BYD SDL Scheduler Event";
    var
        EmployeePlanning: Record "BIT Employee Planning";
        TempEmployeePlanning: Record "BIT Employee Planning" temporary;
        SchedulerEvent: Record "BYD SDL Scheduler Event";
        Employee: Record Employee;
        EmployeePlanningCard: Page "BIT Employee Planning Card";
    begin
        if not CanSchedule(ResourceId) then
            Error(CannotScheduleLbl);

        if not Employee.Get(ResourceId) then
            exit;

        TempEmployeePlanning.Init();
        TempEmployeePlanning."Entry No." := 1;
        TempEmployeePlanning."Employee No." := Employee."No.";
        TempEmployeePlanning."From Date" := StartDateTime;
        TempEmployeePlanning."To Date" := EndDateTime;
        TempEmployeePlanning.insert();

        EmployeePlanningCard.SetRecord(TempEmployeePlanning);
        EmployeePlanningCard.SetTableView("TempEmployeePlanning");
        EmployeePlanningCard.LookupMode(true);
        EmployeePlanningCard.SetRec(TempEmployeePlanning);

        if EmployeePlanningCard.RunModal() = Action::LookupOK then begin
            EmployeePlanningCard.GetRecord(TempEmployeePlanning);

            EmployeePlanning.SetRange("Employee No.", Employee."No.");
            EmployeePlanning.SetRange("Customer No.", TempEmployeePlanning."Customer No.");
            EmployeePlanning.SetRange("From Date", StartDateTime);
            EmployeePlanning.SetRange("To Date", EndDateTime);
            EmployeePlanning.SetRange("Afternoon", DT2Time(StartDateTime) >= 120000T);
            if EmployeePlanning.IsEmpty() then begin
                EmployeePlanning.Init();
                EmployeePlanning."Employee No." := Employee."No.";
                EmployeePlanning.validate("Customer No.", TempEmployeePlanning."Customer No.");
                EmployeePlanning."From Date" := StartDateTime;
                EmployeePlanning."To Date" := EndDateTime;
                EmployeePlanning.Description := TempEmployeePlanning.Description;
                EmployeePlanning.Insert(true);

                GenerateEvent(SchedulerEvent, EmployeePlanning);
                SetDateTimeQuantity(SchedulerEvent, EmployeePlanning, StartDateTime, EndDateTime);
                SchedulerEvent.Modify();
                EmployeePlanning.Modify();
            end;
        end else
            Error('');
        exit(SchedulerEvent);
    end;

    local procedure GenerateEvent(var SchedulerEvent: Record "BYD SDL Scheduler Event"; EmployeePlanning: Record "BIT Employee Planning")
    var
        Customer: Record "Customer";
        Employee: Record Employee;
        TypeHelper: Codeunit "Type Helper";
    begin
        if EmployeePlanning."To Date" = 0DT then
            EmployeePlanning."To Date" := EmployeePlanning."From Date";

        SchedulerEvent.Init();
        SchedulerEvent.ID := EmployeePlanning.RecordId();
        if Employee.Get(EmployeePlanning."Employee No.") then
            SchedulerEvent."Resource ID" := Employee.RecordId();

        SetTime(SchedulerEvent, EmployeePlanning);

        Customer.SetLoadFields("BIT Hex Color", Name, "Name 2");
        if not Customer.Get(EmployeePlanning."Customer No.") then
            Customer.Init();
        SchedulerEvent."Background Color" := Customer."BIT Hex Color";
        if Customer."No." = '' then
            SchedulerEvent.Text := EmployeePlanning.Description
        else
            SchedulerEvent.Text := StrSubstNo(SchedulerPlaceholderLbl, Customer."No.", Customer.Name, Customer."Name 2", TypeHelper.CRLFSeparator(), EmployeePlanning.Description);

        if not IsAdmin() and (not CanSchedule(Employee.RecordId())) then begin
            SchedulerEvent.Text := AbsenceLbl;
            SchedulerEvent."Bar Color" := '';
            SchedulerEvent."Background Color" := '';
        end;

        SchedulerEvent.Insert();
    end;

    procedure IsAdmin(): Boolean
    begin
        exit(true);
    end;

    local procedure CanSchedule(ResourceId: RecordId): Boolean
    begin
        exit(true);
    end;

    var
        AbsenceLbl: Label 'Absence';
        CannotScheduleLbl: Label 'You are not allowed to schedule this resource.';
        SchedulerPlaceholderLbl: Label '%1: %2 %3%4%5', Locked = true;
        UnSchedulerPlaceholderLbl: Label '%1: %2 %3', Locked = true;
        CurrentSchedulerFilter: Text;
        InitialSchedulerFilter: Text;

}