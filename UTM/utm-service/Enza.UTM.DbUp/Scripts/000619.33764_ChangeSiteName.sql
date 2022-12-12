/* Update site name from ENZA-NL to ENZA-SQCSH-NL */
UPDATE SiteLocation SET 
	SiteName = 'ENZA-SQCSH-NL' 
WHERE SiteName = 'ENZA-NL'
GO