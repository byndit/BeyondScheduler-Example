tableextension 50322 "BIT Customer" extends "Customer"
{
    fields
    {
        field(50322; "BIT Hex Color"; Text[7])
        {
            Caption = 'Hex Color';
            DataClassification = CustomerContent;
        }
        field(50321; "BIT Schedule to Planning Board"; Boolean)
        {
            Caption = 'Schedule to Planning Board';
            DataClassification = CustomerContent;
        }
    }
}