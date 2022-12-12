CREATE TABLE MarkerPerVariety
(
    MarkerPerVarID	INT PRIMARY KEY IDENTITY(1, 1), 
    MarkerID		INT FOREIGN KEY REFERENCES Marker(MarkerID), 
    VarietyNr		INT FOREIGN KEY REFERENCES Variety(VarietyNr), 
    StatusCode		INT
)
GO