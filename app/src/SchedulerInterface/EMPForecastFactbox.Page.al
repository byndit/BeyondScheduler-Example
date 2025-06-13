page 50323 "BIT EMP Forecast Factbox"
{
    ApplicationArea = All;
    Caption = 'Forecast';
    PageType = CardPart;
    SourceTable = "BIT Employee Planning";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Employee No."; Rec."Employee No.")
                {
                    ToolTip = 'Specifies a number for the employee.';
                    Editable = false;
                }
                field("Employee First Name"; Rec."Employee First Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Employee First Name field.';
                }
                field("Employee Last Name"; Rec."Employee Last Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Employee Last Name field.';
                }
            }
            group(Planned)
            {
                Caption = 'Capacity:Planned';
                field(GetCapacityWeek; StrSubstNo(CapLbl, Rec.GetCapacity(3), Rec.GetPlanned(3)))
                {
                    CaptionClass = GetCaption(3);
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Capacity Week field.';
                }
                field(GetCapacityMonth; StrSubstNo(CapLbl, Rec.GetCapacity(0), Rec.GetPlanned(0)))
                {
                    CaptionClass = GetCaption(0);
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Capacity Month field.';
                }
                field(GetCapacityQuarter; StrSubstNo(CapLbl, Rec.GetCapacity(1), Rec.GetPlanned(1)))
                {
                    CaptionClass = GetCaption(1);
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Capacity Quarter field.';
                }
                field(GetCapacityYear; StrSubstNo(CapLbl, Rec.GetCapacity(2), Rec.GetPlanned(2)))
                {
                    CaptionClass = GetCaption(2);
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Capacity Year field.';
                }
            }
        }
    }
    var
        CapLbl: Label '%1:%2', Locked = true;


    procedure GetCaption(Period: Integer): Text
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        CaptionLbl: Label '%1: %2 to %3', Comment = '%1 period type, %2 from, %3 to';
    begin
        case period of
            0:
                begin
                    Calendar."Period Start" := CalcDate('<CM>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Month);
                    exit(StrSubstNo(CaptionLbl, Enum::"Analysis Period Type"::Month, Calendar."Period Start", Calendar."Period End"));
                end;
            1:
                begin
                    Calendar."Period Start" := CalcDate('<CM>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Quarter);
                    exit(StrSubstNo(CaptionLbl, Enum::"Analysis Period Type"::Quarter, Calendar."Period Start", Calendar."Period End"));
                end;
            2:
                begin
                    Calendar."Period Start" := CalcDate('<CM>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Year);
                    exit(StrSubstNo(CaptionLbl, Enum::"Analysis Period Type"::Year, Calendar."Period Start", Calendar."Period End"));
                end;
            3:
                begin
                    Calendar."Period Start" := CalcDate('<CW>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Week);
                    exit(StrSubstNo(CaptionLbl, Enum::"Analysis Period Type"::Week, Calendar."Period Start", Calendar."Period End"));
                end;
        end;
    end;
}
