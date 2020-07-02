-- returns distinct identities (the most reliable so far)
SELECT DISTINCT
	IdentityName AS ID
FROM tbl_Command 
WHERE ISNULL(IdentityName, '') != '' AND IdentityName LIKE '<domain>%'
	AND IdentityName NOT LIKE '<filter>'
ORDER BY 1

-- returns all access entries
SELECT 
	IdentityName AS ID,
	StartTime AS Last_Access_Time,
	Command AS Reason,
	IPAddress AS IP,
	ExecutionTime as Time
FROM tbl_Command ORDER BY Last_Access_Time DESC

-- misc
SELECT * FROM sys.tables WHERE NAME LIKE '%Identit%'
SELECT OBJECT_NAME(object_id), * FROM sys.columns WHERE NAME LIKE '%Alias%'
SELECT TOP 100 * FROM ADObjects

-- returns AD Objects, but the list could be very large
SELECT DISTINCT 
	DomainName, SamAccountName, MailNickName, ObjectSID, DisplayName  
FROM ADObjects
WHERE ObjectCategory = 2 -- User
	AND DomainName = '<domain>' 
	AND ISNULL(MailNickName, '') != '' 
	AND fDeleted = 0
	AND YEAR(LastSyncUTC) >= 2017
	AND MailNickName LIKE '<filter>' 
	AND DisplayName NOT LIKE '<filter>'



