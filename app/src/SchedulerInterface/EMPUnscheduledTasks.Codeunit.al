codeunit 50323 "BIT EMP Unscheduled Tasks" implements "BYD SDL IScheduler Unscheduled Event Filters"
{
    procedure GetUnscheduledFilters(var Filters: Record "BYD SDL Scheduler Filter")
    var
        FilterSetup: Record "BYD SDL Un. Ev. Filter Setup";
        Counter: Integer;
    begin
        Counter := 0;
        if GetInitialUnassignedEventsFilter(FilterSetup) then begin
            Filters.Init();
            Filters."Code" := FilterSetup."Code";
            Filters.Name := FilterSetup.Name;
            Filters."Sorting No." := Counter;
            Filters.Insert();
            Counter += 1;
            FilterSetup.SetFilter("Code", '<>%1', FilterSetup."Code");
        end;

        if FilterSetup.FindSet() then
            repeat
                Filters.Init();
                Filters."Code" := FilterSetup."Code";
                Filters.Name := FilterSetup.Name;
                Filters."Sorting No." := Counter;
                Filters.Insert();
                Counter += 1;
            until FilterSetup.Next() = 0;
    end;

    procedure SetSelectedUnscheduledFilter(FilterKey: Text);
    begin
        CurrentUnscheduledSchedulerFilter := FilterKey;
    end;

    local procedure GetInitialUnassignedEventsFilter(var FilterSetup: Record "BYD SDL Un. Ev. Filter Setup"): Boolean
    begin
        exit(GetInitialUnassignedEventsFilter(FilterSetup, ''));
    end;

    local procedure GetInitialUnassignedEventsFilter(var FilterSetup: Record "BYD SDL Un. Ev. Filter Setup"; SelectedSchedulerFilter: Text): Boolean
    var
        DefaultFilter: Record "BYD SDL User Default Filter";
        DefaultFilterCode: Code[20];
    begin
        FilterSetup.InsertIfNotExists();
        Evaluate(DefaultFilterCode, SelectedSchedulerFilter);
        if SelectedSchedulerFilter = '' then
            if DefaultFilter.Get(UserId()) then
                DefaultFilterCode := DefaultFilter."Unassigned Events Filter Code"
            else
                if DefaultFilter.Get('') then
                    DefaultFilterCode := DefaultFilter."Unassigned Events Filter Code";

        if FilterSetup.Get(DefaultFilterCode) then
            exit(true);
    end;

    var
        CurrentUnscheduledSchedulerFilter: Text;
}