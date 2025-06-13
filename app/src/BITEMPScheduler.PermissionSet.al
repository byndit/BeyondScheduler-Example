permissionset 50321 "BIT EMP Scheduler"
{
    Access = Internal;
    Assignable = true;
    Caption = 'All permissions', Locked = true;

    Permissions =
         codeunit "BIT EMP Blocked Times" = X,
         codeunit "BIT EMP Business Times" = X,
         codeunit "BIT EMP Planning Scheduler" = X,
         codeunit "BIT EMP Unscheduled Tasks" = X,
         page "BIT Employee Planning Card" = X,
         page "BIT EMP Employee Planning List" = X,
         page "BIT EMP Forecast Factbox" = X,
         report "BIT EMP Planning Scheduler" = X,
         table "BIT Employee Planning" = X,
         tabledata "BIT Employee Planning" = RIMD;
}