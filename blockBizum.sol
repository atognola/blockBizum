pragma solidity ^0.4.4;

/**
 * Implements the registry for address => name mapping
 * This registry pattern contract is used by thedapps.com for personalizing the user experience
 * 
 * The following work is based upon the pattern_address_registry.sol contract
 *
 * Functional analysis of the pattern:
 * This contract pattern implements a "phone book" (registry) of sorts for the Ethereum network
 * Different pieces of information can be stored in a struct which is associated to an address in the network.
 *
 * Use case:
 * For the scope of this assignment, I will create a Blockchain based Bizum alternative.
 * Users will be able to register their personal information (Name and Phone number).
 * Other users will be able to wire money to these users while only needing to know their friend's phone number!
 * User registering must provide a unique phone number which is assigned on a first come, first served basis.
 * Ideally, some phone number validation would be needed for the user registration.
 * Finally, user's names can be non unique, and will be used only as a confirmation to whoever 
 * sent the payment in the first place
 * 
 * Pattern: Mapping Iteration
 **/

contract BlockBizum {
    
    address   owner;

    // =======
    struct User {                   //User struct (symilar to a class) definition 
        bytes32   name;             //String to store the name of the user (using this datatype uses less gas!)
        uint32    phoneNumber;      //User's phone number -> will the data that identifies users to send money
        uint      lastUpdated;      //Last time the contract was updated
    }

    // Manages the mapping between address & name
    mapping(address => User)  addressMap;

    // Manages the list of addresses
    address[]   addresses;          //Array like structure to store eth addresses of the users

    //Enforce that a function can only be run by the contract´s owner!
    modifier OwnerOnly() {          
        if(msg.sender == owner) _;
        else revert();
    }

    //Gives the caller of the constructor the ownership of the contract
    constructor() public {
        owner = msg.sender;         
    }

    event Transfer(address _from, address _to, uint256 _value);

    // Registers the name the name and user information of the caller into the registry
    // Calling it for a second time with a blank name eliminates that user's entry in the registry
    function registerUser(bytes32 name, uint32 phone) public returns (bool){
        // if(name == 0x0) return false;
        if(name == bytes32(0x0)){
            // owner wants to delete the registration
            if(addressMap[msg.sender].name != bytes32(0x0)){
                delete(addressMap[msg.sender]);
            }
            removeFromAddresses(msg.sender);
            return false;
        }

        if(validateUniquePhone(phone)) {
            if(addressMap[msg.sender].name == bytes32(0x0)){
                addresses.push(msg.sender);
            }
            addressMap[msg.sender].name = name;
            addressMap[msg.sender].phoneNumber = phone;
            addressMap[msg.sender].lastUpdated = now;
        } else {
            return false;
        }
        
        return true;
    }

    // Only the contract Owner can update any name
    // Since the owner of the smart contract is calling this function, no phone number validation is performed
    // Checking that the phone number being input as the updated parameter is up to the user
    // If a repeating phone number is input, the next time a user sends funds to that phone number,
    // the first entry in the mapping will be the one receiving the funds.
    function adminUpdateUser(address given, bytes32 name, uint32 phone) public OwnerOnly  returns (bool){
        if(addressMap[given].name == bytes32(0x0)) return false;
        addressMap[given].name = name;
        addressMap[given].phoneNumber = phone;
        addressMap[msg.sender].lastUpdated = now;
        return true;
    }

    // Any user can update their own data 
    function updateUser(bytes32 name, uint32 phone) public  returns (bool){
        if(addressMap[msg.sender].name == bytes32(0x0)) return false;
        if(validateUniquePhone(phone)) {
            addressMap[msg.sender].name = name;
            addressMap[msg.sender].phoneNumber = phone;
            addressMap[msg.sender].lastUpdated = now;
        } else {
            return false;
        }
        return true;
    }

    // Only the contract Owner can force delete any entry
    function adminDeleteUser(address given) public OwnerOnly returns (bool){
        delete(addressMap[given]);
        removeFromAddresses(given);
        return true;
    }

    // Only the User can delete it's own data
    function deleteUser() public returns (bool){
        delete(addressMap[msg.sender]);
        removeFromAddresses(msg.sender);
        return true;
    }

    // Returns the count of registered users
    function  count() public constant returns (uint){
        return addresses.length;
    }

  
    // Returns the address-user data at the specified index
    function  getByIndex(uint index) public constant returns (address, bytes32, uint32, uint){
        if(index >= addresses.length) return;
        address addr = addresses[index];
        return (addr, addressMap[addr].name, addressMap[addr].phoneNumber, addressMap[addr].lastUpdated);
    }

    // Returns the address-user data by way of the address
    function  getByAddress(address addr) public constant returns (address,bytes32, uint32, uint){
        return (addr, addressMap[addr].name, addressMap[addr].phoneNumber, addressMap[addr].lastUpdated);
    }

    // Returns the address-user data by way of the phone number
    function  getByPhoneNumber(uint32 phone) public constant returns (address, bytes32, uint32, uint){
        for(uint i = 0; i < addresses.length; i++) {
            if(addressMap[addresses[i]].phoneNumber == phone){
                address addr = addresses[i];
                return (addr, addressMap[addresses[i]].name, addressMap[addresses[i]].phoneNumber, addressMap[addresses[i]].lastUpdated);
            }
        }
        return (0, 0, 0, 0);
    }

    // Returns the address-user data by way of the address
    function  transferMoney(uint32 phone) public payable returns (bytes32){
        for(uint i = 0; i < addresses.length; i++) {
            if(addressMap[addresses[i]].phoneNumber == phone){
                emit Transfer(msg.sender, addresses[i], msg.value);
                addresses[i].transfer(address(this).balance);
                return addressMap[addresses[i]].name;
            }
        }
        msg.sender.transfer(address(this).balance);
        return 0;
        
    }

    /**
    * Solidity does not provide an out of the box function to remove the 
    * element of an array and shrink it.
    **/
    function removeFromAddresses(address addr) private {
        for(uint i = 0; i < addresses.length; i++) {
            if(addr == addresses[i]){
                // This simply zeroes out the element - length stays the same
                //delete(addresses[i]);

                // This while loop will shrink size of the array
                while (i < addresses.length - 1) {
                    addresses[i] = addresses[i+1];
                    i++;
                }
                addresses.length--;
                return;
            }
        }
    }

    /**
    * Solidity does not provide an out of the box function to remove the 
    * element of an array and shrink it.
    **/
    function validateUniquePhone(uint32 phone) private returns (bool){
        for(uint i = 0; i < addresses.length; i++) {
            if(addressMap[addresses[i]].phoneNumber == phone){
                return false;
            }
        }
        return true;
    }
}