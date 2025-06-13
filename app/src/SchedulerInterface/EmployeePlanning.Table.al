table 50322 "BIT Employee Planning"
{
    Caption = 'Employee Planning';
    DataCaptionFields = "Employee No.";
    LookupPageId = "BIT Employee Planning Card";
    DrillDownPageId = "BIT Employee Planning Card";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;

            trigger OnValidate()
            begin
                Employee.Get("Employee No.");
                if Employee."Privacy Blocked" then
                    Error(BlockedErr);
            end;
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "From Date"; DateTime)
        {
            Caption = 'From Date';
        }
        field(11; "To Date"; DateTime)
        {
            Caption = 'To Date';
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Quantity (Base)" := UOMMgt.CalcBaseQty(Quantity, "Qty. per Unit of Measure");
            end;
        }
        field(8; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Human Resource Unit of Measure";

            trigger OnValidate()
            begin
                HumanResUnitOfMeasure.Get("Unit of Measure Code");
                "Qty. per Unit of Measure" := HumanResUnitOfMeasure."Qty. per Unit of Measure";
                Validate(Quantity);
            end;
        }
        field(14; Comment; Text[250])
        {
            Caption = 'Comment';
        }
        field(15; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(20; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(21; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No." where(Blocked = const(" "));
        }
        field(22; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
        }
        field(23; "Employee First Name"; Text[30])
        {
            Caption = 'First Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(Employee."First Name" where("No." = field("Employee No.")));
        }
        field(24; "Employee Last Name"; Text[30])
        {
            Caption = 'Last Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(Employee."Last Name" where("No." = field("Employee No.")));
        }
        field(30; Afternoon; Boolean)
        {
            Caption = 'Afternoon';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "From Date")
        {
            SumIndexFields = Quantity, "Quantity (Base)";
        }
        key(Key3; "From Date", "To Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        EmployeeAbsence.SetCurrentKey("Entry No.");
        if EmployeeAbsence.FindLast() then
            "Entry No." := EmployeeAbsence."Entry No." + 1
        else begin
            CheckBaseUOM();
            "Entry No." := 1;
        end;
    end;

    var
        EmployeeAbsence: Record "BIT Employee Planning";
        Employee: Record Employee;
        HumanResUnitOfMeasure: Record "Human Resource Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";

        BlockedErr: Label 'You cannot plan because the employee is blocked due to privacy.';

    local procedure CheckBaseUOM()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("Base Unit of Measure");
    end;

    procedure GetPlanned(Period: Integer): Decimal
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        case period of
            0:
                begin
                    Calendar."Period Start" := CalcDate('<CM>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Month);
                    exit(GetPlanned(Calendar."Period Start", Calendar."Period End"));
                end;
            1:
                begin
                    Calendar."Period Start" := CalcDate('<CM>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Quarter);
                    exit(GetPlanned(Calendar."Period Start", Calendar."Period End"));
                end;
            2:
                begin
                    Calendar."Period Start" := CalcDate('<CM>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Year);
                    exit(GetPlanned(Calendar."Period Start", Calendar."Period End"));
                end;
            3:
                begin
                    Calendar."Period Start" := CalcDate('<CW>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Week);
                    exit(GetPlanned(Calendar."Period Start", Calendar."Period End"));
                end;
        end;
    end;

    procedure GetCapacity(Period: Integer): Decimal
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        case period of
            0:
                begin
                    Calendar."Period Start" := CalcDate('<CM>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Month);
                    exit(GetCapacity(Calendar."Period Start", Calendar."Period End"));
                end;
            1:
                begin
                    Calendar."Period Start" := CalcDate('<CM>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Quarter);
                    exit(GetCapacity(Calendar."Period Start", Calendar."Period End"));
                end;
            2:
                begin
                    Calendar."Period Start" := CalcDate('<CM>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Year);
                    exit(GetCapacity(Calendar."Period Start", Calendar."Period End"));
                end;
            3:
                begin
                    Calendar."Period Start" := CalcDate('<CW>', TODAY());
                    PeriodPageMgt.FindDate('<', Calendar, Enum::"Analysis Period Type"::Week);
                    exit(GetCapacity(Calendar."Period Start", Calendar."Period End"));
                end;
        end;
    end;

    local procedure GetCapacity(StartDate: Date; EndDate: Date) Qty: Decimal
    var
        CalendarMgmt: Codeunit "Calendar Management";
        FreeDay: Boolean;
        TempDate: Date;
    begin
        Clear(Qty);
        TempDate := StartDate;
        if CompanyInformation.Name = '' then begin
            CompanyInformation.SetLoadFields("Base Calendar Code");
            CompanyInformation.Get();
        end;
        if BaseCalendar.Code <> CompanyInformation."Base Calendar Code" then begin
            BaseCalendar.Get(CompanyInformation."Base Calendar Code");
            CalendarMgmt.SetSource(CompanyInformation, CustomizedCalendarChange);
        end;

        repeat
            FreeDay := CalendarMgmt.IsNonworkingDay(TempDate, CustomizedCalendarChange);
            if not FreeDay then
                qty += 8;
            TempDate += 1;
        until TempDate > EndDate;
        exit(qty);
    end;

    procedure GetPlanned(StartDate: Date; EndDate: Date) Qty: Decimal
    var
        EmployeePlanning: Record "BIT Employee Planning";
        Calendar: Record Date;
        CalendarMgmt: Codeunit "Calendar Management";
        FreeDay: Boolean;
        TempDate: Date;
        Days: Integer;
    begin
        Clear(Qty);
        TempDate := StartDate;
        if CompanyInformation.Name = '' then begin
            CompanyInformation.SetLoadFields("Base Calendar Code");
            CompanyInformation.Get();
        end;
        if BaseCalendar.Code <> CompanyInformation."Base Calendar Code" then begin
            BaseCalendar.Get(CompanyInformation."Base Calendar Code");
            CalendarMgmt.SetSource(CompanyInformation, CustomizedCalendarChange);
        end;

        EmployeePlanning.SetRange("Employee No.", Rec."Employee No.");
        EmployeePlanning.SetFilter("From Date", '>=%1', CreateDateTime(StartDate, 000000T));
        EmployeePlanning.SetFilter("To Date", '<=%1', CreateDateTime(EndDate, 235959.999T));
        if EmployeePlanning.FindSet() then
            repeat
                Calendar."Period Start" := DT2Date(EmployeePlanning."From Date");
                Calendar.SetRange("Period Type", Enum::"Analysis Period Type"::Day);
                Calendar.SetRange("Period Start", DT2Date(EmployeePlanning."From Date"), DT2Date(EmployeePlanning."To Date"));
                Days := Calendar.Count;
                TempDate := DT2Date(EmployeePlanning."From Date");
                EndDate := DT2Date(EmployeePlanning."To Date");
                repeat
                    FreeDay := CalendarMgmt.IsNonworkingDay(TempDate, CustomizedCalendarChange);
                    if not FreeDay then
                        qty += (EmployeePlanning.Quantity / Days);
                    TempDate += 1;
                until TempDate > EndDate;

            until EmployeePlanning.Next() = 0;
        exit(qty);
    end;


    var
        BaseCalendar: Record "Base Calendar";
        CompanyInformation: Record "Company Information";
        CustomizedCalendarChange: Record "Customized Calendar Change";

}

