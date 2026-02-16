Program
OPS is going to launch a system for program approval.

Business Problem: 
-	Citizens of Ontario will submit a program request for the Government of Ontario.
-	Ministry Employee reviews the submission within an internal portal.
-	Once approved/declined, notification is sent to Citizen.

Technical Requirment:
-	Front-End Platform: React
-	Back-End: Java. API Layer
-	Database: Azure SQL
-	Azure Components: Durable Functions, App services, Azure SQL, Azure Logic Apps and Ai Foundry with a mini model deployed. RBAC authentication 
-	Figma For UI
-	CI/CD: GitHub Actions
-	Security: GHAS. Dependabot, Secret Scanning
-	Azure DevOps: User stories, Test Plans.

First Step:
-	M365 Chat: A prompt for user stories for this project. Maximum 4 or 5 highlilevel like Infra, Backend, front-end, QA.
-	GitHub Copilot: Populate Instruction Files. Which has details around what we are building.
-	GitHub Copilot: Create an Arch diagram to implement this solution.
-	Infra: Have all deployed and pre-built.
-	DBA: Connect and load schemas.
-	Backend Developer: Pull a userstory from AzDo and get Copilot to build a backend solution with at least 2 APIs. 
-	Front-End Developer: Figma to show the UI prototyoe, WCAG and Ontario.ca assets and get Copillot to build a local UI MVP.
-	QA: Improve code coverage, build test plans and push to AzDo
-	DevOps: Build CI to validate changes
-	Showcase the app on a public URL, fully working.
-	Depending on time: Make a change. 
-	Rest of the team: PowerPlatforom and integrations
Here are some of the features:
•	All screens must be bi-lingual (English/French)
•	Screens follow Ontario Design System (Ontario Design System)
•	All screens must be WCAG 2.2 (Web Content Accessibility Guidelines (WCAG) 2.2)
•	Follow OPS template if possible (Government of Ontario | ontario.ca)

<img  alt="image" src="https://github.com/user-attachments/assets/97260422-82e7-4b2a-a869-d7de057c3315" />


o	
<img  alt="image" src="https://github.com/user-attachments/assets/7e605922-6644-4492-94a0-5875698481c5" />

o	 
•	General public should be able to self register or use existing MyOntario account (Probably out of scope for developers’ day)
•	Registered Public user should be able to submit a new program form
o	Let’s try simple form
	Program Name
	Program Description
	Program Type (Drop down) 
o	Maybe having another screen to upload a document
o	Review and Disclaimer and submit
•	Notification goes to the Ministry user (If possible in Developer’s day)
•	Ministry user click on the link and go to Internal Portal for program review and approval
•	Ministry user view the submitted program and supporting document, then add comments and Reject/Approve
•	Public user receive notification and can see the result
•	If we want to show off, we can show generated letter with confirmation of program approval
•	Search program screen
o	Maybe simple criteria to start with program name search and ask GitHub Copilot to build the query
o	And then add program approval date range and ask GitHub Copilot to update the query and screen.
•	It is ideal to show how easy it is to make a change
o	If   time allows add a new field to program approval form and ask GitHub Copilot to:
	Redesign data model
	Redesign Program Form
	Redo queries (Insert, update, read)
	Update Unit Test
	Accessibility Test
	Identify missing French translation
	Not sure if possible but GitHub Copilot suggest what to do with default value in older records
	Regenerate Architecture documents (Data Dictionary, Design Document)
