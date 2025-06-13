pageextension 50321 "BIT Customer Card" extends "Customer Card"
{
    layout
    {
        addlast(content)
        {
            group("BIT Scheduler")
            {
                Caption = 'Scheduler';
                field("BIT Hex Color"; Rec."BIT Hex Color")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Hex Color field.';
                }
                field("BIT Schedule to Planning Board"; Rec."BIT Schedule to Planning Board")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Schedule to Planning Board field.';
                }
            }
        }
    }
}