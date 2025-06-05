/******************************************************/
----- Stored Procedure Logic: load_fact_inpatient_claims -----

USE [sample_health]

-- check if temp_loader exists and reset the resources
drop table if exists #temp_loader

-- Reload the temp_loader table with new data
SELECT 
	ei.ClaimID
	, ei.BeneID
	, ei.AdmissionDt
	, ei.DischargeDt
	, datediff(dd,ei.AdmissionDt,ei.DischargeDt) [length_of_stay]
	, convert(varchar,ei.admissionDt, 112) [admission_date_key]
	, ei.ClmProcedureCode_1
	, ei.ClmDiagnosisCode_1
INTO #temp_loader
FROM [sample_health].[dbo].[extract_inpatient_claims] ei
print('Temp loader successful')

-- check that the dimensional model table exists
IF OBJECT_ID('[sample_health].[dbo].[fact_inpatient_claims]', 'U') IS NULL
BEGIN
	-- if it doesn't exist, then rebuild the table
	Create Table [sample_health].[dbo].[fact_inpatient_claims] (
	[ClaimID] varchar(10) PRIMARY KEY
	, [BeneID] varchar(10)
	, [Admission_Date] date
	, [Discharge_Date] date
	, [length_of_stay] int
	, [admssion_date_key] varchar(8)
	, [clm_procedure_code] varchar(10)
	, [clm_dx_code] varchar(10))
	print('Fact table rebuilt successfully')

	-- load the table
	Insert Into [fact_inpatient_claims]
	Select * From #temp_loader
	print('Fact table load successful')


END
ELSE
BEGIN
	--if the table exists, load it
	Insert Into [fact_inpatient_claims]
	Select * From #temp_loader
	print('Fact table load successful')

	--reset the loader table
	drop table #temp_loader
End


/******************************************************/
----- Stored Procedure Logic: load_fact_daily_clients -------

USE [sample_health]

-- check if temp_loader exists and reset the resources
drop table if exists #temp_loader

-- Reload the temp_loader table with new data
Select
	q.date_key
	,count(q.ClaimID) [num_in_hospital]
into #temp_loader 
From (
	Select
		ei.ClaimID
		,[date_key]
	FROM [sample_health].[dbo].[extract_inpatient_claims] ei
	LEFT Join [sample_health].[dbo].[dim_date] dd
		on dd.date between ei.AdmissionDt and ei.DischargeDt
	) q
Group by q.[date_key]

print('Temp loader successful')

-- check that the dimensional model table exists
IF OBJECT_ID('[sample_health].[dbo].[fact_daily_clients]', 'U') IS NULL
BEGIN
	-- if it doesn't exist, then rebuild the table
	Create Table [sample_health].[dbo].[fact_daily_clients] (
	[date_key] varchar(8)
	, [num_in_hospital] int )

	print('Fact table rebuilt successfully')

	-- load the table
	Insert Into [fact_daily_clients]
	Select * From #temp_loader
	print('Fact table load successful')

END
ELSE
BEGIN
	--if the table exists, load it
	Insert Into [fact_daily_clients]
	Select * From #temp_loader
	print('Fact table load successful')

	--reset the loader table
	drop table #temp_loader
End

/******************************************************/
----- Stored Procedure Logic: load_dim_client -------

USE [sample_health]

-- check if temp_loader exists and reset the resources
drop table if exists #temp_loader

-- Reload the temp_loader table with new data
SELECT 
	ec.BeneID
	, ec.gender
	, ec.[state]
	, ec.[alzheimers]
	, ec.[heartfailure]
	, ec.[cancer]
	, ec.[diabetes]
INTO #temp_loader
FROM [sample_health].[dbo].[extract_clients] ec
print('Temp loader successful')

-- check that the dimensional model table exists
IF OBJECT_ID('[sample_health].[dbo].[dim_client]', 'U') IS NULL
BEGIN
	-- if it doesn't exist, then rebuild the table
	Create Table [sample_health].[dbo].[dim_client] (
	BeneID varchar(10) primary key
	, [gender] varchar(1)
	, [state] varchar(20)
	, [alzheimers] int
	, [heartfailure] int
	, [cancer] int
	, [diabetes] int
	)
	print('Dim table rebuilt successfully')

	-- load the table
	Insert Into [dim_client]
	Select * From #temp_loader
	print('Dim table load successful')


END
ELSE
BEGIN
	--if the table exists, load it
	Insert Into [dim_client]
	Select * From #temp_loader
	print('Dim table load successful')

	--reset the loader table
	drop table #temp_loader
End
