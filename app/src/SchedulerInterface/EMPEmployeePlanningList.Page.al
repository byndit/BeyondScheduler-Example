page 50322 "BIT EMP Employee Planning List"
{
    ApplicationArea = All;
    Caption = 'Employee Planning List';
    PageType = List;
    SourceTable = "BIT Employee Planning";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Employee No."; Rec."Employee No.")
                {
                    ToolTip = 'Specifies a number for the employee.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the Entry No. field.';
                }
                field("From Date"; Rec."From Date")
                {
                    ToolTip = 'Specifies the first day of the employee''s absence registered on this line.';
                }
                field("To Date"; Rec."To Date")
                {
                    ToolTip = 'Specifies the last day of the employee''s absence registered on this line.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ToolTip = 'Specifies the value of the Customer No. field.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the quantity associated with absences, in hours or days.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the absence.';
                }
                field(Comment; Rec.Comment)
                {
                    ToolTip = 'Specifies if a comment is associated with this entry.';
                }
                field(Afternoon; Rec.Afternoon)
                {
                    ToolTip = 'Specifies the value of the Afternoon field.';
                }
            }
        }
        area(FactBoxes)
        {
            part("BIT Forecast Factbox"; "BIT EMP Forecast Factbox")
            {
                Caption = 'Forecast';
                ApplicationArea = All;
                SubPageLink = "Employee No." = field("Employee No.");
            }
        }
    }
}
