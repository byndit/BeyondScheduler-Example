# BeyondScheduler Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Components](#core-components)
4. [Implementation Steps](#implementation-steps)
5. [Interface Implementations](#interface-implementations)
6. [Data Model](#data-model)
7. [Frontend Integration](#frontend-integration)
8. [Configuration](#configuration)
9. [Customization](#customization)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)

## Overview

The BeyondScheduler is a comprehensive scheduling solution for Microsoft Dynamics 365 Business Central that provides a visual interface for managing events, resources, and time allocation. It consists of a drag-and-drop scheduler with unscheduled events sidebar, resource management, and extensive customization capabilities.

### Key Features
- **Visual Scheduling**: Drag-and-drop interface for scheduling events
- **Resource Management**: Assign events to resources based on date and time
- **Unscheduled Events**: Side panel showing events that need to be scheduled
- **Multiple Views**: Different scales and viewports (day, week, month)
- **Event Operations**: Move, resize, copy, and delete events
- **Filtering**: Advanced filtering for both scheduled and unscheduled events
- **Business Rules**: Support for business times, blocked times, and special days
- **Context Actions**: Custom actions for events and time ranges
- **Dependency Links**: Visual connections between related events

## Architecture

The scheduler follows a modular, interface-based architecture that promotes extensibility and maintainability:

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (Control AddIn)                 │
│                    JavaScript + HTML + CSS                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Scheduler Page                           │
│              (BYD SDL Scheduler.Page.al)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Interface Layer                          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐  │
│  │ IScheduler Core │ │ IScheduler      │ │ IScheduler    │  │
│  │                 │ │ Filters         │ │ Events        │  │
│  └─────────────────┘ └─────────────────┘ └───────────────┘  │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐  │
│  │ IScheduler      │ │ IScheduler      │ │ Entity        │  │
│  │ Business Times  │ │ Special Times   │ │ Interface     │  │
│  └─────────────────┘ └─────────────────┘ └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Implementation Layer                        │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐  │
│  │ Service         │ │ Custom Entity   │ │ Business      │  │
│  │ Scheduler       │ │ Implementation  │ │ Logic         │  │
│  └─────────────────┘ └─────────────────┘ └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐  │
│  │ Scheduler Event │ │ Scheduler       │ │ Filter        │  │
│  │ (Temporary)     │ │ Resource        │ │ Setup         │  │
│  └─────────────────┘ └─────────────────┘ └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Scheduler Page ([`Scheduler.Page.al`](/Pages/Scheduler.Page.al))
The main page that hosts the scheduler control and handles all user interactions through triggers:

- **OnControlReady**: Initializes the scheduler
- **OnLoadEvents**: Loads scheduled events for a date range
- **OnLoadResources**: Loads available resources
- **OnLoadUnassignedEvents**: Loads unscheduled events
- **OnEventMove/Resize/Delete**: Handles event modifications
- **OnEventClicked**: Handles event selection
- **OnTimeRangeClicked**: Handles empty time slot clicks

### 2. Interface Layer
A comprehensive set of interfaces that define the contract for scheduler functionality:

#### Core Interfaces
- **[`ISchedulerCore`](/Interfaces/ISchedulerCore.Interface.al)**: Essential scheduler operations
  - `OnInit(Scheduler: ControlAddIn)`
  - `OnLoadEvents(StartDateTime, EndDateTime, Resources, var SchedulerEvent)`
  - `OnLoadResources(var SchedulerResource)`
- **[`ISchedulerFilters`](/Interfaces/ISchedulerFilters.Interface.al)**: Filter management
  - `GetFilters(var Filters)`
  - `SetSelectedFilter(FilterKey)`
- **[`ISchedulerUnscheduledEvents`](/Interfaces/ISchedulerUnscheduledEvents.Interface.al)**: Unscheduled events handling
  - `OnLoadUnscheduledEvents(var SchedulerEvent)`
- **[`ISchedulerUnscheduledEventFilters`](/Interfaces/ISchedulerUnscheduledEventFilters.Interface.al)**: Unscheduled event filters
  - `GetUnscheduledFilters(var Filters)`
  - `SetSelectedUnscheduledFilter(FilterKey)`
- **[`ISchedulerTranslations`](/Interfaces/ISchedulerTranslations.Interface.al)**: Translation management
  - `GetTranslations(var Translations: JsonObject)`

#### Event Handling Interfaces
- **[`ISchedulerClickEvent`](/Interfaces/ISchedulerClickEvent.Interface.al)**: Event click handling
  - `OnEventClicked(EventId)`
- **[`ISchedulerMoveEvent`](/Interfaces/ISchedulerMoveEvent.Interface.al)**: Event movement
  - `OnEventMove(EventID, StartDateTime, EndDateTime, ResourceId): SchedulerEvent`
- **[`ISchedulerResizeEvent`](/Interfaces/ISchedulerResizeEvent.Interface.al)**: Event resizing
  - `OnEventResize(EventID, StartDateTime, EndDateTime): SchedulerEvent`
- **[`ISchedulerDeleteEvent`](/Interfaces/ISchedulerDeleteEvent.Interface.al)**: Event deletion
  - `OnEventDelete(EventID): Boolean`
- **[`ISchedulerClickTimeRange`](/Interfaces/ISchedulerClickTimeRange.Interface.al)**: Time range click handling
  - `OnTimeRangeClicked(StartDateTime, EndDateTime, ResourceId): SchedulerEvent`

#### Business Logic Interfaces
- **[`ISchedulerBusinessTimes`](src/Core/BusinessTimes/ISchedulerBusinessTimes.Interface.al)**: Business hours configuration
  - `OnLoadBusinessTimes(var ShowNonBusinessDaysAndWeekends, var BusinessDayStartsAt, var BusinessDayEndsAt, var BusinessWeekends)`
- **[`ISchedulerBlockedTimes`](src/Core/BlockedTimes/ISchedulerBlockedTimes.Interface.al)**: Blocked time periods (⚠️ Obsolete - replaced by Special Times)
  - `OnLoadBlockTimes(StartDateTime, EndDateTime, Resources, var SchedulerBlockedTime)`
- **[`ISchedulerSpecialTimes`](src/Core/SpecialTime/ISchedulerSpecialTimes.Interface.al)**: Special time handling
  - `OnLoadSpecialTimes(StartDateTime, EndDateTime, Resources, var SchedulerSpecialTime)`
- **[`ISchedulerSpecialDays`](src/Core/SpecialDay/ISchedulerSpecialDays.Interface.al)**: Special day handling
  - `OnLoadSpecialDays(StartDateTime, EndDateTime, var SchedulerSpecialDay)`
- **[`ISchedulerScaleHeaders`](src/Core/Scale/ISchedulerScaleHeaders.Interface.al)**: Custom scale headers
  - `GetScaleHeaders(var ScaleConfig): JsonArray`

#### Context Action Interfaces
- **[`BYD SDL Context Actions`](src/Core/ContextAction/ContextActions.Interface.al)**: Event context actions
  - `OnLoadContextActions(var ContextAction)`
  - `OnContextActionClicked(ActionId, EventId, var SchedulerEvent, var ActionToBePerformed)`
- **[`BYD SDL Time R. Cont. Actions`](src/Core/TimeRangeContextAction/TimeRContActions.Interface.al)**: Time range context actions
  - `OnLoadTimeRangeContextActions(var TimeRangeContextAction)`
  - `OnTimeRangeContextActionClicked(ActionId, StartDateTime, EndDateTime, ResourceId, var SchedulerEvent, var ActionToBePerformed)`

#### Copy Event Interface
- **[`BYD SDL Copy Event`](src/Core/CopyEvent/CopyEvent.Interface.al)**: Event copying functionality
  - `OnEventCopy(EventID, StartDateTime, EndDateTime, ResourceId): SchedulerEvent`

#### Entity and Configuration Interfaces
- **[`BYD SDL Entity`](src/Core/Entity/Entity.Interface.al)**: Entity behavior definition
  - `OnLoadEvents(StartingDateTime, EndingDateTime, Resources, var SchedulerEvent)`
  - `OnEventClicked(EventId)`
  - `OnEventMove(EventID, StartDateTime, EndDateTime, ResourceId, var SchedulerEvent)`
  - `OnEventResize(EventID, StartDateTime, EndDateTime, var SchedulerEvent)`
  - `OnTimeRangeClicked(StartDateTime, EndDateTime, ResourceId, var SchedulerEvent)`
  - `OnEventCopy(EventID, StartDateTime, EndDateTime, ResourceId, var SchedulerEvent)`
- **[`BYD SDL Config`](src/Core/Entity/Config.Interface.al)**: Configuration management
  - `GetEntities(): List of [Enum "BYD SDL Entity"]`
- **[`BYD SDL Dependency Links`](src/Core/DependencyLinks/DependencyLinks.Interface.al)**: Dependency link management
  - `OnLoadDependencyLinks()`

#### Legacy Interfaces (Obsolete)
- **[`BYD SDL IScheduler`](/Interfaces/IScheduler.Interface.al)**: ⚠️ Obsolete (v21.5) - Split into multiple interfaces
- **[`BYD SDL IUnassignedEventsFilter`](/Interfaces/IUnassignedEventsFilter.Interface.al)**: ⚠️ Obsolete (v21.5) - Split for extensibility

### 3. Entity System
The entity system provides a flexible way to handle different types of schedulable objects:

- **[`Entity.Interface`](src/Core/Entity/Entity.Interface.al)**: Defines entity behavior
- **[`Entity.Enum`](src/Core/Entity/Entity.Enum.al)**: Available entity types
- **[`Config.Interface`](src/Core/Entity/Config.Interface.al)**: Configuration management

## Implementation Steps

### Step 1: Set Up the Basic Structure

1. **Create the Scheduler Page**
   ```al
   page 50000 "My Scheduler"
   {
       PageType = Card;
       ApplicationArea = All;
       
       layout
       {
           area(Content)
           {
               usercontrol(Scheduler; "BYD SDL Scheduler")
               {
                   ApplicationArea = All;
                   // Add all required triggers
               }
           }
       }
   }
   ```

2. **Implement Core Interface**
   ```al
   codeunit 50000 "My Scheduler Implementation" implements "BYD SDL IScheduler Core"
   {
       procedure OnInit(Scheduler: ControlAddIn "BYD SDL Scheduler")
       begin
           // Initialize your scheduler
       end;
       
       procedure OnLoadEvents(StartDateTime: DateTime; EndDateTime: DateTime; Resources: List of [RecordId]; var SchedulerEvent: Record "BYD SDL Scheduler Event")
       begin
           // Load your events into the SchedulerEvent temporary table
       end;
       
       procedure OnLoadResources(var SchedulerResource: Record "BYD SDL Scheduler Resource")
       begin
           // Load your resources into the SchedulerResource temporary table
       end;
   }
   ```

### Step 2: Configure the Scheduler Page

In your scheduler page, set up the interface implementations:

```al
trigger OnOpenPage()
var
    MyImplementation: Codeunit "My Scheduler Implementation";
begin
    CurrPage.Scheduler.SetInterfaceCore(MyImplementation);
    // Set other interfaces as needed
end;
```

### Step 3: Implement Event Handling

```al
codeunit 50001 "My Event Handler" implements "BYD SDL IScheduler Move Event", "BYD SDL IScheduler Resize Event"
{
    procedure OnEventMove(EventID: RecordId; StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId): Record "BYD SDL Scheduler Event"
    var
        SchedulerEvent: Record "BYD SDL Scheduler Event";
        MyRecord: Record "My Table";
    begin
        // Get the original record
        MyRecord.Get(EventID);
        
        // Update the record with new times/resource
        MyRecord."Start DateTime" := StartDateTime;
        MyRecord."End DateTime" := EndDateTime;
        MyRecord."Resource ID" := ResourceId;
        MyRecord.Modify();
        
        // Return updated scheduler event
        GenerateSchedulerEvent(SchedulerEvent, MyRecord);
        exit(SchedulerEvent);
    end;
    
    procedure OnEventResize(EventID: RecordId; StartDateTime: DateTime; EndDateTime: DateTime): Record "BYD SDL Scheduler Event"
    begin
        // Similar implementation for resizing
    end;
}
```

### Step 4: Set Up Data Sources

#### For Scheduled Events
**Interface**: `"BYD SDL IScheduler Core"`
```al
procedure OnLoadEvents(StartDateTime: DateTime; EndDateTime: DateTime; Resources: List of [RecordId]; var SchedulerEvent: Record "BYD SDL Scheduler Event")
var
    MyEventTable: Record "My Event Table";
    ResourceRecId: RecordId;
begin
    // Filter by date range
    MyEventTable.SetRange("Start DateTime", StartDateTime, EndDateTime);
    
    // Filter by resources if specified
    if Resources.Count > 0 then begin
        MyEventTable.SetFilter("Resource ID", GetResourceFilter(Resources));
    end;
    
    if MyEventTable.FindSet() then
        repeat
            SchedulerEvent.Init();
            SchedulerEvent.ID := MyEventTable.RecordId();
            SchedulerEvent."Resource ID" := MyEventTable."Resource ID";
            SchedulerEvent."Starting Date-Time" := MyEventTable."Start DateTime";
            SchedulerEvent."Ending Date-Time" := MyEventTable."End DateTime";
            SchedulerEvent.Text := MyEventTable.Description;
            SchedulerEvent."Background Color" := GetEventColor(MyEventTable);
            SchedulerEvent.Insert();
        until MyEventTable.Next() = 0;
end;
```

#### For Unscheduled Events
**Interface**: `"BYD SDL IScheduler Unscheduled Events"`
```al
procedure OnLoadUnscheduledEvents(var SchedulerEvent: Record "BYD SDL Scheduler Event")
var
    UnscheduledTable: Record "My Unscheduled Table";
begin
    UnscheduledTable.SetRange(Scheduled, false);
    
    if UnscheduledTable.FindSet() then
        repeat
            SchedulerEvent.Init();
            SchedulerEvent.ID := UnscheduledTable.RecordId();
            SchedulerEvent.Text := UnscheduledTable.Description;
            SchedulerEvent."Background Color" := GetEventColor(UnscheduledTable);
            SchedulerEvent.Insert();
        until UnscheduledTable.Next() = 0;
end;
```

## Interface Implementations

### Required Interfaces

#### 1. IScheduler Core (Mandatory)
**Interface**: `"BYD SDL IScheduler Core"`
```al
interface "BYD SDL IScheduler Core"
{
    procedure OnInit(Scheduler: ControlAddIn "BYD SDL Scheduler");
    procedure OnLoadEvents(StartDateTime: DateTime; EndDateTime: DateTime; Resources: List of [RecordId]; var SchedulerEvent: Record "BYD SDL Scheduler Event");
    procedure OnLoadResources(var SchedulerResource: Record "BYD SDL Scheduler Resource");
}
```

#### 2. IScheduler Filters (Optional)
**Interface**: `"BYD SDL IScheduler Filters"`
```al
interface "BYD SDL IScheduler Filters"
{
    procedure GetFilters(var Filters: Record "BYD SDL Scheduler Filter");
    procedure SetSelectedFilter(FilterKey: Text);
}
```

#### 3. IScheduler Unscheduled Events (Optional)
**Interface**: `"BYD SDL IScheduler Unscheduled Events"`
```al
interface "BYD SDL IScheduler Unscheduled Events"
{
    procedure OnLoadUnscheduledEvents(var SchedulerEvent: Record "BYD SDL Scheduler Event");
}
```

#### 4. IScheduler Unscheduled Event Filters (Optional)
**Interface**: `"BYD SDL IScheduler Unscheduled Event Filters"`
```al
interface "BYD SDL IScheduler Unscheduled Event Filters"
{
    procedure GetUnscheduledFilters(var Filters: Record "BYD SDL Scheduler Filter");
    procedure SetSelectedUnscheduledFilter(FilterKey: Text);
}
```

### Event Handling Interfaces

#### Move Events
**Interface**: `"BYD SDL IScheduler Move Event"`
```al
procedure OnEventMove(EventID: RecordId; StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId): Record "BYD SDL Scheduler Event"
var
    SchedulerEvent: Record "BYD SDL Scheduler Event";
    SourceRecord: Record "Your Source Table";
begin
    // 1. Validate the move operation
    ValidateEventMove(EventID, StartDateTime, EndDateTime, ResourceId);
    
    // 2. Update the source record
    SourceRecord.Get(EventID);
    SourceRecord."Start DateTime" := StartDateTime;
    SourceRecord."End DateTime" := EndDateTime;
    SourceRecord."Resource No." := GetResourceNo(ResourceId);
    SourceRecord.Modify(true);
    
    // 3. Generate and return the updated scheduler event
    GenerateSchedulerEvent(SchedulerEvent, SourceRecord);
    exit(SchedulerEvent);
end;
```

#### Click Events
**Interface**: `"BYD SDL IScheduler Click Event"`
```al
procedure OnEventClicked(EventId: RecordId)
var
    SourceRecord: Record "Your Source Table";
begin
    if SourceRecord.Get(EventId) then
        PAGE.Run(PAGE::"Your Detail Page", SourceRecord);
end;
```

#### Time Range Clicks
**Interface**: `"BYD SDL IScheduler Click TimeRange"`
```al
procedure OnTimeRangeClicked(StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId): Record "BYD SDL Scheduler Event"
var
    SchedulerEvent: Record "BYD SDL Scheduler Event";
    NewRecord: Record "Your Source Table";
begin
    // Create a new record for the time slot
    NewRecord.Init();
    NewRecord."Start DateTime" := StartDateTime;
    NewRecord."End DateTime" := EndDateTime;
    NewRecord."Resource No." := GetResourceNo(ResourceId);
    NewRecord.Insert(true);
    
    // Generate scheduler event for the new record
    GenerateSchedulerEvent(SchedulerEvent, NewRecord);
    exit(SchedulerEvent);
end;
```

## Data Model

### Core Tables

#### 1. Scheduler Event (Temporary Table)
```al
table 70838689 "BYD SDL Scheduler Event"
{
    TableType = Temporary;
    
    fields
    {
        field(1; ID; RecordId) { }                          // Unique identifier (RecordId of source)
        field(10; "Resource ID"; RecordId) { }              // Resource assignment
        field(11; "Starting Date-Time"; DateTime) { }       // Event start time
        field(12; "Ending Date-Time"; DateTime) { }         // Event end time
        field(13; "Text"; Text[100]) { }                    // Main display text
        field(15; "Bar Color"; Text[100]) { }               // Event bar color (hex)
        field(16; "Background Color"; Text[100]) { }        // Event background color (hex)
        field(17; "Additional Text 1"; Text[100]) { }       // Additional display text
        field(18; "Additional Text 2"; Text[100]) { }       // Additional display text
        field(19; "Additional Text 3"; Text[100]) { }       // Additional display text
    }
}
```

#### 2. Scheduler Resource (Temporary Table)
```al
table 70838690 "BYD SDL Scheduler Resource"
{
    TableType = Temporary;
    
    fields
    {
        field(1; ID; RecordId) { }                          // Resource RecordId
        field(10; Name; Text[100]) { }                      // Resource display name
        field(11; "Parent ID"; RecordId) { }                // For hierarchical resources
        field(12; "Sorting No."; Integer) { }               // Display order
    }
}
```

### Configuration Tables

#### Filter Setup
```al
table 50000 "My Filter Setup"
{
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[100]) { }
        field(10; "Resource Filter"; Text[250]) { }          // TableView filter for resources
        field(11; "Event Filter"; Text[250]) { }             // TableView filter for events
    }
}
```

## Frontend Integration

### Control AddIn Structure
The scheduler uses a JavaScript-based control add-in with the following structure:

```
/Scheduler.ControlAddIn.al
├── index.html                 // Main HTML structure
├── css/
│   └── scheduler.css          // Styling
└── js/
    ├── main.js               // Core scheduler logic
    ├── events.js             // Event handling
    └── utils.js              // Utility functions
```

### Key JavaScript Methods
```javascript
// Initialize the scheduler
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnControlReady', [controlId]);

// Load events for date range
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnLoadEvents', [
    controlId, 
    startDateTime, 
    endDateTime, 
    resourcesArray,
    selectedFilter
]);

// Handle event operations
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnEventMove', [
    controlId,
    eventId,
    newStartDateTime,
    newEndDateTime,
    newResourceId
]);
```

## Configuration

### Core Setup
Configure the scheduler through the Core Setup table:

```al
table 70838691 "BYD SDL Core Setup"
{
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(10; "Entity for Time Range Click"; Enum "BYD SDL Entity") { }
        field(20; "Show Dependency Links"; Boolean) { }
        field(30; "BYD SDL Table No. Line 1"; Integer) { }   // Custom field mapping
        field(31; "BYD SDL Field No. Line 1"; Integer) { }
        // Additional field mappings...
    }
}
```

### Business Times Configuration
**Interface**: `"BYD SDL IScheduler Business Times"`
```al
procedure OnLoadBusinessTimes(var ShowNonBusinessDaysAndWeekends: Boolean; var BusinessDayStartsAt: Integer; var BusinessDayEndsAt: Integer; var BusinessWeekends: Boolean)
begin
    ShowNonBusinessDaysAndWeekends := true;
    BusinessDayStartsAt := 8;  // 8 AM
    BusinessDayEndsAt := 17;   // 5 PM
    BusinessWeekends := false;
end;
```

### Special Times and Blocked Times
**Interface**: `"BYD SDL IScheduler Blocked Times"`
```al
procedure OnLoadBlockTimes(StartDateTime: DateTime; EndDateTime: DateTime; Resources: List of [RecordId]; var SchedulerBlockedTime: Record "BYD SDL Scheduler Blocked Time")
var
    Holiday: Record "Base Calendar Change";
begin
    // Load holidays and blocked periods
    Holiday.SetRange(Date, DT2Date(StartDateTime), DT2Date(EndDateTime));
    if Holiday.FindSet() then
        repeat
            SchedulerBlockedTime.Init();
            SchedulerBlockedTime."Starting Date-Time" := CreateDateTime(Holiday.Date, 0T);
            SchedulerBlockedTime."Ending Date-Time" := CreateDateTime(Holiday.Date, 235959T);
            SchedulerBlockedTime.Description := Holiday.Description;
            SchedulerBlockedTime.Insert();
        until Holiday.Next() = 0;
end;
```

## Customization

### Custom Entity Implementation
Create your own entity to handle specific business objects:

**Interface**: `"BYD SDL Entity"`
```al
codeunit 50010 "My Custom Entity" implements "BYD SDL Entity"
{
    procedure OnLoadEvents(StartingDateTime: DateTime; EndingDateTime: DateTime; Resources: List of [RecordId]; var SchedulerEvent: Record "BYD SDL Scheduler Event")
    begin
        LoadMyCustomEvents(StartingDateTime, EndingDateTime, Resources, SchedulerEvent);
    end;
    
    procedure OnEventClicked(EventId: RecordId)
    var
        MyRecord: Record "My Custom Table";
    begin
        if MyRecord.Get(EventId) then
            PAGE.Run(PAGE::"My Custom Card", MyRecord);
    end;
    
    procedure OnEventMove(EventID: RecordId; StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId; var SchedulerEvent: Record "BYD SDL Scheduler Event")
    begin
        // Handle move operation for your custom entity
    end;
    
    // Implement other required procedures...
}
```

### Context Actions
Add custom actions to events and time ranges:

**Interface**: `"BYD SDL Context Actions"`
```al
procedure OnLoadContextActions(var ContextAction: Record "BYD SDL Context Action")
begin
    ContextAction.Init();
    ContextAction.ID := 'COMPLETE';
    ContextAction.Caption := 'Mark Complete';
    ContextAction.Icon := 'check';
    ContextAction."Sorting No." := 10;
    ContextAction.Insert();
    
    ContextAction.Init();
    ContextAction.ID := 'CANCEL';
    ContextAction.Caption := 'Cancel';
    ContextAction.Icon := 'times';
    ContextAction."Sorting No." := 20;
    ContextAction.Insert();
end;

**Interface**: `"BYD SDL Context Actions"`
```al
procedure OnContextActionClicked(ActionId: Text; EventId: Text; var SchedulerEvent: Record "BYD SDL Scheduler Event"; var ActionToBePerformed: Text)
var
    MyRecord: Record "My Table";
begin
    MyRecord.Get(EventId);
    
    case ActionId of
        'COMPLETE':
            begin
                MyRecord.Status := MyRecord.Status::Completed;
                MyRecord.Modify();
                ActionToBePerformed := 'refresh';
            end;
        'CANCEL':
            begin
                MyRecord.Status := MyRecord.Status::Cancelled;
                MyRecord.Modify();
                ActionToBePerformed := 'delete';
            end;
    end;
    
    GenerateSchedulerEvent(SchedulerEvent, MyRecord);
end;
```

### Color Coding
Implement dynamic color coding for events:

```al
local procedure GetEventColor(MyRecord: Record "My Table"): Text[100]
begin
    case MyRecord.Priority of
        MyRecord.Priority::High:
            exit('#FF0000');    // Red
        MyRecord.Priority::Medium:
            exit('#FFA500');    // Orange
        MyRecord.Priority::Low:
            exit('#008000');    // Green
        else
            exit('#0078D4');    // Default blue
    end;
end;
```

## Best Practices

### 1. Performance Optimization
- **Use SetLoadFields**: Only load required fields when querying data
- **Implement Proper Filtering**: Use efficient filters in OnLoadEvents
- **Batch Operations**: Process multiple events together when possible
- **Temporary Tables**: Use temporary tables for scheduler data transfer

```al
procedure OnLoadEvents(StartDateTime: DateTime; EndDateTime: DateTime; Resources: List of [RecordId]; var SchedulerEvent: Record "BYD SDL Scheduler Event")
var
    MyEventTable: Record "My Event Table";
begin
    // Use SetLoadFields for performance
    MyEventTable.SetLoadFields("Start DateTime", "End DateTime", "Resource No.", Description, Priority);
    
    // Efficient date filtering
    MyEventTable.SetRange("Start DateTime", StartDateTime, EndDateTime);
    
    // Process in batches if needed
    if MyEventTable.FindSet() then
        repeat
            GenerateSchedulerEvent(SchedulerEvent, MyEventTable);
        until MyEventTable.Next() = 0;
end;
```

### 2. Error Handling
- **Validate Operations**: Always validate before modifying data
- **User-Friendly Messages**: Provide clear error messages
- **Rollback on Failure**: Use transactions for complex operations

```al
procedure OnEventMove(EventID: RecordId; StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId): Record "BYD SDL Scheduler Event"
var
    SchedulerEvent: Record "BYD SDL Scheduler Event";
    MyRecord: Record "My Table";
begin
    if not MyRecord.Get(EventID) then
        Error('Event not found.');
    
    // Validate the move
    if StartDateTime >= EndDateTime then
        Error('Start time must be before end time.');
    
    if not ValidateResourceAvailability(ResourceId, StartDateTime, EndDateTime) then
        Error('Resource is not available during this time.');
    
    // Perform the move
    MyRecord."Start DateTime" := StartDateTime;
    MyRecord."End DateTime" := EndDateTime;
    MyRecord."Resource No." := GetResourceNo(ResourceId);
    MyRecord.Modify(true);
    
    GenerateSchedulerEvent(SchedulerEvent, MyRecord);
    exit(SchedulerEvent);
end;
```

### 3. Extensibility
- **Use Interfaces**: Implement all relevant interfaces for full functionality
- **Business Events**: Publish business events for extensibility
- **Configuration**: Make behavior configurable through setup tables

```al
[BusinessEvent(false)]
local procedure OnBeforeEventMove(var MyRecord: Record "My Table"; StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId; var IsHandled: Boolean)
begin
end;

[BusinessEvent(false)]
local procedure OnAfterEventMove(MyRecord: Record "My Table")
begin
end;
```

### 4. User Experience
- **Consistent Colors**: Use consistent color schemes
- **Meaningful Text**: Display relevant information in event text
- **Responsive Design**: Ensure the scheduler works on different screen sizes

## Troubleshooting

### Common Issues

#### 1. Events Not Loading
**Problem**: Events don't appear in the scheduler
**Solutions**:
- Check that `OnLoadEvents` is properly implemented
- Verify date range filtering
- Ensure `SchedulerEvent.Insert()` is called
- Check that the Core interface is set

#### 2. Drag and Drop Not Working
**Problem**: Cannot move or resize events
**Solutions**:
- Implement `IScheduler Move Event` and `IScheduler Resize Event` interfaces
- Set the interfaces in the page's `OnOpenPage` trigger
- Check for validation errors in move/resize procedures

#### 3. Resources Not Showing
**Problem**: Resource list is empty
**Solutions**:
- Implement `OnLoadResources` in the Core interface
- Ensure resources are properly inserted into `SchedulerResource`
- Check resource filtering logic

#### 4. Performance Issues
**Problem**: Scheduler loads slowly
**Solutions**:
- Optimize database queries with proper filtering
- Use `SetLoadFields` to limit field loading
- Implement efficient date range filtering
- Consider pagination for large datasets

### Debugging Tips

1. **Use Temporary Tables**: The scheduler uses temporary tables - data won't persist
2. **Check Interface Implementation**: Ensure all required interfaces are implemented and set
3. **Validate JSON**: Check that JSON generation doesn't fail
4. **Test Date Ranges**: Verify that date/time conversions work correctly
5. **Monitor Performance**: Use the AL profiler to identify bottlenecks

### Logging and Diagnostics

```al
local procedure LogSchedulerOperation(Operation: Text; EventId: RecordId; Success: Boolean)
var
    ActivityLog: Record "Activity Log";
begin
    ActivityLog.LogActivity(
        EventId,
        ActivityLog.Status::Success,
        'SCHEDULER',
        Operation,
        StrSubstNo('Scheduler operation: %1', Operation)
    );
end;
```

## Advanced Features

### Dependency Links
Create visual connections between related events:

```al
procedure SaveDependencyLink(FromEventId: RecordId; ToEventId: RecordId)
var
    DependencyLinks: Record "BYD SDL Dependency Links";
begin
    DependencyLinks.Init();
    DependencyLinks.From := FromEventId;
    DependencyLinks."To" := ToEventId;
    DependencyLinks.Insert();
end;
```

### Copy Events
Implement event copying functionality:

**Interface**: `"BYD SDL Copy Event"`
```al
procedure OnEventCopy(EventID: RecordId; StartDateTime: DateTime; EndDateTime: DateTime; ResourceId: RecordId): Record "BYD SDL Scheduler Event"
var
    SchedulerEvent: Record "BYD SDL Scheduler Event";
    OriginalRecord: Record "My Table";
    NewRecord: Record "My Table";
begin
    OriginalRecord.Get(EventID);
    
    NewRecord := OriginalRecord;
    NewRecord."Start DateTime" := StartDateTime;
    NewRecord."End DateTime" := EndDateTime;
    NewRecord."Resource No." := GetResourceNo(ResourceId);
    NewRecord.Insert(true);
    
    GenerateSchedulerEvent(SchedulerEvent, NewRecord);
    exit(SchedulerEvent);
end;
```

### Multi-Entity Support
Support multiple entity types in one scheduler:

**Interface**: `"BYD SDL Config"`
```al
local procedure GetConfig(): Interface "BYD SDL Config"
var
    CoreSetup: Record "BYD SDL Core Setup";
    Config: Interface "BYD SDL Config";
begin
    CoreSetup.Get();
    Config := CoreSetup.Config;
    exit(Config);
end;

**Interface**: `"BYD SDL IScheduler Core"` (delegating to entities)
```al
procedure OnLoadEvents(StartingDateTime: DateTime; EndingDateTime: DateTime; Resources: List of [RecordId]; var SchedulerEvent: Record "BYD SDL Scheduler Event")
var
    Entity: Interface "BYD SDL Entity";
begin
    foreach Entity in GetConfig().GetEntities() do
        Entity.OnLoadEvents(StartingDateTime, EndingDateTime, Resources, SchedulerEvent);
end;
```

This comprehensive guide provides everything needed to implement your own scheduler using the BeyondScheduler framework. The modular architecture allows for extensive customization while maintaining a consistent user experience.
## Complete Interface Reference

### Interface-to-Procedure Mapping

| Interface | Procedure | Parameters | Return Type | Description |
|-----------|-----------|------------|-------------|-------------|
| **BYD SDL IScheduler Core** | `OnInit` | `Scheduler: ControlAddIn` | void | Initialize scheduler |
| | `OnLoadEvents` | `StartDateTime, EndDateTime, Resources, var SchedulerEvent` | void | Load scheduled events |
| | `OnLoadResources` | `var SchedulerResource` | void | Load available resources |
| **BYD SDL IScheduler Filters** | `GetFilters` | `var Filters` | void | Get available filters |
| | `SetSelectedFilter` | `FilterKey: Text` | void | Set active filter |
| **BYD SDL IScheduler Unscheduled Events** | `OnLoadUnscheduledEvents` | `var SchedulerEvent` | void | Load unscheduled events |
| **BYD SDL IScheduler Unscheduled Event Filters** | `GetUnscheduledFilters` | `var Filters` | void | Get unscheduled filters |
| | `SetSelectedUnscheduledFilter` | `FilterKey: Text` | void | Set unscheduled filter |
| **BYD SDL IScheduler Translations** | `GetTranslations` | `var Translations: JsonObject` | void | Get UI translations |
| **BYD SDL IScheduler Click Event** | `OnEventClicked` | `EventId: RecordId` | void | Handle event clicks |
| **BYD SDL IScheduler Move Event** | `OnEventMove` | `EventID, StartDateTime, EndDateTime, ResourceId` | `SchedulerEvent` | Handle event moves |
| **BYD SDL IScheduler Resize Event** | `OnEventResize` | `EventID, StartDateTime, EndDateTime` | `SchedulerEvent` | Handle event resizing |
| **BYD SDL IScheduler Delete Event** | `OnEventDelete` | `EventID: RecordId` | `Boolean` | Handle event deletion |
| **BYD SDL IScheduler Click TimeRange** | `OnTimeRangeClicked` | `StartDateTime, EndDateTime, ResourceId` | `SchedulerEvent` | Handle time range clicks |
| **BYD SDL IScheduler Business Times** | `OnLoadBusinessTimes` | `var ShowNonBusinessDaysAndWeekends, var BusinessDayStartsAt, var BusinessDayEndsAt, var BusinessWeekends` | void | Load business hours |
| **BYD SDL IScheduler Blocked Times** | `OnLoadBlockTimes` | `StartDateTime, EndDateTime, Resources, var SchedulerBlockedTime` | void | Load blocked times (obsolete) |
| **BYD SDL IScheduler Special Times** | `OnLoadSpecialTimes` | `StartDateTime, EndDateTime, Resources, var SchedulerSpecialTime` | void | Load special times |
| **BYD SDL IScheduler Special Days** | `OnLoadSpecialDays` | `StartDateTime, EndDateTime, var SchedulerSpecialDay` | void | Load special days |
| **BYD SDL IScheduler Scale Headers** | `GetScaleHeaders` | `var ScaleConfig` | `JsonArray` | Get custom scale headers |
| **BYD SDL Context Actions** | `OnLoadContextActions` | `var ContextAction` | void | Load context actions |
| | `OnContextActionClicked` | `ActionId, EventId, var SchedulerEvent, var ActionToBePerformed` | void | Handle context action clicks |
| **BYD SDL Time R. Cont. Actions** | `OnLoadTimeRangeContextActions` | `var TimeRangeContextAction` | void | Load time range actions |
| | `OnTimeRangeContextActionClicked` | `ActionId, StartDateTime, EndDateTime, ResourceId, var SchedulerEvent, var ActionToBePerformed` | void | Handle time range action clicks |
| **BYD SDL Copy Event** | `OnEventCopy` | `EventID, StartDateTime, EndDateTime, ResourceId` | `SchedulerEvent` | Handle event copying |
| **BYD SDL Entity** | `OnLoadEvents` | `StartingDateTime, EndingDateTime, Resources, var SchedulerEvent` | void | Load entity events |
| | `OnEventClicked` | `EventId: RecordId` | void | Handle entity event clicks |
| | `OnEventMove` | `EventID, StartDateTime, EndDateTime, ResourceId, var SchedulerEvent` | void | Handle entity event moves |
| | `OnEventResize` | `EventID, StartDateTime, EndDateTime, var SchedulerEvent` | void | Handle entity event resizing |
| | `OnTimeRangeClicked` | `StartDateTime, EndDateTime, ResourceId, var SchedulerEvent` | void | Handle entity time range clicks |
| | `OnEventCopy` | `EventID, StartDateTime, EndDateTime, ResourceId, var SchedulerEvent` | void | Handle entity event copying |
| **BYD SDL Config** | `GetEntities` | none | `List of [Enum "BYD SDL Entity"]` | Get configured entities |
| **BYD SDL Dependency Links** | `OnLoadDependencyLinks` | none | void | Load dependency links |

### Implementation Priority

#### Essential (Must Implement)
1. **BYD SDL IScheduler Core** - Required for basic functionality
2. **BYD SDL IScheduler Unscheduled Events** - For unscheduled events sidebar

#### Recommended (Should Implement)
3. **BYD SDL IScheduler Move Event** - For drag-and-drop functionality
4. **BYD SDL IScheduler Resize Event** - For event resizing
5. **BYD SDL IScheduler Click Event** - For event interaction
6. **BYD SDL IScheduler Filters** - For filtering capabilities

#### Optional (Nice to Have)
7. **BYD SDL IScheduler Business Times** - For business hours display
8. **BYD SDL Context Actions** - For custom event actions
9. **BYD SDL IScheduler Click TimeRange** - For creating events by clicking empty slots
10. **BYD SDL Copy Event** - For event duplication
11. **BYD SDL IScheduler Special Times/Days** - For special time handling
12. **BYD SDL IScheduler Scale Headers** - For custom time scales

#### Advanced (For Complex Scenarios)
13. **BYD SDL Entity** - For multi-entity support
14. **BYD SDL Config** - For entity configuration
15. **BYD SDL Time R. Cont. Actions** - For time range context menus
16. **BYD SDL Dependency Links** - For event relationships