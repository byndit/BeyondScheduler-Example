codeunit 50324 "BIT EMP Business Times" implements "BYD SDL IScheduler Business Times"
{
    procedure OnLoadBusinessTimes(var ShowNonBusinessDaysAndWeekends: Boolean; var BusinessDayStartsAt: Integer; var BusinessDayEndsAt: Integer; var BusinessWeekends: Boolean);
    begin
        ShowNonBusinessDaysAndWeekends := false;
        BusinessDayStartsAt := 8;
        BusinessDayEndsAt := 17;
        BusinessWeekends := false;
    end;
}