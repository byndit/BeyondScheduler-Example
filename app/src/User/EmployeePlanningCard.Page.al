page 50321 "BIT Employee Planning Card"
{
    AdditionalSearchTerms = 'employee planning calendar outlook';
    Caption = 'Employee Planning Card';
    DataCaptionFields = "Employee No.";
    DelayedInsert = true;
    PageType = Document;
    SourceTable = "BIT Employee Planning";
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field("Employee No."; Rec."Employee No.")
            {
                ApplicationArea = BasicHR;
                ToolTip = 'Specifies a number for the employee.';
                Editable = false;
            }
            field("From Date"; Rec."From Date")
            {
                ApplicationArea = BasicHR;
                ToolTip = 'Specifies the first day of the employee''s absence registered on this line.';
                Editable = false;
            }
            field("To Date"; Rec."To Date")
            {
                ApplicationArea = BasicHR;
                ToolTip = 'Specifies the last day of the employee''s absence registered on this line.';
                Editable = false;
            }
            field("Customer No."; Rec."Customer No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Customer No. field.';
            }
            field(Quantity; Rec.Quantity)
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the quantity associated with absences, in hours or days.';
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = BasicHR;
                ToolTip = 'Specifies a description of the absence.';
            }
            field(Comment; Rec.Comment)
            {
                ApplicationArea = Comments;
                ToolTip = 'Specifies if a comment is associated with this entry.';
            }
            part("BIT Forecast Factbox"; "BIT EMP Forecast Factbox")
            {
                Caption = 'Forecast';
                ApplicationArea = All;
                SubPageLink = "Employee No." = field("Employee No.");
            }
        }
    }

    procedure SetRec(var EmployeePlanning: Record "BIT Employee Planning")
    begin
        Rec.TransferFields(EmployeePlanning);
        Rec.Insert();
    end;

    procedure SetCaption(NewCaption: Text)
    begin
        CaptionTxt := NewCaption;
    end;

    var
        CaptionTxt: Text;
}

