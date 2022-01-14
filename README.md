# ArduPilot-Projects

**Flight CSVs**: Contains the flight logs in CSV format
 - changed_flight: consists of flight data using changed parameters
- noid: consists of normal flight data
- norm2change2norm: consists of flight data that is initially normal than is changed to malicious then returns to normal

**Flight Logs** : Contains the flight logs in tlog format 
- changed_flight: consists of flight data using changed parameters
- noid_flight: consists of normal flight data
- n2c2n_flight: consists of flight data that is initially normal than is changed to malicious then returns to normal

**Parameter Files** Contains the flight parameters used
-	changed.parm are the malicious parameters (Follow Changing Parameter Files PDF to Create this File)
-	default.parm are the initialized parameters
-	noid.parm are the normal flight log parameters (Follow Changing Parameter Files PDF to Create this File)
-	
**Setting Up ArduPilot**
-	Setting Up ArduPilot.pdf : commands that describe installing Ardupilot
-	output.csv: flight log output
-	flight.tlog: flight log output
-	Displaying Flight Log data (html/m) : depicts how to view flight data
-	Changing Parameter Files: command to change parameters, run a flight with them, and save flight logs


IDS: the intrusion detection system that determines the change from benign to malicious flight parameters
