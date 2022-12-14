CREATE TABLE Test
(
    TestID		INT IDENTITY(1, 1) PRIMARY KEY,
    TempName		NVARCHAR(100),
    TestName		NVARCHAR(200),
    LabPlatePlanID	INT,
    PeriodID		INT,
    StatusCode		INT
);
GO

CREATE TABLE TestDetAssignment
(
    TestDetAssignmentID INT IDENTITY(1, 1) PRIMARY KEY,
    TestID		    INT,
    DetAssignmentID	    INT
);
GO

CREATE TABLE Plate
(
    PlateID		    INT IDENTITY(1, 1) PRIMARY KEY,
    PlateName		    NVARCHAR(200),
    TestDetAssignmentID INT,
    LabPlateID		    INT
);
GO