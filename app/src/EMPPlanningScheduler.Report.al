report 50321 "BIT EMP Planning Scheduler"
{
    Caption = 'Employee Planning Scheduler';
    UsageCategory = Tasks;
    ApplicationArea = All;
    ProcessingOnly = True;
    UseRequestPage = false;



    trigger OnInitReport()
    var
        "BlockedTimes": Codeunit "BIT EMP Business Times";
        AbsenceScheduler: Codeunit "BIT EMP Planning Scheduler";
        Unscheduled: Codeunit "BIT EMP Unscheduled Tasks";
        SpecialTimes: Codeunit "BYD SDL SP. Ti. From Base Cal.";
        SpecialDays: Codeunit "BYD SDL Sp. Day From Base Cal.";
        ScaleHeaders: Codeunit "BYD SDL Scale Headers";
        SchedulerPage: Page "BYD SDL Scheduler";
    begin
        SchedulerPage.SetInterfaceCore(AbsenceScheduler);

        SchedulerPage.SetInterfaceFilters(AbsenceScheduler);

        SchedulerPage.SetInterfaceScaleHeaders(ScaleHeaders);

        SchedulerPage.SetInterfaceClickEvent(AbsenceScheduler);

        SchedulerPage.SetInterfaceClickTimeRange(AbsenceScheduler);

        SchedulerPage.SetInterfaceResizeEvent(AbsenceScheduler);

        SchedulerPage.SetInterfaceMoveEvent(AbsenceScheduler);

        SchedulerPage.SetInterfaceResizeEvent(AbsenceScheduler);

        SchedulerPage.SetInterfaceDeleteEvent(AbsenceScheduler);

        SchedulerPage.SetInterfaceUnscheduledEvents(AbsenceScheduler);

        SchedulerPage.SetInterfaceUnscheduledEventFilters(Unscheduled);

        SchedulerPage.SetInterfaceSpecialTimes(SpecialTimes);

        SchedulerPage.SetInterfaceSpecialDay(SpecialDays);

        SchedulerPage.SetInterfaceBusinessTimes(BlockedTimes);

        SchedulerPage.Run();
    end;
}