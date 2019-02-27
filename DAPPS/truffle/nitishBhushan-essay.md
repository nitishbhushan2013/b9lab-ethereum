Regulated system of toll roads

Purpose :
Tha main purpose of regulated system of toll road is to auotmate the toll collection process by relying on latest technology like RFID and Blockchain system. This system allows seemless toll collection process without stopping the vehicle at toll point.  As an added benefits, it also enables seemless traffic managament, reduce carbon footprint by reducing the vehicle queue at toll point, smart anti theft management and vehicle type classification, movement and audit.  


Problems :
The manual toll collection plaza has several limitation and inherent issues. Couple of them are listed below
-  Long queue at toll gate/traffic congestion : The manual process rely on man power to collect the toll fee, proces it, returns back the balance amount and then namually or elctronically open the gate . This enforces a long queue at the toll point.
- increase vehicle pollution / fuel consumption -  As the long vehicle queue, there is pollution increase at the toll point which add up to over all carbon foor print.
- Lost time - Since manual process takes time to process, its a lost oppurtunity time for the drivers.
- lack of proper traffic management - Its hard to keep track of all the vehicle movements on road. Also , in case of theft or hit-run or robbery scenario, its hard to get the vehicle movement as they are not being tracked.


Solutions :
By automating the toll collection process, we would be achieving below advantages
- shorter or no vehicle queue : Smooth reading of RFID tag on each vehicle by the RFID reader mounted at the toll gate  would ensure fast toll collection and thus smooth traffic movement.
- low toll collection cost - The automation of toll plaza can have the best solution over money loss at toll plaza by reducing the manpower required for collection of money and also to reduce the traffic indirectly resulting in reduction of time at the toll plaza.
- low pollution  - lack of traffic congestion would ensure to lower the vehicle emission
- better time/money management : Its win-win for both the driver and the road operator. For driver, its a no stop solution and thus better time management. For the road operator, its a smart solution which reduces manpower and thus overall expenditure. 




Important player and its role and responsibilities

State - They holds the perpetual lease over toll road land. 

Transport authority / Road Regulator  - They have the comprehensive responsibilities for the planning, construction, operation and management of motorway and expressway network and also outline the policies for the Road operator to collect tolls for using this network. 
They sublease toll roads to road operator for the management and collection of toll fee on these roads. 

In the current project, Road regulator has adopted 'distance based' tolling. Below are couple of their responsibilities 
	- identify kind of vehicle and set toll rate for the same.
	- Set maximum allowable toll price for the use of toll road for each type of vehicle
    - management of road operator. Create or delete road operators.  
	- maximum toll road price updation - This can be done based on different index like Customer Price Index (CPI) or Average Weekly Earnings (EWE) or combination of both. 

	
Road Operator - Road Regulator handovers the management and collection of toll road fee to Road operator under regulatory guideline. Road operator can then establish toll booths on the toll road to collect the toll fee from the motorist.
Main responsibilities 
	- create and establish toll booth and its infrastructure.
	- Define base toll fee price between toll booth. The final toll fee ( after multiplying with vehicle toll rate) must not be greater than the maximum toll fee set by the road regulator.
	- If its electronic toll booth, then provides RFID enable tag and digital platform for the customer to manage their account and preferred payment mode. 
	Customer in turn would purchase tag, create account with the Toll operator, link their preferred payment method for the road operator and stick the tag in their vehicle windscreen. 
	- Manage different toll fee collection scenario for the customer like 
		- in case of missing tag or account balance deficit, genetrate  pay invoice and post it to the customer address. 
		- Levy penalty of  not paying toll fee with in due time frame.
		- provides an online medium to pay the toll fee. 
		- provides different aspect of managing individual online account such as 'Login issue', 'user name PIN and password', 'Account balance and payment', 'Account update'.


Toll booth - Toll booth workers collect money, disburse change, and issue receipts to motorists who use toll roads and private facilities. They also document how many people come by and watch out for toll evaders. Toll booth workers ensure that toll roads operate smoothly and efficiently.

In a cashless tolling system, toll booth is equipped with RFID tag reader, different sensors, survilleance cameras. These system work in a seamless way to detect approaching vechile, determine its type, read the license plate, run check againts possible theft, read tagId, fetch account details, check balance and block approx toll amount, manange account transaction and update the account and audit system. 
Please find attach the flow diagram depicting the complete system.   

pre-requisite 
In the current system, user has to buy tag from the road operator, create account with the road operator,link tag with the account and provide payment mode( ethereum address or debit/credit/pre-paid card) . So each tag will be mapped with vehicle registartion and link with the user's preferred payment mode. User has to mount this tag on the vehicle windscreen. 

user has a account with the road operator. tag device is linked with account and has mapped with vehicle registration no. and payment mode.
Road operator also provides smart contarct for user to link their ethereum address.  If selected paymode mode is etehreum address then user has to provide his ethereum address. 
Thus with the tagid, its easy to get user profile, car registration details and the linked ethereum address.  


Vehicle types
There are four vehicle types 
	- Class 1 :: motorcycle -  A two-wheeled motor vehicle, includes motor vehicles with a trailer or side-car.
	- Class 2 :: Car - Four-wheeled motor vehicles, less than 2.8m in height and 12.5m in length, including taxis which are not commercial vehicles (including vehicles towing a trailer or caravan).
	- Class 3 :: Light Commercial Vehicle (LCV) : Any two axle rigid vehicle with a cab chassis construction, with a gross vehicle mass that is greater than 1.5 tonnes but less than 4.5 tonnes.
	- Class 4 :: Heavy commercial vehicle (HCV) :  Any three or more axle rigid vehicle, with a gross vehicle mass that is greater than 4.5 tonnes 

Implementation
As vehicle approaches the toll gate, IR sensor would sense it, identify the vehicle type and activates camera to capture number plate. It then run through anti theft module to check againsts stolen or reported vehicle. If vehicle is stolen then information can rely to the police control center and txt message delivered to car authorised owner. Toll gate would not allows the vehicle to pass through.

If not stolen, then RFID sensor would read the tag ID and fetch the payment mode detail. 

payment mode = etehreum address
If payment mode is linked to ethereum address and proper balance is there then smart contract method would invokes with (tag id, car type, car registartion number, ethereum address, entry toll address) parameters and approx toll fee amount is blocked. Toll gate allows the vehicle to pass through. 

if not enough balance, then these details get passed to autonomous subsystem to prepare the toll fee demand letter which then will sent to the vehicle registered owner adddress. Toll gate allows the vehicle to pass through. 


payment mode = credit/debit/pre-paid card 
If payment mode is linked to card and proper balance is there then smart contract method would invokes with (tag id, car registartion number and card details) paraneter and approx toll fee amount is blocked.

if not enough balance, then these details get passed to autonomous subsystem to prepare the toll fee demand letter which then will sent to the vehicle registered owner adddress. Toll gate allows the vehicle to pass through.

If no tag atatched with the vehicle
Then car registartion number passed to autonomous subsystem to prepare the toll fee demand letter which then will sent to the vehicle registered owner adddress. Toll gate allows the vehicle to pass through.

 
At the toll exit gate
RFID sensor again scan the outgoing vehicle and pass the (tag id, registartion details, entry toll address, exit toll address, block amount, payment mode) to the the smart contarct. Smart contract then calculate the actual toll amount through toll-fee matrix, deduct the amount from the blocked amount, rervert back the balance amount back to the user, do account balance, and update ledger. 



	
	
	
	

 

 