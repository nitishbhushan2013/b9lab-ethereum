    pragma solidity ^0.4.25;
   
   /**
    *@title Ownable
    *@dev This contract maintains and identify the owner of the contract.
    */
contract Ownable{
	/**
    *@dev this modifier ensures that only owner can can call the function 
     */
    modifier onlyOwner;
	
	 /**
    *@return boolean to indicate if the contract invoker is the owner of the 
    contract
     */
    function isOwner() public view returns(bool);
	
	/**
    * @dev This function will returns the owner address
    * @return owner address
     */
    function getOwner() public view returns(address);
}



/**
*@title Pausable
*@dev This contract contains feture to pause the contract functionlities.
 This inherent can only be invoked by the contract owner
*/
contract Pausable is Ownable {
    
        /**
    *@dev this modifier allow to call function ONLY when contract is not paused.
    */
    modifier onlyWhenNotPaused;
    
    /**
    *@dev this modifier allow to call function ONLY when contract is paused. 
    */
    modifier onlyWhenPaused ;
    
    /** 
    * @dev Only when pause flag is mot set, then contract owner can call this 
    *function.  */
    function pause() public onlyOwner onlyWhenNotPaused;
    
    /** 
    * @dev Only when pause flag is set, then contract owner can call this 
    *function  to unset the flag.*/
    function unPause() public onlyOwner onlyWhenPaused;
}	




/**
* @title Regulator
  @author Nitish Bhushan
  @dev this contract represents Transport Regulator and are responsible for below activities
   - set the vehicle type and its toll rate. 
   - set maximum toll price for each vehicle type
   - instantiate the road operator
   - management of road operator
   - provide timeframe and methodology to update maximum toll price for each vehicle type
**/
contract Regulator is Pausable {
    
    /**
    @dev This event is emitted when regulator would set vehicle type and its rate in the system
    @param regulator regulator, which is the owner of this contract
    @param vehicleTypeText vehicle type in text format for the easy understanding. Vehicle types are 'Class1','Class2','Class3', and 'Class4'
    @param vehicleType vehicle type 
    @param rate 
     */
    event LogVehicleTypeAndRateSet(address regulator,  String vehicleTypeText, bytes32 vehicleType, uint rate);

    /**
    @dev This event is emitted when regulator would set the maximum applicable toll fee for vehicle type. Vehicle types are 'Class1','Class2','Class3', and 'Class4'
    @param  regulator regulator, which is the owner of this contract
    @param vehicleTypeText vehicle type in text format for the easy understanding. It could be 'Class1','Class2','Class3', and 'Class4'
    @param vehicleType vehicle type
    @param maxTollFee maximum allowable toll fee for vehicle type 
     */
    event LogVehicleMaxTollFeeSet(address regulator,  String vehicleTypeText, bytes32 vehicleType, uint maxTollFee);

    /**
    @dev This event is emitted when regulator would create the road operator
    @param regulator, regulator, which is the owner of this contract
    @param roadOperatorAddress
     */
    event LogRoadOperatorCreated(address regulator,  address roadOperatorAddress);

    /**
    @dev This event is emitted when regulator would delete the road operator
    @param regulator, regulator, which is the owner of this contract
    @param roadOperatorAddress
     */
    event LogRoadOperatorDeleted(address regulator,  address roadOperatorAddress);

    /**
    @dev This event is emitted when regulator would update vehicle type and its rate in the system
    @param regulator regulator, which is the owner of this contract
    @param vehicleTypeText vehicle type in text format for the easy understanding. Vehicle types are 'Class1','Class2','Class3', and 'Class4'
    @param vehicleType vehicle type 
    @param rate 
     */
    event LogVehicleTypeAndRateUpdated(address regulator, String vehicleTypeText, bytes32 vehicleType, uint rate);


    /**
    @dev This event is emitted when current regulator would replace itself with a new regulator.
    @param oldRegulator, which is the owner of this contract
    @param newRegulator, new owner for this contract
     */
    event LogRegulatorUpdated(address oldRegulator, address newRegulator);



    /**
    @dev this function would initialise the vehicle type and set its rate. There are four vehicle types 
        - Class 1 :: motorcycle -  A two-wheeled motor vehicle, includes motor vehicles with a trailer or side-car.
        - Class 2 :: Car - Four-wheeled motor vehicles, less than 2.8m in height and 12.5m in length, including taxis which are not commercial vehicles (including vehicles towing a trailer or caravan).
        - Class 3 :: Light Commercial Vehicle (LCV) : Any two axle rigid vehicle with a cab chassis construction, with a gross vehicle mass that is greater than 1.5 tonnes but less than 4.5 tonnes.
        - Class 4 :: Heavy commercial vehicle (HCV) :  Any three or more axle rigid vehicle, with a gross vehicle mass that is greater than 4.5 tonnes 

    @param vehicle : this could be Class1, Class2, Class3 or Class4 in bytes32 format
    @param rate : rate for each vehicle
    @return boolean to indicate success status of this call
    @restriction 
     */
    function setVehicleTypeAndRate(bytes32 vehicleType, uint rate) public onlyWhenNotPaused onlyOwner  returns(bool);


    /** 
    @dev this function would returns the vehicle rate
    @param vehicleType 
    @return rate
     */
    function getVehicleRate(bytes32 vehicleType) public view onlyWhenNotPaused returns(uint rate);


    /** 
    @dev this function would set the maximum toll fee for the vehicle type. Only current contract owner can invoke this function. 
    @param vehicleType 
    @param maxTollFee
    @return boolean to indicate success status of this call
     */
    function setMaximumVehicleTollFee(bytes32 vehicleType, uint maxTollFee) public onlyWhenNotPaused onlyOwner  returns(bool);


     /** 
     @dev this function would get the maximum toll fee for the vehicle type.
     @param vehicleType 
     @return maxTollFee
     */
    function getMaximumVehicleTollFee(bytes32 vehicleType) public view  onlyWhenNotPaused returns(uint maxTollFee);


    /** 
     @dev this function will update the toll rate for vehicle type. The new arte is calculated based on business logic and different index. Couple of indexes used are Customer Price Index (CPI) or Average Weekly Earnings (EWE) or combination of both. Only current contract owner can invoke this function. 
     @param vehicleType 
     @return newRate
     */
    function updateVehicleTypeAndRate(bytes32 vehicleType) public onlyWhenNotPaused onlyOwner  returns (uint newRate);


     /** 
     @dev this function will craete the new road operator. Only current contract owner can invoke this function. 
     @param roadOperatorAddress 
     @return roadOperator 
     */
    function createRoadOperator(address roadOperatorAddress) public onlyWhenNotPaused onlyOwner  returns(RoadOperator roadOperator);


    /** 
     @dev this function will delete the new road operator. Only current contract owner can invoke this function. 
     @param roadOperatorAddress 
     @return boolean to indicate success status of this call
     */
    function deleteRoadOperator(address roadOperatorAddress) public onlyWhenNotPaused onlyOwner  returns(bool success);

    /** 
     @dev this function will determine if the passed in address is a valid Road Operator. 
     @param roadOperatorAddress 
     @return boolean to indicate success status of this call
     */
    function isRoadOperator(address roadOperatorAddress) public view onlyWhenNotPaused  returns(bool success);
   

    /** 
     @dev this function will replace the current regulator with new regulator. Only current contract owner can invoke this function. 
     @param newRegulatorAddress 
     @return newRegulator
     */
    function updateRegulator(address newRegulatorAddress) public onlyWhenNotPaused onlyOwner returns (address newRegulator);

}




/**
 @title RoadOperator
 @author Nitish Bhushan
 @dev Below are its main responsibilites
    - Instantiate and track toll booth operators. Each toll booth is identified by its unique Id and this information is publically available
    - manage toll booth operators 
    - define base toll fee matrix between two points (entry toll and exit toll)
    - iT also rely on utility library to get details for each tagId and its related entities. 

 */
contract RoadOperator is Pausable {


    /**
    @dev This event is emitted when road operator has added a new toll Booth.
    @param roadOperator owner of the current contract
    @param tollBoothaddress toll booth address
    @param tollBoothId id of the toll booth that got added
     */
    event LogTollBoothAdded(address roadOperator, address tollBoothaddress, bytes32 tollBoothId); 


    /**
    @dev This event is emitted when road operator has removed a toll Booth.
    @param roadOperator
    @param tollBoothaddress
    @param tollBoothId
     */
    event LogTollBoothRemoved(address roadOperator, address tollBoothaddress, bytes32 tollBoothId);   


    /**
    @dev This event is emitted when road operator has added a base toll fee for the vehicle type. This base toll fee MUST NOT be more then the maximum toll fee set by regulator.
    @param
    @param
    @param
    @param
     */ 
    event LogBaseTollFeeAddedForVehicleType(address roadOperator, bytes32 entryTollBoothId, bytes32 exitTollBoothId, bytes32 vehicleType);    


    /**
    @dev This event is emitted when road operator has
    @param
    @param
    @param
    @param
     */
    event LogTollBoothAdded(address roadOperator, address tollBoothaddress);


    /**
    @dev  This event is emitted when road operator has
    @param
    @param
    @param
    @param
     */    
    event LogTollBoothRemoved(address roadOperator, address tollBoothaddress); 


    /**
    @dev This event is emitted when road operator has
    @param
    @param
    @param
    @param
     */    
    event LogBaseTollFeeAdded(address roadOperator, bytes32 entryTollBoothId, bytes32 exitTollBoothId, bytes32 vehicleType); 


    /**
    @dev This event is emitted when road operator has
    @param
    @param
    @param
    @param
     */ 
    event LogBaseTollFeeUpdated(address roadOperator, bytes32 entryTollBoothId, bytes32 exitTollBoothId, bytes32 vehicleType);  


    /**
    @dev This event is emitted when road operator has
    @param
    @param
    @param
    @param
     */
    event LogVehicleOwnerDetailFetched(address roadOperator, bytes32 tagId, bytes32 vehicleRegistrationNo);   


    /**
    @dev This event is emitted when road operator has
    @param
    @param
    @param
    @param
     */
    event LogEthereumAddressBalanceEnquired(address roadOperator, bytes32 tagId, bytes32 personId, address ethereumAddress);


    /**
    @dev This event is emitted when road operator has
    @param
    @param
    @param
    @param
     */
    event LogCardBalanceEnquired(address roadOperator,  bytes32 tagId, bytes32 personId, bytes32 cardNo);    
   
     /** 
     @dev this function will add a new toll booth operator. Only current contract owner can invoke this function. 
     @param tollBoothaddress 
     @return tollBoothId
     */
    function addTollBooth(address tollBoothaddress) public onlyWhenNotPaused onlyOwner  returns (bytes32 tollBoothId);

    /** 
     @dev this function will remove exsting toll booth operator. Only current contract owner can invoke this function. 
     @param tollBoothId 
     @return  boolean to indicate success status of this call
     */
    function removeTollBooth(bytes32 tollBoothId) public onlyWhenNotPaused onlyOwner  returns (bool status);


     /** 
     @dev this function will validate a given toll booth operator Id. This will be used by the vehicle to confirm the entry toll booth identification.
     @param tollBoothId 
     @return  boolean to indicate success status of this call
     */
    function isValidTollBooth(bytes32 tollBoothId) public view onlyWhenNotPaused  returns (bool status);


    /** 
     @dev this function will returns the list of all the toll booth Ids.
     @param  
     @return  tollBoothIds 
     */
    function getListTollBooth() public view onlyWhenNotPaused  returns (bytes32 memory [] tollBoothIds);


     
     /** 
     @dev this function will set base toll fee between two given toll booth Id for the given vehicle type. Only current contract owner can invoke this function. This price (base price * vehicle type Rate) must not exceed the maximum toll fee set by the regulator for the given vehicle type. 
     @param entryTollBoothId 
     @param exitTollBoothId 
     @param vehicleType 
     @return  rate
     */
    function setBaseTollFee(bytes32 entryTollBoothId, bytes32 exitTollBoothId, bytes32 vehicleType) public onlyWhenNotPaused onlyOwner  returns (uint rate);


    /** 
     @dev this function will get base toll fee between two given toll booth Id for the given vehicle type. 
     @param entryTollBoothId 
     @param exitTollBoothId 
     @param vehicleType 
     @return  rate
     */
    function getBaseTollFee(bytes32 entryTollBoothId, bytes32 exitTollBoothId, bytes32 vehicleType) public onlyWhenNotPaused  returns (uint rate);


    /** 
     @dev this function will update base toll fee between two given toll booth Id for the given vehicle type. Only current contract owner can invoke this function. 
     This price must not exceed the maximum toll fee set by the regulator for the given vehicle type. 
     @param entryTollBoothId 
     @param exitTollBoothId 
     @param vehicleType 
     @return  rate
     */
    function updateBaseTollFee(bytes32 entryTollBoothId, bytes32 exitTollBoothId, bytes32 vehicleType) public onlyWhenNotPaused onlyOwner  returns (uint rate);


    
    /** 
     @dev In the road operator system, each tag id is uniquely linked with vehicle registration number and mapped with the registered ownerfor this vehicle. Also payment method and account details are also linked. Hence through tagid, system can fetch not only vehicle details but also the owner details. 
     Based on tagId, this function would fetch the registered owner details. This function would utilise the library function for the same. 

     @param tagId 
     @param vehicleRegistrationNo 
     @return  customerId, customerName, phone,  contactAddress, etehreumAddress, cardDetail
     */
    function getOwnerDetails(bytes32 tagId, bytes32 vehicleRegistrationNo) public onlyWhenNotPaused returns(customerId, customerName, phone, contactAddress, etehreumAddress, cardDetail);
   
   
     /** 
     @dev Based on ethereumAddress, this function would fetch the owner account balance. This function would utilise the library function for the same. 
     @param tagId 
     @param personId 
     @param ethereumAddress
     @return  uint
     */
    function getEthereumAccountBalance(bytes32 tagId, bytes32 personId, address ethereumAddress) public onlyWhenNotPaused viw returns (uint);


     /** 
     @dev Based on cardNo, this function would fetch the owner account balance. This function would utilise the library function for the same. 
     @param tagId 
     @param personId 
     @param cardNo
     @return  uint
     */
    function getCardAccountBalance(bytes32 tagId, bytes32 personId, bytes32 cardNo) public onlyWhenNotPaused viw returns (uint);
}    




library utility {

    function getAccountDetails(bytes32 tagId) public view returns (customerId, customerName, phone, contactAddress, etehreumAddress, card detail);

    function getEthereumAccountBalance(bytes32 tagId, bytes32 personId, address ethereumAddress) public viw returns (uint);

    function getCardAccountBalance(bytes32 tagId, bytes32 personId, bytes32 cardNo) public viw returns (uint);
}



/**
 @title TollBoothOperator
 @author Nitish Bhushan
 @dev Below are its main responsibilites
    -  read vehicle number plate and run it through anti theft sub system to validate its not stolen
    - process tag id, capture their toll journey details 
    - process linked account and block the amount
    - At the exit, calculate final toll fee, process the accounts, returns balance, and update the system.

 */
contract TollBoothOperator is Pausable {

    event LogVehicleEntered(address tollBoothOperator, bytes32 tagId, bytes32 vehicleType, bytes32 entryTollBoothId, uint dateTime);

    

    /**
    @dev this function make sure that tag is not stolen. It would process tagid and match the received registration details with the one on vehicle. 
    @param tagId
    @return boolean to indicate success status of this call
     */
    function processVehicleTagId(bytes32 tagId) public onlyWhenNotPaused view returns(bool status);


    /** 
    @dev This function will capture all the necessary details for the vehicle entering the toll system. From the tagId, function will derive owner details, registration details and ethereum address. 
    @param tagId
    @param vehicleType
    @param entryTollBoothId
    @param dateTime
    @return boolean to indicate success status of this call
     */
    function captureVehicleEntry(bytes32 tagId, bytes32 vehicleType, bytes32 entryTollBoothId, uint dateTime ) public onlyWhenNotPaused view returns(bool status);
   

   /**
    @dev Based on vehicle type, this function will blocks the maximum allowed toll fee from the ethereum adddress. From the tagId, function will derive owner details, registration details and ethereum address.
    @param tagId
    @param vehicleType
    @param entryTollBoothId
   @param dateTime
    @return blockedAmount
     */
    function blockAmount(bytes32 tagId, bytes32 vehicleType, bytes32 entryTollBoothId uint dateTime) public onlyWhenNotPaused view returns(uint blockedAmount);
   

    /**
    @dev Based on tagid, vehicle type and rego, this function will identify the vehicle and calculate its actual toll fee. This will also settle the account and returns the balanced amount back to the ethreum address. 
    @param tagId
    @param vehicleType
    @param vehicleRegistrationNo
    @param entryTollBoothId
    @param dateTime
    @return
     */
    function processExitingVehicle(bytes32 tagId, bytes32 vehicleType, bytes32 vehicleRegistrationNo, bytes32 entryTollBoothId, uint dateTime) public onlyWhenNotPaused view returns(bool status);

}    