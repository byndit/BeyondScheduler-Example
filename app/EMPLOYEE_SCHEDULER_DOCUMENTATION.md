# Employee Scheduler - BeyondScheduler Custom Integration Documentation

## Overview

The Employee Scheduler is a custom Microsoft Dynamics 365 Business Central extension that integrates with the BeyondScheduler framework to provide visual employee planning and scheduling capabilities. This solution enables organizations to efficiently manage employee time allocation, customer assignments, and resource planning through an intuitive drag-and-drop interface.

### Key Features

- **Visual Employee Planning**: Drag-and-drop interface for scheduling employee time
- **Customer Assignment**: Link employee planning entries to specific customers
- **Flexible Time Management**: Support for half-day (4 hours) and full-day (8 hours) scheduling
- **Unscheduled Customer Queue**: Side panel showing customers waiting to be scheduled
- **Color-Coded Events**: Visual distinction using customer-specific hex colors
- **Capacity Planning**: Built-in capacity calculation and planning forecasts
- **Multi-language Support**: German and English localization

## Architecture

### Application Structure
```
Employee Scheduler Extension
├── Core Implementation
│   └── BIT EMP Planning Scheduler (Codeunit 50322)
├── Data Model
│   ├── BIT Employee Planning (Table 50322)
│   └── Customer Extensions (TableExt 50322)
├── User Interface
│   ├── Employee Planning Card (Page 50321)
│   ├── Employee Planning List (Page 50323)
│   └── Forecast Factbox (Page 50324)
└── Supporting Components
    ├── Business Times (Codeunit 50323)
    ├── Blocked Times (Codeunit 50324)
    └── Unscheduled Tasks (Codeunit 50325)
```

### Dependencies
- **BeyondScheduler Framework**: Core scheduling engine (v1.0.0.0)
- **Business Central Platform**: v25.0.0.0
- **Runtime**: AL Language v14.0

## Core Implementation

### Main Scheduler Codeunit

The [`BIT EMP Planning Scheduler`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:1) (Codeunit 50322) serves as the central implementation, implementing multiple BeyondScheduler interfaces with their corresponding procedures:

## Interface Implementation Mapping

### 1. BYD SDL IScheduler Core (Required)
**Purpose**: Essential scheduler operations for loading events and resources

| Procedure | Line | Description |
|-----------|------|-------------|
| [`OnInit`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:8) | 8-10 | Initializes the scheduler (currently empty implementation) |
| [`OnLoadEvents`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:12) | 12-22 | Loads employee planning entries within date range and converts to scheduler events |
| [`OnLoadResources`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:24) | 24-36 | Loads active employees as scheduler resources |

### 2. BYD SDL IScheduler Filters (Optional)
**Purpose**: Filter management for scheduler views

| Procedure | Line | Description |
|-----------|------|-------------|
| [`GetFilters`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:116) | 116-118 | Returns available filters (currently empty implementation) |
| [`SetSelectedFilter`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:120) | 120-123 | Sets the currently selected filter |
| [`SetInitialFilter`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:125) | 125-128 | Sets the initial filter on scheduler load |

### 3. BYD SDL IScheduler Click Event
**Purpose**: Handles user clicks on scheduled events

| Procedure | Line | Description |
|-----------|------|-------------|
| [`OnEventClicked`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:38) | 38-64 | Opens Employee Planning Card for editing when event is clicked |

### 4. BYD SDL IScheduler Click TimeRange
**Purpose**: Handles user clicks on empty time slots

| Procedure | Line | Description |
|-----------|------|-------------|
| [`OnTimeRangeClicked`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:274) | 274-325 | Creates new planning entry when empty time slot is clicked |

### 5. BYD SDL IScheduler Move Event
**Purpose**: Handles drag-and-drop movement of events

| Procedure | Line | Description |
|-----------|------|-------------|
| [`OnEventMove`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:66) | 66-114 | Handles moving events between resources/times, supports both planning entries and unscheduled customers |

### 6. BYD SDL IScheduler Resize Event
**Purpose**: Handles resizing of events (changing duration)

| Procedure | Line | Description |
|-----------|------|-------------|
| [`OnEventResize`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:169) | 169-187 | Handles changing event duration by dragging event edges |

### 7. BYD SDL IScheduler Delete Event
**Purpose**: Handles deletion of events

| Procedure | Line | Description |
|-----------|------|-------------|
| [`OnEventDelete`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:151) | 151-167 | Deletes planning entries when events are removed from scheduler |

### 8. BYD SDL IScheduler Unscheduled Events
**Purpose**: Manages unscheduled items in the side panel

| Procedure | Line | Description |
|-----------|------|-------------|
| [`OnLoadUnScheduledEvents`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:130) | 130-135 | Loads customers marked for scheduling into unscheduled events panel |

## Supporting Methods

### Helper Procedures
| Procedure | Line | Description |
|-----------|------|-------------|
| [`GenerateEvent`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:327) | 327-359 | Converts Employee Planning record to Scheduler Event |
| [`SetDateTimeQuantity`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:189) | 189-244 | Calculates time slots and quantities for events |
| [`SetTime`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:246) | 246-272 | Sets appropriate time ranges based on quantity (4h/8h) |
| [`LoadUnScheduledEvents`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:137) | 137-149 | Internal method to load unscheduled customers |
| [`IsAdmin`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:361) | 361-364 | Security check for administrative privileges |
| [`CanSchedule`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:366) | 366-369 | Security check for scheduling permissions |

## Data Model

### Employee Planning Table

The [`BIT Employee Planning`](src/SchedulerInterface/EmployeePlanning.Table.al:1) table (Table 50322) stores all planning entries:

#### Key Fields
- **Employee No.** (Code[20]): Links to Employee table
- **Entry No.** (Integer): Unique identifier
- **From Date/To Date** (DateTime): Planning period
- **Customer No.** (Code[20]): Associated customer
- **Quantity** (Decimal): Hours planned (4 or 8 typically)
- **Description** (Text[100]): Planning description
- **Comment** (Text[250]): Additional notes
- **Afternoon** (Boolean): Half-day afternoon indicator

#### Business Logic Features

##### Automatic Entry Numbering
```al
trigger OnInsert()
begin
    EmployeeAbsence.SetCurrentKey("Entry No.");
    if EmployeeAbsence.FindLast() then
        "Entry No." := EmployeeAbsence."Entry No." + 1
    else
        "Entry No." := 1;
end;
```

##### Capacity Calculations
The table includes sophisticated capacity calculation methods:
- [`GetCapacity(Period: Integer)`](src/SchedulerInterface/EmployeePlanning.Table.al:195): Calculates available capacity
- [`GetPlanned(Period: Integer)`](src/SchedulerInterface/EmployeePlanning.Table.al:162): Calculates planned hours
- Support for Month, Quarter, Year, and Week periods

### Customer Extensions

The [`BIT Customer`](src/Customer/Customer.TableExt.al:1) table extension adds scheduler-specific fields:

- **BIT Hex Color** (Text[7]): Color code for visual identification
- **BIT Schedule to Planning Board** (Boolean): Marks customers for scheduling queue

## User Interface

### Employee Planning Card

The [`BIT Employee Planning Card`](src/User/EmployeePlanningCard.Page.al:1) (Page 50321) provides detailed planning entry management:

#### Features
- **Read-only Employee and Date Fields**: Prevents accidental modifications
- **Customer Assignment**: Dropdown for customer selection
- **Description and Comments**: Free-text fields for planning details
- **Integrated Forecast Factbox**: Shows capacity planning information

#### Usage Patterns
```al
procedure SetRec(var EmployeePlanning: Record "BIT Employee Planning")
begin
    Rec.TransferFields(EmployeePlanning);
    Rec.Insert();
end;
```

## Scheduling Logic

### Time Management

The system implements sophisticated time management logic:

#### Half-Day vs Full-Day Logic
```al
case EmployeePlanning.Quantity of
    4: // Half-day
        case EmployeePlanning."Afternoon" of
            true:  // 1:00 PM - 5:00 PM
                begin
                    SchedulerEvent."Starting Date-Time" := CreateDateTime(Date, 130000T);
                    SchedulerEvent."Ending Date-Time" := CreateDateTime(Date, 170000T);
                end;
            false: // 8:00 AM - 12:00 PM
                begin
                    SchedulerEvent."Starting Date-Time" := CreateDateTime(Date, 080000T);
                    SchedulerEvent."Ending Date-Time" := CreateDateTime(Date, 120000T);
                end;
        end;
    8: // Full-day: 8:00 AM - 5:00 PM
        begin
            SchedulerEvent."Starting Date-Time" := CreateDateTime(Date, 080000T);
            SchedulerEvent."Ending Date-Time" := CreateDateTime(Date, 170000T);
        end;
end;
```

#### Multi-Day Planning
For planning entries spanning multiple days:
```al
SchedulerEvent."Starting Date-Time" := CreateDateTime(DT2Date(StartDateTime), 080000T);
SchedulerEvent."Ending Date-Time" := CreateDateTime(DT2Date(EndDateTime), 170000T);
EmployeePlanning.Quantity *= Calendar.Count; // Multiply by number of days
```

### Event Generation

The [`GenerateEvent`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:327) procedure creates scheduler events:

```al
local procedure GenerateEvent(var SchedulerEvent: Record "BYD SDL Scheduler Event"; EmployeePlanning: Record "BIT Employee Planning")
var
    Customer: Record "Customer";
    Employee: Record Employee;
begin
    SchedulerEvent.Init();
    SchedulerEvent.ID := EmployeePlanning.RecordId();
    SchedulerEvent."Resource ID" := Employee.RecordId();
    SchedulerEvent."Background Color" := Customer."BIT Hex Color";
    SchedulerEvent.Text := StrSubstNo('%1: %2 %3%4%5', 
        Customer."No.", Customer.Name, Customer."Name 2", 
        CRLF, EmployeePlanning.Description);
    SchedulerEvent.Insert();
end;
```

## Unscheduled Events Management

### Customer Queue System

The system maintains a queue of customers waiting to be scheduled:

```al
procedure OnLoadUnScheduledEvents(var SchedulerEvent: Record "BYD SDL Scheduler Event")
var
    Customer: Record "Customer";
begin
    Customer.SetRange("BIT Schedule to Planning Board", true);
    if Customer.FindSet() then
        repeat
            SchedulerEvent.Init();
            SchedulerEvent.ID := Customer.RecordId();
            SchedulerEvent.Text := StrSubstNo('%1: %2 %3', Customer."No.", Customer.Name, Customer."Name 2");
            SchedulerEvent."Background Color" := Customer."BIT Hex Color";
            SchedulerEvent.Duration := 8 * 60 * 60; // Default 8 hours
            SchedulerEvent.Insert();
        until Customer.Next() = 0;
end;
```

### Drag-and-Drop from Queue

When dragging customers from the unscheduled queue:

```al
case EventID.TableNo of
    Database::"Customer":
        begin
            Customer.Get(EventID);
            EmployeePlanning."Customer No." := Customer."No.";
            Employee.Get(ResourceId);
            EmployeePlanning."Employee No." := Employee."No.";
            EmployeePlanning."From Date" := StartDateTime;
            EmployeePlanning."To Date" := EndDateTime;
            EmployeePlanning.Insert(true);
        end;
end;
```

## Security and Permissions

### Permission Management

The system includes built-in permission checks:

```al
local procedure CanSchedule(ResourceId: RecordId): Boolean
begin
    exit(true); // Simplified - implement your security logic
end;

procedure IsAdmin(): Boolean
begin
    exit(true); // Simplified - implement your admin logic
end;
```

### Privacy Protection

Employee privacy is protected:
```al
trigger OnValidate() // Employee No. field
begin
    Employee.Get("Employee No.");
    if Employee."Privacy Blocked" then
        Error('You cannot plan because the employee is blocked due to privacy.');
end;
```

## Configuration and Setup

### Application Metadata

From [`app.json`](app.json:1):
- **App ID**: 76d5e7f6-a494-4250-a90f-cdda271a4d40
- **Publisher**: BEYONDIT GmbH
- **Version**: 2025.5.0.0
- **Object Range**: 50321-50340

### Localization Support

The extension supports multiple languages:
- German (de-DE)
- English (en-US)

Translation files are located in the [`Translations/`](Translations/) folder.

## Business Logic Features

### Capacity Planning

The system provides sophisticated capacity planning:

#### Available Capacity Calculation
```al
local procedure GetCapacity(StartDate: Date; EndDate: Date) Qty: Decimal
var
    CalendarMgmt: Codeunit "Calendar Management";
    FreeDay: Boolean;
    TempDate: Date;
begin
    repeat
        FreeDay := CalendarMgmt.IsNonworkingDay(TempDate, CustomizedCalendarChange);
        if not FreeDay then
            qty += 8; // 8 hours per working day
        TempDate += 1;
    until TempDate > EndDate;
end;
```

#### Planned Hours Calculation
The system calculates planned hours considering:
- Working days only (excludes weekends and holidays)
- Proportional allocation for multi-day entries
- Base calendar integration

### Event Interaction

#### Time Range Clicks
When users click on empty time slots:

```al
procedure OnTimeRangeClicked(StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId): Record "BYD SDL Scheduler Event"
begin
    // Create temporary planning entry
    TempEmployeePlanning.Init();
    TempEmployeePlanning."Employee No." := Employee."No.";
    TempEmployeePlanning."From Date" := StartDateTime;
    TempEmployeePlanning."To Date" := EndDateTime;
    
    // Open planning card for user input
    if EmployeePlanningCard.RunModal() = Action::LookupOK then begin
        // Create actual planning entry
        EmployeePlanning.Insert(true);
    end;
end;
```

#### Event Editing
Double-clicking events opens the planning card:

```al
procedure OnEventClicked(EventID: RecordId)
begin
    if EmployeePlanning.Get(EventID) then begin
        EmployeePlanningCard.SetRec(EmployeePlanning);
        if EmployeePlanningCard.RunModal() = Action::LookupOK then begin
            // Update planning entry with changes
            EmployeePlanning.Modify();
        end;
    end;
end;
```

## Integration Points

### Employee Master Data
- Links to standard Employee table
- Respects employee status (Active only)
- Honors privacy blocking settings

### Customer Master Data
- Extends Customer table with scheduling fields
- Uses customer names and numbers for display
- Supports customer-specific color coding

### Calendar Integration
- Integrates with Business Central base calendar
- Respects company working days
- Excludes holidays and non-working days

## Best Practices

### Performance Optimization
1. **Efficient Filtering**: Use date range filters in [`OnLoadEvents`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:12)
2. **SetLoadFields**: Minimize data transfer for large employee lists
3. **Temporary Tables**: Use temporary records for UI operations

### Data Integrity
1. **Validation**: Implement proper field validation
2. **Error Handling**: Provide user-friendly error messages
3. **Transaction Management**: Use proper commit/rollback patterns

### User Experience
1. **Visual Feedback**: Use customer colors for easy identification
2. **Intuitive Operations**: Support standard drag-and-drop patterns
3. **Responsive Design**: Ensure scheduler works on different screen sizes

## Troubleshooting

### Common Issues

#### Events Not Displaying
- Verify date range filtering in [`OnLoadEvents`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:16-17)
- Check that employees have Status = Active
- Ensure planning entries exist in the date range

#### Drag-and-Drop Not Working
- Verify permission settings in [`CanSchedule`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:366)
- Check that move/resize interfaces are properly implemented
- Ensure employee is not privacy blocked

#### Unscheduled Customers Not Showing
- Verify customers have "BIT Schedule to Planning Board" = true
- Check customer blocking status
- Ensure [`OnLoadUnScheduledEvents`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:130) is implemented

### Debugging Tips
1. Use AL debugger to trace event generation
2. Check temporary table contents in scheduler events
3. Verify RecordId consistency between operations
4. Monitor database locks during drag operations

## Extension and Customization

### Adding Custom Fields
To extend the planning functionality:

1. Add fields to [`BIT Employee Planning`](src/SchedulerInterface/EmployeePlanning.Table.al:1) table
2. Update [`GenerateEvent`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:327) procedure
3. Modify [`Employee Planning Card`](src/User/EmployeePlanningCard.Page.al:1) page layout

### Custom Business Logic
Implement custom validation in:
- [`CanSchedule`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:366): Resource-specific permissions
- [`IsAdmin`](src/SchedulerInterface/EMPPlanningScheduler.Codeunit.al:361): Administrative privileges
- Table triggers: Data validation and business rules

### Integration with Other Modules
The scheduler can be extended to integrate with:
- Project Management
- Service Management
- Manufacturing
- Time Sheet Management

## Conclusion

The Employee Scheduler provides a comprehensive solution for visual employee planning in Business Central. Its integration with the BeyondScheduler framework ensures a modern, intuitive user experience while maintaining the flexibility to adapt to specific business requirements.

The modular architecture allows for easy customization and extension, making it suitable for various industries and organizational structures. The built-in capacity planning and calendar integration provide the foundation for effective resource management and planning optimization.